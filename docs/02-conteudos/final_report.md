# Final Report — Conteúdos (rename Página → Conteúdo + nova identidade)

> Relatório de entrega. Dono: QA. Atualizado em 2026-07-03.

## Status: implementação + E2E + bateria automatizada completos (verdes) · migração (Fase 5) é OPS do humano no merge para `develop`

As Fases 1–4 e 6 (E2E) estão implementadas e verificadas. A Fase 5 (migração
destrutiva `pages`→`contents`) **roda sozinha no deploy** e é executada pelo humano
conforme o roteiro OPS do `test_plan.md` quando `feature/conteudos` for para `develop`.

## O que a feature entregou

Rename conceitual **página → conteúdo** em toda a stack, com **nova identidade**:
`id` = **CUID2** opaco/imutável (ID de suporte); `slug` = referência do dev, **única
por projeto** (`@@unique([projectId, slug])`), derivada do Nome ao vivo e validada por
`^[a-z][a-z0-9-]*$`.

| Fase | Entrega | Risco |
|---|---|---|
| 1 | `sdui_core`: `PageSpec`→`ContentSpec`, `parsePageSpec`→`parseContentSpec`, `kind:"page"`→`"content"`, remove `screenTarget`, adiciona `slug`/`description` | BAIXO |
| 2 | `sdui_flutter`: renderer renomeado; fachada pública `DrivaContent` **reservada** (nome+contrato, sem rede) | BAIXO |
| 3 | `driva_editor`: `contents_module` + `editor_module`, rotas `/contents`, form Nome+Descrição+slug, card novo, textos pt-BR | MÉDIO |
| 4 | `backend`: `/v1/contents`, Prisma `Page`→`Content` (CUID2, `@@unique`, `409`+`suggestedSlug`), migrations versionadas | MÉDIO |
| 5 | Migração destrutiva versionada (backfill de slug + reescrita JSONB), roda no deploy | ALTO 🔴 (OPS humano) |
| 6 | E2E por rodadas + bateria automatizada + docs vivas | — (fecha a feature) |

## Verificado por máquina

| Verificação | Resultado |
|---|---|
| `flutter analyze` (workspace) | ✅ **No issues found** |
| `dart test packages/sdui_core` | ✅ 30 (schema/`parseContentSpec`, catálogo 14 primitivos, `tree_ops`) |
| `flutter test packages/sdui_flutter` | ✅ 7 (contrato catálogo↔registry, fixture de conteúdo ponta a ponta, props→estilo, ações, `nodeWrapper`, fallback) |
| `flutter test apps/driva_editor` | ✅ **47** (era 20; **+27 na Fase 6**) |
| ↳ Bateria da Fase 6 (nova) | ✅ `slug_test` (15: `isValid`/`slugify`/`suggestFree` + bordas); `content_list_page_test` (10: widget por estado do sealed — Loading/Empty/Error+retry/Loaded — com **a11y** Semantics/tooltip, + diálogo "Novo conteúdo": slug ao vivo, dedupe `home→home-2`, validação no cliente); `content_list_golden_test` (2: card + empty, fontes reais, comparador tolerante ao ruído subpixel) |
| Contrato do backend (`e2e.sh`, Postgres efêmero) | ✅ **17/17** — POST 201 + `id` CUID2 + slug ecoado; envelope `kind:"content"`/`slug`/sem `screenTarget`; slug repetido→**409** com `suggestedSlug=home-2`; mesmo slug em outro projeto coexiste; slug inválido→400; PUT/GET/DELETE + 404 pós-delete |
| **Total Flutter/Dart** | ✅ **84 testes** verdes (30 + 7 + 47), `flutter analyze` sem issues |

## E2E — por rodadas, com prints headless (novo padrão)

O E2E passou a rodar **em rodadas**, com o QA **gerando os prints** (o dev só confere):

- **`e2e.sh`** valida todo o contrato do backend por API (base de teste efêmera).
- **`e2e_shots.sh`** captura os 8 estados visuais em headless: **01–04 por URL**
  (`--screenshot`) e **05–08 de interação** dirigindo o canvas Flutter por **CDP puro**
  (`e2e_drive.mjs`, sem dependências): slug ao vivo, colisão→`home-2`, drag-drop→preview, salvar.
- Evidências em `evidencias/rodada_MM/`. A **rodada_04** tem os 8 prints conferidos.

### Achados das rodadas

1. **Ícones "tofu" (□)** no `flutter run` **não eram bug** de código nem de build — o
   `build/web` emite `MaterialIcons-Regular.otf` + FontManifest corretos e renderiza
   (provado por screenshot headless). Era **estado sujo do browser em debug**; fix:
   incognito (o recipe antigo `--user-data-dir=<pasta fixa>` persistia cache).
2. **Colisão de slug**: submeter slug repetido **não reabre diálogo com aviso** (como o
   test_plan previa) — o app **auto-resolve para `home-2` e abre o editor**. Bate com o
   PRD (§ Exceções). **Aceito pelo dev** como o UX desejado; test_plan alinhado.
3. **Base de teste do `e2e.sh` é efêmera de verdade** (verificado: `default` nasce
   vazio; `down -v` exit 0). Endurecido para avisar caso o `down -v` falhe.

## Critério 6 — rename completo

Código e fixtures: **zero** `PageSpec`/`parsePageSpec`/`screenTarget`/`kind:"page"`/`Page`
remanescente (varredura na Fase 6). Docs de estado atual (`CLAUDE.md`, `README.md`,
`especialista-dados.md`) realinhadas a `/v1/contents`. Referências a `/v1/pages` que
sobraram são **legítimas** (histórico do CHANGELOG, docs do I1, linhas que descrevem o
próprio rename/rollback).

## Desvios

`variance_report.md` **001** — branch de integração `feature/conteudos` no lugar de
PR-de-fase direto para `develop` (rename encadeado quebraria a CI-cancela em PRs
intermediários). Sem mudança de escopo/critérios; só topologia de merge.

## Pendente para fechar a feature

- **Fase 5 — migração** — roteiro OPS do humano (`test_plan.md`): backup → `resolve
  --applied 0_baseline` por ambiente → merge dispara `migrate deploy` → validação em
  hml antes de prod.

## Fora do escopo entregue (backlog)

Serving ao app cliente + `Driva.init`/`DrivaContent` com rede (I-seguinte) · testes
automatizados do **backend** (Jest — follow-up) · `flutter_driver` nativo (o CDP já
cobre a interação) · undo/redo · auto-save.
