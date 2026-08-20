# Plano T5b — a comparação vira um modo do editor (redesenho da T5)

> Proposto em 2026-08-20 pelo Tech Lead, a pedido do dono do produto, depois de testar a T5
> entregue no PR #191. Substitui a **interação** da T5; não substitui o `plan.md` do item 50,
> que continua valendo para T0–T4, T6 e para a semântica dos três verbos (Ver / Carregar no
> rascunho / Publicar).

## Objetivo

Hoje comparar é um diálogo modal (`VersionCompareDialog`) que tampa o editor: dois previews
pequenos e inertes, e as diferenças numa lista de nós ao lado. O dono do produto pediu outra
coisa:

> "Exibir outro mock na janela do builder, ao lado do existente, onde o da esquerda é o atual e o
> da direita é a versão que o user está comparando. Ao selecionar outra versão, o mock da direita
> vai mostrando como era, e o da esquerda permanece. Para sair desse modo o user salva ou cancela,
> e aí o mock da direita some e fica só o da esquerda como é o padrão."

Ou seja: a comparação deixa de ser uma tela e vira um **modo do editor**. O mock da esquerda
continua sendo o canvas editável de sempre; o da direita é a versão escolhida, inerte. Paleta,
árvore e inspector continuam vivos e utilizáveis, e é **neles** que as diferenças aparecem — a
lista de nós do modal deixa de existir.

O motor puro (`compareContentSpecs`, `copyComparableNodeProperties` em
`packages/sdui_core/lib/src/ops/compare_ops.dart`) não muda: as duas funções continuam byte a byte
como estão, com os testes que já as cobrem.

---

## Decisões

### D1 — Marcadores vão para a árvore; setas vão para o Inspector

**Decidido: sim, como recomendado — com quatro emendas.** A árvore de widgets (aba
`LeftPanelTab.tree`) ganha, por nó, o marcador `Propriedades alteradas` / `Somente no rascunho` /
`Somente na versão` / `Tipo mudou`. O Inspector ganha, ao lado de **cada propriedade que difere**
do nó selecionado, o botão que traz o valor da versão. Isso mata
`VersionCompareChangedNodes`, `VersionCompareExclusiveNodes` e toda a família de listas.

Por quê: as duas listas do modal existiam só porque o modal não tinha onde mais pendurar a
informação. A árvore já é o índice de nós do documento, e o Inspector já é a superfície de
propriedades — pôr o diff lá é o Squidex campo-a-campo no lugar que o driva já tem, e o usuário
lê a diferença sem trocar de contexto.

**O Inspector aguenta**, porque o slot já existe: `PropFieldShell` tem `actions: List<Widget>`
(hoje `[?bindingButton, ?resetButton]`) e `headerTrailing: Widget?`. Um terceiro botão entra na
mesma lista, sem inventar layout. As quatro emendas, todas verificadas no código:

1. **`DimensionEditor` não passa pelo caminho comum.** `PropFieldEditor` bifurca em
   `SelfChromedPropEditor` para `FieldKind.dimension`, e `DimensionEditor` monta a própria
   `PropFieldShell` — e ainda **descarta o `bindingButton` quando a unidade é `%`**. O botão novo
   precisa ser propagado por `SelfChromedPropEditor` → `DimensionEditor` como mais um `Widget?`
   nomeado, e **não** pode ser descartado em `%`: `width`/`height` são exatamente as props que se
   quer trazer de volta de uma versão.
2. **O diff é por nó e booleano.** `NodeDiff.propertiesChanged` é um `bool`; não existe conjunto
   de chaves alteradas, e `copyComparableNodeProperties` copia **todas** as props do nó de uma vez.
   Um botão por propriedade exige uma função nova (D-anexa em T5b.10) — mas ela **acrescenta**, não
   altera as duas funções existentes.
3. **Chave alterada que o catálogo não expõe fica invisível.** O Inspector só desenha as
   `PropField` do `WidgetDescriptor`. Se a versão tiver uma chave que o descriptor atual não
   descreve, ela não ganha seta. Por isso o Inspector também ganha um **bloco de cabeçalho de
   comparação** com a contagem (`N propriedades diferem`) e a ação de nó inteiro
   `Trazer todas as propriedades desta versão` — que usa `copyComparableNodeProperties` e cobre o
   resto. Quando a contagem for maior que o número de setas visíveis, o bloco nomeia as chaves sem
   campo.
4. **`InspectorVm` tem `==`/`hashCode` escritos à mão.** Dado de comparação **não** entra nele —
   entraria e o painel deixaria de rebuildar em silêncio. Vai num `BlocSelector` aninhado, sobre o
   cubit do modo.

`safeArea` e metadados do conteúdo não pertencem a nó nenhum: seus marcadores vão para a linha
fixa `PageTreeRow` no topo da árvore e para o Inspector em modo página (`node == null`), ambos
somente leitura — a v1 continua não copiando esses três.

### D2 — Troca de versão: barra própria acima do mock da direita, e o Histórico continua sendo o seletor

**Decidido: barra própria com `‹`/`›`, sem transformar o histórico em painel.**

A barra fica colada acima do mock da direita, com a mesma altura da `CanvasToolbar`
(`AppSizes.canvasToolbarHeight`), para os dois mocks começarem na mesma linha. Ela mostra
`Versão N · data`, `‹` (mais antiga) e `›` (mais nova), `Carregar versão inteira no rascunho` e
`Fechar comparação`.

Para pular para uma versão distante, o botão `Histórico` da top bar **continua vivo durante o
modo**: seu `Comparar` passa a **trocar a candidata** em vez de abrir um segundo modo.

Por quê não transformar o histórico em painel não-modal: seria um quarto painel disputando a
largura que a D4 mostra já estar apertada, e a lista tem paginação por scroll infinito
(`VersionHistoryCubit.loadMore`) que teria de ser reimplantada num layout novo. Com `‹`/`›` +
o diálogo que já existe e já está testado, o custo é uma barra e um callback.

### D3 — `Fechar comparação` só fecha; nada é revertido por baixo dos panos

