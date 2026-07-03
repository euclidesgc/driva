# Plan — Conteúdos (rename Página → Conteúdo + nova identidade)

> Documento vivo. Dono: Tech Lead. **1 fase = 1 PR.** **Topologia de merge (desvio 001, ver `variance_report.md`):** por causa do rename encadeado (o workspace não compila entre fases) e da CI-cancela que só dispara em PRs para `develop`/`main`, existe uma **branch de integração `feature/conteudos`** (nasceu de `develop`). **Cada fase nasce de `feature/conteudos` e volta por PR PARA `feature/conteudos`.** Só o merge final `feature/conteudos → develop` (após a Fase 6) passa pela CI-cancela. Fonte: `prd.md` aprovado pelo dev em 2026-07-02 (sem ajustes). As fases estão ordenadas de **MENOR → MAIOR risco**: começa pelo que não toca dados vivos e isola a migração destrutiva.
>
> Marcas de tarefa: `[P]` pode rodar em paralelo com as vizinhas · `[S]` delegar a sub-agente (varredura/rename pesado).

## Convenções desta feature

- **Sem comentários explicativos no código.** Nome descritivo no lugar do comentário; comentar só o "porquê" não-óbvio. Vale para Dart e TypeScript.
- **Rename ≠ bateria nova.** Cada fase de rename **atualiza os testes já existentes** para compilar/passar (mecânico — faz parte do rename; "pronto" = `analyze` verde + testes existentes passando). A **bateria automatizada nova** (casos de slug, `409`, data migration, goldens) é escrita **por último**, na Fase 6, após o E2E manual atestado — cap. 22 do livro.
- **Fixtures e docs contam para o critério 6.** Renomear `page_valid.json` → `content_valid.json`, reescrever envelope (`kind:"content"`, `slug`, sem `screenTarget`) e varrer docs/fixtures em cada fase.
- **Nada de `extra:` em rotas; variantes `*Named`; go_router.** Regras do CLAUDE.md mandam em qualquer contradição.
- **Desvio do plano** só entra com aprovação do dev humano e registro em `docs/02-conteudos/variance_report.md` (como estava · por que mudou · o que mudou).

## Mapa de dependências e paralelismo

```
Fase 1 (sdui_core) → Fase 2 (sdui_flutter) → Fase 3 (driva_editor)
Fase 4 (backend/CRUD)  ── independente do chain Dart, pode ir em PARALELO ──
Fase 5 (migração destrutiva)  depende da Fase 4  ── RISCO ALTO · OPS do humano ──
Fase 6 (E2E + testes + docs)  depende de tudo
```

- **Chain Dart (1→2→3)** é sequencial: cada fase depende do símbolo renomeado pela anterior.
- **Fase 4 [P]** é outra base de código (NestJS, fora do workspace Dart) e só depende do contrato de fio já acordado no PRD — pode abrir em paralelo com o chain Dart.
- **Fase 5** é a única que transforma dados vivos; **depende do schema `Content` da Fase 4** e fica isolada.

---

## Fase 1 — `sdui_core`: `PageSpec` → `ContentSpec`  · risco: BAIXO (Dart puro, não toca dados)

Âncoras: `packages/sdui_core/lib/src/model/page_spec.dart`, schema zard e parser do kernel, `packages/sdui_core/test/fixtures/page_valid.json`.

- [ ] Renomear `PageSpec` → `ContentSpec` (`page_spec.dart` → `content_spec.dart`); campos: **remove** `screenTarget`, **adiciona** `slug` e `description` (opcional); `Equatable`, imutável, sem `fromMap`/`toMap` cru
- [ ] `toMap`/`toJson` do envelope: `kind:"page"` → `kind:"content"`, emitir `slug`/`description`, sem `screenTarget`
- [ ] `parsePageSpec` → `parseContentSpec`; schema zard do envelope: `kind` fixo `"content"`, `slug` validado `^[a-z][a-z0-9-]*$`, `description` opcional, **`screenTarget` removido** do schema
- [ ] Fixture `page_valid.json` → `content_valid.json` (novo envelope) [P]
- [ ] Atualizar barrels/exports e **os testes existentes do `sdui_core`** para compilar com os novos nomes
- [ ] [S] Varredura no pacote: zero `PageSpec`/`parsePageSpec`/`screenTarget`/`kind:"page"` remanescente
- [ ] Cancela: `dart test packages/sdui_core` verde + `flutter analyze` verde

