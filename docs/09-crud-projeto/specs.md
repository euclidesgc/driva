# Specs — CRUD de Projeto (novo topo da hierarquia)

> Documento vivo. Dono: PM. Base técnica levantada no código atual, com o tech-lead e a análise de storage do tech-lead+CISO.
> Roadmap: item **novo**, inserido **antes** do item 10. Referência de produto: CMS **Squidex**.
>
> **⚠️ Defaults provisórios (humano ausente, 2026-07-09).** O humano autorizou construir as partes não-design; as decisões abaixo foram travadas como **default adotado na ausência do humano — a confirmar** na volta dele. O desenvolvimento pode seguir sobre elas. Nenhuma é irreversível sem custo baixo (todas ficam explicitadas para revisão).

## Problema

Hoje **não existe entidade Projeto**. `Content.projectId` é só uma `String` com default `"default"` — um placeholder multi-tenant no schema, controlável pelo header `x-project-id`. A home lista **conteúdos direto**, sem um nível acima. Sem Projeto como raiz, não há como:

- separar o trabalho do usuário em espaços independentes (cards na home, estilo Squidex);
- ancorar categorias e conteúdos dentro de um escopo real (o item 10 constrói categorias/conteúdos **dentro** de um projeto);
- dar identidade visual ao espaço (imagem, título, descrição).

## Objetivo

Criar **Projeto** como o **novo topo da hierarquia** do produto:

```
Projeto (card na home: imagem, título, descrição)   ← NOVO, primeira página
   └── Categorias (árvore, parentId)                  ← item 10
          └── Conteúdos                                ← já existe, passa a viver num projeto
```

`projectId` deixa de ser string livre e passa a ser **FK real** para `Project`. Esta feature entrega o **CRUD de Projeto** (backend NestJS + Prisma + Postgres) e a **camada data/domain** do editor que o consome. A **UI** (home com cards, formulário) é feita pelo humano no Claude Design — aqui só o **contrato** e o que a UI vai precisar consumir.

## Escopo

**Dentro:**
- **Backend** — CRUD de Projeto: `POST/GET/GET:id/PUT:id/DELETE:id /v1/projects`.
- **Upload de imagem do projeto** (arquivo, não URL): endpoint de upload + pipeline de segurança + serving da imagem. Storage por **port `StorageService`** com adapter local (default reversível) e adapter S3 codado/pronto (ativado por env).
- **Modelo Prisma** — tabela `Project` + transformar `Content.projectId` (e futura `Category.projectId`) em **FK** para `Project`.
- **Seed/migração** — banco recriado do zero (decisão do humano no item 10); precisa de projeto default? (decisão em aberto).
- **Editor** (novo `projects_module`, camada `domain`/`data`): entidade `Project`, contrato de repositório, use cases (list/get/create/update/delete + upload de imagem), models zard, repo impl. **Sem UI** — telas vêm do Claude Design.

**Fora (não-escopo):**
- **UI de projetos** — home com cards, formulário de criar/editar, tela de detalhe (Claude Design). Aqui só a infra de dados/contrato.
- **Categorias e o CRUD/filtro/paginação de conteúdos** — item 10, construído **dentro** de um projeto depois desta feature.
- **Autenticação real** — a API segue sem auth (header `x-project-id`); é feature à parte. Registrada como **débito de segurança** (ver Riscos).
- **Escolha final Garage vs R2 e credenciais de S3** — decisão parada do humano; **bloqueia o deploy real do upload, não o desenvolvimento**.

## Estado atual (levantado no código)

- **Prisma** (`backend/prisma/schema.prisma`): `model Content { id (cuid2), projectId @default("default") @map("project_id"), name, slug, description?, spec Json, createdAt, updatedAt, @@unique([projectId, slug]), @@index([projectId]) }`. **`projectId` é `String` livre, sem FK. Nenhum `model Project`.**
- **Controller** (`contents.controller.ts`): tenant por header `x-project-id`; helper `projectOf(header)` → `header?.trim() || 'default'`. Prefixo global `/v1`.
- **Service** (`contents.service.ts`): padrões a imitar — id **CUID2** cunhado pelo Prisma (`@default(cuid(2))`), slug conflict → **409** com `suggestedSlug` já calculado no corpo, `$transaction` no create, `updateMany`/`deleteMany` escopados por `projectId` (retorno `count===0` → `NotFoundException`).
- **DTOs** (`create-content.dto.ts`, `update-content.dto.ts`): `class-validator` — `@IsString @IsNotEmpty @MaxLength(120)` no name; slug com `@Matches(/^[a-z][a-z0-9-]*$/)`; description `@IsOptional @MaxLength(280)`.
- **Editor** — módulo espelho em `apps/driva_editor/lib/modules/contents_module/`:
  - `domain/entities/content_summary.dart`: `ContentSummary extends Equatable` (id/name/slug/description?/updatedAt).
  - `domain/repositories/contents_repository.dart`: `abstract interface class` devolvendo `Future<Either<Failure, T>>` (fpdart).
  - `data/models/content_summary_model.dart`: valida com **zard** (`z.map({...}).safeParse` → `Either`), erro → `ValidationFailure(z.prettifyError(...))`.
  - `data/repositories/contents_repository_impl.dart`: `Dio` injetado; **único try/catch**; traduz `DioException` → `Failure` (404→NotFound, 409→Conflict com `suggestedSlug`, 400→Validation, timeout/connError→Network).
