# plan.md — API de conteúdos (item 10) + fluxo do protótipo (Projeto → Categorias → Conteúdos)

> Documento vivo. Dono: **tech-lead**. Guardião do plano. Fonte: `prd.md` + `specs.md` (aprovados; decisões travadas 2026-07-09 + **adendo pós-feature-09**).
> Regra de ouro do "pronto": **`flutter analyze` verde + `backend build` verde + testes existentes passando** (nunca opinião). Bateria automatizada nova é escrita **por último** (após E2E).
> Escopo do plano: o **item 10** (API de conteúdos: envelope/cursor/busca/sort/filtro + fundação `Category`) **mais** a **UI da tela do projeto** (árvore de categorias + painel de conteúdos + forms), fechando o fluxo do protótipo. A home de Projetos (cards) é da feature 09; o Construtor já existe (`editor_module`) — só o clique no conteúdo leva a ele.

## Contexto de dependência (crítico) — empilhamento sobre a feature 09

A feature 09 (`feature/crud-projeto`, ainda **não mergeada** em `develop` — F5 dela é UI, bloqueada por design) criou:
- `model Project` (Prisma) + `Content.projectId` FK NOT NULL → Project (`onDelete: Restrict`) + seed do `Project` id `default` + migração `20260709055732_add_projects`.
- `projects_module` no editor (domain + data prontos; **sem presentation** — F5 bloqueada por design).

**Consequências para este plano:**
1. **A P1 depende do schema da 09.** A migração de `Category` referencia `Project`; a criação da "Geral-por-projeto" **encosta no `ProjectsService.create` da 09** (mesma transação — adendo). Logo a **branch da P1 empilha sobre `feature/crud-projeto`** (não sobre `develop` puro), até a 09 mergear.
2. **Ordem de merge dos PRs** (ver seção final): a 09 mergeia **antes** da P1. Se por decisão do humano a 09 mergear em `develop` primeiro, a P1 rebaseia em `develop` e deixa de empilhar. Enquanto a 09 não mergeia, a P1 vive como branch empilhada.
3. **A UI da tela do projeto (P2) assume o `projects_module` da 09** (para navegar Projeto → tela do projeto). A F5 da 09 (home de cards) e a P2 daqui compartilham o novo topo de navegação — coordenar o `app_router.dart` para não conflitar.

## Gabaritos (o que imitar — já levantado)

**Backend** (`backend/src/contents/`): `contents.controller.ts` (`@Controller('contents')`, header `x-project-id` → `projectOf`, `GET @Get() list(@Headers('x-project-id'))` — **hoje sem query params**), `contents.service.ts` (`list(projectId)` → **array puro** via `toSummary()`, select `id/name/slug/description/updatedAt`, `where {projectId}`; CUID2 pelo Prisma, `$transaction`, 409 slug via P2002 com `suggestedSlug`), `dto/*.dto.ts` (class-validator), `main.ts` (ValidationPipe global, prefixo `/v1`). Referência de FK/seed/onDelete e de `_count`: `backend/src/projects/projects.service.ts` (`toSummary()`, `imageUrl` computado, **sem `_count` hoje**) — gabarito para P3.

**Editor** (`apps/driva_editor/lib/modules/contents_module/`): `data/repositories/contents_repository_impl.dart` (`getContents()` faz `dio.get('/v1/contents')` e espera **`List<dynamic>` puro** — **quebra com o envelope**), `data/models/content_summary_model.dart` (zard `id/name/slug/description?/updatedAt`; **sem `categoryId`**), `domain/entities/content_summary.dart` (Equatable, os mesmos campos), `domain/use_cases/get_contents_use_case.dart` (**re-ordena no cliente** por `updatedAt desc` — some na P1), presentation em `presentation/content_list/content_list_page.dart` + `content_list/cubit/content_list_cubit.dart` + `content_list_state.dart`. Módulo novo (`projects_module`) para imitar layout de módulo. Falhas em `core/error/failure.dart` (`sealed`: Network/Validation/NotFound/Conflict/Unexpected). Router: `apps/driva_editor/lib/app_router.dart` (`ContentsRoutes.route` em `/contents` name `contents`; `EditorRoutes.route` em `/contents/:id/edit` name `editor`).

