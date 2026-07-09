# plan.md — CRUD de Projeto (novo topo da hierarquia)

> Documento vivo. Dono: **tech-lead**. Guardião do plano. Fonte: `prd.md` + `specs.md` (aprovados; defaults provisórios 2026-07-09).
> Branch: `feature/crud-projeto`. 1 feature, 1 branch → as fases são **marcos incrementais** (podem entrar em commits separados ou agrupados no mesmo PR).
> Regra de ouro do "pronto": **`flutter analyze` verde + `backend build` verde + testes existentes passando** (nunca opinião). A bateria automatizada nova é escrita **por último** (após E2E).

## Escopo desta rodada (travado pelo humano)

Construímos **só as partes NÃO-visuais**: backend (NestJS+Prisma+Postgres) + a camada **domain/data** de um novo `projects_module` no editor. A camada **presentation/UI** fica **BLOQUEADA POR DESIGN (humano)** — o humano desenha as telas (home com cards, formulário) no Claude Design; ligamos depois.

## Gabaritos (o que imitar — já levantado)

**Backend** (`backend/src/contents/`): `contents.controller.ts` (header `x-project-id` → `projectOf`), `contents.service.ts` (CUID2 pelo Prisma, `$transaction`, `updateMany`/`deleteMany` escopados + `count===0`→`NotFoundException`, 409 traduzido via `PrismaClientKnownRequestError` P2002), `dto/*.dto.ts` (class-validator), `contents.module.ts`, `main.ts` (ValidationPipe global, prefixo `/v1`, CORS — **sem limite de body hoje**), `prisma/schema.prisma`, `prisma/prisma.service.ts`.

**Editor** (`apps/driva_editor/lib/modules/contents_module/`): `domain/entities/content_summary.dart` (Equatable), `domain/repositories/contents_repository.dart` (`abstract interface class` → `Future<Either<Failure,T>>`), `domain/use_cases/*` (um por operação, `call()`), `data/models/content_summary_model.dart` (zard `safeParse`→Either, erro→`ValidationFailure(z.prettifyError)`), `data/repositories/contents_repository_impl.dart` (Dio injetado, **único try/catch**, `DioException`→`Failure`), `contents_injection.dart` / `contents_routes.dart` / `contents_module.dart` (barrel só rota+DI). Falhas em `core/error/failure.dart` (`sealed`: Network/Validation/NotFound/Conflict/Unexpected).

---

## Fases

Legenda: **[JÁ]** construível agora · **[BLOQUEADA POR DESIGN]** espera o Claude Design · **[∥]** paralelizável com fases marcadas com o mesmo símbolo.

### F1 — Schema Prisma + migração + seed + StorageService (port + adapter local)  **[JÁ]**

**Objetivo.** Modelo de dados no lugar (tabela `projects`, `Content.projectId` vira FK), banco recriado do zero com seed do `Project` id `default`, e o port `StorageService` com adapter local funcional. É a fundação — tudo depende dela.

**Especialista:** `especialista-infra` (backend).

**Arquivos a criar/tocar:**
- `backend/prisma/schema.prisma` — adicionar `model Project` (id `@default(cuid(2))`, `title`, `description?`, `imageKey @map("image_key")`, timestamps, `contents Content[]`, `@@map("projects")`); alterar `model Content`: `projectId` perde `@default("default")`, ganha `project Project @relation(fields:[projectId], references:[id], onDelete: Restrict)`. Manter `@@unique([projectId, slug])` e `@@index([projectId])`. Modelar de forma que o item 10 (Category) **não re-migre** Project.
- `backend/prisma/migrations/<ts>_add_projects/migration.sql` — **banco do zero, sem backfill**: cria `projects`, adiciona FK em `contents`. Ordem: criar `projects` → seed do `default` → adicionar constraint FK (senão a FK NOT NULL falha com contents órfãos, mas banco é do zero então é seguro; ainda assim seed antes da FK é mais robusto).
- **Seed do `Project` id `"default"`** (title "Projeto Padrão"): decidir mecanismo — **preferência: `INSERT ... ON CONFLICT DO NOTHING` dentro da própria migration SQL** (roda em `migrate deploy` antes de qualquer código, garante FK não-órfã sem depender de script TS separado; segue o racional já usado na migration de rename). Alternativa `prisma/seed.ts` + `package.json` `prisma.seed` só se o time preferir seed idempotente fora da migration — **decisão de implementação do infra**, registrar no commit.
- `backend/src/storage/storage.service.ts` — port (interface abstrata Nest `abstract class StorageService` ou token de injeção): `put(key, buffer, contentType)`, `get(key)`, `delete(key)`.
- `backend/src/storage/local-storage.service.ts` — adapter local (filesystem, pasta configurável por env, default de dev). **Default reversível.**
- `backend/src/storage/storage.module.ts` — provê o adapter conforme env (`STORAGE_DRIVER=local|s3`, default `local`); no F1 só o local.
- (S3 adapter fica no F2, junto do resto do upload, para não inflar F1.)