## Fase 2 — `sdui_flutter`: renderer + fachada `DrivaContent` reservada  · risco: BAIXO

Âncoras: `packages/sdui_flutter/lib/src/sdui_view.dart`, `registry.dart`, `renderer.dart`, `builders/`.

- [ ] `SduiView.page(spec)` → equivalente de conteúdo (ex.: `SduiView.content(spec)`); assinaturas e docstrings falam "conteúdo". **Recebe spec já resolvido — NÃO busca por slug**
- [ ] Ajustar referências ao tipo renomeado (`ContentSpec`) vindas da Fase 1
- [ ] **Reservar `DrivaContent`** como fachada pública: **só nome + contrato de dados** (`slug`, etc.). **Sem** rede/serving/fetch — serving por slug e `Driva.init(projectId:)` são escopo do próximo incremento (registrar essa fronteira no docstring/barrel)
- [ ] Atualizar **testes existentes** do renderer para compilar (contrato catálogo↔registry inalterado)
- [ ] [S] Varredura no pacote: zero nomes antigos remanescentes
- [ ] Cancela: `flutter test packages/sdui_flutter` verde + `flutter analyze` verde

## Fase 3 — `driva_editor`: `contents_module` + `editor_module` + rotas  · risco: MÉDIO

Fatia vertical: renomeia os **dois** módulos e as rotas atomicamente, para o app seguir funcionando ponta a ponta neste PR. Âncoras: `apps/driva_editor/lib/modules/pages_module/**`, `apps/driva_editor/lib/modules/editor_module/**`, `apps/driva_editor/lib/app_router.dart`, `apps/driva_editor/lib/core/error/failure.dart`, `apps/driva_editor/lib/core/dev/fake_pages_store.dart`.

- [ ] `pages_module` → `contents_module`: domain (`PageSummary`→`ContentSummary` com `slug`/`description`, sem `screenTarget`; use cases `get/create/delete`), data (model zard + repo Dio + fake), presentation (`PageListCubit/Page` → `ContentListCubit/Page`); barrel/`*_injection`/`*_routes` renomeados
- [ ] Card do conteúdo: **`slug` em destaque**, `id` como "ID de suporte", `name`, `description` (acessibilidade: cor nunca é o único sinal; `Semantics`/tooltip)
- [ ] Formulário de criação: **Nome** (obrigatório) + **Descrição** (opcional); campo `screenTarget` **removido**
- [ ] [P] Util de slug: derivação ao vivo do nome (`slugify` → `^[a-z][a-z0-9-]*$`) + sugestão local de slug livre em colisão (`home` → `home-2`); Dart puro/testável
- [ ] [P] `core/error`: nova `Failure` tipada de conflito (ex.: `ConflictFailure`) para o `409` de slug; **tradução do `409` mora só na camada data** (único try/catch)
- [ ] Presentation trata `ConflictFailure`: exibe slug ajustado sugerido + mensagem ("slug já em uso neste projeto"); aviso não-bloqueante ao editar slug de conteúdo existente
- [ ] `editor_module`: renomear refs a `PageSpec`/`screenTarget` (`inspector_panel.dart`, `editor_top_bar.dart`, cubit/estado, use cases `LoadPage`/`SaveDraft`); consumo do kernel via `parseContentSpec`
- [ ] Rotas: `/pages` → `/contents` e `/pages/:id/edit` → `/contents/:id/edit`; classes `ContentsRoutes`/`EditorRoutes` (constantes + `static GoRoute get route` + variantes `*Named`); `initialLocation` e redirects em `app_router.dart`
- [ ] `core/dev/fake_pages_store.dart` → `fake_contents_store.dart` (dados de exemplo com `slug`, sem `screenTarget`)
- [ ] Textos pt-BR: "Conteúdos", labels do formulário, empty state, mensagens de erro
- [ ] Atualizar **testes existentes** do editor para compilar
- [ ] [S] Varredura no app: zero `PageSpec`/`screenTarget`/`/pages`/`kind:"page"` remanescente
- [ ] Cancela: `flutter analyze` verde + testes existentes do editor passando; lista abre no Chrome (verificação manual do dev)

