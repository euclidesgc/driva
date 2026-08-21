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

**Cópia por propriedade no Inspector (T5b, F3).** Ao lado de **cada propriedade que difere** do nó
selecionado aparece a seta que traz o valor da versão. Ela existe só quando o modo está ativo, o
tipo do nó não mudou e a chave está em `changedPropertyKeys` — botão que não pode agir não é
montado, nunca aparece desabilitado. `EditorCubit.copyPropertyFromVersion` emite **sem**
`coalesceKey`, então a cópia não se funde na entrada de undo de uma digitação anterior na mesma
propriedade: `Ctrl+Z` desfaz uma coisa de cada vez. `width`/`height` também têm seta, inclusive com
a unidade em `%` — o `DimensionEditor` monta a própria `PropFieldShell` e descartava o botão de
binding nesse caso; o de cópia não podia herdar esse descarte. O cabeçalho de comparação mostra a
**contagem real** e nomeia as chaves alteradas que o `WidgetDescriptor` não expõe, dizendo que só a
ação de nó inteiro as alcança — sem isso, uma diferença ficaria invisível, que é a classe exata de
defeito que este item existe para matar.

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
| Unitário (cubit) | `apps/driva_editor/test/modules/editor_module/presentation/editor/cubit/editor_cubit_test.dart`, `.../cubit/version_compare_mode_cubit_test.dart`, `.../cubit/version_compare_close_keeps_copies_test.dart` |
| Widget | `.../widgets/prop_field/prop_version_copy_button_test.dart`, `.../widgets/inspector/inspector_compare_header_test.dart`, `.../widgets/widget_tree/tree_row_diff_marker_test.dart`, `.../widgets/canvas/version_compare_mock_pane_test.dart`, `.../page/canvas_area_test.dart` |
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

Dois dos quatro passos do roteiro migraram para teste de widget (recarregar a página cai no editor
sem o modo; fechar a comparação depois de duas cópias mantém as duas, com `Ctrl+Z` desfazendo uma a
uma). **Os outros dois ficam sem cobertura, e o risco é conhecido e aceito:** fidelidade de fonte e
imagem entre dois `SduiView` reais lado a lado, e digitação instantânea sob carga real de navegador.
O "tofu" do item 24 foi um defeito que só o navegador de verdade mostrou — a suspensão é uma troca
consciente, não um esquecimento.

## Dívidas que ficam

**1. `updateNodeProps` não revalida o schema no merge.** `packages/sdui_core/lib/src/ops/tree_ops.dart:154-161`
faz `{...current.properties, ...patch}` e remove as chaves nulas, sem passar o resultado pelo
`WidgetDescriptor` nem por `parseContentSpec`. É **pré-existente e vale para toda edição manual do
editor**, não só para a cópia por propriedade — qualquer `updateProps` grava o que lhe derem. A
cópia da F3 não amplia o buraco (o valor vem de um spec que a própria API devolveu e que já passou
por parse na leitura), mas passa a exercitá-lo com valores de **outra** versão do documento.
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

## Docs vivas: o que não mudou, e por quê

- **`README.md`** — descreve o repositório em nível de plataforma (editor, kernel, renderer,
  backend) e não enumera funcionalidades do editor. O item 50 não criou módulo, comando nem passo
  de setup. Sem alteração.
- **`ANALYTICS.md`** — continua verdadeiro: **nenhum evento** é enviado por `contents_module` /
  `editor_module`. O item 50 não instrumentou nada. Se a instrumentação entrar, "versão comparada"
  e "propriedade copiada de versão" são candidatos naturais, ao lado dos já listados.
- **`ERROR_LOGS.md`** — nenhuma `Failure` nova. A comparação e a cópia são locais (operações puras
  do kernel + cubit); a busca de versão reusa `NetworkFailure` / `NotFoundFailure` /
  `ValidationFailure`, já descritas lá, e o publish idempotente não introduziu status novo.

## Desvios registrados

Onze entradas em [`variance_report.md`](../plans/50-historico-seguro/variance_report.md). As que
mudam o que o usuário vê: **VR-50-04** (o modal virou modo do editor), **VR-50-06** (o toggle de
base morreu, e em troca vieram a legenda e o `Voltar à versão publicada`), **VR-50-05**
(`Cancelar` → `Fechar comparação`), **VR-50-08** (o limiar de colapso da barra subiu para 893) e
**VR-50-09** (o E2E do item morreu). As de execução: **VR-50-10** (o motor puro ganhou
`changedPropertyKeys`) e **VR-50-11** (`inspector_node_comparison.dart` não foi criado — virou o
`PropFieldCompareBinding`).

## Fora de escopo, por decisão registrada

Continuam fora, como o `plan.md` fixou: histórico de autosave e ator/eventos de domínio (dependem
de auth e auditoria — item 26); merge estrutural (inserir, remover, trocar tipo, mover), que exige
contrato próprio de patch e conflito; comparar duas versões antigas arbitrárias entre si, diff
textual de JSON, comentários por versão, agendamento e aprovação; e qualquer mudança no contrato
público ou no app cliente.