---

## Fases (1 fase = 1 PR ideal)

Legenda: **[JÁ]** construível agora · **[PARCIAL/DESIGN]** estrutura definida, pixel-perfect espera design · **[∥]** paralelizável.

### P1 — Backend (Category CRUD + contents API evoluído) + editor data/domain na MESMA fatia  **[JÁ]**

**Objetivo.** Fatia **vertical** (backend + editor data/domain juntos): o `GET /v1/contents` passa a envelope/cursor/busca/sort/filtro; nasce a fundação `Category` (tabela em árvore por projeto + `Content.categoryId` NOT NULL + "Geral" por projeto) **e o CRUD de categoria**; o `contents_module` do editor é adaptado ao novo contrato **na mesma PR** (o envelope quebra o parse — restrição dura); e nasce um `categories_module` (domain/data). **Sem UI** — a UI é a P2.

> **[RESTRIÇÃO DURA — fatia vertical]** O envelope `{ data, nextCursor }` **quebra em runtime** o parse atual do editor (espera array puro). Backend + a camada `data`/`domain` do editor que consome `/v1/contents` **DEVEM ir na MESMA PR**. **Nunca** mergear o backend sozinho — auto-deploy em hml derrubaria a home. (`prd.md` › Riscos › CRÍTICO.)

**Especialistas:** `especialista-infra` (backend), `especialista-dominio` + `especialista-dados` (editor). **Gate CISO** na fase (novo endpoint de escrita `Category`, filtro de tenant, `categoryId` cross-tenant).

**Arquivos a criar/tocar:**

*Backend — schema/migração/seed:*
- `backend/prisma/schema.prisma` — `model Category` (id CUID2, `projectId` **FK NOT NULL → Project** `@map("project_id")` com `onDelete: Restrict`, `name`, `slug`, `parentId?` auto-relação `CategoryTree` `onDelete: SetNull`, `contents Content[]`, timestamps, `@@unique([projectId, slug])`, `@@index([projectId, parentId])`, `@@map("categories")`); em `model Content` adicionar `categoryId` **NOT NULL** + `category Category @relation(onDelete: Restrict)`, `nameNormalized @map("name_normalized")`, e o índice `@@index([projectId, updatedAt(sort: Desc), id])`. Descomentar `categories Category[]` em `model Project` (09 deixou o placeholder).
- `backend/prisma/migrations/<ts>_add_categories/migration.sql` — cria `categories`; adiciona `category_id`/`name_normalized` em `contents`; **ordem crítica**: criar `categories` → **seed "Geral" no projeto `default`** → backfill `category_id` dos conteúdos existentes para a "Geral" do projeto → só então a FK NOT NULL + índice. Banco do zero: sem dado legado, mas a ordem seed→FK é a mesma robustez da 09.

*Backend — Category CRUD + service da "Geral":*
- `backend/src/categories/categories.controller.ts` — `@Controller('categories')`, `x-project-id`→`projectOf`; `GET` (árvore/lista do projeto), `POST` (name + parentId?), `PUT :id` (rename/mover parentId), `DELETE :id` (Restrict se tiver conteúdos → **409 traduzido**, análogo ao P2002 de contents).
- `backend/src/categories/categories.service.ts` — CRUD Prisma escopado por `projectId`; slug derivado do name; validação de `parentId` do mesmo projeto; tradução P2003 (Restrict) → 409.
- `backend/src/categories/dto/*.dto.ts` — class-validator (name obrigatório; parentId opcional).
- `backend/src/categories/categories.module.ts` + import em `backend/src/app.module.ts`.
- **"Geral" por projeto (adendo):** tocar `backend/src/projects/projects.service.ts` (da 09) — no `create`, inserir a categoria "Geral" (`parentId=null`) **na mesma `$transaction`** do insert do projeto. → **encosta em código da 09** (empilhamento).

