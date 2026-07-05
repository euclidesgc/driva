# Changelog

## [Unreleased]

### Alterado

- **driva_editor · lista de conteúdos (navegação)**: criar um conteúdo não pisca mais um spinner na lista antes de abrir o construtor. No sucesso, `ContentListCubit.create()` deixa de fazer `await load()` (spinner `ContentListLoading` + round-trip `getContents()` inútil, que repintava uma grade prestes a ser destruída pelas rotas flat) e navega direto ao editor. A exclusão virou **otimista**: o card some na hora (`Loaded(n-1)` ou `Empty`), a API é chamada em seguida e, em falha, `load()` reconcilia (o card reaparece) com snackbar estático — sem spinner full-screen apagando a grade. Data/domain intocados. _(roadmap item 2 / melhorias item 10)_

## [0.2.0] — 2026-07-04 · Conteúdos + perf do editor + DNS próprio

### Alterado

- **Infra · DNS próprio do projeto**: os domínios migraram de `*.bmjtech.duckdns.org` para o DuckDNS próprio `*.driva.duckdns.org` (wildcard, IP `64.181.165.16`). Produção = `driva.duckdns.org` (front) / `api.driva.duckdns.org` (API); homologação = `hml.driva.duckdns.org` (front) / `api-hml.driva.duckdns.org` (API). Atualiza `config/{hml,prod}.json` (`API_BASE_URL` compile-time), `docs/deploy/coolify.md`, `backend/.env.example`, `CLAUDE.md` e as skills de GitFlow. O `bmjtech.duckdns.org` fica só como host de infra compartilhada.
- **Conteúdos (rename página → conteúdo) · Fase 1 — `sdui_core`**: `PageSpec` → `ContentSpec` (remove `screenTarget`; adiciona `slug`, validado `^[a-z][a-z0-9-]*$`, e `description` opcional), `parsePageSpec` → `parseContentSpec`, envelope `kind:"page"` → `kind:"content"`. Fixture `page_valid.json` → `content_valid.json`. Kernel Dart puro; `slug` passa a ser o handle técnico do conteúdo.
- **Conteúdos · Fase 2 — `sdui_flutter`**: renderer passa a falar "conteúdo" — `SduiView.page(spec)` → `SduiView.content(ContentSpec)` (recebe spec já resolvido, sem busca por slug/rede). Reservada a fachada pública `DrivaContent(slug:)` como **nome + contrato** apenas — o serving por slug em runtime e o `Driva.init(projectId:)` ficam para o próximo incremento.
- **Conteúdos · Fase 3 — `driva_editor`**: `pages_module` → `contents_module`, `editor_module` e rotas `/pages` → `/contents` (e `/contents/:id/edit`). Listagem passa a falar "Conteúdos"; card mostra o `slug` em destaque, o `id` como "ID de suporte", `name` e `description`. Formulário de criação passa a **Nome** (obrigatório) + **Descrição** (opcional) — o campo "Tela de destino" (`screenTarget`) foi **removido**; o `slug` é derivado do nome ao vivo, editável e validado (`^[a-z][a-z0-9-]*$`), com sugestão local de slug livre em colisão.
- **Conteúdos · Fase 4 — `backend`**: `/v1/pages` → `/v1/contents`; modelo Prisma `Page` → `Content` (tabela `contents`), `id` passa a **CUID2** (`@default(cuid(2))`), `screenTarget` **removido**, adicionados `slug` e `description?`, com unicidade dura por projeto (`@@unique([projectId, slug])`). DTOs sem `screenTarget`; `create` gera o `spec` JSONB com `kind:"content"`.
- **Conteúdos · Fase 5 — `backend` (migração)**: o backend passa a usar **Prisma Migrate** (encerra o `prisma db push` no start do container, que vira `prisma migrate deploy`). Migração destrutiva versionada que renomeia `pages` → `contents`, semeia o `slug` a partir do antigo `screen_target` (com deduplicação por projeto), reescreve o `spec` JSONB (`kind:"content"`, sem `screenTarget`), preserva os `id` UUID legados e só então dropa `screen_target`.

### Adicionado