**Paralelismo:** F1 é **pré-requisito duro** de todo o resto do backend (F2). Internamente, o port/adapter (`src/storage/*`) e o schema/migração podem ser escritos em paralelo por serem independentes, mas é 1 especialista — trate como sequencial leve.

**Pronto quando:** `backend` build verde; `prisma migrate` aplica num Postgres novo sem erro; seed cria o `Project` `default`; um teste manual rápido de `contents` existente continua funcionando (o `projectId=default` resolve para o projeto real, sem FK órfã).

**Risco/pré-req:** requer Postgres novo (banco do zero — dado de dev descartável). Ordem seed→FK na migration é crítica. **`dart pub get` não é necessário** para F1 (backend só). Instalar deps npm novas **não** é necessário no F1 (multer/sharp/file-type/aws-sdk entram no F2).

---

### F2 — Backend: Project CRUD + upload seguro (pipeline CISO) + limite de body  **[JÁ]**

**Objetivo.** `/v1/projects` completo (list/get/create/update/delete) com upload de imagem multipart, pipeline de segurança **não-negociável do CISO**, serving seguro, limite de body em duas camadas e rate-limit. Depende de F1.

**Especialista:** `especialista-infra` (backend). **Gate obrigatório do CISO nesta fase** (upload é superfície de ataque).

**Arquivos a criar/tocar:**
- `backend/src/projects/projects.controller.ts` — rotas `@Controller('projects')`, header `x-project-id` (helper `projectOf` igual ao de contents), `@Post`/`@Put` com `@UseInterceptors(FileInterceptor('image', { limits: { fileSize } }))` do `@nestjs/platform-express`; rota de serving `GET :id/image` (content-type detectado + `X-Content-Type-Options: nosniff`).
- `backend/src/projects/projects.service.ts` — CRUD Prisma (imita contents): list `select` id/title/description/imageKey/updatedAt + mapeia `imageUrl`; create `$transaction`; update `updateMany` escopado + `count===0`→404; delete escopado; **tradução de `onDelete: Restrict` (P2003) → 409** (análogo ao P2002→409 de contents), nunca 500 cru; ao trocar/remover imagem ou apagar projeto vazio, chamar `StorageService.delete` da chave antiga.
- `backend/src/projects/dto/create-project.dto.ts` — `title` `@IsNotEmpty @MaxLength(120)`; `description?` `@IsOptional @MaxLength(280)`. (Multipart: campos texto validados; o `image` é `file`, tratado no interceptor/pipeline, não no DTO.)
- `backend/src/projects/dto/update-project.dto.ts` — todos opcionais + `removeImage?` (`"true"`).
- `backend/src/projects/image-pipeline.ts` (ou `projects.upload.ts`) — **pipeline CISO**: (1) magic bytes com `file-type`; (2) allowlist fechada **png/jpg/webp** (SVG proibido); (3) reencode com `sharp` (strip EXIF + limite de dimensão anti-decompression-bomb); (4) nome por **UUID do servidor** (`crypto.randomUUID`), nunca o filename do cliente; devolve `{ key, contentType, buffer }` para o `StorageService.put`.
- `backend/src/storage/s3-storage.service.ts` — adapter **S3** (`@aws-sdk/client-s3`) codado e pronto, ativado por `STORAGE_DRIVER=s3` + envs (bucket/endpoint/creds). **Não ligar em hml/prod** sem a Decisão 4 (Garage vs R2 + creds) — dev roda no local.
- `backend/src/projects/projects.module.ts` — controller + service + StorageService + PrismaService.
- `backend/src/app.module.ts` — importar `ProjectsModule`.
- `backend/src/main.ts` — **configurar limite de body** (o default ~100kb do Express estoura imagem): `express.json({ limit })` / raw limit no bootstrap; garantir que multipart não seja barrado antes do multer. Rate-limit no endpoint de upload (`@nestjs/throttler` ou guard dedicado — decisão de implementação; registrar).
- `backend/package.json` — deps novas: `@nestjs/platform-express` (já existe), `multer`+`@types/multer`, `sharp`, `file-type`, `@aws-sdk/client-s3`, e `@nestjs/throttler` se for a via de rate-limit.
- **Limite de body — 2ª camada (infra):** documentar/ajustar `client_max_body_size` no nginx/Traefik em `docs/deploy/` (deploy só liga com storage decidido; a config vai no repo/docs, não o segredo). Se a mudança for só de deploy, registrar como TODO de deploy no plano, não bloqueia o build.

