# PRD — CRUD de Projeto (novo topo da hierarquia)

> Documento vivo. Dono: PM. Contrato do "pronto" desta feature. Referência de produto: **Squidex**.
> Escopo em uma frase: criar **Projeto** como o **novo topo da hierarquia** (card na home: imagem, título, descrição), com **CRUD de backend** + **upload seguro de imagem** + a **camada data/domain** do editor que consome — **sem UI** (o Claude Design cuida das telas).
>
> **⚠️ Defaults provisórios (humano ausente, 2026-07-09).** O humano autorizou construir as partes não-design. As cinco decisões de produto foram travadas como **default adotado na ausência do humano — a confirmar** (ver _Decisões travadas_). O storage está **resolvido tecnicamente** (tech-lead + CISO). O dev segue sobre estes defaults; cada um é revisável na volta do humano.

## Problema

Não existe entidade Projeto. `Content.projectId` é `String` livre com default `"default"` — placeholder multi-tenant. A home lista conteúdos direto, sem um nível acima. Sem Projeto como raiz não há como separar o trabalho em espaços (cards, à la Squidex), ancorar categorias/conteúdos num escopo real (item 10) nem dar identidade visual (imagem/título/descrição) ao espaço.

## Objetivo

1. Criar `Project` como **topo da hierarquia**: `Projeto → Categorias → Conteúdos`.
2. Entregar **CRUD de Projeto** no backend (`/v1/projects`) com **upload de imagem por arquivo** e pipeline de segurança do CISO.
3. Transformar `Content.projectId` (e a futura `Category.projectId`) em **FK real** para `Project`.
4. Entregar a camada **data/domain** de um novo `projects_module` no editor que consome o CRUD — **sem UI** (Claude Design).

## Escopo

**Dentro:**
- CRUD REST `/v1/projects` (list/get/create/update/delete).
- Upload de imagem (arquivo) + serving seguro; storage via port `StorageService` (adapter local default + adapter S3 pronto por env).
- Modelo Prisma: tabela `Project`; `Content.projectId` vira FK → `Project`.
- Seed/migração (banco do zero) com **seed de "Projeto Padrão" (id `default`)** — default provisório (Decisão 2).
- Editor: `projects_module` (`domain`/`data`) — `Project`, contrato, use cases, models zard, repo impl.

**Fora (não-escopo):**
- UI de projetos (home/cards/formulário/detalhe) — **Claude Design**.
- Categorias + CRUD/filtro/paginação de conteúdos — **item 10**.
- Autenticação — feature à parte (débito de segurança registrado).
- Escolha final Garage vs R2 + credenciais — decisão parada; bloqueia o **deploy real** do upload, **não o desenvolvimento** (adapter local cobre o dev).

## Contrato REST — `/v1/projects`

Tenant/escopo segue por header `x-project-id` **por consistência com o contrato atual** (débito de segurança — ver Riscos). O prefixo global `/v1` é herdado.

> **Nota de modelagem:** hoje "projeto" É o tenant (`x-project-id`). Ao criar a entidade `Project`, o `id` do projeto **passa a ser** o valor que hoje vive em `x-project-id`. O CRUD de `/v1/projects` opera sobre a **coleção de projetos** do tenant/instalação; conteúdos e categorias continuam escopados por `projectId` = `Project.id`. **Consequência da Decisão 5 (auth adiada):** enquanto não há auth, o CRUD de projetos é efetivamente **global** (qualquer cliente lista/cria/apaga todos os projetos), pois não há escopo acima de projeto no header. Registrado como débito de segurança.

### `GET /v1/projects` — lista (cards da home)

Resposta `200` — array de resumos (o que o card precisa):

```json
[
  {
    "id": "abc123cuid2",
    "title": "Meu App",
    "description": "App de delivery",
    "imageUrl": "https://.../v1/projects/abc123cuid2/image",
    "createdAt": "2026-07-09T11:00:00.000Z",
    "updatedAt": "2026-07-09T12:00:00.000Z"
  }
]
```