**Decidido: fechar o modo NÃO reverte cópia nenhuma.** O que foi trazido continua no rascunho,
sujo, desfazível um a um com Ctrl+Z — exatamente como qualquer edição manual.

Por quê: reverter seria desfazer trabalho por baixo dos panos, que é a regra que o item 50 inteiro
existe para não quebrar (T5.5 e `VR-50-03` no `plan.md`). Pior: durante o modo o usuário também
edita à mão, e um "reverter tudo do modo" teria de decidir o que é cópia e o que é edição —
decisão que ele nunca autorizou.

Consequência de nomenclatura: o botão **não** se chama `Cancelar`. "Cancelar" promete reverter.
Ele se chama **`Fechar comparação`**, com tooltip
`Fecha a comparação. O que você já trouxe continua no rascunho — use Ctrl+Z para desfazer.`

`Salvar` encerra o modo, como o dono pediu — mas só o `Salvar` de verdade: a transição
`SaveStatus.saving → SaveStatus.saved`. Um `Ctrl+Z` que devolva o documento ao último estado salvo
também produz `SaveStatus.saved` (`EditorCubit._statusFor`), e **não** pode fechar o modo.

### D4 — Largura: a decisão é pela escala resultante, não por um número de janela

**Decidido: três faixas, e o limiar do meio é uma escala, não uma largura.**

| Faixa | Comportamento |
| --- | --- |
| Janela `< AppBreakpoints.compact` (600) | Nada novo: `EditorViewportGate` já troca o workspace inteiro por `SmallViewportNotice`. O modo não existe. |
| Escala do par abaixo de `AppSizes.canvasCompareMinSplitScale` | **Um mock por vez**, com `SegmentedButton` `Rascunho` / `Versão N` na barra da D2. |
| Escala do par no piso ou acima | **Dois mocks lado a lado.** |

