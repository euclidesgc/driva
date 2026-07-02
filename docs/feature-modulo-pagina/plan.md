# Plan — Módulo Página (I1)

> Documento vivo. Dono: Tech Lead. Cada fase = 1 PR. Marcas: `[P]` pode rodar em paralelo com vizinhas; `[S]` delegar a sub-agente (varredura pesada). Fonte: plano aprovado pelo dev em 2026-07-01.

## Fase 0 — Fundação + time de IA ✅ (2026-07-01/02)

- [x] pub workspace (pubspec raiz, analysis_options, .gitignore) + esqueletos dos 3 pacotes
- [x] CLAUDE.md com as regras do projeto
- [x] 9 agentes em `.claude/agents/` + 5 skills em `.claude/skills/`
- [x] docs vivas desta feature (specs, prd, plan, variance_report, test_plan, final_report)

## Fase 1 — sdui_core ✅ (2026-07-01)

- [x] Modelos (SduiNode com id, PageSpec, SduiAction) — Equatable, imutáveis
- [x] Schema (zard no envelope + validação recursiva de nós contra o catálogo/slots)
- [x] Catálogo: 14 descriptors com PropField/FieldKind + `defaultNode`
- [x] tree_ops puras (find/insert/setChild/remove/move/updateProps) com guarda de ciclo
- [x] Fixture `page_valid.json` + 30 testes verdes

## Fase 2 — sdui_flutter ✅ (2026-07-01)

- [x] SduiRegistry + SduiRenderer com `nodeWrapper` (gancho de seleção do editor)
- [x] parsers/enums/material_icons + 14 builders (props planas → estilo)
- [x] SduiView / SduiView.page
- [x] 7 testes verdes, incl. contrato catálogo ↔ registry e fixture ponta a ponta

## Fase 3 — Casca do editor + pages_module (em andamento)

- [ ] core/: error (Failure sealed), network (createDio), observability (AppBlocObserver), config (AppConfig)
- [ ] bootstrap.dart (4 redes de erro) + main_dev/main_prod + config/dev.json [P com pages_module]
- [ ] core/theme: AppTheme (tokens do protótipo), widgets compartilhados (ResizableSplitView)
- [ ] pages_module: domain (PageSummary, PagesRepository, 3 use cases) → data (model zard + `PagesRepositoryFake`) → presentation (PageListCubit sealed, PageListPage grid + diálogo "Nova página")
- [ ] Fiação: pages_routes/pages_injection/barrel + app_router + injection
- [ ] Verificável: `flutter run -d chrome` abre a lista com dados fake

## Fase 4 — editor_module

- [ ] domain: EditorRepository (loadPage/saveDraft) + use cases [P com widgets]
- [ ] data: page_spec_model (delega a parsePageSpec) + `EditorRepositoryFake`
- [ ] EditorCubit + EditorState sealed (document/selectedNodeId/device/zoom/saveStatus); mutações via tree_ops
- [ ] Painéis: editor_top_bar, widget_palette_panel (Draggable), widget_tree_panel (DragTarget), canvas_panel (moldura + SduiView + nodeWrapper), inspector_panel (derivado do catálogo), prop_field_editor (fábrica FieldKind→editor)
- [ ] Atalhos (Delete, Ctrl+S) + acessibilidade (contorno + label na seleção, Semantics)
- [ ] Verificável: criar página, arrastar os 14 primitivos, reordenar, editar props, preview com zoom/device — em memória

## Fase 5 — Backend + integração

- [ ] NestJS pages (controller/service/DTOs class-validator) + Prisma (Page: id, projectId, name, screenTarget, spec Json) + docker-compose postgres:16 [P com fases 3–4]
- [ ] Repos Dio reais no flavor dev apontando para `http://localhost:3000/v1`
- [ ] Verificável: salvar/reabrir persiste no Postgres

## Fase 6 — E2E + testes + docs (fluxo do livro)

- [ ] Gate CISO (código limpo) → QA instrumenta E2E → dev testa (test_plan.md + evidencias/)
- [ ] Wrap: limpar instrumentação + final_report.md → gate CISO
- [ ] Bateria automatizada por último: bloc_test dos cubits, widget tests por estado, golden [S]
- [ ] Docs vivas: README, CHANGELOG, ANALYTICS.md ("nenhum evento"), ERROR_LOGS.md