- `imageUrl`: URL servível pela imagem do projeto; **`null`** quando o projeto não tem imagem. (Se a imagem for servida pelo próprio backend, é a rota de serving; se por S3 público/assinado, é a URL do objeto — transparente para o card.)
- `description` omitido quando nulo (padrão do service atual).
- `createdAt` **incluído na lista** (Decisão C — ver `variance_report.md`): é um escalar trivial e a entidade única `Project` do domain o exige sempre; incluí-lo evita um `createdAt` nullable no domain ou um split summary/detail. Lista e detalhe têm a mesma forma.
- Ordenação default `updatedAt desc` (a decidir se precisa de mais — segue o padrão de conteúdos).

### `POST /v1/projects` — criar

**`multipart/form-data`** (por causa do arquivo de imagem):

| Campo | Tipo | Regras |
|---|---|---|
| `title` | text | **obrigatório**, 1–120 chars |
| `description` | text | opcional, ≤ 280 chars |
| `image` | file | **opcional** (Decisão 3) — png/jpg/webp, ≤ limite (ver segurança). Ausente → card com placeholder. |

Resposta `201` — o projeto criado (mesma forma do item de lista, com `imageUrl`). Sem `slug` (Decisão 3).

### `GET /v1/projects/:id` — detalhe

`200` com `{ id, title, description?, imageUrl, createdAt, updatedAt }`; inexistente → `404`.

### `PUT /v1/projects/:id` — atualizar

**`multipart/form-data`**, todos os campos opcionais (atualiza só o enviado):

| Campo | Tipo | Regras |
|---|---|---|
| `title` | text | opcional, 1–120 chars |
| `description` | text | opcional, ≤ 280 chars |
| `image` | file | opcional — **enviar** substitui a imagem (a antiga é removida do storage) |
| `removeImage` | text `"true"` | opcional — **remove** a imagem atual sem enviar outra |

`200` com o projeto atualizado; inexistente → `404`.

### `DELETE /v1/projects/:id` — apagar

`204` sem corpo; inexistente → `404`. **Projeto com categorias/conteúdos NÃO pode ser apagado** (`onDelete: Restrict` — Decisão 1): a tentativa retorna **409 traduzido** (não 500 cru); o usuário esvazia/move antes (UX no Claude Design). A imagem no storage é removida junto ao apagar um projeto vazio.

### Erros

| Situação | HTTP |
|---|---|
| `title` ausente/vazio no create, ou > limites | 400 |
| imagem com tipo/magic-bytes fora da allowlist, ou acima do limite | 400 (ou 413 no estouro do limite de body) |
| projeto inexistente em get/put/delete | 404 |
| delete de projeto com categorias/conteúdos (`Restrict`, Decisão 1) | 409 (traduzido, não 500 cru) |
| sucesso | 200 / 201 / 204 |

## Modelo de dados / migração (Prisma)

```prisma
model Project {
  id          String   @id @default(cuid(2))
  title       String
  description String?
  imageKey    String?  @map("image_key")   // chave/URL no storage; NUNCA o binário
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  contents    Content[]
  // categories Category[]  // chega no item 10

  @@map("projects")
}

model Content {
  // ... campos atuais ...
  projectId String  @map("project_id")               // deixa de ter default "default"
  project   Project @relation(fields: [projectId], references: [id], onDelete: Restrict)  // Decisão 1

  @@unique([projectId, slug])
  @@index([projectId])
  @@map("contents")
}
```

- **`Project.imageKey`**: guarda **só a chave/URL** da imagem no storage; o binário nunca entra no Postgres. `null` = projeto sem imagem.
- **`Content.projectId` vira FK** (`references: [id]`); perde o `@default("default")`. `onDelete: Restrict` (Decisão 1) — não se apaga projeto com conteúdos.
- **Banco recriado do zero** (decisão do humano, alinhada ao item 10): sem backfill de dados legados. **O seed cria um `Project` de id `"default"`** (Decisão 2) — o `x-project-id=default` resolve para ele e nenhuma FK de conteúdo fica órfã. Dado de dev, se houver, é descartável.
- A futura `Category` (item 10) também referenciará `Project` — modelar de forma que o item 10 **não precise re-migrar** `Project`.