Por quê pela escala e não por largura de janela: `fitScaleFor` já escala o mock para caber, e o
tamanho da moldura depende do `DevicePreset` — 393pt no smartphone, 820pt no tablet. Um número fixo
de janela acertaria num preset e erraria no outro. A conta a mudar é uma só, e já está isolada em
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas_panel.dart:63-73`:
ao comparar, o viewport que alimenta `fitScaleFor` passa a ser a metade da largura, menos o vão.

O piso vale `0.4` — o mesmo `EditorCubit.minZoom` que já é o menor zoom manual aceito no editor.
Não é número novo; é o número que o editor já usa para dizer "abaixo disto o mock não serve".

`AppSizes.versionCompareDialogFitWidth` (1000), `versionCompareDialogWidth`,
`versionCompareDialogMaxHeight` e `versionComparePreviewPaneHeight` morrem com o modal.

Válvula de escape que já existe e não custa código: `EditorLayoutController.enterFullscreen()`,
acionável pelo botão de tela cheia da `CanvasToolbar`, some com os dois painéis laterais e devolve
a largura inteira aos mocks.

### D5 — O que morre (tabela completa em "Arquivos")

`compareContentSpecs` e `copyComparableNodeProperties` **não são tocadas**. O arquivo
`packages/sdui_core/lib/src/ops/compare_ops.dart` **ganha** uma função nova no fim
(`changedPropertyKeys`), porque a igualdade profunda (`_deepEquals`) é privada dele e duplicá-la na
camada de apresentação criaria a divergência mais cara possível: um nó marcado "propriedades
alteradas" sem nenhuma seta correspondente. O DoD da T5b.10 cobra que as duas funções e as classes
`NodeDiff`/`SpecComparisonResult` saiam idênticas do diff.

**Perda deliberada de função:** o toggle `Base: Rascunho / No ar` morre. No modo, o lado esquerdo
**é** o canvas do editor — não há como fazê-lo exibir a versão publicada sem congelar o editor, que
é o oposto do que o dono pediu. Quem quiser olhar a publicada continua tendo `Ver` no histórico
(`VersionReviewDialog`, intacto) e `Comparar` sobre ela. Com isso `VersionComparisonBase`,
`version_compare_base_phrases.dart` e a regra do `VR-50-02` (rótulo que nomeia a base exibida)
deixam de existir: a base é sempre o rascunho, e o rótulo volta a ser `Somente no rascunho` fixo.

---

## Arquivos

### Kernel — `packages/sdui_core/`

| Arquivo | Situação |
| --- | --- |
| `packages/sdui_core/lib/src/ops/compare_ops.dart` | **Acrescido** de `changedPropertyKeys`; as duas funções públicas existentes e as classes ficam idênticas. |
| `packages/sdui_core/lib/src/ops/tree_ops.dart` | **Intacto** (`updateNodeProps` já faz a cópia de uma chave; `null` remove). |
| `packages/sdui_core/lib/sdui_core.dart` | **Acrescido** do export da função nova. |

### Editor — apagados

Todos em `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/versions/`:

`version_compare_dialog.dart` · `version_compare_windowed_shell.dart` ·
`version_compare_fullscreen_shell.dart` · `version_compare_body.dart` ·
`version_compare_loaded_body.dart` · `version_compare_header.dart` ·
`version_compare_preview_section.dart` · `version_compare_preview_pane.dart` ·
`version_compare_diff_view.dart` · `version_compare_changed_nodes.dart` ·
`version_compare_exclusive_nodes.dart` · `version_compare_exclusive_list.dart` ·
`version_compare_exclusive_node_tile.dart` · `version_compare_node_row.dart` ·
`version_compare_summary_markers.dart` · `version_compare_side_toggle.dart` ·
`version_compare_copy_arrow_button.dart` · `version_compare_base_phrases.dart`

E em `.../presentation/editor/cubit/`: `version_compare_cubit.dart`,
`version_compare_state.dart`, `version_comparison_base.dart`.

Testes que caem junto: `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/versions/version_compare_dialog_test.dart`,
`.../version_compare_golden_test.dart` e os quatro goldens em
`.../versions/goldens/version_compare_*.png`;
`apps/driva_editor/test/modules/editor_module/presentation/editor/cubit/version_compare_cubit_test.dart`.

### Editor — novos

| Arquivo | Papel |
| --- | --- |
| `.../presentation/editor/cubit/version_compare_mode_cubit.dart` + `version_compare_mode_state.dart` | Estado do modo: candidata carregada, spec base ao vivo, resultado, lista de versões para `‹`/`›`. |
| `.../presentation/editor/widgets/canvas/version_compare_mock_pane.dart` | O mock da direita: barra + moldura + preview inerte. |
| `.../presentation/editor/widgets/canvas/version_compare_candidate_bar.dart` | Barra da D2. |
| `.../presentation/editor/widgets/canvas/version_compare_inert_preview.dart` | `FocusScope(canRequestFocus: false)` + `AbsorbPointer` + `SduiView.content` sem `nodeWrapper`. |
| `.../presentation/editor/widgets/canvas/canvas_compare_side_toggle.dart` | `Rascunho` / `Versão N` da faixa estreita. |
| `.../presentation/editor/widgets/canvas/canvas_compare_side.dart` | `enum CanvasCompareSide { draft, candidate }`. |
| `.../presentation/editor/widgets/widget_tree/tree_row_diff_marker.dart` | Marcador de diff da linha da árvore. |
| `.../presentation/editor/widgets/inspector/inspector_node_comparison.dart` | Objeto de valor com `changedKeys`, `candidateProperties`, `typeChanged`, `exclusiveSide`. |
| `.../presentation/editor/widgets/inspector/inspector_compare_header.dart` | Bloco de cabeçalho da D1, emenda 3. |
| `.../presentation/editor/widgets/prop_field/prop_version_copy_button.dart` | O botão por propriedade. |

### Editor — sobrevivem, com mudança

| Arquivo | Mudança |
| --- | --- |
| `.../widgets/versions/version_compare_enums.dart` | Perde `VersionCompareVisibleSide` (vira `CanvasCompareSide`); `VersionCompareMarkerKind` fica. |
| `.../widgets/versions/version_compare_marker_chip.dart` | Perde `labelOverride` (a base é sempre o rascunho). |
| `.../widgets/versions/version_compare_full_load_banner.dart` | Mesmo widget, novo chamador (a barra da D2). |
| `.../widgets/versions/version_compare_unsafe_view.dart` | Mesmo widget, desenhado no lugar do mock da direita. |
| `.../widgets/versions/load_full_version_into_draft.dart` | Perde o `Navigator.of(context).pop()` — não há diálogo a fechar. |
| `.../widgets/versions/version_history_dialog.dart` | `_compare` entra/troca no modo em vez de abrir diálogo; ganha o cubit do modo por construtor. |
| `.../widgets/canvas_panel.dart`, `.../widgets/canvas/canvas_panel_body.dart` | Ganham `isComparing`; a conta de viewport parte a largura; o segundo mock fica **fora** do `DragTarget` da raiz. |
| `.../page/canvas_area.dart` | `BlocSelector` sobre o cubit do modo, alimentando `isComparing`. |
| `.../page/editor_page.dart` | Provê `VersionCompareModeCubit` acima de `EditorWorkspace`. |
| `.../page/editor_top_registrar.dart` | Repassa o cubit do modo ao `VersionHistoryDialog`. |
| `.../widgets/widget_tree_panel.dart`, `.../widgets/widget_tree/tree_row.dart`, `tree_row_content.dart`, `page_tree_row.dart` | Recebem e desenham o marcador. |
| `.../page/left_panel.dart` | O `BlocSelector` de `_structureKey` não vê o diff — precisa de `BlocBuilder` aninhado sobre o cubit do modo. |
| `.../page/inspector_area.dart`, `.../widgets/inspector_panel.dart`, `.../widgets/inspector/inspector_prop_list.dart` | Recebem e distribuem `InspectorNodeComparison?`. |
| `.../widgets/prop_field_editor.dart`, `.../widgets/prop_field/prop_field_shell.dart`, `self_chromed_prop_editor.dart`, `dimension_editor.dart` | Threading do botão por propriedade. |
| `.../cubit/editor_cubit.dart` | Ganha `copyPropertyFromVersion` (entrada de undo própria, sem coalescer). |
| `apps/driva_editor/lib/core/theme/app_sizes.dart` | Perde os quatro tokens do modal; ganha `canvasCompareMinSplitScale` e `canvasCompareGutter`. |

### Intactos

`packages/sdui_flutter/` inteiro · `backend/` inteiro ·
`.../widgets/versions/version_snapshot_preview.dart` (ainda serve o `VersionReviewDialog`) ·
`.../widgets/versions/version_review_*.dart` · `.../widgets/versions/version_row*.dart` ·
`.../widgets/versions/version_readonly_badge.dart` · `.../widgets/versions/version_failure_message.dart` ·
`.../widgets/versions/load_version_into_draft_confirm_dialog.dart` ·
`.../cubit/version_review_cubit.dart` · `.../cubit/version_history_cubit.dart` ·
`.../widgets/canvas/device_frame.dart`, `fit_scale.dart`, `.../editor/device_preset.dart` ·
`.../widgets/canvas/preview_surface.dart`, `selectable_node*.dart` (o mock da direita **não** os reusa).

---

## Fases e tarefas

Precedência: `F1 → F2 → F3 → F4`. Uma fase = uma PR.

```text
F1 modo no editor (paridade + morte do modal)
 └ F2 marcadores na árvore
     └ F3 cópia por propriedade no Inspector
         └ F4 docs vivas + roteiro manual
