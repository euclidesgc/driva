# Variance report — Destravar o construtor

Desvios entre esta entrega e o método de trabalho / o plano de gaveta
`docs/plans/38-destravar-drop-e-envolver/plan.md`. Cada entrada registra **como estava**,
**por que mudou** e **o que mudou** — a ordem exigida pelo CLAUDE.md.

**Estado:** 3 desvios. VR-15-01 aprovado pelo humano antes de codar (2026-08-15);
VR-15-02 e VR-15-03 nasceram na implementação da F5 e foram aprovados na revisão de QA
e CISO (2026-08-15).

## VR-15-01 — F3 e F4 saem num PR só, contra o "1 fase = 1 PR"

**Aprovado pelo humano em 2026-08-15, antes do início da implementação.**

### Como estava

O CLAUDE.md (§ Método de trabalho) fixa **"1 fase = 1 PR"**, e o plano de gaveta tratava
as duas fases como paralelas e independentes: a F3 vinha marcada `[depende de F1]`
`[∥ com F2]`, sugerindo que kernel e editor poderiam ser revisados e integrados em PRs
distintos.

### Por que mudou

A conferência do plano contra o código atual (`develop`, pós-item 23) mostrou que o
paralelismo não existe — **é impossível deixar o workspace verde entre as duas fases**:

- `DropResolution` é uma **sealed class** (`packages/sdui_core/lib/src/ops/drop_ops.dart:15`).
  Os quatro `switch` do editor sobre ela
  (`apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_cubit.dart:96`,
  `:131`, `:243`, `:277`) são **statements exaustivos sem `default`**. Acrescentar
  `DropRequiresWrap` no kernel (F3) **quebra a compilação do editor no mesmo commit**.
- Remover `DropRefusal.noSlotAvailable` do enum (`drop_ops.dart:8`) quebra junto o
  `_kindOf` do cubit (`:385-389`) e o `EditorNoticeMessage.of`
  (`.../widgets/status_bar/editor_notice_message.dart:11-29`), também exaustivo sem
  `default`.

Fechar a F3 sozinha exigiria um commit intermediário com `flutter analyze` vermelho —
o que viola a cancela de máquina do projeto ("pronto" = analyze verde) e reprovaria no
CI, que é a mesma régua do PR humano.

**Alternativa avaliada e descartada:** o kernel manter `noSlotAvailable` no enum como
valor morto, só para o editor continuar compilando, e a F4 removê-lo depois. Foi
recusada porque deixaria um valor **inalcançável** no contrato público do kernel — que é
exatamente o que a decisão D2 do plano existe para eliminar — e porque criaria uma
janela em que o kernel promete uma recusa que ele nunca mais emite.

### O que mudou

- As F3 e F4 continuam sendo **duas fases**: dois donos (`especialista-dominio` e
  `especialista-apresentacao`), dois critérios de aceite escritos em separado (`plan.md`
  §5) e **duas revisões de QA**.
- Elas passam a **fechar num único PR** (o PR 3 da §6 do `plan.md`).
- A razão está registrada como **decisão D7** do `plan.md`, com um aviso endereçado ao
  QA — para a fase não ser reprovada por regra, já que o desvio é consciente.

### Consequência prática

O PR 3 é maior que os demais e cruza a fronteira kernel/editor. A revisão deve ser feita
**em duas passadas** (primeiro o contrato do kernel, depois o consumo no editor), e não
como uma leitura única de diff.

### Como fica quando não valer mais

Não expira: é uma propriedade do sistema de tipos do Dart para `sealed`, não uma
conveniência de cronograma. Qualquer mudança futura que acrescente ou remova um caso de
`DropResolution` ou de `DropRefusal` terá o mesmo acoplamento entre kernel e editor.

## VR-15-02 — `SelectableNode` troca o critério de bypass de `node.type` para `built is Expanded`/`Spacer`

**Aprovado na revisão de QA e CISO da F5 (2026-08-15), depois de implementado.**

### Como estava

`SelectableNode` pulava o embrulho interativo (`Draggable`/`DragTarget`/`Stack` de
decoração) para **qualquer** nó de `node.type` em `{'spacer', 'expanded'}`, incondicional:
```dart
static const _unwrappable = {'spacer', 'expanded'};
...
if (_unwrappable.contains(node.type)) return built;
```
A guarda existia para evitar o crash de `ParentDataWidget`: `Expanded`/`Spacer` só são
filhos legais de um `Flex` (`Row`/`Column`), e interpor o `Stack` da
`SelectableNodeSurface` entre eles e o `Flex` derruba a árvore.

### Por que mudou

O critério por `node.type` protegia o caso legítimo (nó dentro de `Row`/`Column`), mas
também escondia **o caso que a F5 precisa alcançar**: um `expanded`/`spacer` **fora** de
um flex — exatamente o cenário do critério de aceite 1 do plano (`§5 F5`). Nesse caso o
`sdui_flutter` já degrada o builder para o filho puro (`buildExpanded`,
`packages/sdui_flutter/lib/src/builders/expanded.dart:11-18`; `buildSpacer`,
`.../builders/spacer.dart:11-14`), então `built` deixa de ser um `Expanded`/`Spacer` de
verdade — não há mais risco de `ParentDataWidget`, mas o bypass por `node.type` continuava
ativo e escondia o nó do overlay de seleção e da nova marcação de erro.

