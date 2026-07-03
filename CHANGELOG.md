# Changelog

## [Unreleased]

### Alterado

- **Conteúdos (rename página → conteúdo) · Fase 1 — `sdui_core`**: `PageSpec` → `ContentSpec` (remove `screenTarget`; adiciona `slug`, validado `^[a-z][a-z0-9-]*$`, e `description` opcional), `parsePageSpec` → `parseContentSpec`, envelope `kind:"page"` → `kind:"content"`. Fixture `page_valid.json` → `content_valid.json`. Kernel Dart puro; `slug` passa a ser o handle técnico do conteúdo.
- **Conteúdos · Fase 2 — `sdui_flutter`**: renderer passa a falar "conteúdo" — `SduiView.page(spec)` → `SduiView.content(ContentSpec)` (recebe spec já resolvido, sem busca por slug/rede). Reservada a fachada pública `DrivaContent(slug:)` como **nome + contrato** apenas — o serving por slug em runtime e o `Driva.init(projectId:)` ficam para o próximo incremento.
- **Conteúdos · Fase 3 — `driva_editor`**: `pages_module` → `contents_module`, `editor_module` e rotas `/pages` → `/contents` (e `/contents/:id/edit`). Listagem passa a falar "Conteúdos"; card mostra o `slug` em destaque, o `id` como "ID de suporte", `name` e `description`. Formulário de criação passa a **Nome** (obrigatório) + **Descrição** (opcional) — o campo "Tela de destino" (`screenTarget`) foi **removido**; o `slug` é derivado do nome ao vivo, editável e validado (`^[a-z][a-z0-9-]*$`), com sugestão local de slug livre em colisão.
- **Conteúdos · Fase 4 — `backend`**: `/v1/pages` → `/v1/contents`; modelo Prisma `Page` → `Content` (tabela `contents`), `id` passa a **CUID2** (`@default(cuid(2))`), `screenTarget` **removido**, adicionados `slug` e `description?`, com unicidade dura por projeto (`@@unique([projectId, slug])`). DTOs sem `screenTarget`; `create` gera o `spec` JSONB com `kind:"content"`.
- **Conteúdos · Fase 5 — `backend` (migração)**: o backend passa a usar **Prisma Migrate** (encerra o `prisma db push` no start do container, que vira `prisma migrate deploy`). Migração destrutiva versionada que renomeia `pages` → `contents`, semeia o `slug` a partir do antigo `screen_target` (com deduplicação por projeto), reescreve o `spec` JSONB (`kind:"content"`, sem `screenTarget`), preserva os `id` UUID legados e só então dropa `screen_target`.

### Adicionado

- **Conteúdos · Fase 3 — `driva_editor`**: tratamento de conflito de slug — `ConflictFailure` tipada (traduzida do `409` só na camada data) exibe o slug sugerido e "slug já em uso neste projeto"; util de slug puro (`SlugUtil`: `slugify`/`isValid`/`suggestFree`).
- **Conteúdos · Fase 4 — `backend`**: `409 Conflict` em colisão de slug no projeto, com `suggestedSlug` (um slug livre, sufixo incremental) no corpo da resposta — o contrato casa com o `ConflictFailure` do editor.

- **driva_editor**: wordmark "Driva Builder" na home é um link para a própria home, com tipografia própria (fonte **Space Grotesk** empacotada, pesos 500/700) e "Driva" no laranja da marca.

### Corrigido

- **driva_editor**: URLs limpas no Flutter Web via path URL strategy (`usePathUrlStrategy`) — `/pages` em vez de `/#/pages`. O SPA fallback do nginx (`try_files … /index.html`) já cobre o refresh direto.

## [0.1.0] — 2026-07-02 · I1: Módulo Página

- **sdui_core**: kernel do spec (specVersion 1) — `SduiNode` com id, `PageSpec` (página = fragmento com `screenTarget`, root sempre `column`), `parsePageSpec` (zard + validação recursiva contra o catálogo e slots), catálogo de 14 primitivos com descriptors, `tree_ops` puras.
- **sdui_flutter**: renderer com registry `type → builder` para os 14 primitivos, `SduiView`, `nodeWrapper` (gancho de seleção do editor), fallback amigável para tipo desconhecido.
- **driva_editor**: lista de páginas (grid, criar/excluir) e o editor de 3 colunas — paleta com busca e drag-and-drop, árvore com reordenação/aninhamento, canvas com moldura de dispositivo (3 presets + zoom) renderizando o preview com o renderer real, inspector 100% derivado do catálogo, salvar explícito (botão + Ctrl+S) com indicador de estado, Delete remove o bloco selecionado. Tema claro extraído do protótipo (laranja `#E8602C`), tipografia **Public Sans** empacotada (pesos 400/500/600/700).
- **backend**: NestJS + Prisma + Postgres (porta 5433) com `/v1/pages` (CRUD de specs JSONB), escopo por `x-project-id`, validação de DTO e de `specVersion`.
- **Método**: time de IA (9 agentes + 5 skills em `.claude/`), CLAUDE.md com as regras do livro, docs vivas em `docs/01-modulo-pagina/`.
- Testes: 57 (30 kernel + 7 renderer + 20 editor), `flutter analyze` zero issues.
