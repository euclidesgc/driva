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

## Fase 3 — Casca do editor + pages_module ✅ (2026-07-02)

- [x] core/: error (Failure sealed com message), network (createDio + x-project-id), observability (AppBlocObserver), config (AppConfig com useFakeData)
- [x] bootstrap.dart (4 redes de erro) + main_dev/main_prod + config/{dev,prod}.json
- [x] core/theme: AppTheme (tokens do protótipo — laranja #E8602C, tema claro) + ResizableSplitView
- [x] core/dev: FakePagesStore (compartilhado pelos fakes; página de exemplo)
- [x] pages_module completo (domain → data com fake e Dio → PageListCubit/PageListPage)
- [x] Fiação + verificado: lista abre no Chrome com dados fake

## Fase 4 — editor_module ✅ (2026-07-02)

- [x] domain: EditorRepository + LoadPage/SaveDraft (com trava de revalidação no save)
- [x] data: impl Dio (`GET/PUT /v1/pages/:id`, parse só via kernel) + fake
- [x] EditorCubit + EditorState sealed; mutações via tree_ops; id único por documento
- [x] Painéis: top bar (status de salvamento), paleta (Draggable + clique-para-adicionar), árvore (DragTarget, reordenar/aninhar), canvas (moldura 3 presets + zoom + SduiView + nodeWrapper de seleção), inspector derivado do catálogo, prop_field_editor (9 kinds)
- [x] Atalhos Ctrl+S/Delete; seleção com contorno + label; Semantics/tooltips
- [x] Verificado no Chrome via DTD: editor completo renderizado, zero erros de runtime

## Fase 5 — Backend + integração ✅ (2026-07-02)

- [x] NestJS (controller/service/DTOs) + Prisma (`pages`, JSONB) + docker-compose postgres:16 na porta **5433** (5432 ocupada por outro projeto)
- [x] Tenant por `x-project-id`; CORS restrito a localhost; specVersion validada no PUT
- [x] dev.json passa a USE_FAKE_DATA=false; fakes seguem como default sem config
- [x] Verificado: contrato inteiro por curl (roundtrip do spec) + UI real com `GET /v1/pages` 200

## Fase 6 — E2E + testes + docs (fluxo do livro)

- [x] Bateria automatizada: 20 testes no editor (PageListCubit, EditorCubit, SaveDraftUseCase) — total 57 no workspace
- [x] test_plan.md com o roteiro completo do E2E manual + mapa de instrumentação
- [x] Docs vivas: README, CHANGELOG, ANALYTICS.md ("nenhum evento"), ERROR_LOGS.md, final_report.md
- [ ] **Dev executa o E2E manual** (roteiro do test_plan.md) e anexa prints em evidencias/
- [ ] Gates do CISO (revisão de segurança da entrega) — recomendado antes do merge
- [ ] Golden tests do editor — quando o design estabilizar (backlog)
