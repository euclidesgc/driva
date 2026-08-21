# Relatório final — item 50: publicação e histórico deixam de ser um salto no escuro

> Fechado em 2026-08-21. Planejamento em
> [`docs/plans/50-historico-seguro/plan.md`](../plans/50-historico-seguro/plan.md) (T0–T4, T6) e
> [`plan_t5b.md`](../plans/50-historico-seguro/plan_t5b.md) (o redesenho que substituiu a T5).
> Desvios em [`variance_report.md`](../plans/50-historico-seguro/variance_report.md).

## O que ficou pronto

**As ações saíram do ⋮ (T1).** `Histórico` virou `AppBarAction.outlined` com ícone e rótulo;
`Despublicar` aparece só quando existe versão publicada. O `EditorMoreMenuDialog` esvaziou e foi
apagado junto com o `more_vert` específico do editor — abaixo do limiar de colapso, as ações caem
no overflow **único** do shell, sem menu novo. O limiar da época, `AppSizes.topBarActionsFitWidth`,
foi calibrado por medição com a fonte real do app e recalibrado logo depois (VR-50-08); **hoje ele
não existe mais** — o item 52 o substituiu pela soma de `AppSizes.topBarChromeWidth` com a largura
estimada das próprias ações, porque uma constante não sabe quantas ações a barra tem
(`apps/driva_editor/lib/core/theme/app_sizes.dart:127-133` guarda a lápide e a razão).

**Ver uma versão sem restaurá-la (T2 e T3).** A lista do histórico não baixa specs em massa:
`GetContentVersionUseCase` busca **uma** versão quando o usuário pede. Cada linha passou a oferecer
`Ver`, `Comparar` e `Carregar no rascunho`. O `VersionReviewDialog` desenha o spec histórico dentro
de `AbsorbPointer` + `FocusScope(canRequestFocus: false)` — superfície somente leitura, que não
aceita toque, `Tab` nem digitação. `Carregar no rascunho` aplica em memória, empilha **uma** entrada
de undo e nunca chama o endpoint `restore`: o que persiste é o `Salvar` seguinte.

**O motor puro de comparação (T4).** `compareContentSpecs` e `copyComparableNodeProperties` vivem em
`packages/sdui_core/lib/src/ops/compare_ops.dart`, sem Flutter, Dio nem Bloc: diferenças por id,
propriedades e eventos, tipo alterado, nós exclusivos, `safeArea` e metadados. Id duplicado bloqueia
a comparação inteira e deixa os dois specs intactos.

**Comparar virou um modo do editor, não um diálogo (T5b, F1 — VR-50-04).** A T5 entregou a
comparação como modal, o dono usou e disse que não era isso. O redesenho pôs os **dois mocks no
canvas**: à esquerda o rascunho ao vivo, editável; à direita a versão escolhida, inerte
(`FocusScope(canRequestFocus: false)` + `AbsorbPointer`, fora do `DragTarget` da raiz — soltar um
widget da paleta sobre ele não faz nada). Paleta, árvore e Inspector continuam vivos, e é neles que
a diferença aparece. Trocar de versão troca só o mock da direita. `Fechar comparação` fecha e não
reverte nada (VR-50-05); `Salvar` encerra o modo; `Ctrl+Z` não encerra. Todo o modal e sua família
de listas foram apagados na mesma PR, depois da paridade.

**A árvore aponta cada diferença (T5b, F2).** Cada linha ganha o marcador do seu diff —
propriedades alteradas, tipo mudou, só no rascunho — sempre com ícone + tooltip + rótulo semântico,
nunca cor sozinha. A linha fixa da página marca `safeArea` e metadados. Os nós que **só existem na
versão comparada** entram como linhas-fantasma somente leitura: sem representação, a diferença
sumiria da tela.

**O rascunho ganhou nome e porta de volta (T5b, F2b — fecha o VR-50-06).** Legenda `Rascunho` no
lado esquerdo e botão `Voltar à versão publicada`, com confirmação nomeando o que se perde e uma
única entrada de undo; o botão só é montado quando existe versão publicada. Junto veio a decisão de
vocabulário do dono: **Publicado/Despublicado** (e `Publicada` para versão) — "no ar" saiu de todos
os rótulos da UI.

