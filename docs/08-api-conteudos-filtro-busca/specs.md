# Specs (RASCUNHO) — API de conteúdos: filtro, busca, ordenação e paginação

> Documento vivo. Dono: PM. **RASCUNHO da rodada 1 de discovery** — contém decisões em aberto que bloqueiam o PRD. Base técnica levantada no código atual e com o tech-lead.
> Roadmap: item **10** ("API de conteúdos com filtro, busca, ordenação e paginação"). Fundação do backend do **Marco 3**; precede os itens 11–16.

## Problema

O `GET /v1/contents` hoje devolve **todos** os conteúdos do projeto de uma vez, como **array puro**, ordenado por `updatedAt desc` no backend e re-ordenado no cliente. Não há filtro, busca, ordenação configurável nem paginação. À medida que um projeto acumula conteúdos, a listagem não escala e não há como o editor:

- filtrar por **categoria** (conceito que ainda **não existe** em lugar nenhum da stack);
- **buscar** por termo;
- escolher **ordenação**;
- **paginar** (necessário para a listagem infinita do item 16).

## Objetivo

Evoluir o contrato de `GET /v1/contents` para aceitar **filtro, termo de busca, ordenação e paginação**, e preparar a **fundação de dados de "categoria de conteúdo"** de forma que os itens 11–16 (árvore de categorias, filtro por categoria, atribuição, busca/ordenação, paginação infinita) sejam construídos **sem re-migrar** o schema.

Entrega em duas camadas:
1. **Backend** (NestJS + Prisma + Postgres): novos query params no `GET /v1/contents`, novo formato de resposta (envelope com dados de paginação), modelo de dados de categoria e migração Prisma.
2. **Editor** (camada `domain`/`data` do `contents_module`): entidade/contrato/use case/model+zard/repo impl para consumir o novo contrato. **Sem UI nova** — as telas de categoria vêm nos itens 11–14.

## Escopo

**Dentro:**
- `GET /v1/contents` passa a aceitar query params: filtro por categoria, `q` (busca), ordenação (campo + direção), paginação.
- Novo **formato de resposta** de listagem (envelope com metadados de paginação) — muda o contrato atual (array puro).
- **Modelo de dados de categoria** (schema Prisma + migração) — o desenho exato é decisão em aberto (ver abaixo).
- Editor: atualização de `ContentsRepository`, `GetContentsUseCase`, `ContentSummaryModel` (zard), `ContentsRepositoryImpl` e entidade `ContentSummary` para o novo contrato/paginação/filtros.

**Fora (itens seguintes / não-escopo):**
- **UI de categorias** — árvore na home, "Todos", clique-filtra, atribuir conteúdo (itens 11–14). Aqui só a **infra de dados/contrato**.
- Endpoints de **CRUD de categoria** (criar/renomear/mover/excluir categoria) — só se a decisão de modelo os exigir já; caso contrário ficam para o item 11.
- Offline-first / cache local (item 17).
- Multi-projeto real na UI (segue single-project compile-time por `x-project-id`).
- Serving por slug ao app cliente (incremento futuro, herdado do I1).

## Estado atual (levantado no código)

- **Prisma** (`backend/prisma/schema.prisma`): `model Content { id (cuid2), projectId @default("default"), name, slug, description?, spec Json, createdAt, updatedAt, @@unique([projectId, slug]), @@index([projectId]) }`. **Sem categoria.**
- **Service** (`contents.service.ts`): `list(projectId)` → `findMany({ where:{projectId}, orderBy:{updatedAt:'desc'}, select:{id,name,slug,description,updatedAt} })`, retorna **array puro**.
- **Controller**: `GET /contents` (prefixo global `/v1`), tenant por header `x-project-id`.
- **"Categoria" no código hoje** é só do **catálogo de widgets** (`WidgetCategories`, paleta) — conceito **diferente e não relacionado** a categoria de conteúdo.
- **Editor**: `ContentsRepositoryImpl.getContents()` → `dio.get('/v1/contents')` espera `List<dynamic>`, valida cada item com zard (`ContentSummaryModel`: id/name/slug/description?/updatedAt). `GetContentsUseCase` reordena por `updatedAt desc` no cliente. Entidade `ContentSummary`.
- **Migrations**: `0_baseline`, `20260702120000_rename_pages_to_contents`. Prisma 6.19.