**Paralelismo:** internamente sequencial (um especialista, forte acoplamento CRUD↔pipeline↔storage). **Não paraleliza com F1** (depende dela). **Paraleliza com F3** (editor domain é independente do backend — ver abaixo).

**Pronto quando:** `backend` build verde; `npm install` das deps novas ok; CRUD responde os códigos do contrato (201/200/204/404/409/400); upload rejeita svg/tipo-forjado/oversize; serving devolve content-type fixo + `nosniff`; **gate CISO aprovado**. (E2E por script vem nas rodadas finais, não aqui.)

**Risco/pré-req:** superfície de ataque — **atalho no pipeline = reprovação de gate** (aceitar SVG, confiar no content-type do cliente, servir sem `nosniff`, usar filename do cliente). Oversize pode ser 413 (camada body) ou 400 (multer) — o infra escolhe a camada e documenta. `npm install` obrigatório (deps novas).

---

### F3 — Editor: `projects_module` **domain** (entidade + contrato + use cases)  **[JÁ]** **[∥ com F2]**

**Objetivo.** A camada domain do novo módulo: Dart puro, sem UI, sem data. Espelha o `contents_module`.

**Especialista:** `especialista-dominio`.

**Arquivos a criar (novo módulo via skill `criar-modulo` como scaffold):**
- `apps/driva_editor/lib/modules/projects_module/domain/entities/project.dart` — `Project extends Equatable` (id, title, description?, imageUrl?, updatedAt). **Sem slug.** (`imageUrl` é o que a UI/card consome; o `imageKey` do backend não vaza para o domain.)
- `domain/entities/entities.dart` (barrel).
- `domain/repositories/projects_repository.dart` — `abstract interface class ProjectsRepository` → `Future<Either<Failure,T>>`:
  - `getProjects()` → `List<Project>`
  - `getProject(String id)` → `Project`
  - `createProject({required String title, String? description, List<int>? imageBytes, String? imageFilename})` → `Project`
  - `updateProject(String id, {String? title, String? description, List<int>? imageBytes, String? imageFilename, bool removeImage})` → `Project`
  - `deleteProject(String id)` → `Unit`
- `domain/repositories/repositories.dart` (barrel).
- `domain/use_cases/{get_projects,get_project,create_project,update_project,delete_project}_use_case.dart` — um por operação, `call()`. `CreateProjectUseCase` valida `title` não-vazio/≤120 e `description`≤280 (espelha `CreateContentUseCase`, **sem** validação de slug).
- `domain/use_cases/use_cases.dart` (barrel).

**Paralelismo:** **totalmente independente do backend** — pode rodar **em paralelo com F1 e F2** (só precisa da forma do contrato, já definida no PRD). F4 depende de F3.

**Pronto quando:** `flutter analyze` verde. (Sem testes ainda — bateria por último.)

**Risco/pré-req:** decidir se `imageBytes` (`List<int>`) é o tipo de transporte no contrato (recomendado — mantém domain sem depender de `dart:io`/multipart; a `data` monta o `MultipartFile`). **Nenhuma dep nova** (equatable/fpdart já no workspace) → `dart pub get` **não** necessário para F3.

---

### F4 — Editor: `projects_module` **data** (model zard + repo impl multipart)  **[JÁ]**

**Objetivo.** A camada data: model com validação zard e a impl do repositório com Dio + multipart. Depende de F3 (contrato) e assume o contrato REST de F2 (mas não depende do backend rodando para compilar/analisar).

**Especialista:** `especialista-dados` (único dono do try/catch).

