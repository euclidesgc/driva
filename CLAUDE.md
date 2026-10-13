# driva

Plataforma de **Server-Driven UI** para apps Flutter: o editor web (`apps/driva_editor`, Flutter Web) monta páginas como **spec JSON**, validado pelo kernel (`packages/sdui_core`) e desenhado pelo renderer (`packages/sdui_flutter`) — o mesmo renderer que os apps dos clientes usarão. O backend (`backend/`, NestJS + Prisma + Postgres) apenas armazena os specs (JSONB), sem interpretá-los.

## Layout do workspace (Dart pub workspace)

- `packages/sdui_core` — kernel do spec. **Dart puro** (equatable, fpdart, zard; `package:flutter` proibido). Modelos, schema zard, catálogo de widgets, operações puras de árvore.
- `packages/sdui_flutter` — renderer. Registry `type → builder`, `SduiView`. Depende só de `sdui_core`.
- `apps/driva_editor` — o editor. Depende de `sdui_flutter` e `sdui_core`.
- `apps/driva_demo_app` — app de demonstração (Android/iOS/Web). Primeiro consumidor externo do renderer: lê o spec por slug na API pública (`/v1/public`, header `x-driva-key`) e desenha com `SduiView`. Tem suíte própria na CI, um job de build Android e está sob os mesmos gates do editor.
- `backend/` — NestJS (fora do workspace Dart). Contrato REST em `/v1/contents`.
- `docs/` — só documentação **permanente** do repositório: `GITFLOW.md`, `deploy/`, `benchmark-flutterflow/`, `web-prototipe/`, `specs/`. Os documentos de fase de uma feature (Discovery, PRD, Spec, Plan) **não** moram aqui: ficam anexados ao card da história no board (ver "Método de trabalho"). As pastas `docs/NN-<nome>/` e `docs/plans/` são **histórico** das features feitas antes do board — servem de consulta, não se criam novas.

## O gabarito

A arquitetura vem de um livro que **não está neste repositório** (é material do dono, fora do versionamento) — as referências a "cap. N do livro" espalhadas pelo harness são procedência, não ponteiro: ninguém consegue abri-las, e nada depende de abri-las. O que se imita é código.

O módulo de referência é `apps/driva_editor/lib/modules/contents_module/` — na dúvida, imite-o. São 72 arquivos, então **abra o exemplar da camada**, não o módulo inteiro (caminhos relativos a `apps/driva_editor/lib/modules/contents_module/`):

| Camada | Exemplar |
|---|---|
| Entidade | `domain/entities/content_summary.dart` |
| Contrato de repositório | `domain/repositories/contents_repository.dart` |
| Use case | `domain/use_cases/get_contents_use_case.dart` |
| Model com validação zard | `data/models/content_summary_model.dart` |
| Impl do repositório (o try/catch) | `data/repositories/contents_repository_impl.dart` |
| Cubit + estado `sealed` | `presentation/content_list/cubit/content_list_cubit.dart` + `content_list_state.dart` |
| Página com `pageBuilder` | `presentation/project_detail/project_detail_page.dart` |
| Widget de UI (token + `Semantics`) | `presentation/project_detail/widgets/content_panel/publication_badge.dart` |
| Fiação do módulo | `contents_routes.dart`, `contents_injection.dart`, `contents_module.dart` |

Regra de desempate: **se algo contradiz uma regra deste arquivo, a regra ganha.**

## Regras inegociáveis (Flutter/Dart)