## Fase 4 — `backend`: `/v1/contents` + modelo `Content` (código, sem tocar dados vivos)  · risco: MÉDIO · [P] independente do chain Dart

Âncoras: `backend/prisma/schema.prisma`, `backend/src/pages/**` (controller/service/dto), `backend/src/app.module.ts`. **Esta fase NÃO transforma dados vivos** — usa o docker postgres local (dados descartáveis) para dev/CI; a migração versionada contra hml/prod é a Fase 5.

- [ ] `schema.prisma`: `model Page` → `model Content`; `id String @id @default(cuid(2))`; **remove** `screenTarget`; **adiciona** `slug`/`description?`; `@@unique([projectId, slug])`; `@@map("contents")`; ajustar índice
- [ ] Renomear `src/pages/` → `src/contents/`; `@Controller('pages')` → `@Controller('contents')` (`/v1/contents`); `pages.service.ts` → `contents.service.ts`; `pages.module.ts` idem
- [ ] DTOs: `CreatePageDto` → `CreateContentDto` (sem `screenTarget`, com `description`); `Update...` idem; `service.create` gera o `spec` JSONB com `kind:"content"` e **sem `screenTarget` no envelope**
- [ ] Mapear violação de `@@unique` → **`409 Conflict`** (`ConflictException`) na criação/edição com slug em uso no projeto
- [ ] Dev local: `db push` contra docker postgres (throwaway). **Não tocar hml/prod aqui**
- [ ] Atualizar **testes existentes** do backend para compilar; ajustar `docker-compose`/README de dev se citarem `pages`
- [ ] [S] Varredura no backend: zero `Page`/`/v1/pages`/`screenTarget`/`kind:"page"` remanescente
- [ ] Cancela: `build` + testes existentes do backend verdes (mesma régua do CI)

## Fase 5 — Migração destrutiva versionada (ISOLADA)  · risco: ALTO 🔴

> **Quem executa: humano (OPS) — backup + janela de manutenção. A IA só ENTREGA o código da migration + o script de data migration + o roteiro no PR; NÃO roda nada contra prod/hml, nem na CI.** Depende do schema `Content` da Fase 4. Operação destrutiva e irreversível (drop de `screenTarget`, `@@unique` nova, reescrita de JSONB linha a linha).

- [ ] Introduzir **Prisma Migrate** (encerra o `db push`): **baseline = SQL do estado DEPLOYADO atual (`pages`)**, para `migrate resolve --applied <baseline>` marcar prod/hml como aplicado **sem** rodar SQL no estado já existente
- [ ] Migration de rename: `pages` → `contents`; `add slug`, `add description`; `add @@unique([projectId, slug])`; `drop screen_target`
- [ ] Script de **data migration** versionado: por registro → `slug = dedupe(slugify(screen_target), projectId)` sanitizado para `^[a-z][a-z0-9-]*$`, sufixo incremental em colisão por projeto (`home`, `home-2`); **reescrever o JSONB** do `spec` (`kind:"page"`→`"content"`, remover `screenTarget` do envelope); **manter `id` (UUID legado) intacto** — só novos nascem CUID2
- [ ] Script de validação pós-migração: contagem de linhas antes/depois + amostra rodando `parseContentSpec` + checagem de JSONB sem `screenTarget`/`kind:"page"`
- [ ] **Roteiro OPS no PR** (e em `test_plan.md`): 1) backup Postgres prod+hml; 2) aplicar em **hml primeiro** + validação manual; 3) aplicar em **prod**; 4) **rollback documentado** (restaurar backup) se a validação falhar
- [ ] [S] Varredura de segurança do script: nenhum segredo/URL de banco no repo (só env no Coolify)
- [ ] Cancela: código da migration + script + roteiro revisáveis "de relance"; **sem execução contra dados vivos pela IA**

## Fase 6 — E2E manual + bateria automatizada + docs vivas (fluxo do livro)  · fecha a feature