O novo critério lê o **efeito**, não a **intenção**:
```dart
bool get _isRawFlexParentDataWidget => switch (node.type) {
  'expanded' => built is Expanded,
  'spacer' => built is Spacer,
  _ => false,
};
```

**Evidência de equivalência, verificada nos dois sentidos:**

- `renderFlexChildren` (`packages/sdui_flutter/lib/src/renderer.dart:31-37`) tem
  **exatamente dois chamadores**: `column.dart:15` e `row.dart:15`, e os dois jogam o
  resultado direto num `Flex` real (`Column`/`Row`). Não existe terceiro caminho que
  produza um `Expanded`/`Spacer` real fora de um `Flex` — logo `built is Expanded` não é
  uma aproximação, é **equivalente** à condição que `node.type` tentava adivinhar.
- Pelo lado dos builders: `buildExpanded`/`buildSpacer` só devolvem o widget real
  (`Expanded(...)`/`Spacer(...)`) quando `SduiFlexScope.isInFlex(context)` é verdadeiro
  (`expanded.dart:13`, `spacer.dart:12`); fora disso devolvem sempre um substituto seguro
  (`child` ou `SizedBox.shrink()`), nunca um `ParentDataWidget`.

### O que mudou

- `SelectableNode` (`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/selectable_node.dart`)
  troca o campo estático `_unwrappable` pelo getter `_isRawFlexParentDataWidget`, que
  checa o tipo **runtime** de `built`.
- Efeito colateral **desejado**: um `expanded`/`spacer` fora do flex passa a ser
  selecionável, arrastável pelo canvas e a receber `SelectableNodeSurface` — inclusive a
  marcação de erro da F5. Dentro do flex nada muda (guard continua ativo,
  `selectable_node_test.dart:41` cobre esse caso).
- Registrado também como **limitação conhecida do E2E** no `plan.md` (§5 F5): o
  `expanded` solto agora arrasta pelo canvas além da árvore — comportamento a mais que
  "marcar", benigno, mas visível ao dev humano.

### Consequência prática

Nenhuma migração necessária — é uma troca de condição dentro de um único getter privado,
sem mudança de assinatura pública. `selectable_node_test.dart` continua verde sem
alteração.

### Como fica quando não valer mais

Se um dia `renderFlexChildren` ganhar um terceiro chamador que não seja um `Flex` direto
(por exemplo, um novo widget de layout flexível fora de `Row`/`Column`), a equivalência
para de valer e o critério precisa ser reavaliado — mas a checagem por tipo runtime
continua correta por construção: ela nunca depende de **quem** chamou, só de **o que**
`built` realmente é.

## VR-15-03 — O helper de agrupamento de diagnósticos não seguiu o padrão de VM por área

**Aprovado na revisão de QA (2026-08-15), depois de implementado.**

### Como estava

O `plan.md` (§5 F5 e §8, item 7) pedia que a F5 seguisse o padrão já estabelecido de
**VM por área** — classes como `page/status_bar_vm.dart` e `page/inspector_vm.dart`,
uma por região da tela, para não reconstruir a árvore quando só o canvas muda (e
vice-versa).

### Por que mudou

O agrupamento de diagnósticos por `nodeId` (`diagnosticsByNode`) não é um VM de área: é
uma função pura, sem estado de tela, consumida por **duas** áreas diferentes
(`LeftPanel`, dono da árvore, e `PreviewSurface`, dono do canvas) que já têm ciclos de
vida e fontes de dados distintos entre si — a árvore lê o `EditorState` direto via
`BlocSelector`; o canvas mantém sua própria cópia throttled do documento
(`_PreviewSurfaceState._rendered`) e não pode reusar um VM calculado no `LeftPanel` sem
acoplar os dois painéis. Criar um "VM de diagnósticos" só para guardar uma função pura
teria sido peso morto — o padrão de VM de área serve para agregar **campos de estado
lidos por `BlocSelector`**, não para hospedar lógica sem estado reusada por dois
consumidores que já não compartilham VM nenhum.

O precedente exato para "helper puro compartilhado por mais de uma feature do módulo,
morando direto em `widgets/`" já existe no próprio módulo:
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/drag_payload.dart`
(sealed class consumida por árvore e canvas) e `widgets/palette_icons.dart` (mapa +
função top-level, mesmo tier). O helper da F5 segue esse tier, não o de VM de área.

### O que mudou

- Criado `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/node_diagnostics_summary.dart`
  com `diagnosticsByNode()` (agrupa `List<SpecDiagnostic>` por `nodeId`, uma vez por
  leitura) e `summarizeDiagnostics()`/`NodeDiagnosticsSummary` (severidade + mensagem
  combinadas), no tier de módulo (`widgets/`), não em `page/`.
- A intenção do plano — agrupar uma vez, distribuir um `Map`, nunca propagar o getter
  cru `EditorReady.diagnostics` para cada linha/nó — foi cumprida integralmente; só o
  arquivo/local mudou.

### Consequência prática

Nenhuma: `LeftPanel` e `PreviewSurface` chamam o mesmo helper puro cada um a seu tempo
(um por rebuild de estrutura da árvore, outro por documento throttled do canvas), sem
acoplamento novo entre os dois painéis.

### Como fica quando não valer mais

Se uma futura fase precisar de um VM de página unificado (hoje explicitamente evitado —
`plan.md` §8, item 7), o agrupamento por `nodeId` pode migrar para dentro dele sem mudar
a assinatura de `diagnosticsByNode`/`summarizeDiagnostics` — só o chamador muda.