**Arquivos a criar/tocar:**
- `apps/driva_editor/lib/modules/projects_module/data/models/project_model.dart` — `ProjectModel extends Project`; zard `z.map({ id, title, description?, imageUrl? (nullable/optional), updatedAt: z.date() }).safeParse` → Either; erro → `ValidationFailure(z.prettifyError(...))`. Atenção: `imageUrl` é **nullable** (`null` quando sem imagem) — modelar com `z.string().nullable().optional()`.
- `data/models/models.dart` (barrel).
- `data/repositories/projects_repository_impl.dart` — `Dio` injetado; **único try/catch**; `getProjects`/`getProject` (GET+parse), `createProject`/`updateProject` via **`FormData` multipart** (`MultipartFile.fromBytes(imageBytes, filename)` quando presente; campos texto; `removeImage: 'true'` quando pedido), `deleteProject` (DELETE). Tradução `DioException`→`Failure`: 404→`NotFound`, 400→`Validation`, **413→`Validation`/`Network`** (oversize — mensagem clara), **409→`ConflictFailure`** (delete sob `Restrict`), timeout/connError→`Network`, resto→`Unexpected`.
- `data/repositories/repositories.dart` (barrel) + (opcional) `projects_repository_fake.dart` se o padrão de fake-store for replicado — **só se o time achar útil; não é bloqueante**.
- **`core/error/failure.dart` — ponto de atenção:** `ConflictFailure` hoje é **slug-específico** (carrega `suggestedSlug`, mensagem sobre slug). O 409 de projeto é **Restrict** (projeto com filhos), sem slug. **Decisão de implementação:** ou (a) reusar `ConflictFailure` passando uma `message` genérica (o `suggestedSlug` fica `null` — funciona, mas a mensagem default é sobre slug), ou (b) generalizar `ConflictFailure`/adicionar um `RestrictFailure`. **Tocar `core/error` afeta os dois módulos → mudança de core exige aprovação do humano** (registrar em `variance_report.md` se generalizar). Recomendação: (a) no primeiro momento (reuso com message custom), evita mexer no core.

**Paralelismo:** depende de F3. Não paraleliza com F3 (mesmo módulo, contrato→impl). Paraleliza com F2 no sentido de que o editor não precisa do backend de pé para `analyze` — mas o E2E de integração só fecha com F2 pronto.

**Pronto quando:** `flutter analyze` verde. Model parseia payload válido; inválido → `ValidationFailure`. (Testes por último.)

**Risco/pré-req:** `dio`/`fpdart`/`zard` já no workspace → provavelmente **sem dep nova**; confirmar que `MultipartFile.fromBytes` está disponível (dio padrão, sim). Se o barrel/DI do módulo exigir registro, o `projects_injection.dart` + `projects_module.dart` entram aqui como plumbing mínimo (registrar o repo/use cases no get_it), **mas SEM** wire de rota de página (isso é presentation → F5).

---

### F5 — Editor: `projects_module` **presentation** (páginas, cubits, rota)  **[BLOQUEADA POR DESIGN (humano)]**

**Objetivo.** UI da home (cards de projeto) + formulário criar/editar + rota. Cubit com estado `sealed` + `switch` exaustivo, página `StatelessWidget` com `static pageBuilder` (único lugar que toca get_it), guarda `isClosed` pós-`await`. `projects_routes.dart` + registro da rota no `app_router`.

**Especialista:** `especialista-apresentacao`.

**Status:** **BLOQUEADA POR DESIGN (humano)** — as telas vêm do Claude Design. Só ligar quando o design chegar. O `projects_injection.dart` / barrel podem existir do F4 sem a rota de página; F5 adiciona a rota, os cubits, os estados e as páginas, e conecta `ContentsRoutes`/home ao novo topo (Projeto → Conteúdos), incluindo a decisão de UX de primeira-experiência (empty-state vs card `default`) que é do humano.

**Pronto quando (na volta do design):** `flutter analyze` verde + a home renderiza cards + fluxo criar/editar/apagar funciona no E2E manual/script.

---

### F6 — E2E por script (rodadas) + docs vivas + bateria automatizada  **[parcial JÁ / parcial BLOQUEADA]**

**Objetivo.** Fechamento. Ordem do método: **E2E por script primeiro, testes automatizados por último.**

**Especialista:** `qa` (instrumenta/valida) + gates do `ciso`.