## Segurança do upload (não-negociáveis do CISO)

Pipeline **obrigatório** no endpoint de upload (create/update com `image`):

1. **Magic bytes** — detectar o tipo real com `file-type` (não confiar no `Content-Type`/extensão do cliente).
2. **Allowlist fechada** — **png / jpg / webp** apenas. **SVG proibido** (vetor de XSS).
3. **Reencode com `sharp`** — reprocessa a imagem: mata polyglot/webshell embutido, **strip EXIF**, **limita a dimensão decodificada** (defesa contra decompression bomb).
4. **Nome por UUID gerado no servidor** — nunca usar o filename do cliente (path traversal / overwrite).
5. **Serving seguro** — content-type **fixado no tipo detectado** + header **`X-Content-Type-Options: nosniff`**.
6. **Limite de tamanho em duas camadas** — nginx/Traefik `client_max_body_size` **E** `multer` no Nest (defesa em profundidade).
7. **Rate-limit** no endpoint de upload.
8. **Escopo de tenant por UUID não-enumerável** (o `id` CUID2 já ajuda; a chave da imagem também por UUID).

**Deps novas do backend:** `multer` (via interceptor do `@nestjs/platform-express`), `sharp`, `file-type`, `@aws-sdk/client-s3`. **Configurar limite de body no bootstrap** (`main.ts` hoje não tem — o default ~100kb do Express estoura imagem).

**Storage (resolvido tecnicamente):** port `StorageService` (`put`/`get`/`delete`), adapter **local** (default reversível, dev) + adapter **S3** (`@aws-sdk/client-s3`, pronto, ativado por env). `Project.imageKey` guarda a chave. Escolha final Garage (`s3.bmjtech.duckdns.org`) vs R2 + credenciais = **Decisão 4 (parada, não trava o dev)**.

## Editor — camada data/domain (`projects_module`)

Espelha o `contents_module` (gabarito), **sem UI**:

- `domain/entities/project.dart` — `Project extends Equatable` (id, title, description?, imageUrl?, updatedAt).
- `domain/repositories/projects_repository.dart` — `abstract interface class` com `Future<Either<Failure, T>>`:
  - `getProjects()` → `List<Project>`
  - `getProject(id)` → `Project`
  - `createProject({title, description?, imageBytes?})` → `Project`
  - `updateProject(id, {title?, description?, imageBytes?, removeImage?})` → `Project`
  - `deleteProject(id)` → `Unit`
- `domain/use_cases/*` — um use case por operação (`call()`).
- `data/models/project_model.dart` — zard (`z.map({...}).safeParse` → `Either`), erro → `ValidationFailure(z.prettifyError(...))`.
- `data/repositories/projects_repository_impl.dart` — `Dio` injetado; **único try/catch**; multipart no create/update (imagem como bytes); traduz `DioException` → `Failure` (404→NotFound, 400→Validation, 413→específica/Network, timeout/connError→Network, 409→Conflict se `onDelete: Restrict`).
- `projects_routes.dart` + `projects_injection.dart` + barrel `projects_module.dart` (expõe **só** rota e DI).

> A UI (home/cards/formulário) consome essa camada. O que ela precisa consumir, por operação: **list** (cards: title, description, imageUrl, updatedAt), **create** (title obrigatório + description + imagem opcional), **update** (idem + trocar/remover imagem), **delete** (id), **get** (detalhe).

## Decisões travadas (defaults provisórios — a confirmar com o humano)

> Todas travadas em **2026-07-09** como **default adotado na ausência do humano — a confirmar** na volta dele. O dev implementa sobre elas; as alternativas ficam registradas para revisão. Storage (Decisão 4) segue **parada**.

### 1. `onDelete` de Projeto = **`Restrict`** — *default adotado na ausência do humano — a confirmar*