*Backend — contents API evoluído:*
- `backend/src/contents/contents.controller.ts` — `GET` passa a aceitar query params `categoryId?`, `q?`, `sort?`, `order?`, `cursor?`, `limit?` (DTO de query com class-validator: `sort`/`order` enum, `limit` int 1–100 → **400** fora da faixa, `cursor` string opaca).
- `backend/src/contents/dto/list-contents.query.dto.ts` — novo DTO de query (validação → 400).
- `backend/src/contents/contents.service.ts` — `list()` reescrito: **envelope `{ data, nextCursor }`**, keyset cursor `(campo_sort, id)`, filtro `categoryId` (nó exato), busca `ILIKE` sobre `nameNormalized`, `orderBy` por sort/order, `take limit+1` para calcular `nextCursor`. Select ganha **`categoryId`**. `create`/`update` gravam `nameNormalized` (lowercase + sem acento em Node) e aceitam `categoryId` opcional (omitido → "Geral" do projeto; inválido/cross-tenant → **400**).
- `backend/src/contents/dto/{create,update}-content.dto.ts` — aceitam `categoryId?`.

*Editor — contents_module adaptado (MESMA PR):*
- `apps/driva_editor/lib/modules/contents_module/domain/entities/content_summary.dart` — adicionar `categoryId` (String, obrigatório).
- `.../domain/repositories/contents_repository.dart` — `getContents(...)` ganha params (`categoryId?`, `q?`, `sort`, `order`, `cursor?`, `limit`) e passa a devolver **página + próximo cursor** (novo tipo `ContentsPage { List<ContentSummary> items; String? nextCursor }` em domain).
- `.../domain/use_cases/get_contents_use_case.dart` — **remover o re-sort cliente** (ordenação é do servidor); repassar filtros/cursor.
- `.../data/models/content_summary_model.dart` — zard ganha `categoryId` (obrigatório); **novo** schema do envelope (`data: array, nextCursor: string|null`) → `ContentsPageModel`/parse do envelope. Inválido → `ValidationFailure`.
- `.../data/repositories/contents_repository_impl.dart` — `getContents()` monta querystring, parseia **envelope** (não mais `as List`). `create`/`update` mandam `categoryId` quando houver.
- `.../presentation/content_list/*` — ajuste **mínimo** para não regredir a home (consumir `page.items`; sem UI de filtro ainda — isso é P2). A home continua carregando a primeira página.

*Editor — categories_module novo (domain/data):*
- `apps/driva_editor/lib/modules/categories_module/` via skill `criar-modulo` — `domain` (entidade `Category {id, name, slug, parentId?, projectId}`, contrato `CategoriesRepository` com `getCategories/createCategory/updateCategory/deleteCategory` → `Future<Either<Failure,T>>`, use cases um por operação), `data` (model zard + `CategoriesRepositoryImpl` Dio, único try/catch, 409→Conflict, 400→Validation). `categories_injection.dart` + barrel. **Sem presentation** (é P2). Montar a árvore a partir da lista `parentId` fica na presentation da P2 (ou um helper puro no domain).

**Pronto quando:** `backend` build verde; migração aplica em Postgres do zero com "Geral" semeada; `GET /v1/contents` devolve envelope/cursor/busca/sort/filtro com os 400s do contrato; `POST`/`PUT` gravam `nameNormalized` e respeitam `categoryId`; Category CRUD responde 200/201/204/400/409; **`flutter analyze` verde** (editor parseia o envelope, home não regride); **gate CISO aprovado**. E2E por script vem nas rodadas finais.

**Risco/pré-req:** **empilha sobre `feature/crud-projeto`** (schema + service da "Geral"). Restrição da fatia vertical (nunca mergear backend sozinho). `categoryId` cross-tenant precisa checar projeto+existência. Deps: nenhuma nova no editor (dio/zard/fpdart já há); backend não precisa de dep nova (normalização em Node puro).

---

### P2 — UI da tela do projeto (árvore + painel + forms)  **[PARCIAL — bloqueada por design]**