```

F1 entrega paridade funcional com o modal antes de apagá-lo: os dois mocks, a troca de versão, a
cópia por nó no Inspector, o banner de carregar versão inteira e o bloqueio por ID duplicado. Nenhuma
função existente fica indisponível entre PRs.

---

### F1 — A comparação vira um modo do editor

#### T5b.1 — `VersionCompareModeCubit` **[paralela: não — todas as outras dependem dela]**

Criar o cubit do modo e seu estado `sealed`, no padrão de
`apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/version_history_cubit.dart`
(estados via `part of`). Ele é escopado ao editor, não a um diálogo, e vive enquanto a página vive.

Estados: `VersionCompareModeInactive` (inicial) · `VersionCompareModeLoading(candidateVersion)` ·
`VersionCompareModeActive(candidate, baseSpec, result, versions, nextCursor, isLoadingMore)` ·
`VersionCompareModeFailure(failure, candidateVersion)`.

Métodos: `enter(int candidateVersion)` (busca o spec da candidata **e** a primeira página de
versões), `selectVersion(int)`, `stepOlder()`, `stepNewer()`, `exit()`,
`copyNodeProperties(String nodeId)`.

Herda de `VersionCompareCubit` o que já estava certo: assina `editorCubit.stream` para manter
`baseSpec` igual ao rascunho ao vivo, e a cópia sempre incide sobre `editorCubit.state.document`.
Perde o `useBase`/`publishedVersion` (D5).

A saída por salvamento mora aqui: no listener do editor, `exit()` só quando o estado anterior era
`SaveStatus.saving` e o novo é `SaveStatus.saved`. Um `Ctrl+Z` que devolva o documento ao último
salvo também emite `saved` e não pode fechar o modo.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart` existe, declara `class VersionCompareModeCubit extends Cubit<VersionCompareModeState>` e tem `part 'version_compare_mode_state.dart';`; o arquivo de estado declara `sealed class VersionCompareModeState` com exatamente as quatro subclasses `VersionCompareModeInactive`, `VersionCompareModeLoading`, `VersionCompareModeActive`, `VersionCompareModeFailure`.
- `grep -n "VersionComparisonBase\|publishedVersion\|useBase" apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart` não retorna nenhuma linha.
- `apps/driva_editor/test/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit_test.dart` tem um `blocTest` provando que uma transição de `SaveStatus.saving` para `SaveStatus.saved` no `EditorCubit` leva o estado a `VersionCompareModeInactive`, e outro provando que emitir `EditorReady` com `saveStatus: SaveStatus.saved` **sem** passar por `saving` mantém `VersionCompareModeActive`.
- Há teste provando que `copyNodeProperties` num id cujo tipo mudou entre os dois specs não chama `EditorCubit.applyComparedNodeProperties` e não altera `editorCubit.state.document`.
- Há teste provando que `stepOlder`/`stepNewer` nas pontas da lista não emitem novo estado, e que `stepOlder` no último item carregado com `nextCursor` não nulo dispara `GetContentVersionsUseCase` com esse cursor.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.2 — Dois mocks no canvas, com a barra da candidata **[paralela: não — dep. T5b.1]**

`CanvasPanel` e `CanvasPanelBody` ganham `final bool isComparing`. Quando verdadeiro, o `Expanded`
que hoje contém o `DragTarget<DragPayload>` + `InteractiveViewer` passa a ser o primeiro filho de
uma `Row`; o segundo é `VersionCompareMockPane`, **fora** daquele `DragTarget` — se ficasse dentro,
soltar um widget da paleta sobre a versão o adicionaria à raiz do rascunho.

A conta de viewport de `canvas_panel.dart:63-73` passa a descontar a metade e o vão
(`AppSizes.canvasCompareGutter`) antes de chamar `fitScaleFor`. A escala resultante é **uma só** e
vale para os dois mocks — mocks em escalas diferentes não se comparam a olho.

Se essa escala ficar abaixo de `AppSizes.canvasCompareMinSplitScale`, cai-se na faixa estreita da
D4: um mock por vez, escolhido por `CanvasCompareSideToggle` na barra, e a escala volta a ser
calculada sobre a largura inteira.

`VersionCompareMockPane` monta, de cima para baixo: `VersionCompareCandidateBar` (altura
`AppSizes.canvasToolbarHeight`, para alinhar com a `CanvasToolbar` do lado esquerdo) e, abaixo,
`RepaintBoundary` **próprio** (o único do repositório hoje envolve só a moldura editável, em
`canvas_panel_body.dart:79`) → `Transform.scale(alignment: Alignment.topCenter)` →
`DeviceFrame(device:, highlighted: false, child: VersionCompareInertPreview(...))`.

`VersionCompareInertPreview` copia a receita de `version_snapshot_preview.dart`:
`FocusScope(canRequestFocus: false)` + `AbsorbPointer` + `SingleChildScrollView` +
`SduiView.content` **sem** `nodeWrapper` e **sem** `onAction`. `DeviceFrame` é agnóstico ao
documento e não muda.

Quando `result` for `Left(DuplicateNodeIdComparisonFailure)`, o pane desenha
`VersionCompareUnsafeView` no lugar da moldura.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/version_compare_mock_pane.dart`, `version_compare_candidate_bar.dart`, `version_compare_inert_preview.dart`, `canvas_compare_side_toggle.dart` e `canvas_compare_side.dart` existem, com **uma** classe pública cada.
- `grep -n "SelectableNode\|PreviewSurface\|nodeWrapper\|onAction" apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/version_compare_inert_preview.dart` não retorna nenhuma linha, e o arquivo contém `AbsorbPointer` e `FocusScope`.
- Em `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/canvas_panel_body.dart`, o widget `VersionCompareMockPane` **não** aparece dentro da subárvore do `DragTarget<DragPayload>`: a leitura do arquivo mostra o `DragTarget` fechado antes de o segundo filho da `Row` começar.
- Existe `RepaintBoundary` dentro de `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/version_compare_mock_pane.dart`.
- `apps/driva_editor/lib/core/theme/app_sizes.dart` declara `canvasCompareMinSplitScale` e `canvasCompareGutter`, e o dartdoc de `canvasCompareMinSplitScale` diz que o valor é o mesmo piso de zoom manual do editor (`EditorCubit.minZoom`).
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/version_compare_mock_pane_test.dart` monta o canvas comparando numa largura em que a escala calculada fica **acima** do piso e encontra dois `DeviceFrame`; monta numa largura em que fica **abaixo** e encontra um `DeviceFrame` mais um `CanvasCompareSideToggle`.
- `cd apps/driva_editor && bash ../../scripts/gates_guard.sh` (ou `bash scripts/gates_guard.sh` a partir da raiz) sai com código 0.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.3 — Entrada e saída do modo **[paralela: não — dep. T5b.1]**