- Clean Architecture por módulo: `lib/modules/<nome>_module/{domain,data,presentation}` + `<nome>_routes.dart` + `<nome>_injection.dart` + barrel público `<nome>_module.dart` que expõe **só** a rota e o registro de DI.
- **domain** = Dart puro; entidades imutáveis (`Equatable`, sem `fromMap`/`toMap`); contratos `abstract interface class` devolvendo `Future<Either<Failure, T>>` (fpdart); **um use case por operação** (método `call()`), mesmo passa-fica.
- **data** = models com (de)serialização validada por **zard** (`safeParse` → `Either`); impl do repositório atrás do contrato; **único lugar com try/catch** (traduz `DioException` → `Failure` tipada de `core/error/`).
- **presentation** = `Cubit` (flutter_bloc) com estado `sealed class` + `switch` exaustivo (states via `part of`); página `StatelessWidget` com `static Widget pageBuilder` — **o único lugar que toca o get_it**. Guarda `isClosed` após `await` antes de `emit`.
- **Escopo mínimo de rebuild.** Nunca reconstrua uma tela inteira a cada tecla/tick: escope o rebuild ao menor pedaço que muda. Preferir Cubit escopado + `BlocSelector`/`buildWhen` (reconstrói só o painel afetado), ou um widget-folha pequeno e local para estado **efêmero** (hover, foco, drag). Estado nunca mora no topo de uma tela grande sob um `BlocBuilder` único. Isolar o que é caro com `RepaintBoundary` e throttlar só o cálculo pesado, mantendo campo/estado instantâneos.
- **presentation NUNCA importa data.** Nenhum módulo importa o interno de outro (só o barrel público). Lógica recebe dependências pelo construtor.
- Navegação: go_router; rotas por módulo em classe `XRoutes` (`static GoRoute get route` + constantes); sempre variantes `*Named`; nada de `extra:` (some no refresh web).
- Erros imprevistos: `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` + `AppBlocObserver` no `bootstrap.dart`.
- Flavors: `main_dev.dart`/`main_prod.dart` → `bootstrap(AppConfig)`; config via `--dart-define-from-file=config/<env>.json`; segredo nunca em dart-define.
- **Zero build_runner** (nada de freezed, json_serializable, injectable, mockito, go_router_builder).
- Testes: `test/` espelha `lib/`; `mocktail` (`MockX extends Mock implements X`) + `bloc_test`. **A pirâmide é a regra — unitário e de widget primeiro, golden onde o pixel importa; E2E está suspenso** _(decisão do dono, 2026-08-20 — ver Método de trabalho)_, e a bateria é escrita **junto da sub-tarefa que ela cobre**, não guardada para o fim.
- Acessibilidade: cor nunca é o único sinal de informação; controles com `Semantics`/tooltip.
- Arquivos `snake_case`, classes `PascalCase`, **uma classe/widget por arquivo** (pública ou privada); código em inglês, UI e docs em pt-BR. Única exceção: o estado `sealed` do cubit mora na mesma **biblioteca** do cubit, num `<x>_state.dart` ligado por `part`/`part of` (ver o exemplar de cubit em "O gabarito").
- **Zero comentário — o código se explica por nomes.** Vale para todo código do repo (Dart e TypeScript), em `//` e em dartdoc `///`. **Não escreva** comentário que diga o que a linha faz, que repita o nome do identificador logo abaixo, cabeçalho decorativo de seção, nem nota de autoria/histórico ("antes era X", "adicionado na F12") — para isso existe o git. Legibilidade se conquista **extraindo** variável/função/widget com nome descritivo, não com prosa ao lado. **Única exceção:** o **porquê** que o código não tem como mostrar — decisão de arquitetura, workaround de bug externo, restrição de plataforma ou invariante não óbvia; e aí o comentário explica a **razão**, nunca a mecânica. Ao editar um arquivo já comentado, limpe o que não passa nesse teste.
- Cancela de máquina: **"pronto" = `dart format --output=none --set-exit-if-changed .` + `flutter analyze` + `scripts/gates_guard.sh` + testes, todos verdes** — a mesma ordem do job Flutter do `ci.yml`. Nunca opinião.

## Design system e organização de widgets (inegociável)

Valem em **`apps/driva_editor`, `apps/driva_demo_app` e `packages/sdui_flutter`** (os três são Flutter).

**Quem cobra na máquina é `scripts/gates_guard.sh`** — job "Gates de qualidade" do `ci.yml`, `exit 1` na primeira violação, e nenhum `flutter analyze` o substitui. Rode-o antes de dar qualquer coisa por pronta. O que ele alcança, exatamente:

- **Gates 1 e 4** em `apps/driva_editor/lib` e `apps/driva_demo_app/lib`; **só o Gate 4** em `packages/sdui_flutter/lib`.
- **Isento por caminho:** `core/theme/` (apps) e `src/theme/` (renderer) — são a fonte dos tokens. A isenção é do caminho exato: `presentation/theme/` do `preferences_module` continua sob os gates.
- **Escape por linha, com motivo:** `// gate1-ok: <motivo>` ou `// gate4-ok: <motivo>` no fim da linha. É a **única** saída — sem ela, a CI fica vermelha. Escape sem motivo real é achado de revisão.
- Os **Gates 2 e 3** são heurísticos demais para grep e ficam com a revisão humana (`revisar-fase`) e com os especialistas de apresentação/infra.

- **Gate 1 — Zero função/método que retorna `Widget`.** Cada pedaço de UI é um `Widget` próprio (`StatelessWidget`/`StatefulWidget`) recebendo dados **pelo construtor** — nunca `Widget _buildX(...)`. Isso preserva `const`, isolamento de rebuild e reuso (a razão de o Flutter/Dart desaconselharem o padrão). **Não são o anti-padrão** (e são permitidos): o `build()` override, o `static Widget pageBuilder`, e os callbacks de builder do framework (`itemBuilder`, `builder:`) — mas quando não-triviais devem delegar a um widget dedicado, não montar árvore inline extensa. **Exceção documentada:** `packages/sdui_flutter/lib` fica **inteiro** fora deste gate (não só `src/builders/`) — os builders `type → builder(node)` são um padrão de registry/plugin, e `render`/`renderAll`/`renderFlexChildren` são a API pública do renderer; o isolamento de rebuild lá vem do wrapper por-nó do `renderer.dart`.
- **Gate 2 — Widget mora por proximidade — menos específico = mais longe da feature.** Três tiers: **feature** (`.../presentation/<feature>/widgets/`) → **módulo** (`modules/<x>_module/presentation/widgets/`, usado por mais de uma feature do módulo) → **app-wide compartilhado** em `apps/driva_editor/lib/core/widgets/` (**o "components"**: organizado por categoria em subpastas, cada categoria com barrel; barrel raiz `core/widgets/widgets.dart`). **Padrão de destino:** widget usado por vários módulos vai para `core/widgets/`; só desce de tier quando o uso justificar. Ao promover um widget, mova-o de tier e ajuste os barrels.
- **Gate 3 — Uma classe/widget por arquivo.** Widget novo = arquivo novo `snake_case`. O **alvo real** são arquivos gordos entupidos de widgets distintos (várias telas/`_XCard`/`_YBanner` no mesmo arquivo). **Não são violação** (podem coabitar o arquivo): o par `StatefulWidget`+`State`, o cubit e seus estados via `part of` (`sealed class` + subestados), uma família `sealed` e **enums agrupados** num `*_enum.dart`.
- **Gate 4 — Design system: tema-token, zero hardcode.** Cor, tipografia, espaçamento, raio, elevação, duração de animação etc. vivem **agrupados em `core/theme/`** (tokens tipados: `AppColors`/`AppTypography`/`AppSpacing`/`AppRadii`… + `ThemeExtension` quando não couber no `ThemeData` padrão) e são consumidos via `Theme.of(context)`/token — nada de literal cru na tela/widget. O `gates_guard.sh` reprova, um a um: `Color(0x…)`, `Colors.<nome>` (menos `white`/`black`/`transparent`), `fontSize: <num>`, `circular(<num>)` e `EdgeInsets.all/fromLTRB(<num>)` ou `EdgeInsets.symmetric/only(…: <num>)`. **Tokenizar tudo, sem exceção de estilo hardcoded:** até o chrome do device-mock, gradientes de capa e a paleta de syntax highlight viram token (com variante dark, mesmo que hoje não variem entre temas). Trocar ou criar um tema novo = mexer **só** no `core/theme/`. O renderer (`sdui_flutter`) segue o mesmo princípio para o que é chrome do renderer (o styling derivado do spec SDUI continua vindo do catálogo/props).

## Regras do spec SDUI