- **E2E de backend por API (`e2e.sh`) — [JÁ]** (não depende de UI): CRUD completo de projeto; upload válido (png/jpg/webp) e inválido (svg/tipo forjado/oversize → rejeitado); serving com headers corretos (`nosniff` + content-type detectado); delete de projeto vazio (204) **e** de projeto com conteúdos (409 `Restrict`); seed `default` resolve.
- **E2E visual/canvas (`e2e_shots.sh` + `e2e_drive.mjs`) — [BLOQUEADA POR DESIGN]** (depende de F5).
- **Docs vivas — [JÁ]** (backend/data podem começar): `final_report.md`, `CHANGELOG` (Unreleased), `ANALYTICS.md`, `ERROR_LOGS`; `docs/roadmap.md` marca o item. Fechamento total espera F5.
- **Bateria automatizada — [parcial]**: unit dos use cases (F3) + model/repo (F4) podem ser escritos assim que F3/F4 fecharem e passarem no gate; widget/golden da UI ficam **BLOQUEADOS por F5**. **Escrita por último**, após o E2E atestado e o 2º gate do CISO.

**Pronto quando:** E2E de backend atestado por rodadas (evidências em `evidencias/rodada_MM/`); gate CISO; testes verdes; docs em dia (DoD).

---

## Ordem de execução e paralelismo (resumo)

```
F1 (schema+seed+storage local)          [JÁ]  ── pré-requisito duro do backend
   │
   ├── F2 (backend CRUD+upload+CISO)     [JÁ]  ─┐  (depende de F1)
   │                                            ├─ podem ir em paralelo entre si
   └── F3 (editor domain)                [JÁ]  ─┘  (independe do backend)
                                                    │
                                          F4 (editor data)   [JÁ]  (depende de F3)
                                                    │
                                          F5 (presentation)  [BLOQUEADA POR DESIGN]
                                                    │
                                          F6 (E2E + docs + testes)  [parcial JÁ / parcial bloqueada]
```

**Frente A (backend):** F1 → F2 → (E2E backend do F6). Um especialista-infra, gate CISO no F2.
**Frente B (editor):** F3 → F4 (→ F5 quando o design chegar). especialista-dominio depois especialista-dados.
**As duas frentes rodam em paralelo** (não se tocam até o E2E de integração). Máximo de paralelismo real: **F3 ∥ F1/F2**.

## Pré-requisitos globais / riscos técnicos

- **Postgres do zero:** F1 recria o schema; dado de dev é descartável (decisão do humano). Sem backfill.
- **npm install (F2):** deps novas backend (`multer`, `sharp`, `file-type`, `@aws-sdk/client-s3`, possivelmente `@nestjs/throttler`). `sharp` tem binário nativo — confirmar no build/CI do Coolify (Dockerfile do backend).
- **`dart pub get`:** provavelmente **desnecessário** — o editor não ganha dep nova (equatable/fpdart/zard/dio já no workspace). Confirmar ao criar o módulo; se algo faltar, rodar na raiz.
- **Tocar `core/error` (F4):** se generalizar `ConflictFailure`, é mudança de core que afeta contents_module → **aprovação do humano + `variance_report.md`**. Recomendação: reusar com message custom para não mexer no core agora.
- **Limite de body em 2 camadas (F2):** a camada nginx/Traefik é config de deploy (docs), não bloqueia build; a camada multer é código.
- **Storage decidido só no deploy (Decisão 4 parada):** dev roda 100% no adapter local; **não ligar upload em hml/prod** sem Garage-vs-R2 + creds por env no Coolify. Não bloqueia F1–F4.
- **Blast radius alto:** Project é o novo topo; o modelo deve nascer estável para o item 10 (Category) não re-migrar. FK `Content.projectId` deixa de ter default → seed `default` é pré-condição dura.

## Progresso

- [ ] F1 — Schema + migração + seed + StorageService local
- [ ] F2 — Backend CRUD + upload seguro (CISO) + limite de body
- [ ] F3 — Editor domain
- [ ] F4 — Editor data
- [ ] F5 — Editor presentation **(BLOQUEADA POR DESIGN)**
- [ ] F6 — E2E por script + docs vivas + bateria automatizada

## Variância

Nenhuma até agora. Desvios do plano só entram com **aprovação do humano** e registro em `variance_report.md` (como estava / por que mudou / o que mudou).