`_EditorPageState.build`, em
`apps/driva_editor/lib/modules/editor_module/presentation/editor/editor_page.dart`, envolve
`EditorWorkspace` num `BlocProvider<VersionCompareModeCubit>` criado com
`context.read<EditorCubit>()` e os dois use cases que a página já recebe por construtor — a página
**não** toca o `get_it` (só o `pageBuilder` toca, e ele já resolve os dois).

`EditorTopRegistrar` repassa o cubit do modo ao `VersionHistoryDialog`, pelo mesmo motivo pelo qual
já repassa `editorCubit`: `showDialog` monta noutra subárvore. `VersionHistoryDialog._compare` deixa
de construir cubit e de abrir diálogo — chama `enter(version)` (ou `selectVersion(version)` se o
modo já estiver ativo) e fecha o histórico.

A saída por `Fechar comparação` chama `exit()`. A saída por salvamento já mora no cubit (T5b.1).

**DoD**
- `grep -n "VersionCompareDialog\|VersionCompareCubit" apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/versions/version_history_dialog.dart` não retorna nenhuma linha.
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/editor_page.dart` não contém `getIt<` fora do corpo de `static Widget pageBuilder`.
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/versions/version_history_dialog_test.dart` prova que tocar `Comparar` numa linha fecha o diálogo (`find.byType(VersionHistoryDialog)` some) e deixa o `VersionCompareModeCubit` em `VersionCompareModeActive` com a versão daquela linha.
- Teste de widget prova que, com o modo já ativo, tocar `Comparar` noutra linha troca `VersionCompareModeActive.candidate.version` sem passar por `VersionCompareModeInactive`.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.4 — Cópia por nó no Inspector **[paralela: sim]**

Criar `InspectorCompareHeader`, desenhado no topo de `InspectorPanel` só quando o modo está ativo e
há diferença no nó selecionado. Conteúdo: o `VersionCompareMarkerChip` aplicável, o texto
`N propriedades diferem da versão M` e o botão `Trazer todas as propriedades desta versão`, que
chama `VersionCompareModeCubit.copyNodeProperties(nodeId)`.

Quando o nó só existe de um lado, ou o tipo mudou, **não** há botão — o cabeçalho explica por que e
aponta `Carregar versão inteira no rascunho` (a barra da D2), a mesma alternativa segura que o
`VersionCompareFullLoadBanner` já oferece. Botão inexistente, nunca desabilitado: é a convenção que
`VersionCompareNodeRow` estabeleceu.

Em modo página (`node == null`), o cabeçalho mostra os chips somente leitura de
`safeAreaChanged` e `changedContentMetadataFields`.

O dado chega por `BlocSelector` aninhado sobre `VersionCompareModeCubit`, **não** por
`InspectorVm` — cujo `==`/`hashCode` são manuais e engoliriam o campo novo em silêncio.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/inspector/inspector_compare_header.dart` existe com uma classe pública.
- `grep -n "comparison\|Comparison" apps/driva_editor/lib/modules/editor_module/presentation/editor/page/inspector_vm.dart` não retorna nenhuma linha.
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/inspector/inspector_compare_header_test.dart` prova: (a) com o nó selecionado tendo `propertiesChanged` verdadeiro e mesmo tipo, o botão `Trazer todas as propriedades desta versão` existe e acionar chama `copyNodeProperties`; (b) com `typeChanged` verdadeiro, `find.widgetWithText(OutlinedButton, 'Trazer todas as propriedades desta versão')` não encontra nada e o texto explicativo aparece; (c) com `node == null` e `safeAreaChanged` verdadeiro, um chip `Safe area alterada` aparece.
- `bash scripts/gates_guard.sh` sai com código 0.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.5 — Corte do modal **[paralela: não — dep. T5b.2, T5b.3, T5b.4]**

Apagar os 18 arquivos de `widgets/versions/` e os 3 de `cubit/` listados em "Editor — apagados",
mais os testes e goldens órfãos. Ajustar os sobreviventes: `version_compare_enums.dart` perde
`VersionCompareVisibleSide`; `version_compare_marker_chip.dart` perde `labelOverride`;
`load_full_version_into_draft.dart` perde o `Navigator.of(context).pop()`.
`app_sizes.dart` perde `versionCompareDialogFitWidth`, `versionCompareDialogWidth`,
`versionCompareDialogMaxHeight` e `versionComparePreviewPaneHeight`.

**DoD**
- `ls apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/versions/` não lista nenhum arquivo cujo nome comece por `version_compare_` além de `version_compare_enums.dart`, `version_compare_marker_chip.dart`, `version_compare_full_load_banner.dart` e `version_compare_unsafe_view.dart`.
- `ls apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/` não lista `version_compare_cubit.dart`, `version_compare_state.dart` nem `version_comparison_base.dart`.
- `grep -rn "versionCompareDialogFitWidth\|versionCompareDialogWidth\|versionCompareDialogMaxHeight\|versionComparePreviewPaneHeight\|VersionCompareVisibleSide\|labelOverride\|VersionComparisonBase" apps/driva_editor/lib apps/driva_editor/test` não retorna nenhuma linha.
- `ls apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/versions/goldens/` não lista nenhum arquivo cujo nome comece por `version_compare_`.
- `cd apps/driva_editor && flutter test -r compact` termina com 0 falhas.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.6 — Bateria de widget da F1 **[paralela: sim, depois de T5b.5]**

Fechar a cobertura da fase: modo ativo/inativo no canvas, as duas faixas da D4, a barra da D2 com
`‹`/`›` nas pontas, o bloqueio por ID duplicado desenhado no lugar do mock, e o golden novo do
canvas comparando em desktop (substituindo os quatro goldens do modal).