- Todo nó tem `id`, `type`, `props`; `events` e `children`/`child` opcionais. Conteúdo: `{specVersion, kind: "content", id, name, slug, root?}`. **`root` é opcional (qualquer widget do catálogo, não só `column`)**: página vazia = sem `root` (`root: null`, chave omitida no JSON); o **primeiro widget adicionado vira a raiz**. Quando presente, `root` é validado como um nó normal contra o catálogo, recursivamente.
- O JSON só vira entidade por `parsePageSpec` (zard) do `sdui_core` — nenhum `fromMap` cru fora dele.
- Paleta, inspector e defaults derivam 100% do `widget_catalog.dart` (WidgetDescriptor/PropField). Novo primitivo = novo descriptor + novo builder + fixture; nada hardcoded no editor.
- Binding `{{prop}}` e ações são **dados** — o editor não os executa (só o app cliente).

## Método de trabalho: o board Faz AI manda

_(decisão do dono, 2026-10-13 — substitui o fluxo do `/tech-manager`, removido.)_ Toda implementação deste projeto é conduzida pelo **board Faz AI "driva"** (MCP `faz-ai`). **O processo — fases, documentos, aprovações, branch, PR — é o do board; este arquivo manda no código.** Se uma skill ou um agente do repositório disser outra coisa sobre processo, o board ganha.

- **Fluxo de uma história:** Backlog → Discovery → PRD → Spec → Plan → Implementação → Revisão → Homologação → Concluído. Discovery, PRD, Spec, Plan e Homologação exigem aprovação do dono. Quem conduz é o agente `condutor-do-board`, que segue a skill `faz-ai-fluxo` e delega o trabalho técnico aos agentes do repositório.
- **Documentos de fase** (`DISCOVERY.md`, `PRD.md`, `SPEC.md`, `PLAN.md`) ficam **anexados ao card da história**, não em `docs/`. No Plan, cada passo vira sub-tarefa com Esforço, Skills e `depends_on`; sub-tarefas sem dependência entre si rodam juntas, então recorte-as por arquivos disjuntos.
- **Branch, pasta de trabalho e PR** são do board (`prepare_workspace`; PRs de partes de uma mesma feature são empilhados por ele). A Homologação entrega a seção "Como testar" na história + o PR registrado no card; o merge só sai com a aprovação do dono.
- **Pendência com o dono** (decisão, acesso, desvio do plano) vai pela conversa do card — pergunta, pedido de revisão com pendência ou bloqueio — e nunca fica só num comentário. **Desvio do plano aprovado** fica registrado na conversa da história.
- **`docs/roadmap.md` está congelado** e será migrado para o board: não se atualiza nem se acrescenta nada nele. O que antes ia para o roadmap (feature nova, débito, decisão pendente) vira card no Backlog.

**Todo plano termina num DoD — plano sem DoD não está pronto.** A última seção do `PLAN.md` da história é a **Definition of Done**, com cada linha **verificável** (responde "como eu provo que isto está feito", não intenção genérica).

**A prova padrão é teste automatizado; o E2E humano é a exceção cara.** _(decisão do dono, 2026-08-20 — substitui a regra anterior, que fazia todo plano terminar num E2E atestado.)_ A pirâmide, de baixo para cima: **unitário** (domínio, kernel, motor puro, model zard), **widget** (cubit + tela, `bloc_test`, golden onde o pixel importa), **contrato** (Jest no backend contra o schema real) e, no topo, **E2E**. Cada nível só sobe o que o nível abaixo não consegue provar — fluxo de UI, lógica de cubit, validação de spec e comparação de árvore **não são E2E**, são widget e unitário.

**E2E suspenso** _(decisão do dono, 2026-08-20 — vale para o repositório inteiro, até segunda
ordem)_: **nenhuma fase escreve E2E** — nem script, nem roteiro manual. A prova para no
unitário + widget, com golden onde o pixel importa; o teste de contrato (Jest no backend)
continua. Os dois blocos abaixo — critérios de admissão e formato de roteiro — ficam
registrados para quando a suspensão cair, e **não autorizam E2E novo enquanto ela valer**.