**Restaurar é por versão inteira, e a seta é uma só (T5b, F3 — revertida em 2026-08-21,
VR-50-12).** A F3 entregou a cópia por propriedade (uma seta ao lado de cada chave que difere) mais
a ação de nó inteiro no cabeçalho do Inspector. O dono usou e decidiu o contrário: *"O restore é por
versão completa, não por propriedade. O histórico é de versão, não de propriedades."* O que ficou no
produto é **uma seta na barra da candidata** — `Carregar versão inteira no rascunho` —, que reusa o
`loadFullVersionIntoDraft` e a confirmação já existentes; sumiram o `PropVersionCopyButton`, o
`PropFieldCompareBinding`, `EditorCubit.copyPropertyFromVersion`,
`EditorCubit.applyComparedNodeProperties` e `VersionCompareModeCubit.copyNodeProperties`. O
cabeçalho de comparação do Inspector **continua vivo e puramente informativo**: a contagem real de
propriedades que diferem e os nomes das chaves alteradas que o `WidgetDescriptor` não expõe — sem
isso, uma diferença ficaria invisível, que é a classe exata de defeito que este item existe para
matar.

**O ciclo imutável, provado contra o banco (T6).** Publicar consulta a versão publicada dentro de
uma **única transação** e é no-op quando os JSONB são semanticamente iguais: não move ponteiro, não
toca `publishedAt` nem o ETag público, e devolve `hasUnpublishedChanges: false`. Draft diferente
cria vN+1 — inclusive quando coincide com uma versão antiga que não é a publicada. Ver, comparar,
carregar localmente e fechar não criam `ContentVersion`.

**O escopo de rebuild do canvas, consertado (T5b.14).** Dentro do modo comparação, digitar 5 teclas
num campo do Inspector custava **5 rebuilds** do `PreviewSurface` — o mock do rascunho estava dentro
do subtree que rebuildava quando o cubit do modo emitia. Passou a custar **no máximo 1**, o mesmo
teto de fora do modo, e trocar a versão comparada custa **0**.

## Como isto foi provado

A prova é a pirâmide, escrita **junto de cada fase** — não guardada para o fim.

| Nível | Onde |
| --- | --- |
| Unitário (kernel) | `packages/sdui_core/test/ops/compare_ops_test.dart` (inalterado pela T5b, como o DoD exigia) e `packages/sdui_core/test/ops/changed_property_keys_test.dart` |
| Unitário (cubit) | `apps/driva_editor/test/modules/editor_module/presentation/editor/cubit/editor_cubit_test.dart`, `.../cubit/version_compare_mode_cubit_test.dart` |
| Widget | `.../widgets/canvas/canvas_compare_pane_test.dart`, `.../widgets/inspector/inspector_compare_header_test.dart`, `.../widgets/widget_tree/tree_row_diff_marker_test.dart`, `.../widgets/canvas/version_compare_mock_pane_test.dart`, `.../page/canvas_area_test.dart` |
| Golden | `.../widgets/inspector/goldens/inspector_panel_compare_mode.png`, `.../widgets/canvas/goldens/version_compare_mock_pane.png`, `.../widgets/canvas/goldens/version_compare_candidate_bar_compact.png` |
| Escopo de rebuild | `.../presentation/editor/canvas_compare_preview_perf_test.dart` — conta builds de `PreviewSurface` por `debugOnRebuildDirtyWidget`, no padrão do `editor_perf_test.dart` |
| Contrato (backend) | `backend/src/contents/contents.service.spec.ts` — idempotência JSONB do publish dentro da transação, posse por tenant e append-only |

Cancela de máquina do repositório: `bash scripts/gates_guard.sh`, `dart format --set-exit-if-changed`,
`flutter analyze`, `flutter test -r compact` (editor) e `dart test -r compact` (kernel).

## E2E: suspenso (VR-50-09)

**Este item não tem E2E — nem script, nem roteiro manual, nem pasta `evidencias/`.** A T7 do
`plan.md` (o par `e2e_hml.sh` + `e2e_shots.sh` + `e2e_drive.mjs`, no padrão do item 24) já havia
encolhido para um roteiro manual curto pelo VR-50-07; a T5b.16, que era esse roteiro, morreu pelo
**VR-50-09**. A causa é política do repositório, decidida pelo dono em 2026-08-20 e registrada no
`CLAUDE.md`: E2E está suspenso no repositório inteiro, e a prova para no unitário + widget, com
golden onde o pixel importa.

Dois dos quatro passos do roteiro migraram para teste de widget — e um deles morreu junto com a
reversão de 2026-08-21 (fechar a comparação depois de duas cópias por propriedade mantinha as duas:
não existe mais cópia por propriedade). Sobra o que continua verdadeiro: recarregar a página cai no
editor sem o modo. **Os dois passos restantes ficam sem cobertura, e o risco é conhecido e
aceito:** fidelidade de fonte e imagem entre dois `SduiView` reais lado a lado, e digitação
instantânea sob carga real de navegador.
O "tofu" do item 24 foi um defeito que só o navegador de verdade mostrou — a suspensão é uma troca
consciente, não um esquecimento.

## Dívidas que ficam