**DoD**
- Existe `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/version_compare_canvas_golden_test.dart` e o golden correspondente em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/canvas/goldens/`.
- Teste de widget prova que, com o modo inativo, `find.byType(VersionCompareMockPane)` não encontra nada e o canvas tem exatamente um `DeviceFrame`.
- Teste de widget prova que com `Left(DuplicateNodeIdComparisonFailure)` o pane da direita mostra `VersionCompareUnsafeView` e nenhum `DeviceFrame` a mais.
- Teste de widget prova que `‹` está desabilitado na versão mais antiga carregada sem `nextCursor` e `›` na mais nova.
- `cd apps/driva_editor && flutter test -r compact` termina com 0 falhas.

---

### F2 — Marcadores de diff na árvore de widgets

#### T5b.7 — `TreeRowDiffMarker` e o slot na linha **[paralela: sim]**

Criar `TreeRowDiffMarker`, no padrão de
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diagnostic_icon.dart`
(`Tooltip` + `Icon` com `semanticLabel`, cor nunca sozinha). `TreeRowContent` ganha o parâmetro e o
desenha no trailing, **antes** de `TreeRowDiagnosticIcon`, e `TreeRow` o repassa.
`PageTreeRow` ganha o mesmo parâmetro, para `safeArea`/metadados.

Numa linha da árvore o espaço é curto: o marcador é ícone + tooltip + `Semantics`, sem o texto do
chip. O texto por extenso continua existindo no Inspector (T5b.4), que é onde há largura.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diff_marker.dart` existe com uma classe pública, e o arquivo contém `Tooltip`, `Semantics` (ou `semanticLabel`) e `IconData`.
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_content.dart` declara um campo para o marcador e o posiciona antes de `TreeRowDiagnosticIcon` na `Row` — a ordem literal das linhas é a prova.
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/widget_tree/page_tree_row.dart` aceita o mesmo marcador.
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/widget_tree/tree_row_diff_marker_test.dart` prova que os quatro rótulos `Propriedades alteradas`, `Somente no rascunho`, `Somente na versão` e `Tipo mudou` aparecem como `Tooltip.message` e como rótulo semântico, cada um com `IconData` distinto do dos outros três.
- `bash scripts/gates_guard.sh` sai com código 0.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.8 — Fiação da árvore ao cubit do modo **[paralela: não — dep. T5b.7]**

`WidgetTreePanel` passa a receber o índice `Map<String, NodeDiff>` mais os dois conjuntos de nós
exclusivos, e `_buildRows` escolhe o marcador de cada linha.

Armadilha a tratar explicitamente: `LeftPanel.build` usa
`BlocSelector<EditorCubit, EditorState, String>` cujo seletor é a chave de estrutura montada por
`_structureKey` em `left_panel.dart:141`. Ele só reconstrói quando a estrutura ou a seleção mudam —
trocar a versão comparada não muda nenhuma das duas, e a árvore ficaria com marcadores da versão
anterior. A fiação tem de vir de um `BlocBuilder`/`BlocSelector` aninhado sobre
`VersionCompareModeCubit`, dentro do builder existente.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/page/left_panel.dart` contém um `BlocSelector` ou `BlocBuilder` cujo tipo de bloc é `VersionCompareModeCubit`, aninhado dentro do builder do `BlocSelector<EditorCubit, EditorState, String>` já existente.
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/page/left_panel_test.dart` prova que, com a árvore aberta e o modo ativo, emitir um `VersionCompareModeActive` com **outra** candidata (mesmo documento no `EditorCubit`, sem mudança de estrutura nem de seleção) troca o marcador exibido numa linha identificada por seu rótulo.
- Teste de widget prova que, com o modo inativo, nenhuma linha da árvore tem `TreeRowDiffMarker`.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.9 — Bateria de widget da F2 **[paralela: sim, depois de T5b.8]**

Cobrir a combinação árvore + modo: nó alterado, nó só no rascunho, nó só na versão, nó com tipo
mudado, linha de página com `safeArea` alterada, e a coexistência com o ícone de diagnóstico já
existente na mesma linha.

**DoD**
- Existe teste de widget provando que uma linha com marcador de diff **e** diagnóstico mostra os dois ícones simultaneamente, sem que um substitua o outro.
- Existe teste de widget provando que a linha `PageTreeRow` mostra marcador quando `SpecComparisonResult.safeAreaChanged` é verdadeiro e não mostra quando é falso.
- `cd apps/driva_editor && flutter test -r compact` termina com 0 falhas.

---

### F3 — Cópia por propriedade no Inspector

#### T5b.10 — `changedPropertyKeys` no kernel **[paralela: sim]**

Acrescentar a `packages/sdui_core/lib/src/ops/compare_ops.dart` a função pura
`Set<String> changedPropertyKeys(SduiNode base, SduiNode candidate)`: união das chaves dos dois
mapas `properties`, mantendo aquelas em que `_deepEquals` for falso. Reusa o `_deepEquals` privado
do próprio arquivo — duplicá-lo produziria a divergência mais cara possível, um nó marcado
"propriedades alteradas" sem nenhuma seta correspondente. Exportar no barrel.

Nada mais no arquivo muda: nem `compareContentSpecs`, nem `copyComparableNodeProperties`, nem
`NodeDiff`, nem `SpecComparisonResult`.

**DoD**
- `git diff develop -- packages/sdui_core/lib/src/ops/compare_ops.dart | grep '^-' | grep -v '^---'` não retorna nenhuma linha (o diff é só de adição).
- `grep -n "changedPropertyKeys" packages/sdui_core/lib/sdui_core.dart` retorna pelo menos uma linha, ou o barrel reexporta o arquivo que a contém.
- `packages/sdui_core/test/ops/compare_ops_test.dart` continua no repositório sem modificação (`git diff develop -- packages/sdui_core/test/ops/compare_ops_test.dart` vazio) e passa.
- Novo arquivo de teste em `packages/sdui_core/test/ops/` cobre: chave só na base (entra no conjunto), chave só na candidata (entra), chave igual (não entra), valor de mapa aninhado diferente em profundidade (entra), lista com mesma ordem e valores (não entra), lista reordenada (entra), e dois nós sem propriedade alguma (conjunto vazio).
- `cd packages/sdui_core && dart format --set-exit-if-changed lib test && dart test -r compact` termina com 0 falhas.

#### T5b.11 — `EditorCubit.copyPropertyFromVersion` **[paralela: sim]**