**A régua de conclusão, com o E2E suspenso** _(decisão do dono, 2026-08-21)_: **um item fecha
`[x]` com a pirâmide automatizada verde** — unitário, widget, golden onde o pixel importa e o
teste de contrato. Não espera validação em aparelho, porque ela não pode ser escrita enquanto a
suspensão valer. O que **só o hardware ou o navegador real provam** não vira fase bloqueante nem
`[-]` eterno: vira um **card no Backlog do board** ("Validação de campo: …"), ligado à história de
origem, dizendo o que exatamente ficou sem verificação, e o dono roda quando tiver o aparelho na
mão. A lista antiga da seção _Validações de campo pendentes_ do `docs/roadmap.md` continua lá até a
migração. **A lista é obrigação de quem fecha o item** — fechar sem registrar o que ficou de fora é o
que transforma troca consciente em esquecimento. O risco assumido tem nome e precedente: o
`android.permission.INTERNET` que faltava no manifest release do app de demonstração era invisível
para `analyze`, para a suíte inteira e para todo build de debug, e só apareceu num aparelho.

**O E2E entrava quando, e só quando, um destes fosse verdade:**

1. **Integração real que nenhum fake reproduz** — Postgres/Prisma de verdade, transação, CORS, ETag, rate limit, deploy no Coolify.
2. **Comportamento que só existe em runtime real** — renderização de fonte (o "tofu"), aparelho físico, permissão de plataforma, rede caindo.
3. **Modo de falha que precisa ser provado visualmente distinto** e nenhum golden alcança.

**O formato encolheu junto.** Onde o critério acima se aplica, o padrão deixa de ser o par `e2e_hml.sh` + driver CDP com dezenas de prints e passa a ser um **roteiro manual curto** anexado à história no board: passos numerados que o dev humano executa em **homologação** (nunca `localhost` — lição do item 9g), com print só dos passos que provam o que a automação não prova. Script automatizado de E2E continua permitido, mas agora é **escolha justificada** no plano, não o default — e escrevê-lo nunca substitui a cobertura de widget da mesma tela.

**Toda sub-tarefa também tem DoD, e quem o cobra é um supervisor cego.** São **três níveis**: o **plano** (a seção final do `PLAN.md`, acima), a **história** (cobrada na coluna Revisão com a skill `revisar-fase`) e a **sub-tarefa**: cada uma termina num bloco **DoD** com critérios de "está feito quando Z", em vez da instrução "faça X". Ao concluir uma sub-tarefa que **muda comportamento** (código, spec, contrato, rota), o condutor do board lança o agente `supervisor-dod` passando **o bloco DoD e o ponteiro para o trabalho, mais nada**: o ponteiro é o **objeto sob verificação**, não contexto — o DoD segue sendo a **única fonte de critério**. O supervisor não conhece o plano nem o raciocínio de quem executou, e é essa cegueira que o mantém um par independente em vez de um revisor que já comprou o argumento. Por isso o bloco tem de ser **auto-contido**: apagadas todas as referências entre parênteses (`(D2)`, `(§2.5)`, "a decisão acima"), cada linha ainda diz o que conferir e onde. Sub-tarefa puramente textual (CHANGELOG, README) tem DoD, mas não lança supervisor — é cobrada na Revisão da história. Veredito reprovado volta ao **condutor do board**, nunca direto ao executor: ele devolve a sub-tarefa, ou corrige o DoD **se o errado era o DoD**, ou leva ao dono pela conversa do card. **Afrouxar o DoD para a sub-tarefa passar é proibido** — mudança que não seja correção de erro é decisão do dono, pedida e registrada na conversa da história.

Comando não-óbvio: o editor roda **de dentro de `apps/driva_editor`**, com caminhos relativos — `cd apps/driva_editor && flutter run -d chrome --target lib/main_dev.dart --dart-define-from-file=config/dev.json` (a forma do `README.md` e dos 4 configs de editor do `.vscode/launch.json`). Da raiz não funciona: o `pubspec.yaml` da raiz é o `driva_workspace`, sem plataforma web — `flutter build web` sai com `This project is not configured for the web`, e o `flutter run -d chrome` é pior, porque **avisa e sobe assim mesmo**, com um scaffold sintetizado que ignora o `apps/driva_editor/web/flutter_bootstrap.js` (o arquivo que força `canvasKitVariant: "full"` e é o antídoto do "tofu").

