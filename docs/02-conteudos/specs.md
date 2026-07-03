# Specs — Conteúdos (Content)

> Mudança de conceito aprovada pelo dev humano (2026-07-02). Documento vivo: descreve o que a feature **é**. Dono: PM. Base técnica levantada com o tech-lead sobre o estado atual do repo.

## O que é

O driva deixa de gerenciar **"páginas"** e passa a gerenciar **"conteúdos" (content)**. Um conteúdo é uma árvore SDUI que pode ser uma **página inteira** ou só um **fragmento** — a diferença deixa de ser um conceito do produto. No app cliente, o dev pede um conteúdo **por referência (slug)** e usa o widget do pacote driva para renderizá-lo **onde quiser** na sua própria tela.

Isso é, em essência, um **rename de conceito em toda a stack** (`sdui_core` → `sdui_flutter` → `driva_editor` → `backend` → docs/testes/fixtures) somado a uma **nova identidade** para o objeto: o `slug` vira o handle técnico, substituindo o antigo `screenTarget`.

## Conceitos

| Conceito | Definição |
|---|---|
| Conteúdo (content) | Árvore SDUI reutilizável (página inteira **ou** fragmento); topo é `root.children`. Substitui "página". Spec: `{specVersion, kind: "content", id, name, root}` |
| `id` | CUID2, opaco, imutável. Identidade interna (suporte/debug). Prisma `@default(cuid(2))`. Exposto no card |
| `slug` | A **referência que o dev usa no código Flutter**. Único **por projeto** (`@@unique([projectId, slug])`). Auto-gerado do Nome, editável, validado `^[a-z][a-z0-9-]*$`, sufixo automático em colisão (`home-banner-2`). Exposto em destaque no card |
| `name` | Rótulo humano, obrigatório |
| `description` | Texto livre, opcional |
| Bloco | Instância de um primitivo do catálogo, com props e `id` único (inalterado) |
| Referência no app | `DrivaContent(slug: 'home-banner')`, escopado pelo projeto configurado no pacote |

## Dentro desta feature

- **Rename em toda a stack**, mantendo a arquitetura e o comportamento existentes:
  - `sdui_core`: `PageSpec` → `ContentSpec`, `parsePageSpec` → `parseContentSpec`, envelope `kind: "page"` → `"content"`; **remove `screenTarget`** do modelo/schema/`toJson`.
  - `sdui_flutter`: nomenclatura do renderer (`SduiView.page` → equivalente de conteúdo), assinaturas e docstrings.
  - `driva_editor`: **dois módulos** afetados — `pages_module` → `contents_module` (listagem/CRUD) **e** `editor_module` (edição por id, que consome `PageSpec`/`screenTarget` e cuja rota é `/pages/:id/edit`). Rota `/pages` → `/contents` e `/pages/:id/edit` → `/contents/:id/edit` (`PagesRoutes`/`EditorRoutes`, variantes `*Named`, `initialLocation` e redirects em `app_router.dart`); entidade/model/use cases/cubit/página renomeados; textos de UI em pt-BR ("Conteúdos", labels, empty state, erros).
  - `backend`: `/v1/pages` → `/v1/contents`; modelo Prisma `Page` → `Content`, tabela `pages` → `contents`; DTOs (`CreatePageDto` → sem `screenTarget`, com `description`). Nota: `kind` e `screenTarget` também vivem **dentro do `spec` JSONB persistido** (gerado pelo `service.create` e por `PageSpec.toJson()`), não só em colunas — a migração precisa reescrever o JSONB, não só o schema.
  - docs, fixtures (`page_valid.json` etc.) e testes.
- **Nova identidade do objeto:**
  - Formulário de criação: **Nome** (obrigatório) + **Descrição** (opcional). O campo **"Tela de destino"/`screenTarget` é removido**.
  - `slug` auto-gerado do Nome, editável, validado no cliente e com **garantia dura de unicidade por projeto no Postgres** (`@@unique([projectId, slug])`); backend responde **`409 Conflict`** em corrida; sufixo incremental em colisão.
  - `id` passa a **CUID2** para novos registros.
- **Card do editor** expõe: `id` (suporte), `slug` (destaque), `name`, `description`.
- **Paridade funcional**: tudo que a listagem/criação/edição/exclusão de "páginas" fazia continua funcionando para "conteúdos"; nenhuma capacidade nova de edição SDUI é adicionada aqui.

## Fora desta feature

- **Serving real ao app cliente** (endpoint `GET /v1/contents/by-slug/:slug` e resolução em runtime) — o widget `DrivaContent(slug:)` fica com **nome e contrato de dados definidos**, mas o fetch por slug em produção é incremento futuro (segue "Fora do I1" do módulo página).
- Multi-projeto real na UI (hoje `DEFAULT_PROJECT_ID` é single-project compile-time, header `x-project-id`; permanece assim).
- Distinção de produto entre "página" e "fragmento" (o conceito é unificado; não há flag/tipo).
- Workflow/papéis/versionamento/publish, condições/binding, undo/redo, auth — inalterados (I2–I4).
- Novos primitivos de catálogo.

## Decisões que sustentam esta spec

1. "Página" → "conteúdo" (content) em toda a stack; `kind: "content"` (dev, 2026-07-02).
2. Formulário: **Nome** (obrigatório) + **Descrição** (opcional); **`screenTarget` removido** — o handle técnico passa a ser o `slug` (dev, 2026-07-02).
3. Identidade: `id` = CUID2 opaco/imutável; `slug` = referência do dev, único por projeto (`@@unique([projectId, slug])`), `^[a-z][a-z0-9-]*$`, sufixo em colisão, `409` do backend em corrida; `name`/`description` como acima (dev, 2026-07-02).
4. Card expõe `id`, `slug` (destaque), `name`, `description` (dev, 2026-07-02).
5. Processo: GitFlow, feature branch de `develop`, CI é a cancela (dev, 2026-07-02).

## Pendências para o humano (bloqueiam o PRD)

Ver perguntas numeradas devolvidas ao tech-manager nesta rodada (migração de dados prod/hml, mutabilidade do slug, fronteira de escopo do `DrivaContent`, nomenclatura pt-BR, geração/visibilidade do sufixo). O `prd.md` só é escrito após essas respostas.