Um projeto é dono de categorias (item 10) e conteúdos. **Travado: `Restrict`** — não se apaga um projeto que ainda tem conteúdos/categorias; o usuário esvazia/move antes (UX no Claude Design). Coerente com o item 10 (`Content → Category` também é `Restrict`); protege contra perda acidental. A tentativa de apagar projeto não-vazio retorna **409 traduzido**.

Alternativas descartadas (por ora): **`Cascade`** (apagar projeto apaga tudo — destrutivo/irreversível, exige confirmação dupla + cascata de imagens no storage); **soft-delete** (`deletedAt` — mais seguro, mas adiciona coluna + filtro em toda query + "lixeira"; escopo maior, overkill agora). *Se o humano preferir o fluxo "apagar projeto = apagar tudo", trocar para `Cascade` + confirmação forte na UI.*

### 2. Seed de **"Projeto Padrão" (id `default`)** na migração — *default adotado na ausência do humano — a confirmar*

Banco recriado do zero; `Content.projectId` vira FK NOT NULL → precisa existir **algum** `Project` antes de qualquer conteúdo. **Travado:** a migração/seed cria um `Project` de **id `"default"`** (title "Projeto Padrão", `parentId=null`), mantendo o `x-project-id=default` resolvendo e sem FK órfã. Menos atrito em dev/hml.

**Ponto explicitamente em aberto (humano/Claude Design):** a **UX de primeira-experiência da home** — mostrar o projeto default como um card **ou** exibir um empty-state "crie seu primeiro projeto" (à la Squidex). **O seed NÃO impede nenhuma das duas:** ele só garante integridade de FK no backend; **o frontend decide se esconde ou mostra o projeto `default`**. Esta escolha de produto/design é do humano e não bloqueia o backend.

### 3. Campos e validações do Projeto — *default adotado na ausência do humano — a confirmar*

- **Sem `slug`** — o `id` CUID2 basta como referência; título é livre. *(Se surgir necessidade de URL amigável, adicionar depois com `@@unique` + `409 + suggestedSlug` como nos conteúdos.)*
- **Título:** obrigatório, 1–120 chars (espelha `name` de conteúdo).
- **Descrição:** opcional, ≤ 280 chars (espelha conteúdo).
- **Imagem opcional no create** — cria sem imagem, adiciona depois; card mostra placeholder quando ausente. *(Se o humano quiser obrigatória, o create passa a exigir `image` e rejeita sem ela com 400.)*

### 4. Storage: adapter local no dev; Garage vs R2 = **decisão PARADA do humano**

Resolvido tecnicamente (port `StorageService` + adapters). **Travado para o dev:** desenvolver contra o **adapter local** (default reversível). **Parado (humano):** a escolha **Garage** (`s3.bmjtech.duckdns.org`, sem custo, sob controle do time) **vs. Cloudflare R2** (gerenciado, egress barato, conta externa) + **credenciais**. Bloqueia **só o deploy real** do upload em hml/prod, **não o desenvolvimento**. Credenciais entram por env no Coolify (nunca no repo).

### 5. Auth: seguir **sem autenticação** — *default adotado na ausência do humano — a confirmar* — **débito de segurança**

A API não tem auth hoje (header `x-project-id` controlável pelo cliente). O CISO quer o upload atrelado ao projeto autenticado. **Travado:** seguir **sem auth** nesta feature (auth é feature à parte, fora do escopo), mantendo `x-project-id`. **Débito de segurança explícito:** enquanto não há auth, o CRUD de `/v1/projects` é efetivamente **global** — qualquer cliente lista/cria/apaga qualquer projeto, pois não há escopo acima de projeto no header. **A confirmar com o humano** se isso é aceitável para hml/demo e quando priorizar auth.

## Critérios de aceite