- **Conteúdos · Fase 3 — `driva_editor`**: tratamento de conflito de slug — `ConflictFailure` tipada (traduzida do `409` só na camada data) exibe o slug sugerido e "slug já em uso neste projeto"; util de slug puro (`SlugUtil`: `slugify`/`isValid`/`suggestFree`).
- **Conteúdos · Fase 4 — `backend`**: `409 Conflict` em colisão de slug no projeto, com `suggestedSlug` (um slug livre, sufixo incremental) no corpo da resposta — o contrato casa com o `ConflictFailure` do editor.
- **Conteúdos · Fase 6 — E2E + qualidade**: E2E por **rodadas** com prints **headless** gerados pelo QA (o dev só confere) — `e2e.sh` (contrato do backend por API, base de teste efêmera) + `e2e_shots.sh` (8 estados visuais: 4 por URL + 4 de interação dirigidos por **CDP puro**, `e2e_drive.mjs`, sem dependências). Bateria automatizada ampliada para **84 testes** (+27 no editor): `SlugUtil`, widget tests por estado do sealed da lista (com acessibilidade) e goldens do card e do empty state. Varredura do critério-6: código/fixtures 100% renomeados; docs de estado atual (`CLAUDE.md`/`README.md`) realinhadas a `/v1/contents`.

- **driva_editor**: wordmark "Driva Builder" na home é um link para a própria home, com tipografia própria (fonte **Space Grotesk** empacotada, pesos 500/700) e "Driva" no laranja da marca.

### Alterado

- **driva_editor · editor (performance)**: o construtor deixa de reconstruir o workspace inteiro a cada tecla/tick de drag. Um único `BlocBuilder` no topo virou **escopo por painel** (`BlocSelector`/`context.select`): a paleta é construída uma vez (nunca rebuilda), a árvore só quando a **estrutura** ou a seleção mudam (props não a afetam), o inspector só quando o nó inspecionado muda, e a top bar só no nome/slug/status. O preview do canvas é isolado por `RepaintBoundary` e a re-renderização do documento (o custo caro: o renderer real) passa a ser **throttled** (~120 ms, com render final garantido) — mantendo o campo do Inspector e o estado instantâneos. _(roadmap item 3b)_

### Corrigido

- **driva_editor · Inspector**: campos de propriedade não perdem mais o foco ao digitar (antes, ao informar cada caractere — ex.: elevação do card — o campo era recriado e exigia reclicar). Os editores de texto/número/cor/espaçamento passam a usar `TextEditingController` com key de identidade estável (`nodeId_fieldKey`); a ressincronização por mudança externa é semântica nos numéricos, para não quebrar `1.` → `1.0` durante a digitação. _(roadmap item 1 / melhorias item 16)_
- **driva_editor**: URLs limpas no Flutter Web via path URL strategy (`usePathUrlStrategy`) — `/pages` em vez de `/#/pages`. O SPA fallback do nginx (`try_files … /index.html`) já cobre o refresh direto.

## [0.1.0] — 2026-07-02 · I1: Módulo Página

- **sdui_core**: kernel do spec (specVersion 1) — `SduiNode` com id, `PageSpec` (página = fragmento com `screenTarget`, root sempre `column`), `parsePageSpec` (zard + validação recursiva contra o catálogo e slots), catálogo de 14 primitivos com descriptors, `tree_ops` puras.
- **sdui_flutter**: renderer com registry `type → builder` para os 14 primitivos, `SduiView`, `nodeWrapper` (gancho de seleção do editor), fallback amigável para tipo desconhecido.
- **driva_editor**: lista de páginas (grid, criar/excluir) e o editor de 3 colunas — paleta com busca e drag-and-drop, árvore com reordenação/aninhamento, canvas com moldura de dispositivo (3 presets + zoom) renderizando o preview com o renderer real, inspector 100% derivado do catálogo, salvar explícito (botão + Ctrl+S) com indicador de estado, Delete remove o bloco selecionado. Tema claro extraído do protótipo (laranja `#E8602C`), tipografia **Public Sans** empacotada (pesos 400/500/600/700).
- **backend**: NestJS + Prisma + Postgres (porta 5433) com `/v1/pages` (CRUD de specs JSONB), escopo por `x-project-id`, validação de DTO e de `specVersion`.
- **Método**: time de IA (9 agentes + 5 skills em `.claude/`), CLAUDE.md com as regras do livro, docs vivas em `docs/01-modulo-pagina/`.
- Testes: 57 (30 kernel + 7 renderer + 20 editor), `flutter analyze` zero issues.