**1. `updateNodeProps` não revalida o schema no merge.** `packages/sdui_core/lib/src/ops/tree_ops.dart:154-161`
faz `{...current.properties, ...patch}` e remove as chaves nulas, sem passar o resultado pelo
`WidgetDescriptor` nem por `parseContentSpec`. É **pré-existente e vale para toda edição manual do
editor** — qualquer `updateProps` grava o que lhe derem. A cópia por propriedade da F3 chegou a
exercitá-lo com valores de **outra** versão do documento, mas foi revertida em 2026-08-21
(VR-50-12); o débito continua de pé pela edição manual, que é a origem dele.
Consertar é decidir onde a validação entra: no kernel a cada mutação (caro, e muda a assinatura de
uma operação pura) ou no funil de emissão do `EditorCubit`. Não foi decidido neste item.

**2. Tofu do travessão no dropdown do `EnumEditor`, dentro dos goldens.** O placeholder do seletor
de enum é um travessão literal — `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/enum_editor.dart:29`,
`Text('—')` — e ele sai como caixa vazia nos goldens do Inspector, inclusive no
`inspector_panel_compare_mode.png` criado pela F3. **É pré-existente desde o commit `e7a5cf6`**
("feat(editor): binding por propriedade no Inspector", 2026-08-11), quando o Inspector ganhou a
forma atual; a F3 apenas o congelou num golden novo. Não é o tofu do CanvasKit do item 24 e não se
resolve por `canvasKitVariant`: é a fonte do harness de teste. Saída barata, se incomodar: trocar o
placeholder por um rótulo em palavras, que também é melhor para leitor de tela.

**3. `CanvasCompareBinding` tem nome mentiroso.** O widget vive em
`apps/driva_editor/lib/modules/editor_module/presentation/editor/page/canvas_compare_binding.dart`
e sobreviveu ao conserto do escopo de rebuild — mas **hoje só o `inspector_compare_section.dart:21`
o usa**; o canvas passou a ser servido por bindings próprios. O nome "Canvas" descreve um chamador
que não existe mais, e quem ler o arquivo vai procurar um acoplamento com o canvas que não há.
Renomear é barato (um `git mv`, uma classe e um import) e não muda comportamento algum.

**4. `copyComparableNodeProperties` ficou sem chamador.** A reversão de 2026-08-21 (VR-50-12)
apagou os dois únicos consumidores da função no editor — `EditorCubit.applyComparedNodeProperties` e
`VersionCompareModeCubit.copyNodeProperties`. Hoje
`packages/sdui_core/lib/src/ops/compare_ops.dart:196` só é exercitada pelo teste do próprio kernel
(`packages/sdui_core/test/ops/compare_ops_test.dart`); nenhum código de app a chama. **O kernel não
foi tocado na reversão, de propósito:** a decisão do dono foi sobre a UI do editor, não sobre a API
do motor puro, e apagar função pública de kernel no mesmo commit que muda comportamento de tela
mistura duas causas. Decidir se remove (com o teste) ou se mantém como capacidade do kernel é
**cleanup separado**. A irmã `changedPropertyKeys` continua viva: alimenta a contagem do cabeçalho
de comparação.

**5. `Histórico` desabilitado só se explica por tooltip.** O botão nasce desabilitado quando os use
cases de versão faltam na árvore, e a única explicação ao usuário é o tooltip
`Histórico de versões (indisponível)`, montado por `_historyTooltip` em
`apps/driva_editor/lib/modules/editor_module/presentation/editor/page/editor_top_registrar.dart`.
**Tooltip não aparece em toque** e não alcança quem navega sem mouse: na prática o botão fica cinza
e mudo, e cor/opacidade viram o único sinal — exatamente o que a regra de acessibilidade do
`CLAUDE.md` proíbe. Saída: rótulo visível ou `Semantics` que diga o motivo, ou esconder o botão em
vez de desabilitá-lo. O caminho é raro (só ocorre sem DI completa), mas o mesmo padrão se repete em
qualquer ação que nasça indisponível.

## Lição do ciclo: teste verde contra uma árvore que a produção não monta

**Três defeitos deste item passaram pela suíte inteira sem acender uma luz, e a causa dos três é a
mesma: o harness de teste montava uma árvore de widgets diferente da que a produção monta.** Não é
falta de teste — os testes existiam, passavam, e mediam uma árvore que não existe.

