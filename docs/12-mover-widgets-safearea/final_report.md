# 12 — Mover widgets no mock, barra de status de problemas e área segura da página

**Branch:** `feature/mover-widgets-canvas-safearea` · **Base:** `develop` (`d207d2a`)

## O pedido

Duas dores do uso real do construtor, mais uma pendência de higiene:

1. **"Quero mover widgets para o mock do celular; quando o widget não puder ficar
   onde está, que apareça numa lista de erros numa barra de status. Isso me
   deixaria reorganizar a árvore sem excluir e montar tudo do zero."**
2. **"Preciso de um switch para usar o SafeArea e todas as suas propriedades.
   SafeArea deveria ser o widget raiz de toda página, obrigatoriamente, sem
   precisar ser selecionado nem usado. Ao selecionar a página — ou quando nada
   estiver selecionado — são as propriedades do SafeArea que eu deveria ver."**
3. `backend/.pnpm-store/` (root:root, sobra de build em container) fora do
   `.gitignore`, quebrando `git stash -u`.

## A decisão de projeto

O editor **para de bloquear em silêncio** e passa a **relatar**. Antes,
`moveNode` recusava calado tudo que o kernel considerava inválido — o usuário
arrastava, nada acontecia, e a saída era apagar e remontar. Agora:

- **Nenhum gesto é perdido.** Se o alvo apontado não recebe filhos (folha, ou
  slot único já ocupado), o encaixe **sobe** para o primeiro ancestral que
  recebe, e a barra de status conta o desvio ("Text não recebe esse widget — ele
  foi encaixado no container acima").
- **A guarda estrutural continua no kernel.** O que nunca acontece é escrever
  `children` num slot único ou criar ciclo: isso produziria documento que o
  próprio `parseContentSpec` recusa no reload. Essas recusas viram recado, não
  silêncio.
- **O que é representável mas errado passa a ser visível.** `expanded`/`spacer`
  fora de uma `Row`/`Column` são gravados normalmente e listados como **erro**;
  embrulhos de slot único sem filho (`padding`, `center`, `expanded`) como
  **aviso**. Lista derivada do documento, sempre em sincronia.

A área segura virou **chrome de página**, não nó: fica fora do `widgetCatalog`
(logo `parseNode` recusa `type: "safeArea"`), não aparece na paleta nem na
árvore, e mora em `ContentSpec.safeArea` — um mapa de props com as mesmas chaves
de `safeAreaDescriptor`. Vazio significa "tudo no padrão", igual às props de um
nó. Todo spec já salvo segue válido sem migração.

## O que mudou, por pacote

### `sdui_core` (kernel)

| Arquivo | Papel |
| --- | --- |
| `ops/drop_ops.dart` | `resolveDrop(root, targetId, {movingNodeId})` → `DropAccepted(parentId, index, redirected)` ou `DropRefused(cycle \| unknownTarget \| noSlotAvailable)`. Regra única compartilhada por canvas e árvore. |
| `ops/tree_ops.dart` | `_attach` virou público (`attachNode`) — o cubit precisa encaixar por índice sem passar por `moveNode`. |
| `diagnostics/spec_diagnostic.dart` | `SpecDiagnostic` (nodeId, nodeType, code, severity, message) + `DiagnosticCode`/`DiagnosticSeverity`. |
| `diagnostics/diagnose_ops.dart` | `diagnoseTree(root)` — regras `flexOnlyOutsideFlex` (erro) e `emptySingleSlot` (aviso). |
| `catalog/safe_area_descriptor.dart` | `safeAreaDescriptor`: `enabled`, `top`, `bottom`, `left`, `right`, `minimum` (edgeInsets), `maintainBottomViewPadding` (avançada). Nenhuma é bindable. |
| `catalog/widget_catalog.dart` | `defaultProperties(descriptor)` extraído de `defaultNode` — o chrome de página reusa a mesma resolução de default. |
| `catalog/widget_descriptor.dart` | `fieldOf(key)` / `defaultValueOf(key)`. |
| `model/content_spec.dart` | `safeArea` (`Map<String, dynamic>`, default `{}`), no `copyWith`, no `toJson` (omitido quando vazio) e na igualdade. |
| `schema/content_schema.dart` | `safeArea` validada como objeto; ausência = `{}`. |

### `sdui_flutter` (renderer)

- `layout/sdui_safe_area.dart` — lê as props e cai no default do descriptor
  quando a chave falta; `enabled: false` devolve o filho cru.
- `sdui_view.dart` — `SduiView.content(spec)` embrulha a raiz; o construtor cru
  `SduiView(node:)` **não** ganha chrome de página.
- `builders/spacer.dart` — `Spacer` é `Expanded` por dentro e derrubava a árvore
  por ParentData fora de um flex. Agora é flex-aware, como o `expanded` já era.
  Sem isso, mover um spacer para um lugar errado **quebraria o canvas** em vez
  de virar um item da lista de problemas.

### `driva_editor`

- **Canvas arrasta e recebe.** `SelectableNode` virou `Draggable` +
  `DragTarget`; a pele saiu para `SelectableNodeSurface` (o `Draggable` precisa
  dela em `child` e em `childWhenDragging`). `spacer`/`expanded` seguem sem
  envelope — arrastam só pela árvore.
- **Frestas de reordenação na árvore.** `TreeGapDropZone` entre as linhas dá a
  posição exata dentro da lista de filhos — soltar *sobre* uma linha só encaixa
  "dentro ou depois" dela, e sem as frestas não havia como mandar um nó para a
  **primeira** posição.
- **Barra de status.** `EditorStatusBar` no rodapé do workspace: resumo
  (`N erros · M avisos` / `Nenhum problema`), lista expansível com atalho para
  selecionar o nó culpado, e o recado do último arraste desviado. Estado de
  aberto/fechado é local; fecha sozinha quando o último problema some.
- **Inspector da página.** Sem nó selecionado, o Inspector mostra "Página" e as
  props da área segura — antes mostrava as props **da raiz** sob o título
  "Conteúdo", que é o que motivou o pedido. `InspectorPropList` deixou de
  depender de `SduiNode` (recebe `ownerKey` + `properties` + `onUpdateProps`),
  então serve nó e página com o mesmo código.
- **Linha "Página · área segura"** no topo da árvore: dá onde clicar para voltar
  à página.
- **Mock com o recuo do dispositivo.** `DevicePreset.safeAreaPadding` injetado
  num `MediaQuery` dentro do `DeviceFrame` — sem isso o `SafeArea` do preview
  herdaria o recuo do **navegador** e o mock mentiria.
- **Tokens `warning` e `danger`** em `EditorColors` (light + dark).
- **`PropFieldShell`**: o rótulo passou a ser `Flexible` com ellipsis e tooltip.
  Rótulo longo estourava o `RenderFlex` — latente antes, disparado pela primeira
  prop de nome comprido.

## API do cubit (quebra intencional)

| Antes | Agora |
| --- | --- |
| `addNode(type, {parentId, index})` | `addNode(type, {targetId})` — solta *sobre* um nó |
| `moveNode(id, parentId, index)` | `moveNode(nodeId, targetId)` — solta *sobre* um nó |
| — | `addNodeAt(type, parentId, index)` / `moveNodeAt(nodeId, parentId, index)` — frestas |
| — | `updateSafeAreaProps(patch)` |

`EditorReady` ganhou `diagnostics` (derivado do documento, nunca guardado à
parte) e `notice` (`EditorNotice` com `sequence`, para o mesmo arraste inválido
repetido emitir estado novo e a barra reagir à segunda tentativa).

## Verificação

- `flutter analyze` (workspace): **0 issues**.
- Testes: **408** (`driva_editor` 235 · `sdui_core` 101 · `sdui_flutter` 72) —
  eram 345.
- **E2E manual dirigido no build web** (`USE_FAKE_DATA=true`, Chrome headless via
  CDP), 8 evidências em `evidencias/rodada_01/`, **0 erros no console**:
  desligar a área segura move o conteúdo para debaixo do notch; arrastar o botão
  sobre um `text` desvia para a column e relata; soltar `Padding` gera o aviso;
  soltar `Spacer` dentro dele vira erro **sem derrubar o canvas**; a lista abre e
  clicar num problema seleciona o nó; a fresta da árvore leva o `Divider` para a
  primeira posição; o JSON traz `safeArea`.
- Golden `canvas_device_mock.png` regravado — o canvas encolheu 28px (rodapé da
  barra de status) e o conteúdo agora começa abaixo do notch.

## Aberto de propósito

- **Reordenar direto no mock** só encaixa "dentro ou depois" do alvo; a posição
  exata (inclusive a primeira) é pela fresta da árvore. Linhas de inserção no
  canvas ficam como polimento futuro.
- **Arraste no canvas usa `Draggable` imediato** (é editor web, mouse). O custo é
  perder o "arrastar para rolar" dentro da tela do celular — a roda do mouse e o
  pan pelo fundo continuam.
- `backend/.pnpm-store/` entrou no `.gitignore`, mas a pasta é `root:root` e a
  remoção precisa do humano: `sudo rm -rf backend/.pnpm-store`.