**Objetivo.** A **tela do projeto**: árvore de categorias à esquerda + painel de conteúdos à direita + forms dedicados de categoria e conteúdo. Consome a P1 (Category CRUD + contents API com filtro/busca) e o `projects_module` (09). Fecha o fluxo: Projetos (home 09) → **tela do projeto** → clique no conteúdo → Construtor (`editor_module`, já existe).

> **[DESBLOQUEADA — design-fonte no repo]** O handoff do Claude Design chegou e cobre o **fluxo inteiro** (home de Projetos, **tela do projeto** com árvore + painel, forms e Construtor): `docs/web-prototipe/design-handoff-projetos/Driva Projetos.dc.html` (+ tokens do DS em `_ds/*/tokens/` e screenshots em `screenshots/`). A P2 implementa **fiel a esse fonte** — a estrutura abaixo continua válida como resumo, mas o `.dc.html` manda no visual.

**Estrutura/fluxo (fonte: descrição do humano):**
- **Árvore à esquerda:** entrada "Não categorizados"/raiz + categorias aninhadas (recursivo por `parentId`); **editar/excluir no hover** de cada nó; ação de **nova categoria**; selecionar um nó **filtra** o painel da direita (dispara request com `categoryId`).
- **Painel à direita:** **busca** (dispara `q`), **alternância grade/lista**, botões **novo/editar/mover/excluir** conteúdo, lista **filtrada pela categoria selecionada**; estado-vazio por categoria; clique no card → Construtor.
- **Forms dedicados:** **categoria** (name + seletor de categoria-pai) e **conteúdo** (name + seletor de categoria). "Mover" reusa o seletor de categoria. (No protótipo eram modais; no app, decidir rota dedicada vs modal — **decisão de implementação da presentation**, registrar.)

**Especialista:** `especialista-apresentacao` (presentation dos dois módulos). Consome domain/data de `categories_module` e `contents_module` (P1) e `projects_module` (09).

**Arquivos a criar/tocar:**
- `apps/driva_editor/lib/modules/categories_module/presentation/*` — cubit(s) + estado `sealed`; widget da **árvore** (montada de `parentId`), hover-actions, form de categoria (página `StatelessWidget` com `static pageBuilder`, guarda `isClosed`). `categories_routes.dart`.
- `apps/driva_editor/lib/modules/contents_module/presentation/content_list/*` — evoluir `ContentListCubit`/`ContentListState` para: filtro por `categoryId` selecionado, `q` de busca, toggle grade/lista, ações mover/editar/excluir. Form de conteúdo com seletor de categoria.
- **Tela do projeto (composição):** decidir o dono da rota — provável nova página "project detail" que compõe árvore (categories) + painel (contents) sob um `projectId`. Pode viver num `project_workspace`/na presentation do `projects_module` (09) ou numa página de composição no `contents_module`. **Decisão de arquitetura a registrar** — presentation não importa data de outro módulo; a composição usa os barrels públicos.
- `apps/driva_editor/lib/app_router.dart` — rota da tela do projeto (`/projects/:projectId` → tela do projeto; o clique no conteúdo mantém `/contents/:id/edit` name `editor`). **Coordenar com a F5 da 09** (home de cards) para não conflitar no router.

**Pronto quando:** `flutter analyze` verde; a tela do projeto renderiza árvore + painel; selecionar categoria filtra; busca funciona; criar/editar/mover/excluir categoria e conteúdo funcionam contra a P1; clique no conteúdo abre o Construtor. **Pixel-perfect fica pendente do design** (registrar como TODO visual, não bloqueia o "funcional pronto").

**Risco/pré-req:** depende da P1 (data/domain de categorias + contents API). Depende do `projects_module`/09 para o contexto de projeto. `presentation` NUNCA importa `data` — composição via barrels. Design pendente → travar só o refino visual, não o fluxo.

---

### P3 — Integrações finais (mover conteúdo + contadores nos cards)  **[JÁ]**

**Objetivo.** Fechar as pontas que cruzam módulos: **mover conteúdo entre categorias** (fim-a-fim UI↔API) e **contadores nos cards da home** de Projetos (nº de conteúdos / nº de categorias por projeto).