**Backend**
- [ ] `GET /v1/projects` devolve os cards (id, title, description?, imageUrl, createdAt, updatedAt); ordenado `updatedAt desc`.
- [ ] `POST /v1/projects` (multipart) cria com `title` obrigatório (400 sem ele), `description` opcional, `image` opcional; devolve o projeto com `imageUrl`.
- [ ] `GET /v1/projects/:id` devolve o detalhe; inexistente → 404.
- [ ] `PUT /v1/projects/:id` atualiza campos enviados; trocar imagem remove a antiga do storage; `removeImage=true` zera a imagem.
- [ ] `DELETE /v1/projects/:id` → 204 num projeto **vazio** (imagem removida do storage); num projeto **com** conteúdos/categorias → **409 traduzido** (`Restrict`, Decisão 1), não 500 cru.
- [ ] Upload: rejeita tipo fora de png/jpg/webp (magic bytes), reencoda com sharp (EXIF stripado, dimensão limitada), nomeia por UUID do servidor, serve com content-type fixo + `nosniff`, respeita limite de body em duas camadas, rate-limit ativo.
- [ ] `Content.projectId` é FK para `Project` (`onDelete: Restrict`); migração recria o schema do zero e aplica em hml.
- [ ] Seed cria o `Project` id `"default"` (Decisão 2); `x-project-id=default` resolve; nenhuma FK órfã.
- [ ] `build` do backend verde.

**Editor (data/domain)**
- [ ] `ProjectsRepository` cobre list/get/create/update/delete + imagem (bytes) via multipart.
- [ ] `ProjectModel` (zard) valida o payload; inválido → `ValidationFailure` descritiva.
- [ ] Nenhuma regressão na home de conteúdos (o `projectId` passa a vir de um projeto real; confirmar que o fluxo atual continua).
- [ ] `flutter analyze` verde.

**E2E (por script, rodadas)**
- [ ] `e2e.sh` cobre por API: CRUD completo de projeto, upload válido (png/jpg/webp) e inválido (svg/tipo forjado/oversize → rejeitado), serving com headers corretos, delete de projeto vazio (204) **e** de projeto com conteúdos (409 `Restrict`).

## Analytics (a instrumentar)
- Criação/edição/exclusão de projeto; upload de imagem (sucesso/rejeição por tipo/tamanho). *Detalhamento no `ANALYTICS.md` no fechamento.*

## Erros monitorados
- Upload rejeitado (tipo/magic-bytes/tamanho) — distinguir tentativa maliciosa de erro honesto do usuário.
- Payload de projeto que falha o parse zard no editor → `ValidationFailure` logada.
- Falha no `StorageService` (put/get/delete) — indício de storage indisponível/misconfig.
- Tentativa de delete de projeto com filhos sob `Restrict` (409 tratado, nunca 500 cru).

## Riscos

- **[DEFAULT PROVISÓRIO] Decisões 1 e 2 travadas na ausência do humano:** `onDelete: Restrict` e seed de "Projeto Padrão" (id `default`) definem a migração e o comportamento de delete/seed. O dev segue sobre elas; **a confirmar na volta do humano** — reverter `Restrict`→`Cascade` ou trocar a estratégia de seed teria custo de re-migração (baixo com banco do zero, mas real). A UX de primeira-experiência da home segue em aberto (não bloqueia o backend).
- **[SEGURANÇA] Upload é superfície de ataque:** o pipeline do CISO é **não-negociável**; qualquer atalho (aceitar SVG, confiar no content-type do cliente, servir sem `nosniff`, usar o filename do cliente) é reprovação de gate. CISO revisa a fase de upload.
- **[SEGURANÇA/DÉBITO] Sem auth:** CRUD/upload sem autenticação; escopo de tenant frágil (`x-project-id` controlável). Registrado como débito; auth é feature à parte.
- **[DEPLOY] Storage não decidido:** dev roda no adapter local; **não ligar upload em hml/prod** sem a Decisão 4 e credenciais por env no Coolify.
- **[MIGRAÇÃO] `projectId` vira FK NOT NULL:** exige que exista `Project` antes de qualquer conteúdo (Decisão 2). Banco do zero elimina backfill, mas o seed é pré-condição dura.
- **[INTEGRAÇÃO] Este é o novo topo:** o item 10 (categorias) e todo o resto passam a assumir um `Project` existente. Mudanças aqui têm blast radius alto — o modelo de `Project` deve nascer estável para o item 10 não re-migrar.