- [ ] **Gate CISO** (antes de instrumentar) — revisão de segurança da entrega
- [ ] QA instrumenta o E2E (skill `instrumentar-e2e`; instrumentação temporária, nunca vai a produção) + escreve `test_plan.md` com o roteiro do caminho feliz e casos de borda do PRD
- [ ] **Dev executa o E2E manual** e anexa prints em `docs/02-conteudos/evidencias/`
- [ ] Se o E2E falhar: Tech Lead lê os logs plantados + prints, localiza a quebra e conserta (ou delega ao especialista da fatia)
- [ ] **Gate CISO** (depois de limpar a instrumentação)
- [ ] **Bateria automatizada nova** (por último — skill `escrever-testes`):
  - [ ] `sdui_core` [P]: `parseContentSpec` com fixtures válidas/inválidas (`kind:"content"`, sem `screenTarget`, com `slug`); round-trip de serialização; regressão dos nomes antigos removidos
  - [ ] `sdui_flutter` [P]: contrato catálogo↔registry; fixture ponta a ponta do novo envelope; presença da fachada `DrivaContent` (nome/contrato, sem rede)
  - [ ] `driva_editor` [P]: `bloc_test` dos cubits (lista + editor renomeados); derivação de slug ao vivo; tratamento de `409`; widget tests dos estados; **golden** do card/formulário novos
  - [ ] `backend` [P]: `@@unique` (dois inserts mesmo slug/projeto → `409`); slugs iguais em projetos diferentes coexistem; `id` novo = CUID2; teste da **data migration** (page→content, slug do `screenTarget`, JSONB reescrito, colisão sufixada)
- [ ] [S] **Varredura final consolidada — critério 6**: zero referência a `PageSpec`/`parsePageSpec`/`screenTarget`/`/v1/pages`/`kind:"page"` em **código, docs, fixtures e testes** de toda a stack
- [ ] Docs vivas (skill `manter-docs-vivas`): `README`, `CHANGELOG` (seção `Unreleased`), `ANALYTICS.md` ("nenhum evento novo — rename não introduz telemetria"), `ERROR_LOGS.md` (novo caminho de conflito de slug/`409`), `final_report.md`
- [ ] **DoD**: `flutter analyze` verde + todas as baterias verdes + docs vivas em dia

---

## Critérios de aceite ↔ fase (rastreio)

| # | Critério (PRD) | Fase que fecha |
|---|---|---|
| 1 | Caminho feliz sem erro no console, vocabulário "Conteúdo/Conteúdos" na UI | 3 (UI) · 6 (E2E) |
| 2 | Criar com Nome+Descrição; slug derivado/editável/livre; `409` tratado | 3 · 4 |
| 3 | `@@unique([projectId, slug])` bloqueia duplicata; projetos diferentes coexistem | 4 · 6 (teste) |
| 4 | `id` de novos = CUID2; UUIDs legados preservados | 4 · 5 |
| 5 | Migração aplicada em hml validada (contagem + amostra + JSONB) antes de prod; backup | 5 (OPS humano) |
| 6 | Zero `PageSpec`/`parsePageSpec`/`screenTarget`/`/v1/pages`/`kind:"page"` remanescente | todas + varredura final na 6 |
| 7 | `DrivaContent` fachada reservada (nome+contrato, sem rede); serving/`Driva.init` no próximo incremento | 2 |
| 8 | `analyze` verde + baterias verdes + docs vivas | 6 (DoD) |

## Progresso

- Fase 1 — ✅ concluída (2026-07-02): `sdui_core` renomeado; `dart test packages/sdui_core` verde (30 testes), `dart analyze` limpo; QA aprovou, CISO liberado; PR #8 mergeado na integração `feature/conteudos`
- Fase 2 — ✅ concluída (2026-07-02): `sdui_flutter` renomeado (`SduiView.content`) + fachada `DrivaContent` reservada; `flutter test packages/sdui_flutter` verde (7); QA aprovou, CISO liberado; PR #9 mergeado na integração `feature/conteudos`
- Fase 3 — ✅ concluída (2026-07-02): `driva_editor` — `contents_module` + `editor_module` + rotas `/contents`; card com slug em destaque, form Nome+Descrição, `SlugUtil`, `ConflictFailure` (409 traduzido só na data). **`flutter analyze` da RAIZ verde** (chain Dart 1→2→3 fechado) + `flutter test apps/driva_editor` verde (20). QA aprovou, CISO liberado; PR #10 mergeado na integração `feature/conteudos`.
  - Backlog (não-bloqueia): quando existir superfície de **edição de slug de conteúdo já criado**, reexibir o aviso não-bloqueante nela (hoje o aviso vive como `helperText` do campo Slug na criação).
