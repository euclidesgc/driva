# driva

Plataforma de **Server-Driven UI** para apps Flutter: o editor web (`apps/driva_editor`, Flutter Web) monta páginas como **spec JSON**, validado pelo kernel (`packages/sdui_core`) e desenhado pelo renderer (`packages/sdui_flutter`) — o mesmo renderer que os apps dos clientes usarão. O backend (`backend/`, NestJS + Prisma + Postgres) apenas armazena os specs (JSONB), sem interpretá-los.

## Layout do workspace (Dart pub workspace)

- `packages/sdui_core` — kernel do spec. **Dart puro** (equatable, fpdart, zard; `package:flutter` proibido). Modelos, schema zard, catálogo de widgets, operações puras de árvore.
- `packages/sdui_flutter` — renderer. Registry `type → builder`, `SduiView`. Depende só de `sdui_core`.
- `apps/driva_editor` — o editor. Depende de `sdui_flutter` e `sdui_core`.
- `backend/` — NestJS (fora do workspace Dart). Contrato REST em `/v1/contents`.
- `docs/NN-<nome>/` — docs vivas de cada feature (specs, prd, plan, variance_report, test_plan, final_report). **`NN`** é o número de sequência com dois dígitos, na ordem de desenvolvimento (`01`, `02`, …), para o dev enxergar a linha do tempo e saber onde está. Pastas de referência/apoio (`web-prototipe/`, `deploy/`, `specs/`) **não** são numeradas.

## O gabarito

A arquitetura segue o livro em `docs/livro-flutter/` (Seções I–IV). O módulo de referência é `apps/driva_editor/lib/modules/pages_module/` — na dúvida, imite-o. Regra de desempate: **se algo contradiz uma regra deste arquivo, a regra ganha.**

## Regras inegociáveis (Flutter/Dart)

- Clean Architecture por módulo: `lib/modules/<nome>_module/{domain,data,presentation}` + `<nome>_routes.dart` + `<nome>_injection.dart` + barrel público `<nome>_module.dart` que expõe **só** a rota e o registro de DI.
- **domain** = Dart puro; entidades imutáveis (`Equatable`, sem `fromMap`/`toMap`); contratos `abstract interface class` devolvendo `Future<Either<Failure, T>>` (fpdart); **um use case por operação** (método `call()`), mesmo passa-fica.
- **data** = models com (de)serialização validada por **zard** (`safeParse` → `Either`); impl do repositório atrás do contrato; **único lugar com try/catch** (traduz `DioException` → `Failure` tipada de `core/error/`).
- **presentation** = `Cubit` (flutter_bloc) com estado `sealed class` + `switch` exaustivo (states via `part of`); página `StatelessWidget` com `static Widget pageBuilder` — **o único lugar que toca o get_it**. Guarda `isClosed` após `await` antes de `emit`.
- **presentation NUNCA importa data.** Nenhum módulo importa o interno de outro (só o barrel público). Lógica recebe dependências pelo construtor.
- Navegação: go_router; rotas por módulo em classe `XRoutes` (`static GoRoute get route` + constantes); sempre variantes `*Named`; nada de `extra:` (some no refresh web).
- Erros imprevistos: `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` + `AppBlocObserver` no `bootstrap.dart`.
- Flavors: `main_dev.dart`/`main_prod.dart` → `bootstrap(AppConfig)`; config via `--dart-define-from-file=config/<env>.json`; segredo nunca em dart-define.
- **Zero build_runner** (nada de freezed, json_serializable, injectable, mockito, go_router_builder).
- Testes: `test/` espelha `lib/`; `mocktail` (`MockX extends Mock implements X`) + `bloc_test`; a bateria automatizada é escrita **por último** (após o E2E manual — cap. 22 do livro).
- Acessibilidade: cor nunca é o único sinal de informação; controles com `Semantics`/tooltip.
- Arquivos `snake_case`, classes `PascalCase`, uma classe pública por arquivo; código em inglês, UI e docs em pt-BR.
- Cancela de máquina: **"pronto" = `flutter analyze` verde + testes existentes passando.** Nunca opinião.

## Regras do spec SDUI

- Todo nó tem `id`, `type`, `props`; `events` e `children`/`child` opcionais. Conteúdo: `{specVersion, kind: "content", id, name, slug, root?}`. **`root` é opcional (qualquer widget do catálogo, não só `column`)**: página vazia = sem `root` (`root: null`, chave omitida no JSON); o **primeiro widget adicionado vira a raiz**. Quando presente, `root` é validado como um nó normal contra o catálogo, recursivamente.
- O JSON só vira entidade por `parsePageSpec` (zard) do `sdui_core` — nenhum `fromMap` cru fora dele.
- Paleta, inspector e defaults derivam 100% do `widget_catalog.dart` (WidgetDescriptor/PropField). Novo primitivo = novo descriptor + novo builder + fixture; nada hardcoded no editor.
- Binding `{{prop}}` e ações são **dados** — o editor não os executa (só o app cliente).

## Método de trabalho (time de IA — cap. 22–23 do livro)

O usuário invoca **`/tech-manager <pedido>`** (skill em `.claude/skills/tech-manager/`, que roda na própria conversa e orquestra os agentes de `.claude/agents/`; não é sub-agente). Fluxo: PM faz discovery e mata ambiguidades → `specs.md` → `prd.md` (humano aprova) → tech-lead escreve `plan.md` vivo (1 fase = 1 PR) → especialistas implementam fase a fase (QA valida + CISO revisa + humano revisa o PR) → gate CISO → E2E **por script, em rodadas** (QA prepara `e2e.sh` — contrato por API — e `e2e_shots.sh` — **prints headless** de todo o visual: estados por URL (`--screenshot`) e de interação no canvas (drag/digitação/salvar) dirigidos por **CDP** (`e2e_drive.mjs`, sem deps); o humano só **confere** os prints; evidências por rodada em `evidencias/rodada_MM/`; problema → time corrige/ajusta o script → próxima rodada) → wrap + `final_report.md` → gate CISO → **só então** testes automatizados → DoD (testes verdes + docs vivas em dia). Desvio do plano só entra com aprovação do humano e registro em `variance_report.md`.