## Economia de tokens e tempo (obrigatório)

Custo de token é regra, não preferência — e tempo de parede também: numa história conduzida pelo board, o gargalo não é `flutter analyze`/`flutter test` (segundos), é o raciocínio dos agentes. rtk (reescreve `git`/`grep`/`ls`/… via hook) e o grafo do CRG (`.code-review-graph/`, auto-atualizado por hook a cada edição) já estão ativos — **use-os**:

- **Grafo antes de grep/read cru.** Para explorar/entender código, consulte primeiro os tools do MCP `code-review-graph` (`query_graph`, `get_review_context`, `detect_changes`, `semantic_search_nodes`, `get_impact_radius`). Só caia em `Grep`/`Read` quando o grafo não cobrir. (Vale para subagentes — inclua isso no prompt deles.)
- **Índice antes de `grep` cru em docs.** O equivalente do grafo para prosa: `scripts/docs_index.py` indexa cada `.md` **por seção** (FTS5/BM25 do sqlite) e devolve caminho, faixa de linhas e trilha de títulos — no lugar de `grep` cego seguido de `sed` às escuras dentro de um `plan.md` de 200 KB. Três comandos, rodados da raiz do repositório:

  ```bash
  python3 scripts/docs_index.py search "E2E manual em aparelho físico" --limit 3
  python3 scripts/docs_index.py label D32
  python3 scripts/docs_index.py outline docs/GITFLOW.md --max-level 2
  ```

  `search` acha a seção (`--path <trecho>` restringe a um caminho); `label` acha onde um rótulo do harness (`D32`, `F8`, `VR-46-02`, `§6`) aparece, com a provável definição primeiro; `outline` lista o sumário de um arquivo. Com a faixa de linhas na mão, o `Read` vai direto por `offset`/`limit`, sem despejar o arquivo. O banco vive em `.docs-index/` (local, ignorado pelo git) e **toda consulta reindexa o que mudou antes de responder** — `--no-refresh` desliga.

  **O hook que reindexa a cada edição é versionado em `.claude/settings.json`** — viaja com o repositório e não exige passo de setup. Ele é `PostToolUse` com matcher `Edit|Write`, e o comando é este:

  ```bash
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0; [ -f "$ROOT/scripts/docs_index.py" ] && python3 "$ROOT/scripts/docs_index.py" --root "$ROOT" index --quiet >/dev/null 2>&1 || true
  ```

  Hooks de escopos diferentes **somam** em vez de se sobrescrever: quem já tiver este mesmo comando no `~/.claude/settings.json` deve removê-lo de lá, ou pagará a reindexação duas vezes a cada edição.

  **O que o índice não resolve:** ele acha **onde** a informação está, não se ela continua verdadeira. Ponteiro `arquivo:linha` escrito numa doc não é verificado por ele — conferir no arquivo continua sendo de quem lê, e foi exatamente esse tipo de ponteiro morto que a faxina do harness teve de caçar à mão.