- Fase 4 — ✅ concluída (2026-07-02): `backend` — `model Content` (CUID2, `@@unique([projectId, slug])`, `@@map("contents")`), `/v1/contents`, DTOs sem `screenTarget`, `409` com `suggestedSlug` no corpo (espelha `SlugUtil.suggestFree`; contrato casado com a Fase 3). Cancela: `pnpm build` verde + `prisma:generate`/`validate` ok; backend não tem bateria de testes hoje (a nova é Fase 6). QA aprovou, CISO liberado; PR #11 mergeado na integração `feature/conteudos`.
- Fase 5 — 🚧 em progresso (2026-07-02): **migração destrutiva versionada** `pages`→`contents`. Prisma Migrate (baseline `0_baseline` do estado antigo + `20260702120000_rename_pages_to_contents`), ordem EXPAND→BACKFILL→CONSTRAIN→CONTRACT (slug semeado de `screen_target`, dedupe por projeto, JSONB reescrito, UUID legado preservado, `screen_target` dropado por último). SQL puro numa transação; backfill idempotente (`WHERE slug IS NULL`). `Dockerfile` CMD `db push`→`migrate deploy`. `validate_migration.sql` + roteiro OPS no `test_plan.md`. **Cancela local (Postgres docker efêmero):** QA reproduziu tudo — dedupe (`home`/`home-2`), sanitização, JSONB sem `screenTarget`, UUID preservado, unique ativa, idempotência (MD5 idêntico), `pnpm build` verde; nada executado contra hml/prod. QA aprovou, CISO liberado; PR aberto para `feature/conteudos`.
  - **Recomendações OPS do CISO (para o humano decidir na execução — não bloqueiam o merge do PR de código):**
    - **R1 — janela de escrita:** o backend antigo segue servindo entre o backup (pré-merge) e a subida do container novo; escrita nessa janela fica fora do dump e some num rollback. Para **prod**, colocar o ambiente em manutenção/read-only (ou parar o backend) antes do backup+deploy e tirar o count de referência imediatamente antes.
    - **R2 — baseline à prova de esquecimento (aplicado + achado):** a `0_baseline` foi tornada idempotente (`CREATE ... IF NOT EXISTS`, commit `51bc1f4`). **Revalidação em Postgres efêmero refutou a premissa:** `migrate deploy` sobre schema não-vazio sem histórico aborta no preflight **P3005** *antes* de rodar SQL — a idempotência não contorna esse gate. Portanto o `migrate resolve --applied 0_baseline` **permanece PRÉ-CONDIÇÃO OBRIGATÓRIA** (esquecer derruba o deploy, mas de forma limpa, sem mutar dados). A idempotência fica como defesa em profundidade. **Decisão pendente do humano** para auto-cura real: (a) manter o resolve manual como pré-condição (estado atual, truthful no `test_plan.md`); ou (b) rodar um `migrate resolve --applied 0_baseline` idempotente no entrypoint/Coolify **antes** do `migrate deploy` (muda a orquestração de deploy — exige validação + re-gate próprios).
- **Notas para o gate geral pré-E2E / DoD (Fase 6)** — carregadas das fases 3 e 4:
  - `dio_client`: condicionar o `LogInterceptor` a `!kReleaseMode`/flag de debug; confirmar `useFakeData:false` em `config/prod.json`.
  - **Segurança (CISO, Fase 4):** o tenant vem de `x-project-id` **não autenticado** (fallback `"default"`) — estrutura de isolamento correta (todas as queries e o `freeSlug` escopam por `projectId`), mas falta a autenticação que amarra o header a um tenant. Diferido ao I4; **pré-requisito de segurança antes de qualquer exposição pública multi-tenant**. Garantir `CORS_ORIGINS` preenchido no Coolify de hml/prod (fallback libera `localhost`).
  - `backend`: o `create` faz 2 writes não-transacionais (insert `spec:{}` → update com o spec, para o `spec.id` referenciar o CUID2 cunhado pelo Prisma); avaliar `$transaction` — risco baixo (P2002 dispara no insert, sem órfão no caminho de conflito).
- Fase 6 — não iniciada