**Especialistas:** `especialista-infra` (backend `_count`), `especialista-dados`/`especialista-apresentacao` (editor). Se tocar contrato da 09 → **adendo leve** (registrar).

**Arquivos a criar/tocar:**
- **Mover conteúdo:** já coberto por `PUT /v1/contents/:id` com `categoryId` (P1) + a ação "mover" na UI (P2). A P3 garante o fim-a-fim (drag-para-categoria e/ou seletor no form), reconciliação otimista da lista após mover, e o E2E do move.
- **Contadores nos cards (adendo leve ao contrato da 09):** `GET /v1/projects` passa a incluir **`contentCount`** e **`categoryCount`** via **`_count` do Prisma** (`select: { _count: { select: { contents: true, categories: true } } }`) no `toSummary()` de `backend/src/projects/projects.service.ts`. → **adendo ao contrato da 09** (docs/09/prd.md `GET /v1/projects`): registrar em `docs/09-crud-projeto/variance_report.md` como VR novo (contrato de lista ganha dois inteiros derivados). Editor: `Project` entity + `ProjectModel` (zard) ganham `contentCount`/`categoryCount` (int, default 0); a home de cards (F5/09) exibe os contadores.
- `apps/driva_editor/lib/modules/projects_module/domain/entities/project.dart` + `data/models/project_model.dart` — adicionar os dois inteiros.

**Pronto quando:** `backend` build verde; `GET /v1/projects` traz `contentCount`/`categoryCount`; mover conteúdo funciona fim-a-fim; `flutter analyze` verde; **VR registrado** para o adendo da 09.

**Risco/pré-req:** tocar o contrato da 09 é **mudança de contrato compartilhado** → adendo leve documentado (não é breaking: adiciona campos). Se a 09 já tiver mergeado, a P3 vai por PR próprio sobre `develop`.

---

## Ordem de execução, empilhamento e merge dos PRs

```
feature/crud-projeto (09)  ──(schema Project + projects_module + service.create)
        │  mergeia PRIMEIRO
        ▼
P1  feature/10-contents-api  (empilhada sobre 09 até ela mergear; senão rebaseia em develop)
        │  backend Category+contents API + editor data/domain (fatia vertical, 1 PR)
        ▼
P2  feature/10-tela-projeto  (UI; depende de P1 e do projects_module da 09)
        │  parcialmente bloqueada por design (pixel-perfect)
        ▼
P3  feature/10-integracoes   (mover + contadores _count; adendo leve à 09)
```

**Ordem de merge recomendada:** **09 → P1 → P2 → P3.**
- **09 antes de P1** porque a P1 referencia `Project` no schema e toca `projects.service.ts` (a "Geral"). Enquanto a 09 não mergeia em `develop`, a **branch da P1 empilha sobre `feature/crud-projeto`**; quando a 09 mergear, **rebaseie a P1 em `develop`**.
- **P1 é uma fatia vertical num único PR** (backend + editor data/domain juntos) — nunca fatiar por camada, nunca mergear o backend sozinho (quebraria a home em hml).
- **P2 depois de P1** (precisa do Category CRUD + contents API + o `projects_module`/topo de navegação).
- **P3 por último** (contadores `_count` e move fim-a-fim), com **adendo leve** ao contrato da 09 registrado em `variance_report.md`.

## Progresso

- [ ] P1 — Backend (Category CRUD + contents API envelope/cursor/busca/sort/filtro) + editor data/domain (fatia vertical)
- [ ] P2 — UI da tela do projeto (árvore + painel + forms) **(parcial: pixel-perfect bloqueado por design)**
- [ ] P3 — Integrações finais (mover conteúdo + contadores `_count` nos cards)
- [ ] E2E por script (rodadas) + docs vivas + bateria automatizada (por último)

## Variância

Nenhuma até agora. Desvios do plano só entram com **aprovação do humano** e registro em `variance_report.md` (como estava / por que mudou / o que mudou). O **adendo de contadores na 09** (P3) é registrado em `docs/09-crud-projeto/variance_report.md`.
