# final_report.md — API de conteúdos (item 10) + tela do projeto (docs/08)

> Relatório de fechamento. Fonte da verdade do "pronto": `prd.md` + `plan.md` (aprovados) e o
> gate do CISO. Branch: `feature/api-conteudos` (empilhou sobre a feature 09 — ver
> `docs/09-crud-projeto/`).

## O que foi entregue

Fecha o fluxo do protótipo **Projetos → Categorias → Conteúdos**. Três fatias:

- **P1 — Backend (Category + contents API evoluído) + editor data/domain (fatia vertical):**
  nasce a fundação `Category` (árvore por projeto), o CRUD `/v1/categories`, e o
  `GET /v1/contents` passa a **envelope com cursor + busca + sort + filtro por categoria**. O
  `contents_module` do editor foi adaptado ao novo contrato **na mesma PR** (o envelope quebra
  o parse de array puro — restrição dura). `categoryId` fundido no `contents_module` (o
  `categories_module` separado foi absorvido).
- **P2 — Tela do projeto (`/projects/:id`):** árvore de categorias à esquerda (recursiva por
  `parentId`, editar/excluir no hover, nova categoria), painel de conteúdos à direita (busca,
  alternância grade/lista, mover, nó **"Todos os conteúdos"**), fiel ao handoff do Claude
  Design.
- **P3 — Integrações finais:** contadores por projeto (`_count`) nos cards e na árvore; mover
  conteúdo entre categorias fim-a-fim.

## Contrato final dos endpoints

**`GET /v1/contents`** — envelope e query params:

```
{ "data": [ ...resumos ], "nextCursor": "<opaco>" | null }
```

| Param | Regra |
|---|---|
| `categoryId?` | filtra pelo nó exato |
| `q?` | busca acento-insensível sobre `nameNormalized` (ILIKE) |
| `sort` | `updatedAt` (default) · `createdAt` · `name` |
| `order` | `desc` (default) · `asc` |
| `cursor?` | keyset cursor `(campo_sort, id)`; string opaca |
| `limit` | int **1–100** (default 20); fora da faixa → **400** (sem clamp silencioso) |

Resumo de conteúdo ganha **`categoryId`** (obrigatório). `POST`/`PUT` gravam `nameNormalized` e
aceitam `categoryId?` (omitido → "Geral" do projeto; inválido/cross-tenant → **400**).

**`/v1/categories`** (escopado por `x-project-id`):

| Método | Rota | Resposta |
|---|---|---|
| `GET` | `/v1/categories` | `200` lista flat com `projectId`, `parentId`, `contentCount` |
| `POST` | `/v1/categories` | `201` (`name` + `parentId?`; slug derivado do name) |
| `PUT` | `/v1/categories/:id` | `200` (rename / mover `parentId`) · `400` ciclo · `404` |
| `DELETE` | `/v1/categories/:id` | `204` · `409` com subcategoria ou conteúdo (`Restrict`) |

Todo projeto nasce com a categoria **"Geral"** criada **na mesma `$transaction`** do projeto
(`ProjectsService.create`).

## Arquitetura / decisões

- **Envelope + keyset cursor** — `take limit+1` calcula o `nextCursor`; ordenação é do
  **servidor** (o re-sort no cliente foi removido do `GetContentsUseCase`).
- **Busca acento-insensível** — coluna `nameNormalized` (lowercase + sem acento em Node puro),
  gravada em `create`/`update`; nenhuma dep nova no backend.
- **`Category` em árvore** — `parentId` auto-relação (`onDelete: SetNull`), `Content.categoryId`
  NOT NULL (`onDelete: Restrict`); escopo por `projectId`; unicidade `@@unique([projectId, slug])`.
- **ProjectScope no editor** — `x-project-id` por projeto injetado no Dio conforme o projeto
  em foco.
- **Composição da tela** — `presentation` nunca importa `data` de outro módulo; a tela do
  projeto compõe árvore (categorias) + painel (conteúdos) via barrels públicos.

## Variâncias

- **VR do adendo de contadores** registrado em `docs/09-crud-projeto/variance_report.md`
  (`GET /v1/projects` ganha `contentCount`/`categoryCount` — aditivo, não-breaking).
- **"Não categorizados" → "Todos os conteúdos"** — o nó-raiz da árvore virou "Todos os
  conteúdos" (mostra tudo do projeto), mais fiel à intenção do que um filtro de sem-categoria
  (que não existe, já que todo conteúdo tem categoria). Commit `e9fd344`.

## Gate CISO

**APROVADO.** Novo endpoint de escrita (`Category`), filtro de tenant e `categoryId`
cross-tenant auditados (cross-tenant → 400). Segue valendo o débito **sem-auth** herdado (ver
`docs/09-crud-projeto/`).

## Evidência E2E

`docs/09-crud-projeto/evidencias/e2e_api.sh` cobre o **fluxo inteiro** (Projetos + Categorias +
Conteúdos) — os blocos 2 e 3 exercitam o item 10:

- categorias raiz/aninhada, rename, mover, ciclo→400, DELETE com filhos→409;
- envelope `{data,nextCursor}`, paginação sem repetição, busca acento-insensível ("sao" acha
  "São Paulo"), filtro por `categoryId`, `sort=name asc`, `limit=0`/`limit=500`→400, mover
  conteúdo refletido no filtro do destino.
- **Rodada 01:** `59 PASS / 0 FAIL` (ver `evidencias/rodada_01/resultado.txt`).

## O que ficou como TODO / polimento

1. **Paginação infinita não fiada na UI** — o backend entrega cursor/nextCursor; a tela do
   projeto ainda carrega a primeira página (falta o infinite-scroll consumir o `nextCursor`).
2. **Drag-drop de mover** — mover conteúdo funciona pelo seletor/ação; o arrastar-para-categoria
   direto no painel é polimento pendente.
3. **Pixel-perfect da tela do projeto** — funcional pronto contra o handoff; refino visual fino
   fica como TODO, não bloqueia o "funcional pronto".