Acrescentar a
`apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_cubit.dart`:

```dart
void copyPropertyFromVersion(String nodeId, String propertyKey, Object? value)
```

Ela usa `sdui.updateNodeProps(root, nodeId, {propertyKey: value})` — `value` nulo remove a chave, que
é exatamente o caso "a versão não tem essa propriedade" — e emite **sem** `coalesceKey`. O
`updateProps` existente usa `coalesceKey: 'props:$id:${patch.keys.join(",")}'`; reaproveitá-lo faria
a cópia se fundir na mesma entrada de undo de uma digitação anterior na mesma propriedade, e o
`Ctrl+Z` seguinte desfaria as duas de uma vez.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_cubit.dart` declara `void copyPropertyFromVersion(` e a chamada de emissão nesse método **não** passa `coalesceKey`.
- Teste em `apps/driva_editor/test/modules/editor_module/presentation/editor/cubit/editor_cubit_test.dart` prova a sequência: editar a propriedade `text` do nó por `updateProps`, depois chamar `copyPropertyFromVersion` na **mesma** propriedade, depois `undo()` — e o documento volta ao valor digitado, não ao valor anterior à digitação.
- Teste prova que `copyPropertyFromVersion(nodeId, key, null)` remove a chave de `properties` do nó e deixa `saveStatus` em `SaveStatus.dirty`.
- Teste prova que `copyPropertyFromVersion` num `nodeId` inexistente não altera `document` e não empilha entrada de undo (`canUndo` permanece como estava).
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.12 — O botão por propriedade e seu threading **[paralela: não — dep. T5b.10 e T5b.11]**

Criar `PropVersionCopyButton` em
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/prop_version_copy_button.dart`,
no tamanho e densidade de `prop_reset_button.dart` (que é o vizinho dele na mesma `Row`).

`PropFieldEditor` ganha `final VoidCallback? onCopyFromVersion;` e, quando não nulo, acrescenta o
botão a `actions` — depois de `bindingButton` e `resetButton`. Como `PropFieldEditor` bifurca em
`SelfChromedPropEditor` para `FieldKind.dimension`, o botão tem de ser propagado por
`SelfChromedPropEditor` → `DimensionEditor` como mais um `Widget?` nomeado, do mesmo jeito que
`bindingButton`/`resetButton` já são — e, ao contrário do `bindingButton`, **não** pode ser
descartado quando a unidade é `%`.

`InspectorPropList` decide por campo: `onCopyFromVersion` é não nulo apenas quando o modo está
ativo, o tipo do nó não mudou e `changedPropertyKeys` contém `field.key`. Botão que não pode agir
não existe — nunca aparece desabilitado.

**DoD**
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/prop_version_copy_button.dart` existe com uma classe pública.
- `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/self_chromed_prop_editor.dart` e `.../prop_field/dimension_editor.dart` declaram um parâmetro `Widget?` para esse botão, e em `dimension_editor.dart` ele é incluído em `actions` **sem** condicional de unidade — diferente do `bindingButton`, que ali está sob `if (acceptsInfinite)`.
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/prop_field/prop_version_copy_button_test.dart` prova que, num campo `FieldKind.dimension` com a unidade em `%`, o botão de cópia está presente.
- Teste de widget prova que, num nó cujo tipo mudou, nenhum `PropVersionCopyButton` é montado; e que numa propriedade cuja chave **não** está em `changedPropertyKeys` também não é montado.
- Teste de widget prova que acionar o botão numa propriedade chama `EditorCubit.copyPropertyFromVersion` com a chave daquele campo e o valor vindo do spec da candidata.
- `bash scripts/gates_guard.sh` sai com código 0.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.13 — Contagem e chaves sem campo no cabeçalho **[paralela: não — dep. T5b.12]**

`InspectorCompareHeader` (criado em T5b.4) passa a mostrar a contagem real vinda de
`changedPropertyKeys` e, quando alguma chave alterada não tiver `PropField` correspondente no
`WidgetDescriptor` do tipo, nomeá-las numa linha própria, dizendo que só a ação de nó inteiro as
alcança. Sem isso, a D1 tem um buraco silencioso — que é exatamente a classe de defeito que o item
50 existe para matar.

**DoD**
- Teste de widget em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/inspector/inspector_compare_header_test.dart` prova que, com `changedPropertyKeys` contendo uma chave ausente do `WidgetDescriptor` do tipo do nó, o cabeçalho renderiza um texto que contém essa chave literal.
- Teste de widget prova que a contagem exibida é igual ao tamanho de `changedPropertyKeys`, inclusive quando maior que o número de `PropVersionCopyButton` montados na lista.
- `cd apps/driva_editor && flutter test -r compact` termina com 0 falhas.
- `cd apps/driva_editor && dart format --set-exit-if-changed lib test && flutter analyze` sai verde.

#### T5b.14 — Bateria de widget da F3 **[paralela: sim, depois de T5b.13]**

Golden do Inspector com o cabeçalho de comparação e setas por propriedade; teste de escopo de
rebuild provando que trocar a versão comparada não reconstrói o canvas editável.

**DoD**
- Existe golden do painel direito em modo comparação em `apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/inspector/goldens/`.
- Existe teste provando que emitir uma nova candidata no `VersionCompareModeCubit` não incrementa o contador de builds de `PreviewSurface` (contador instalado no teste, no padrão já usado por `apps/driva_editor/test/modules/editor_module/presentation/editor/editor_perf_test.dart`).
- `cd apps/driva_editor && flutter test -r compact` termina com 0 falhas.

---

### F4 — Fechamento

#### T5b.15 — Docs vivas **[paralela: sim]** *(textual — não lança supervisor)*

Criar `docs/50-historico-seguro/` (ainda não existe) com `final_report.md`; registrar em
`docs/plans/50-historico-seguro/variance_report.md` as três decisões que alteram o que a T5 entregou
— a morte do toggle de base (superando `VR-50-02`), a troca de `Cancelar` por `Fechar comparação`, e
a adição de `changedPropertyKeys` ao arquivo do motor. Atualizar `CHANGELOG.md` (seção `Unreleased`)
e `docs/roadmap.md`.

**DoD**
- `docs/50-historico-seguro/final_report.md` existe e cita o caminho de pelo menos uma evidência da rodada manual da T5b.16.
- `docs/plans/50-historico-seguro/variance_report.md` ganha três entradas novas numeradas na sequência das existentes, cada uma com "o plano dizia / o que foi feito / por quê".
- `CHANGELOG.md` tem, sob `## [Unreleased]`, uma linha descrevendo a comparação como modo do editor.
- `docs/roadmap.md` marca o item 50 como `[x]`.

#### T5b.16 — Roteiro manual curto **[paralela: sim]** *(textual — não lança supervisor)*

**Não há script de E2E novo nesta tarefa** — nem `e2e_hml.sh`, nem `e2e_shots.sh`, nem
`e2e_drive.mjs`. A cobertura de widget e unit das quatro fases é o gate principal. O que sobra para o
olho humano, em homologação, é só o que teste automatizado não alcança:

1. Os dois `SduiView` reais desenham o mesmo spec com a mesma fidelidade e na mesma escala
   (fonte, imagem via `imageUrlResolver`, quebra de texto) — golden em CI não usa a rede.
2. Digitar no Inspector com o modo ativo continua instantâneo, com dois `SduiView` vivos na tela —
   a regra de escopo mínimo de rebuild sob carga real, no Chrome, não no `flutter test`.
3. Recarregar a página (F5) com o modo ativo cai no editor sem o modo, sem erro — o modo não vive
   na URL, de propósito.
4. `Fechar comparação` depois de duas cópias mantém as duas, e dois `Ctrl+Z` desfazem uma de cada
   vez.

Prints em `docs/50-historico-seguro/evidencias/rodada_01/`, atestados pelo dev humano.

**DoD**
- `docs/50-historico-seguro/roteiro_manual.md` existe, lista os quatro passos acima com o resultado esperado de cada um e nomeia o diretório de evidências.
- `grep -rn "e2e_hml\|e2e_shots\|e2e_drive" docs/50-historico-seguro/` não retorna nenhuma linha.

---

## Riscos

| Risco | Proteção |
| --- | --- |
| Soltar um widget da paleta sobre o mock da versão o adiciona ao rascunho | O segundo mock fica **fora** do `DragTarget<DragPayload>` de `canvas_panel_body.dart`; DoD da T5b.2 exige a leitura da ordem literal. |
| Dois `SduiView` vivos derrubam o desempenho ao digitar | `RepaintBoundary` próprio no pane da direita; o pane só rebuilda por `BlocSelector` sobre o cubit do modo; teste de contagem de builds na T5b.14. |
| A árvore mostra marcadores da versão anterior | `_structureKey` não vê o diff — `BlocBuilder` aninhado, com teste dedicado na T5b.8. |
| O Inspector não rebuilda ao trocar a versão | Dado de comparação fora do `InspectorVm` (que tem `==` manual); DoD da T5b.4 cobra o `grep` vazio. |
| `width`/`height` ficam sem seta | `DimensionEditor` é o único `SelfChromedPropEditor`; DoD da T5b.12 exige o teste com a unidade em `%`. |
| Chave alterada invisível por falta de `PropField` | Contagem e nomeação no cabeçalho (T5b.13) + ação de nó inteiro. |
| `Ctrl+Z` depois de uma cópia desfaz demais | `copyPropertyFromVersion` emite sem `coalesceKey`; teste da sequência digitar → copiar → desfazer na T5b.11. |
| Um `Ctrl+Z` fecha o modo sozinho | A saída só reage à transição `saving → saved`; dois `blocTest` na T5b.1. |
| Dois mocks não cabem e o usuário vê dois mocks ilegíveis | Faixa por escala (D4) com piso igual a `EditorCubit.minZoom`; teste nas duas larguras na T5b.2. |
| Perder a comparação contra a versão no ar | Perda consciente (D5); `Ver` no histórico e `Comparar` sobre a publicada continuam disponíveis. Se o dono discordar, é decisão dele e vira desvio registrado. |
| Regressão entre PRs enquanto o modal morre | F1 entrega paridade antes do corte; o corte é a última tarefa da F1, na mesma PR. |

---

## Definition of Done do plano

- [ ] T5b.1–T5b.16 satisfazem seus DoD; toda tarefa que muda comportamento passou pelo `supervisor-dod`.
- [ ] Comparar é um modo do editor: paleta, árvore e Inspector continuam utilizáveis com o modo ativo, e o mock da direita não aceita clique, foco por Tab nem drop.
- [ ] Trocar de versão troca só o mock da direita; o da esquerda continua sendo o rascunho ao vivo.
- [ ] `Fechar comparação` não reverte nada; `Salvar` encerra o modo; `Ctrl+Z` não encerra.
- [ ] Cada diferença tem lugar visível: nó na árvore, propriedade no Inspector, `safeArea`/metadados na linha de página — e nenhuma diferença fica sem representação (a contagem do cabeçalho é a prova).
- [ ] `git diff develop -- packages/sdui_core/lib/src/ops/compare_ops.dart` só tem linhas adicionadas, e `packages/sdui_core/test/ops/compare_ops_test.dart` está inalterado e verde.
- [ ] `bash scripts/gates_guard.sh`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test -r compact` (editor) e `dart test -r compact` (kernel) verdes.
- [ ] Nenhum arquivo do modal de comparação restou em `lib/` ou `test/`.
- [ ] O roteiro manual de quatro passos foi executado em homologação e **atestado pelo dev humano**, com prints em `docs/50-historico-seguro/evidencias/rodada_01/`.
- [ ] `docs/roadmap.md`, `CHANGELOG.md`, `variance_report.md` e `docs/50-historico-seguro/final_report.md` atualizados.

## Referências

- [Plano do item 50](plan.md) — T0–T4, T6; a T5 daquele plano é substituída por este documento.
- [Variance report do item 50](variance_report.md) — `VR-50-02` é superado pela D5 daqui.
- [Roadmap](../../roadmap.md)