**O caso da barra superior.** A T5b trocou o `BlocProvider<VersionCompareModeCubit>` pelo
`VersionCompareModeScope` (um `InheritedWidget`), mas `EditorTopRegistrar` continuou lendo
`context.read<VersionCompareModeCubit>()` no `onPressed` do `Histórico`. Em produção o clique
lançava, a exceção era engolida pelo `runZonedGuarded` e o botão simplesmente não fazia nada — o
sintoma que o dono reportou. O harness de
`apps/driva_editor/test/modules/editor_module/presentation/editor/page/editor_top_registrar_test.dart`
**nunca instalou o escopo que a produção instala** — `EditorWorkspaceHost` monta o
`VersionCompareModeScope` acima do workspace inteiro (e, portanto, acima do topo) sempre que os use
cases de versão existem, o que com a DI real é sempre. Os dois testes de widget do arquivo mediam
layout e overflow: nenhum **clicava** no botão.
Verde com o código quebrado. Corrigido em `f874800`, que passou o registrar a
`VersionCompareModeScope.of(context)`, tratou o nulo como indisponibilidade e **acrescentou ao
harness o escopo que faltava**, mais os testes de clique — 2 testes de widget viraram 4.

**O caso da contagem no cabeçalho do Inspector.** O teste que provava "a contagem exibida vem de
`changedPropertyKeys`, não da lista de botões de cópia montada ao lado" montava o
`InspectorCompareHeader` e **um `PropVersionCopyButton` encenado como irmão dentro de um `Column`**,
em vez de deixar o `InspectorPropList` real montar as setas. A relação entre a contagem e o número
de setas visíveis — a única coisa que o teste dizia estar cobrindo — nunca foi exercitada. Foi por
essa fresta que passou o defeito do tipo trocado (o cabeçalho prometia trazer propriedades enquanto
nenhuma seta era montada), corrigido só na revisão da F3, em `71b65df`.

**A regra que fica:** um harness de widget é uma **afirmação sobre a árvore de produção**, e toda
diferença entre os dois é um buraco de cobertura silencioso. Duas consequências práticas para as
próximas fases:

1. **Escopo/provider que a produção sempre instala entra no harness, sempre.** Se um widget lê um
   `InheritedWidget` ou um `context.read`, o teste que o monta sem esse ancestral não está testando
   o widget — está testando um caso que nunca acontece. Trocar o mecanismo de injeção (o que a T5b
   fez) obriga a varrer **todos** os consumidores, não só os que o `flutter analyze` acusa:
   `context.read` falha em runtime, não em compilação.
2. **Nada de dublê encenado como irmão do widget sob teste quando a asserção é sobre a relação entre
   os dois.** Se o teste afirma "A concorda com B", quem tem de montar B é o código de produção. Um
   B de mentira colado ao lado prova apenas que o teste sabe contar até um.

## Docs vivas: o que não mudou, e por quê

- **`README.md`** — descreve o repositório em nível de plataforma (editor, kernel, renderer,
  backend) e não enumera funcionalidades do editor. O item 50 não criou módulo, comando nem passo
  de setup. Sem alteração.
- **`ANALYTICS.md`** — continua verdadeiro: **nenhum evento** é enviado por `contents_module` /
  `editor_module`. O item 50 não instrumentou nada. Se a instrumentação entrar, "versão comparada"
  e "versão inteira restaurada no rascunho" são candidatos naturais, ao lado dos já listados.
- **`ERROR_LOGS.md`** — nenhuma `Failure` nova. A comparação e a cópia são locais (operações puras
  do kernel + cubit); a busca de versão reusa `NetworkFailure` / `NotFoundFailure` /
  `ValidationFailure`, já descritas lá, e o publish idempotente não introduziu status novo.

## Desvios registrados

Doze entradas em [`variance_report.md`](../plans/50-historico-seguro/variance_report.md). As que
mudam o que o usuário vê: **VR-50-04** (o modal virou modo do editor), **VR-50-06** (o toggle de
base morreu, e em troca vieram a legenda e o `Voltar à versão publicada`), **VR-50-05**
(`Cancelar` → `Fechar comparação`), **VR-50-08** (o limiar de colapso da barra subiu para 893) e
**VR-50-09** (o E2E do item morreu). As de execução: **VR-50-10** (o motor puro ganhou
`changedPropertyKeys`) e **VR-50-11** (`inspector_node_comparison.dart` não foi criado — virou o
`PropFieldCompareBinding`). E a mais recente, **VR-50-12**: o dono reverteu a D1 depois da F3
mergeada — o restore voltou a ser por versão inteira, com uma seta só. Mudança de escopo decidida
pelo humano, não correção de defeito.

## Fora de escopo, por decisão registrada

Continuam fora, como o `plan.md` fixou: histórico de autosave e ator/eventos de domínio (dependem
de auth e auditoria — item 26); merge estrutural (inserir, remover, trocar tipo, mover), que exige
contrato próprio de patch e conflito; comparar duas versões antigas arbitrárias entre si, diff
textual de JSON, comentários por versão, agendamento e aprovação; e qualquer mudança no contrato
público ou no app cliente.