## Decisões que já sustentam esta spec

1. Escopo primário = backend/contrato + camada data/domain do editor; **UI de categoria fica para os itens 11–14** (roadmap + pedido do tech-manager).
2. Tenant continua por `x-project-id` (single-project compile-time), inalterado.
3. Fundação deve evitar re-migração quando os itens 11–14 chegarem.

## Decisões travadas (humano, 2026-07-09)

1. **Escopo:** o modelo de categoria entra **já** no item 10 — tabela `Category` + `Content.categoryId` + param de filtro por categoria + escrita de `categoryId`, **sem UI** (a UI vem nos itens 11–14).
2. **Modelo de categoria:** **1:N com árvore** — `Category` com `parentId` (auto-relação, nullable). **`Content.categoryId` é obrigatória (NOT NULL)** — todo conteúdo tem uma categoria. `onDelete: Restrict`: não se apaga categoria com conteúdos (mover/apagar antes; UX no item 14). Filtro de leitura por **nó exato** (`where categoryId = X`); herança de descendentes fica para depois.
3. **Categoria default "Geral":** a migração faz **seed** de uma categoria raiz "Geral" por projeto. `POST`/`PUT` **sem** `categoryId` caem na "Geral"; **com** `categoryId` válido (existe e é do projeto), respeitam. O editor cria conteúdo sem tocar em categoria; o item 14 só pluga o seletor.
4. **Banco do zero:** nenhum dado é de produção — não há backup nem **migração de backfill de dados legados**. O schema é recriado limpo; `categoryId`/`name_normalized` nascem preenchidos. Dado de dev é descartável.
5. **Paginação:** **keyset cursor** `(campo_ordenado, id)`, envelope `{ data, nextCursor }`, **sem total/count**. Trocar a ordenação **reinicia** a lista (cursor nulo).
6. **Busca:** acento-insensível via **coluna normalizada no app** (`name_normalized` = lowercase + sem acento, normalizado em Node) + **ILIKE** sobre ela. **Não** usar extensão `unaccent`/`pg_trgm` (privilégio não garantido no Coolify). Só o campo `name`.
7. **Ordenação:** campos `updatedAt` (default, `desc`), `createdAt` e `name`. Índice composto `(projectId, updatedAt desc, id)` já no item 10.
8. **`limit`:** default `20`, faixa 1–100; fora da faixa → **400** (validação de DTO), sem clamp.

**Restrição transversal (crítica para o plano):** o envelope `{ data, nextCursor }` **quebra** o parse atual do editor em runtime (hoje espera array puro). Backend + a camada `data`/`domain` do editor que consome `/v1/contents` **DEVEM ir na MESMA PR** (fatia vertical). **Nunca** mergear o backend sozinho — o auto-deploy em hml quebraria a home.

## Adendo pós-feature-09 (Project virou entidade real)

> A feature 09 (docs/09, `feature/crud-projeto`) criou a entidade `Project` real **depois** deste rascunho: `Content.projectId` virou **FK NOT NULL → Project** (`onDelete: Restrict`), com **seed do projeto `default`** e banco recriado do zero. Ajuste de modelagem de `Category`:

- **`Category.projectId` é FK NOT NULL → `Project`** (não `String @default("default")`), espelhando `Content.projectId`. `Category → Project` com **`onDelete: Restrict`** (coerente com `Content → Project` e `Content → Category`). O `x-project-id` segue como tenant, resolvendo para um `Project` real.
- **A "Geral" nasce por projeto** (não global). A migração desta feature semeia a "Geral" no projeto `default` da 09; para **projetos criados em runtime**, a "Geral" é inserida **no `ProjectsService.create` da 09, na mesma `$transaction`** (mais simples que trigger de banco ou seed só de migração). → **dependência de código com a 09**: a P1 empilha sobre `feature/crud-projeto` (ver `plan.md`).
- Contrato/exemplos do `GET /v1/contents` e da escrita **inalterados**.

Marcado como **adendo pós-feature-09**.

> Contrato REST detalhado, modelo de dados/migração e critérios de aceite: ver **`prd.md`**.