**Roadmap vivo (`docs/roadmap.md`).** Fonte única de rastreabilidade do produto — o que foi feito, o que está em andamento, o que falta. Lista **ordenada por dependência** (o que destrava o quê), com status `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída. **É mantido atualizado pela IA** como parte do fechamento de cada trabalho (mesmo checkpoint da faxina de branches): marca o item entregue `[x]`, o item da vez `[-]`. Ao surgir feature nova, a IA tem permissão de **reescrever o texto** do item para dar clareza e **reordená-lo** para o ponto de precedência correto (analisando o código para inferir dependências). Rever/ajustar o roadmap é atividade recorrente, não pontual.

Comandos úteis: `dart pub get` (raiz), `flutter analyze`, `dart test packages/sdui_core`, `flutter test packages/sdui_flutter`, `flutter test apps/driva_editor`, `flutter run -d chrome --target apps/driva_editor/lib/main_dev.dart --dart-define-from-file=apps/driva_editor/config/dev.json`.

## Economia de tokens (obrigatório)

Custo de token é regra, não preferência. rtk (reescreve `git`/`grep`/`ls`/… via hook) e o grafo do CRG (`.code-review-graph/`, auto-atualizado por hook a cada edição) já estão ativos — **use-os**:

- **Grafo antes de grep/read cru.** Para explorar/entender código, consulte primeiro os tools do MCP `code-review-graph` (`query_graph`, `get_review_context`, `detect_changes`, `semantic_search_nodes`, `get_impact_radius`). Só caia em `Grep`/`Read` quando o grafo não cobrir. (Vale para subagentes — inclua isso no prompt deles.)
- **Saída de comando enxuta.** Testes com `-r compact` (`flutter test -r compact`, `dart test -r compact`) e/ou `| tail`; nunca despejar log de teste linha a linha. Analyze/format já são curtos.
- **Não reler** arquivo recém-editado (o harness rastreia o estado) nem redescrever o que já foi estabelecido.
- **Respostas diretas**: sem tabela decorativa nem recapitulação longa; o que muda a decisão do humano, e só.
- **Sessão nova a cada entrega.** Ao fechar um item do roadmap (mesmo checkpoint da faxina de branches + marcação `[x]`), **recomende ao humano iniciar uma sessão nova** para continuar — o `docs/roadmap.md` e as docs vivas dão a continuidade, e o histórico acumulado (caro por reenvio) zera. Não iniciar sessão nova no meio de uma tarefa.

## Git, branches e releases (GitFlow)

Fonte da verdade: **`docs/GITFLOW.md`** (na dúvida, ele manda). Resumo operacional:

- **`main`** = produção (cada commit é uma versão com tag `vX.Y.Z`; **protegida**, só recebe `release/*` e `hotfix/*`). **`develop`** = integração (o próximo release; base de todo trabalho). **Ninguém comita direto em `main`/`develop`** — todo trabalho nasce num branch de suporte e volta por PR.
- Branches de suporte: **`feature/<issue>-<slug>`** (de `develop` → PR para `develop`; **default**), **`bugfix/<issue>-<slug>`** (bug ainda em dev; de `develop` → `develop`), **`hotfix/<issue>-<slug>`** (bug em produção; de **`main`** → PR para `main` **e** merge de volta em `develop`; sobe PATCH), **`release/<vX.Y.Z>`** (estabiliza; de `develop` → `main` **e** `develop`; sobe MINOR, **sem feature nova**).
- **Regra de ouro:** `release/*` e `hotfix/*` voltam para **duas** branches (`main` **e** `develop`), com **tag SemVer** no merge em `main`. Merges de volta usam `--no-ff`.
- **CHANGELOG** (Keep a Changelog): a seção `Unreleased` é atualizada **no mesmo PR** da mudança; o `release/*` a promove para a versão.
- Por situação, use a skill: `iniciar-feature`, `iniciar-bugfix`, `iniciar-hotfix`, `publicar-release`.

## CI/CD e deploy (Coolify)

- **CI é a cancela** (`.github/workflows/ci.yml`): em PR/push para `develop`/`main` roda `dart format` + `flutter analyze` + os testes (e `build` do backend). **O PR da IA passa pela mesma régua que o do humano** — verde é pré-requisito de merge (cap. 35 do livro).
- **Deploy = auto-deploy por branch** no **Coolify** (GitHub App): merge em **`develop` → homologação**, merge em **`main` → produção**. Detalhes e checklist do painel em **`docs/deploy/coolify.md`**.
- Dois deployáveis por ambiente (frontend Flutter Web servido por nginx + backend Nest) + Postgres gerenciado. Domínios sob `driva.duckdns.org` (DNS próprio do projeto; wildcard): prod = `driva.duckdns.org` (front) / `api.driva.duckdns.org` (API); hml = `hml.driva.duckdns.org` (front) / `api-hml.driva.duckdns.org` (API). O `bmjtech.duckdns.org` é só o host principal/infra compartilhada.
- **Segredo/URL/origem nunca no repo** — só como env/Build Variable no Coolify. A URL da API do front é **compile-time** (ARG `API_BASE_URL` no Dockerfile); o CORS do backend vem de `CORS_ORIGINS`.