- **Migrations**: `0_baseline`, `20260702120000_rename_pages_to_contents`. Prisma 6.19.
- **Bootstrap** (`main.ts`): **não há limite de body configurado** — o default ~100kb do Express **estoura** com imagem. Precisa ser ajustado nesta feature.

## Análise de storage (resolvida tecnicamente — tech-lead + CISO, 2026-07-09)

- **Abordagem:** **S3-compatível** via um port `StorageService` no backend (interface `put`/`get`/`delete` de objeto), com **dois adapters**:
  1. **local/dev** (filesystem/pasta do projeto) como **DEFAULT reversível** — nada externo cravado;
  2. **S3** (`@aws-sdk/client-s3`) **codado e pronto**, ativado por **env** quando o humano confirmar o **Garage** já existente no servidor (`s3.bmjtech.duckdns.org`) **ou** um **R2**.
- **`Project` no Prisma guarda só a chave/URL** da imagem (ex.: `imageKey`), **nunca** o binário.
- **Pipeline de upload obrigatório** (não-negociáveis do CISO — ver seção de segurança do PRD): magic bytes (`file-type`), allowlist fechada **png/jpg/webp** (**SVG não**), reencode com **sharp** (mata polyglot/webshell + strip EXIF + limita dimensão contra decompression bomb), nome por **UUID gerado no servidor** (nunca o filename do cliente), serving com content-type **fixado no detectado** + `X-Content-Type-Options: nosniff`, limite de tamanho em **duas camadas** (nginx/Traefik `client_max_body_size` **E** multer no Nest), **rate-limit** no endpoint de upload, escopo de tenant por **UUID não-enumerável**.
- **Deps novas do backend:** `multer` (interceptor do `@nestjs/platform-express`), `sharp`, `file-type`, `@aws-sdk/client-s3`. Configurar limite de body no bootstrap.

## Decisões que já sustentam esta spec (humano)

1. **Projeto vem primeiro**, como feature/item próprio, **antes** do item 10. O item 10 depois constrói categorias/conteúdos **dentro** de um projeto.
2. **Projeto tem:** imagem, título, descrição. Exibido como **cards** na home.
3. **Imagem = upload de arquivo** (não URL).
4. **Escopo:** backend CRUD de Projeto + camada data/domain do editor. UI/design pelo Claude Design — **não desenhar telas**, só contrato e o que a UI consome.
5. **Storage resolvido tecnicamente** (S3-compatível via port + adapters); a **escolha Garage vs R2 e credenciais** é decisão parada, bloqueando só o **deploy real** do upload.
6. **Banco recriado do zero** no item 10 — dado de dev é descartável, sem backfill.

## Decisões travadas (defaults provisórios — a confirmar com o humano)

Detalhamento e alternativas no `prd.md` › _Decisões travadas_. Todas são **default adotado na ausência do humano (2026-07-09) — a confirmar**; o dev segue sobre elas.

1. **`onDelete` de Projeto = `Restrict`.** Não se apaga um projeto com categorias/conteúdos — o usuário esvazia antes. Coerente com o item 10 (`Content → Category` também é `Restrict`); protege contra perda acidental. *(a confirmar)*
2. **Seed de "Projeto Padrão" (id `default`) na migração.** Mantém `x-project-id=default` funcionando em dev/hml e garante que nenhuma FK de conteúdo fica órfã. **A UX de primeira-experiência da home** (empty-state "crie seu primeiro projeto" à la Squidex **vs.** mostrar o projeto default) **é decisão em aberto do humano/Claude Design** — o seed **não impede nenhuma das duas**: o frontend decide se esconde ou mostra o default. *(a confirmar)*
3. **Campos:** **sem `slug`** (o `id` CUID2 basta); **título** obrigatório 1–120 chars; **descrição** opcional ≤ 280 chars; **imagem opcional** no create (card com placeholder quando ausente). *(a confirmar)*
4. **Storage:** desenvolver contra o **adapter local**; **Garage vs R2 + credenciais** = decisão **parada** do humano (bloqueia só o deploy do upload, não o dev). *(parada)*
5. **Auth:** **seguir sem auth**, mantendo `x-project-id`. **Débito de segurança explícito:** o CRUD de `/v1/projects` fica **global** (qualquer cliente lista/cria/apaga qualquer projeto) até haver auth. Auth é feature à parte. *(a confirmar)*

> Contrato REST detalhado, modelo de dados/migração, pipeline de segurança do upload e critérios de aceite: ver **`prd.md`**.