- **Saída de comando enxuta.** Testes com `-r compact` (`flutter test -r compact`, `dart test -r compact`) e/ou `| tail`; nunca despejar log de teste linha a linha. Analyze/format já são curtos.
- **Teste escopado durante iteração; suíte completa só na consolidação.** Corrigindo um achado pontual (fix de QA, ajuste pequeno)? Rode só o(s) arquivo(s) de teste afetado(s) (`flutter test -r compact <caminho>`). A suíte inteira roda nos pontos de consolidação: fim de um conjunto de tarefas paralelas, antes do gate QA/CISO, antes de abrir PR. Rodar tudo a cada ajuste pequeno não pega bug antes — só soma tempo de parede.
- **Paralelismo se declara no Plan, não se improvisa.** Sub-tarefas sem `depends_on` rodam ao mesmo tempo, então recorte-as por arquivos disjuntos e declare dependência **só** onde uma usa o que a outra produz ou as duas tocam o mesmo arquivo. A bateria de testes (`test/`) e o código (`lib/`) costumam ser frentes separáveis; uma separação de causas em commits distintos não é.
- **Contexto quente é o ativo caro — despacho menor + refinamento vence despacho grande.** Retomar um agente já carregado custou **3 a 5× menos** que abrir um novo (medido em 2026-08-18). Despache o **menor escopo que fecha uma sub-tarefa** e refine com o mesmo agente. Isto **não** vale para o `supervisor-dod`: ele é agente **novo** a cada sub-tarefa que muda comportamento, porque a cegueira é o mecanismo — e, na sessão medida, os supervisores pegaram seis defeitos que iriam para `develop`.
- **`rtk proxy <cmd>` quando o filtro atrapalha.** O hook do rtk reescreve `grep`/`ls`/`git`… e embaralha saídas com números soltos (linhas de `grep -n`, contagens). Precisa da saída crua? `rtk proxy grep -n …`. O filtro é o padrão; o proxy é a exceção consciente.
- **Não reler** arquivo recém-editado (o harness rastreia o estado) nem redescrever o que já foi estabelecido.
- **Respostas diretas**: sem tabela decorativa nem recapitulação longa; o que muda a decisão do humano, e só.
- **A continuidade mora no board, não na conversa.** Estado de história, decisão travada e pendência do dono ficam no card (artefatos, conversa, status); regra permanente fica no `CLAUDE.md`/`docs/GITFLOW.md`/skill. **O card aponta, não recita:** cite o caminho do arquivo e a seção que interessam em vez de colar o conteúdo — tudo o que está no card vira contexto de cada execução.

## Git, branches e releases (GitFlow)

Fonte da verdade: **`docs/GITFLOW.md`** (na dúvida, ele manda). Resumo operacional:

- **Ninguém comita direto em `main`/`develop`** — todo trabalho nasce num branch de suporte e volta por PR. `main` = produção (protegida, só recebe `release/*` e `hotfix/*`); `develop` = integração e base de todo trabalho.
- **Branch de história do board é criada pelo board** (`prepare_workspace`), a partir de `develop`, e volta por PR. Fora do board, o trabalho humano segue os nomes do GitFlow: **`hotfix/<issue>-<slug>`**, **`release/<vX.Y.Z>`** (e `feature/`/`bugfix/` quando alguém trabalhar à mão).
- **Regra de ouro:** `release/*` e `hotfix/*` voltam para **duas** branches (`main` **e** `develop`), com **tag SemVer** no merge em `main`. Merges de volta usam `--no-ff`.
- **CHANGELOG** (Keep a Changelog): a seção `Unreleased` é atualizada **no mesmo PR** da mudança; o `release/*` a promove para a versão.
- **PRs de partes de uma mesma feature vão em PILHA** — quem empilha é o board (histórias derivadas partem da branch da anterior). A armadilha do filtro do `ci.yml` com PRs empilhados está em `docs/GITFLOW.md` § 6.
- **Merge automático do board fica desligado:** `develop` não exige checks obrigatórios, então aprovar com ele ligado mergeia com a CI pendente ou vermelha.
- Processos humanos, fora do board: skills `iniciar-hotfix` e `publicar-release`.

## CI/CD e deploy (Coolify)

- **CI é a cancela** (`.github/workflows/ci.yml`). **O PR da IA passa pela mesma régua que o do humano** — verde é pré-requisito de merge (cap. 35 do livro).
- **Deploy = auto-deploy por branch** no **Coolify** (GitHub App): merge em **`develop` → homologação**, merge em **`main` → produção**. Deployáveis, domínios, checklist do painel e variáveis: **`docs/deploy/coolify.md`**.
- **Segredo/URL/origem nunca no repo** — só como env/Build Variable no Coolify. A URL da API do front é **compile-time** (ARG `API_BASE_URL` no Dockerfile); o CORS do backend vem de `CORS_ORIGINS`.
