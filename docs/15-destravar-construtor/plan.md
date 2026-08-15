# Plano — Destravar o construtor: envolver nó e drop sem beco sem saída

_Item **38** do roadmap (Marco 4). Base: `docs/plans/38-destravar-drop-e-envolver/plan.md` —
plano de gaveta, matéria-prima deste. Onde os dois divergirem, **este manda**, e o
motivo está na §8._

> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**.
> **Não toca backend** (o spec é JSONB opaco).
> **0-dep.** Sai antes do item 24, por decisão do humano.
> Módulo alvo: `apps/driva_editor/lib/modules/editor_module/` (**não** `pages_module`).

## Estado

**Plano fechado em 2026-08-15** — as seis perguntas ao humano foram respondidas (§9) e
viraram decisões travadas (§4). Nada bloqueia a execução.

| Fase | O que entrega | Dono | PR | Estado |
| --- | --- | --- | --- | --- |
| F1 | `wrapNode` no kernel | especialista-dominio | 1 | `[x]` |
| F2 | Comando "Envolver em Column/Row" + `Ctrl+G` | especialista-apresentacao | 2 | `[x]` |
| F3 | `DropRequiresWrap` no kernel | especialista-dominio | 3 | `[x]` |
| F4 | O drop agrupa em vez de recusar | especialista-apresentacao | 3 | `[x]` |
| F5 | Marcação de problema no próprio nó | especialista-apresentacao | 4 | `[ ]` |
| F6 | Rótulo honesto no excluir da raiz | especialista-apresentacao | 5 | `[ ]` |
| F7 | Bateria automatizada (por último) | qa | 6 | `[ ]` |

`[ ]` não iniciada · `[-]` em andamento · `[x]` concluída e revisada pelo QA

**F3 e F4 dividem o PR 3 de propósito** (D7 / VR-15-01) — são duas revisões de fase sobre
um PR, não uma fase inchada.

## 1. Objetivo e recorte

O item **8c** deixou a raiz da página ser **qualquer** widget do catálogo, inclusive
uma **folha** (`text`, `image`, `icon`, `divider`). O item **8e** fez o encaixe subir
para o primeiro ancestral que aceita filhos. Ninguém escreveu a metade que falta:
**quando a subida não acha ancestral nenhum, não sobra destino e a página fica sem
saída** — o dev não consegue criar o contêiner que faltava nem tirar de lá o widget
que já está.

**Este item é a metade que falta do 8c.**

**Entra:**

1. Operação de **envolver um nó** num contêiner, no kernel (`sdui_core`).
2. **Comando explícito** "Envolver em Column/Row" no editor — a fatia que destrava o
   dev sozinha.
3. O **drop deixa de recusar**: `resolveDrop` devolve "precisa envolver" em vez de
   `noSlotAvailable`, e o editor materializa o agrupamento, com recado na barra de
   status e desfazível num `Ctrl+Z`.
4. **Marcação de problema no próprio nó** (árvore e canvas) — hoje o diagnóstico só
   existe na barra de status.
5. Higiene: excluir a raiz **apaga a página inteira** sem aviso; o rótulo e o tooltip
   passam a dizer isso.

**Fica fora:** aceitar árvore estruturalmente inválida no documento (D1); área de
rascunho / multi-raiz; envolver **seleção múltipla** (não existe seleção múltipla);
envolver em contêiner de slot único (`card`, `padding`, `center`); a operação irmã
**desenvolver** (unwrap). Registro completo na §7.

## 2. Causa confirmada

Conferida contra o código de hoje (`develop` pós-item 23) — os `file:line` abaixo são
os **atuais**, não os do plano de gaveta.

**`packages/sdui_core/lib/src/ops/drop_ops.dart:73-86`** — o laço sobe pelos
ancestrais; `findParent` só devolve `null` **na raiz**, e aí a função devolve
`DropRefused(DropRefusal.noSlotAvailable)` (**`:76`**).

**Corolário — é a chave do desenho:** `noSlotAvailable` **só** acontece quando a
cadeia inteira até a raiz não tem slot livre. Não existe outro caso. Logo **todo
`noSlotAvailable` é resolvível envolvendo um nó** — não há situação em que o gesto
seja genuinamente impossível. É isso que autoriza o valor a sair do enum.

O caso está coberto por teste, **como comportamento esperado**:
`packages/sdui_core/test/ops/drop_ops_test.dart:73-79` (a asserção em `:75-78`)
afirma `resolveDrop(leafRoot, 'só') == DropRefused(DropRefusal.noSlotAvailable)`.
Esse teste é a prova documental da mudança de comportamento e vai citado no PR da
F3+F4.

**Quem consome a recusa.** Todo gesto converge para a mesma função e para a mesma
mensagem. Prefixo `$E` = `apps/driva_editor/lib/modules/editor_module/presentation/editor/`.

| Gesto | Caminho | Hoje |
| --- | --- | --- |
| Soltar da paleta sobre um nó do canvas | `$E page/canvas_area.dart:34-35,43` → `addNode` → `$E cubit/editor_cubit.dart:96-98` | notice `dropNoSlot` |
| Soltar no vazio do device | `$E widgets/canvas_panel.dart:50` → `canvas_area.dart:28-33` (passa a **própria raiz** como alvo) | notice `dropNoSlot` |
| Soltar na linha da árvore | `$E widgets/widget_tree_panel.dart:88` → `addNode` | notice `dropNoSlot` |
| Soltar no rodapé da árvore | `$E widgets/widget_tree_panel.dart:61` | notice `dropNoSlot` |
| Frestas de inserção | `$E widgets/widget_tree_panel.dart:97-98` | **nem são emitidas** (só para `SlotKind.multi`) |
| `Ctrl+V` | `$E cubit/editor_cubit.dart:277` | notice `dropNoSlot` |
| `Ctrl+D` | `$E cubit/editor_cubit.dart:228-231` | notice `rootNotDuplicable` |
| Arrastar a raiz | `$E cubit/editor_cubit.dart:121-124`, `:169-172` | notice `rootNotMovable` |

Mensagem única, em `$E widgets/status_bar/editor_notice_message.dart:17-18`:
`'Não há onde encaixar: nenhum widget acima do destino aceita filhos.'`

**É beco sem saída de verdade?** Quase. Existem exatamente **dois** caminhos, ambos
destrutivos e ambos não-descobríveis: (i) `Ctrl+C` na raiz → `Delete` (que **apaga a
página inteira**, `$E cubit/editor_cubit.dart:194-197`) → arrastar `column` da paleta
(vira a nova raiz, `:87-91`) → `Ctrl+V` — funciona porque `_clipboard` sobrevive ao
esvaziamento de propósito (`:42`, doc em `:205-208`); (ii) apagar e remontar à mão,
redigitando todas as props.

**Não existe hoje:** `wrapNode`/`unwrapNode` em lugar nenhum do workspace; menu de
contexto de nó (nem árvore nem canvas); `WrapIntent`; atalho; drop-zone acima da raiz.

**Agravante de perda de trabalho.** O botão de lixeira diz **"Remover bloco (Delete)"**
(`$E widgets/inspector/inspector_header.dart:59` e `$E widgets/widget_tree/tree_row_content.dart:73`,
entregue a **todas** as linhas por `$E widgets/widget_tree_panel.dart:86`) — mas na raiz
ele esvazia o conteúdo inteiro, sem confirmação e sem aviso.

## 3. O que já existe e vamos reusar

| O que | Onde (atual) | Uso |
| --- | --- | --- |
| `resolveDrop` / sealed `DropResolution` / enum `DropRefusal` | `sdui_core/lib/src/ops/drop_ops.dart:49,15,8` | Ganha um terceiro caso (D2) |
| `findNode:5`, `findParent:18`, `insertChild:34`, `setChild:43`, `removeNode:50`, `moveNode:68`, `attachNode:85`, `cloneWithNewIds:100`, `updateNodeProps:109`, `_rebuild:118` | `sdui_core/lib/src/ops/tree_ops.dart` | Base do `wrapNode`. **`findParent` e `moveNode` já existem — não criar.** `attachNode` devolve **nullable** |
| Barrel `sdui_core.dart:15-16` exporta os dois arquivos de ops **inteiros**, sem `show`/`hide` | `sdui_core/lib/sdui_core.dart` | Top-level público novo vaza sozinho. **Não há barrel para editar na F1** |
| `SlotKind { none, single, multi }` + campo `slot` | `sdui_core/lib/src/catalog/widget_descriptor.dart:5,25` | Quem decide se um nó recebe filhos |
| `descriptorFor:1098` / `defaultNode:1105` | `sdui_core/lib/src/catalog/widget_catalog.dart` | O contêiner do wrap nasce dos defaults do catálogo |
| `parseNode` recusa filho em `none`/`single`/`multi` errados | `sdui_core/lib/src/schema/node_schema.dart:45-67` (literais em `:49`, `:56`, `:64`) | **A prova que mata a direção (b)** — ver D1 |
| `ContentSpec.root` **nullable**; `copyWith` usa função-getter | `sdui_core/lib/src/model/content_spec.dart:21,36` | Não há lugar no modelo para "fora da árvore" |
| `diagnoseTree(SduiNode? root)` (2 regras) | `sdui_core/lib/src/diagnostics/diagnose_ops.dart:14,28-41,43-53` | Vocabulário de "problema do nó" |
| `SpecDiagnostic` (`nodeId`, `nodeType`, `code`, `severity`, `message`) + `DiagnosticSeverity:3` + `DiagnosticCode:7` | `sdui_core/lib/src/diagnostics/spec_diagnostic.dart:12` — **arquivo separado do `diagnose_ops`** | Já tem `nodeId` e severidade: a F5 não precisa de nada novo no kernel |
| `_emitRoot:406` → `_emitDocument:425` — **funil único de mutação**, com o histórico do item 23 embutido (`_pushHistory:447`) | `$E cubit/editor_cubit.dart` | **1 chamada = 1 entrada de undo** (D4) |
| `_emitClone:292-314` | `$E cubit/editor_cubit.dart` | **Precedente exato** do padrão "monta a subárvore, 1 attach, 1 emissão" — reusar, não reinventar |
| `_nextNodeId(SduiNode? root):66` | `$E cubit/editor_cubit.dart` | Fonte dos ids; o wrap precisa de **um** |
| `EditorNoticeKind` (8 casos) + `EditorNoticeMessage.of` — `switch` **exaustivo sem `default`** | `$E cubit/editor_notice_kind.dart:4-13`, `$E widgets/status_bar/editor_notice_message.dart:6,11-29` | Onde entra o recado |
| `EditorReady.diagnostics` — **getter computado**, sem cache | `$E cubit/editor_state.dart:64` | Recalcula `diagnoseTree` a cada leitura; ver R3 |
| VMs por área (`status_bar_vm.dart`, `inspector_vm.dart`) — **não há VM único da página** | `$E page/` | A F5 cria/estende o VM da árvore e do canvas |
| `status_bar_area.dart:15` é o **único** consumidor de `state.diagnostics` | `$E page/` | Confirmado por varredura |
| `EditorShortcuts` — 9 bindings e a guarda anti-campo-de-texto `_isEditingText:16-19` (aplicada em `:46,49,52,55,58`) | `$E page/editor_shortcuts.dart` | Onde entra o atalho de envolver |
| `SelectableNodeSurface` — `Stack(clipBehavior: Clip.none, fit: StackFit.passthrough)` com 4 ramos de decoração em **foreground** e o `NodeTag` em `Positioned(top: -18)` | `$E widgets/canvas/selectable_node_surface.dart:31-36,38-67,68-73` | Onde a marcação de erro entra sem alterar layout (F5) |
| `TreeRow` recebe `isRoot` (ctor `:16`, campo `:26`, uso no rótulo `:42`); o chamador passa em `widget_tree_panel.dart:83` | `$E widgets/widget_tree/tree_row.dart` | Base da F6 |
| Botões Desfazer/Refazer já na top bar | `$E page/editor_top_registrar.dart:60-69` | Trabalho do item 23, já feito |

## 4. Decisões travadas

_D1 a D6 nasceram no plano de gaveta; **D7 a D9 são desta rodada**. Todas foram
**confirmadas pelo humano em 2026-08-15** — não reabrir sem passar pelo
`variance_report.md`._

### D1 — A árvore continua **sempre válida**. "Aceitar inválido e diagnosticar" está **recusada**.

> **Confirmada pelo humano em 2026-08-15.** O kernel segue impedindo o que
> `parseContentSpec` recusaria no reload; a **F5** entrega a metade visível do pedido
> original.

O dev pediu textualmente _"eles deveriam ser exibidos lá, mas mostrando uma mensagem
de erro"_. A necessidade por trás — _"eu teria condições de reorganizar a árvore para
corrigir os problemas"_ — é atendida integralmente pelas D2/D3 a uma fração do custo.
**O que está recusado é o mecanismo, não o objetivo.**

Três razões verificáveis:

1. **O documento deixaria de reabrir.** `node_schema.dart:45-67` recusa `child`/`children`
   em `SlotKind.none` e `children` em `SlotKind.single`. Um `text` com filho até salva,
   mas **falha no reload** — o conteúdo vira inabrível. Afrouxar o schema derruba junto
   a guarda que protege o app do cliente.
2. **Não há onde guardar "fora da árvore".** `ContentSpec` tem **um** `root`
   (`content_spec.dart:21`). Multi-raiz é campo novo no spec, atravessando schema,
   renderer, painel de árvore, painel de JSON, o item 24 e a rota pública do item 25
   **já no ar**.
3. **É a reversão de uma decisão registrada.** `docs/12-mover-widgets-safearea/final_report.md:29-32`:
   _"A guarda estrutural continua no kernel. O que nunca acontece é escrever `children`
   num slot único ou criar ciclo: isso produziria documento que o próprio
   `parseContentSpec` recusa no reload."_

**O que damos no lugar** é a metade do pedido que importa: a **F5** traz a marcação de
erro **no próprio nó**. O dev vê o problema onde ele está, sem o documento precisar
ficar inválido para isso.

### D2 — `resolveDrop` ganha um terceiro caso; `noSlotAvailable` some do enum.

```dart
final class DropRequiresWrap extends DropResolution {
  const DropRequiresWrap({required this.wrapTargetId, required this.wrapperType});
  final String wrapTargetId;
  final String wrapperType;
}
```

Onde hoje devolve `DropRefused(DropRefusal.noSlotAvailable)` (`drop_ops.dart:76`),
passa a devolver `DropRequiresWrap(wrapTargetId: <o alvo apontado>, wrapperType: 'column')`.

Pelo corolário da §2, `noSlotAvailable` deixa de ser alcançável e **sai do enum**.
Sobram `cycle` e `unknownTarget`, que são recusas legítimas. **A regra única dos dois
painéis (invariante do 8e) é preservada:** quem decide continua sendo o kernel; canvas
e árvore só materializam a decisão.

### D3 — Envolve-se **o nó apontado**, não a raiz; o contêiner padrão é `column`.

`wrapNode(root, 'txt', 'column', newId: 'nd_9')` transforma `txt` em
`column(children: [txt])` **no lugar onde `txt` estava**: se era a raiz, a `column`
vira a nova raiz; se ocupava um slot único, a `column` toma o lugar dele nesse slot.

Por que o nó apontado: é onde a intenção do usuário está. Arrastar sobre um `text`
dentro de `center > padding` e ver o widget aparecer no topo da página seria mais
surpreendente do que vê-lo ao lado do `text`.

Por que `column`: é a direção padrão de uma página e é o que o editor implicitamente
fazia antes do 8c. `row` fica no comando explícito da F2.

**Invariante que simplifica a implementação:** o pai de um nó que dispara wrap **nunca**
é `SlotKind.multi` — se fosse, `_accepts(parent)` seria verdadeiro e a subida teria
parado ali. Logo o wrap sempre substitui **ou a raiz, ou o ocupante de um slot único**.
Não existe caso de reindexação de lista.

### D4 — Envolver + encaixar é **uma** mutação e **uma** entrada de histórico.

`Ctrl+Z` tem de desfazer o agrupamento **e** a inserção de uma vez. É isso que torna o
automatismo aceitável: o editor toma uma decisão estrutural, mas ela custa uma tecla
para reverter.

**Mecanismo confirmado no código do item 23:** `_pushHistory` (`cubit:447`) empilha o
documento **anterior** e é chamado dentro de `_emitDocument` (`:432`), antes do `emit`.
Portanto **uma chamada de `_emitRoot`/`_emitDocument` = uma entrada de undo**, não
importa quantas transformações de árvore foram compostas em memória antes. O cubit
compõe `wrapNode` + `attachNode` e emite **uma** vez. Não passar `coalesceKey` — ele
serve para *colapsar* entradas (usado só em `updateProps:332` e
`updateSafeAreaProps:345`), que é o oposto do que o wrap quer.

**Contrato inegociável do item 23:** toda mutação nova passa pelo funil. Um `emit` que
troque `document` por fora fura o undo e faz `canUndo`/`canRedo` (`editor_state.dart:51-52`)
mentirem, além de quebrar o `SaveStatus` que o histórico controla (`_statusFor:498`).

### D5 — Nada acontece em silêncio: o agrupamento vira recado na barra de status.

`EditorNoticeKind.dropWrapped` → _"Text não recebia esse widget — os dois foram
agrupados numa Column."_ Mesmo padrão do `dropRedirected` do 8e, que já ensinou o
usuário a esperar explicação de desvio. Texto explícito, nunca cor como único sinal.

### D6 — O comando explícito existe **além** do automatismo, não em vez dele.

> **Confirmada pelo humano em 2026-08-15: os dois, nessa ordem.** F2 (comando
> explícito) primeiro; F3+F4 (o drop agrupa em vez de recusar) depois. Não é opcional
> nem "se der tempo" — as duas entram.

O drop automático cobre o gesto; o comando cobre a intenção deliberada ("quero uma Row
aqui") e é o que o usuário usa quando **não** está arrastando nada. Os dois compartilham
o mesmo `wrapNode` do kernel.

### D7 — F3 e F4 são **o mesmo PR**. Desvio consciente do "1 fase = 1 PR".

> **Aprovada pelo humano em 2026-08-15.** Registrada como **VR-15-01** no
> `variance_report.md` desta pasta.
>
> **QA, leia isto antes de revisar a F3 ou a F4:** o PR único **não é descuido** e não
> deve ser reprovado por regra. São **duas revisões de fase** (F3 e F4, cada uma com seu
> critério de aceite na §5) sobre **um** PR.

**A razão dura.** `DropResolution` é `sealed` e os quatro `switch` do cubit (`:96`,
`:131`, `:243`, `:277`) são **statements exaustivos sem `default`**. Adicionar
`DropRequiresWrap` ao kernel quebra a compilação do editor **no mesmo instante**;
remover `noSlotAvailable` do enum quebra `_kindOf` (`cubit:385-389`) e
`EditorNoticeMessage.of` (`editor_notice_message.dart:11-29`, também exaustivo sem
`default`).

Manter F3 e F4 em PRs separados exigiria um commit intermediário com o workspace
vermelho — o que viola a cancela de máquina (`flutter analyze` verde) e reprovaria no
CI, que é a mesma régua do humano. A alternativa descartada era o kernel manter
`noSlotAvailable` morto no enum só para o editor compilar: deixaria um valor
inalcançável no contrato público do kernel, exatamente o que a D2 quer eliminar.

Elas continuam sendo **duas fases**: dois donos (dominio e apresentacao), dois critérios
de aceite, duas revisões de QA — e **um** PR.

### D8 — O atalho de envolver é **`Ctrl+G`**. `Ctrl+Shift+W` está morto.

> **Decidida pelo humano em 2026-08-15.**

`Ctrl+G` é a convenção de "group" em ferramentas de design (Figma, FlutterFlow) e é
interceptável em Flutter Web pelo mesmo mecanismo que já faz o `Ctrl+D` do item 23
funcionar apesar de o Chrome usá-lo para favoritar.

**Por que `Ctrl+Shift+W` (a sugestão do plano de gaveta) não serve, para ninguém tentar
de novo:** o editor roda em Flutter **Web**, e `Ctrl+Shift+W` **fecha a janela do
Chrome**. O navegador consome a tecla antes de o app vê-la — não há `preventDefault` que
alcance, porque atalhos de gerenciamento de janela/aba (`Ctrl+W`, `Ctrl+Shift+W`,
`Ctrl+T`, `Ctrl+N`, `Ctrl+Shift+T`) não chegam ao documento. O binding existiria no
`EditorShortcuts` e nunca dispararia — pior que não existir, porque parece implementado.

Entra em `editor_shortcuts.dart` junto dos outros nove, sob a mesma guarda
`_isEditingText:16-19` (`Ctrl+G` dentro de um campo de texto não deve envolver nada).

### D9 — Excluir a raiz: **só o rótulo muda**, para **"Esvaziar conteúdo"**. Sem diálogo.

> **Decidida pelo humano em 2026-08-15 (fecha as duas metades da pergunta: o quê e como).**

O botão continua fazendo exatamente o que já fazia — o que muda é ele **parar de mentir**.
Na raiz, "Remover bloco" descreve uma operação local, mas o efeito é apagar a página
inteira (`cubit:194-197`).

**Texto: "Esvaziar conteúdo".** Diz o que acontece e não promete que é reversível — a
reversibilidade é do `Ctrl+Z`, não do botão.

**Sem confirmação**, e essa é a decisão que economiza mais atrito: o histórico do item 23
já cobre o arrependimento com uma tecla, e um diálogo disparado pelo mesmo botão que
remove qualquer bloco viraria um "OK" reflexo em toda exclusão — ruído que treina o
usuário a ignorar diálogos, sem proteger nada que o undo não proteja.

## 5. Fases

### F1 — Kernel: `wrapNode` · **[base]** · **[sub-agente: especialista-dominio]**

- **`packages/sdui_core/lib/src/ops/tree_ops.dart`** — nova função top-level:
  ```dart
  SduiNode? wrapNode(SduiNode root, String nodeId, String wrapperType, {required String newId});
  ```
  Devolve `null` quando `nodeId` não existe ou quando `wrapperType` não é `SlotKind.multi`
  no catálogo (envolver em folha ou em slot único não faz sentido e não vira exceção —
  mesmo contrato de `attachNode:85`, que já é nullable). Preserva a subárvore por
  referência (`properties`/`events` são imutáveis por contrato). O contêiner nasce de
  `defaultNode(wrapperType, id: newId)` e reusa `_rebuild:118` / `setChild:43`.
- **Nada a fazer no barrel:** `sdui_core.dart:16` já exporta `tree_ops.dart` inteiro.

**Aceite (validável):**

1. Envolver a raiz troca a raiz e mantém a subárvore intacta — igualdade `Equatable` do
   nó original preservada.
2. Envolver o ocupante de um slot único mantém o pai e troca só o `child`.
3. `wrapperType` folha (`text`) ou single (`padding`) → `null`.
4. `nodeId` inexistente → `null`.
5. Round-trip: o resultado passa por `toJson` → `parseContentSpec` sem erro.

### F2 — Editor: comando "Envolver em…" · **[depende de F1]** · **[∥ com F5, F6]** · **[sub-agente: especialista-apresentacao]**

**Esta é a fatia mínima que destrava o dev.** É mergeável sozinha e não muda nenhuma
semântica de drop.

- **`$E cubit/editor_cubit.dart`** — `void wrapSelected(String wrapperType)`: usa
  `_nextNodeId(root)`, chama `sdui.wrapNode`, emite **uma** vez por `_emitRoot` (sem
  `coalesceKey`) e **seleciona o contêiner criado** — é o que o usuário vai configurar
  em seguida. Espelhar o formato de `_emitClone:292-314`.
- **`$E cubit/editor_notice_kind.dart`** + **`$E widgets/status_bar/editor_notice_message.dart`** —
  `nodeWrapped`. Lembrar que o `switch` de `of` é exaustivo: o caso novo quebra a
  compilação até o texto pt-BR existir.
- **`$E widgets/inspector/wrap_node_button.dart`** (arquivo novo) — botão ao lado do de
  remover em `inspector_header.dart:57-63`, abrindo Column/Row. **Gates:** widget próprio
  em arquivo próprio (G1/G3), tokens de `core/theme/` (G4), `Semantics`/tooltip.
- **`$E page/editor_intents.dart`** + **`$E page/editor_shortcuts.dart`** — `WrapIntent`
  e o atalho **`Ctrl+G`** (D8), sob a mesma guarda `_isEditingText:16-19`. A `WrapIntent`
  entra no mesmo arquivo dos outros oito intents, seguindo o precedente da família (não é
  violação do Gate 3). **Não usar `Ctrl+Shift+W`** — o Chrome o consome antes do app
  (D8). `Ctrl+G` envolve em **`column`**; a `row` sai pelo botão.

**Aceite (validável):**

1. Com a raiz `text` selecionada, "Envolver em Column" produz `column[text]`.
2. A `column` fica selecionada logo após o comando.
3. A paleta volta a aceitar drop sobre a página (o beco sumiu).
4. Um único `Ctrl+Z` desfaz o wrap inteiro.
5. Envolver um nó no meio da árvore não mexe em irmãos.
6. **`Ctrl+G` dispara o mesmo wrap que o botão** (D8) e **não faz nada** com o cursor
   dentro de um campo de texto do inspector.
7. `editor_shortcuts_test.dart` continua verde.

### F3 — Kernel: `DropRequiresWrap` · **[depende de F1]** · **[mesmo PR da F4 — D7]** · **[sub-agente: especialista-dominio]**

- **`packages/sdui_core/lib/src/ops/drop_ops.dart`** — o caso da D2 em `:76`;
  `DropRefusal.noSlotAvailable` sai do enum (`:8`).
- **`packages/sdui_core/test/ops/drop_ops_test.dart:73-79`** — o teste que hoje afirma a
  recusa passa a afirmar `DropRequiresWrap`. **É a prova documental da mudança de
  comportamento e vai citada no PR.**

**Aceite (validável):**

1. Raiz folha → `DropRequiresWrap(wrapTargetId: 'só', wrapperType: 'column')`.
2. Cadeia de slots únicos ocupados até a raiz → idem, apontando o **alvo apontado**.
3. `cycle` e `unknownTarget` intocados.
4. `grep noSlotAvailable` no workspace devolve **zero** ocorrências.

### F4 — Editor: o drop agrupa em vez de recusar · **[depende de F2+F3]** · **[mesmo PR da F3 — D7]** · **[sub-agente: especialista-apresentacao]**

- **`$E cubit/editor_cubit.dart`** — os quatro `switch` (`:96`, `:131`, `:243`, `:277`)
  ganham o braço `DropRequiresWrap`: compõe `wrapNode` + `attachNode`/`moveNode` **em
  memória** e emite **uma** vez (D4), com notice `dropWrapped`.
- **`$E cubit/editor_notice_kind.dart`** — `dropNoSlot` sai (inalcançável), `dropWrapped`
  entra; `_kindOf(DropRefusal)` (`:385-389`) encolhe para dois casos.
- **`$E widgets/widget_tree_panel.dart:97-98`** — as frestas de inserção só existem para
  `SlotKind.multi`. **Recorte:** ficam como estão; fresta acima de uma raiz folha é
  ergonomia adicional, não desbloqueio (§7).

**Aceite (validável) — o cenário literal do relato:**

1. Página com raiz `text`; arrastar `image` da paleta para o mock → vira
   `column[text, image]`.
2. A barra de status explica o agrupamento (D5).
3. Um único `Ctrl+Z` volta ao `text` sozinho.
4. Mesmo resultado soltando **na linha da árvore**, **no rodapé da árvore** e **no vazio
   do device**.
5. `Ctrl+V` com raiz folha também cola (não emite mais `dropNoSlot`).
6. `Ctrl+D` sobre a raiz continua recusando com `rootNotDuplicable` (não é o caso de wrap).

### F5 — Marcação de problema no próprio nó · **[0-dep; ∥ com tudo]** · **[sub-agente: especialista-apresentacao]**

A metade do pedido do dev que sobrevive à D1. Hoje o problema só existe na barra de
status: `status_bar_area.dart:15` é o **único** consumidor de `diagnostics`; nem
`TreeRowContent` nem `SelectableNodeSurface` os recebem. **Nada a fazer no kernel** —
`SpecDiagnostic` já carrega `nodeId`, `nodeType`, `code`, `severity` e `message`.

- **`$E page/`** — os diagnósticos passam a ser **agrupados uma vez** em
  `Map<String, List<SpecDiagnostic>>` por `nodeId` e distribuídos aos dois painéis, no
  mesmo padrão de VM por área que já existe (`status_bar_vm.dart`, `inspector_vm.dart`).
  **Não propagar o getter `EditorReady.diagnostics` cru** — ver R3.
- **`$E widgets/widget_tree/tree_row_content.dart`** — ícone de erro/aviso na linha, com
  tooltip trazendo a mensagem. Nunca só cor.
- **`$E widgets/canvas/selectable_node_surface.dart`** — marcação **aditiva** em
  **foreground**. Cuidado: as 4 decorações atuais (`:38-67`) são ramos **mutuamente
  exclusivos** de um if/else (drop-target · selecionado · hover · repouso); a marcação de
  erro **não** é um quinto ramo — ela tem de aparecer junto com qualquer um deles, como o
  `NodeTag` (`Positioned`, `:68-73`). O `Stack` já é `Clip.none` + `StackFit.passthrough`
  (`:31-36`), então não altera layout.

**Aceite (validável):**

1. Um `expanded` fora de `Row`/`Column` aparece marcado **na árvore** e **no canvas**,
   além da barra.
2. A marcação some ao corrigir a estrutura.
3. Erro e aviso se distinguem por ícone + texto, não só por cor.
4. **Nenhum golden de canvas muda** para documento **sem** diagnóstico
   (`canvas_panel_golden_test.dart` verde sem regravar).
5. `editor_perf_test.dart` continua dentro do orçamento (R3).

### F6 — Higiene: excluir a raiz apaga a página · **[0-dep; ∥ com tudo]** · **[sub-agente: especialista-apresentacao]**

- **`$E widgets/inspector/inspector_header.dart:57-63`** — quando o nó é a raiz,
  tooltip/rótulo viram **"Esvaziar conteúdo"**.
- **`$E widgets/widget_tree/tree_row_content.dart:71-78`** — o mesmo. **Atenção:**
  `TreeRowContent` **não** recebe `isRoot` hoje (params em `:10-16`); quem sabe disso é
  `TreeRow` (`:16,26,42`). O caminho limpo é `TreeRow` passar o rótulo já resolvido, não
  vazar mais uma flag booleana para dentro do conteúdo.
- **Sem diálogo de confirmação** (D9): o `Ctrl+Z` do item 23 cobre o arrependimento, e um
  diálogo a cada exclusão de bloco seria pior. **Nada do comportamento muda nesta fase —
  só o texto.** Se a fase mexer no fluxo de exclusão, saiu do escopo.

**Aceite (validável):**

1. Na raiz, tooltip e rótulo dizem **"Esvaziar conteúdo"** (D9), nos **dois** lugares:
   inspector e linha da árvore.
2. Nos demais nós, nada muda — texto (`"Remover bloco (Delete)"`) e comportamento
   idênticos.
3. **Nenhuma mudança de comportamento**: o botão apaga o mesmo que apagava, sem diálogo.
4. `widget_tree_panel_test.dart` e `inspector_panel_test.dart` verdes.

### F7 — Bateria automatizada · **[por último, depois do E2E atestado]** · **[dono: qa]**

- `sdui_core/test/ops/tree_ops_test.dart` — os 5 casos de aceite do `wrapNode` +
  round-trip `toJson`/`parseContentSpec`.
- `sdui_core/test/ops/drop_ops_test.dart` — `DropRequiresWrap`; **teste de invariante**:
  varrer o catálogo montando **cada tipo** como raiz e afirmar que nenhum produz gesto
  sem destino.
- `apps/driva_editor/test/.../cubit/editor_cubit_test.dart` (`bloc_test`) — `wrapSelected`;
  `addNode` sobre raiz folha; **`Ctrl+Z` desfaz wrap+drop numa única entrada** (D4);
  notice correta.
- Widget test — botão de envolver no `InspectorHeader`; marcação de erro na `TreeRow`.

**Pendências identificadas na revisão do PR3 (QA, 2026-08-15) — registradas aqui para
não se perderem, cobertura entra só na F7:**

- `Ctrl+Y` chamando `redo()` de fato — hoje o teste do undo do wrap só afirma `canRedo`,
  não que o `redo()` reaplica o agrupamento.
- `Ctrl+V` com a raiz sendo uma folha — o braço `DropRequiresWrap` de `paste()` existe e
  está correto, mas sem teste dedicado.
- **A mais importante:** o braço `DropRequiresWrap` de `moveNode`
  (`editor_cubit.dart:162-176`) é **alcançável pelo usuário** (arrastar um nó existente
  para cima de um alvo cuja cadeia de slots únicos está esgotada) e não tem teste. Caso:
  `card(child: padding(child: text))`, arrastar o `text` sobre o `card` →
  `column[card(padding()), text]`.

**Aceite:** os testes acima (incluindo as três pendências) passam e a suíte existente
continua verde.

## 6. Ordem de PRs e paralelismo

```
F1 ──► F2 ──► [F3+F4] ──► F7
F5 ─────────────────────► F7   (0-dep, pode começar no dia 1)
F6 ─────────────────────► F7   (0-dep, pode começar no dia 1)
```

| PR | Fase(s) | Depende de | Pode começar |
| --- | --- | --- | --- |
| 1 | F1 | — | agora |
| 2 | F2 | PR 1 | após F1 |
| 3 | F3 + F4 | PR 2 | após F2 (D7) |
| 4 | F5 | — | **agora, em paralelo** |
| 5 | F6 | — | **agora, em paralelo** |
| 6 | F7 | todos + E2E atestado | por último |

**Paralelismo real:** F5 e F6 não tocam nenhum arquivo das F1–F4 e podem correr desde o
início. F2 e F3 **não** são paralelas de verdade, ao contrário do que o plano de gaveta
sugeria — a F3 arrasta a F4 (D7), e a F4 depende do `wrapSelected` da F2.

**F2 sozinha já é entregável** e resolve o relato do dev. Se o tempo acabar, é ela que
tem de estar no ar.

## 7. Riscos

- **R1 — Exaustividade de `sealed` derruba o build.** Mitigado pela D7 (F3+F4 no mesmo
  PR). Vale também para os dois `switch` de notice.
- **R2 — Atalho reservado do navegador. `[resolvido pela D8]`** O editor é Flutter **Web**
  e `Ctrl+Shift+W` fecha a janela do Chrome antes de o app ver a tecla. Fechado com
  `Ctrl+G`. **Continua valendo como regra geral:** todo atalho novo do editor precisa ser
  testado no Chrome, não só no teste de widget — `editor_shortcuts_test.dart` passa mesmo
  para um binding que o navegador nunca deixa chegar.
- **R3 — `EditorReady.diagnostics` é getter computado sem cache** (`editor_state.dart:64`):
  cada leitura roda `diagnoseTree` na árvore inteira. Distribuir o getter cru para cada
  linha da árvore e cada nó do canvas multiplicaria isso por N. A F5 agrupa **uma vez**
  num `Map` por `nodeId` e distribui o mapa. `editor_perf_test.dart` é a cancela.
- **R4 — Goldens do canvas.** A F5 mexe em `SelectableNodeSurface`; regravar golden por
  descuido esconde regressão visual. O aceite exige golden verde **sem** regravação para
  documento sem diagnóstico.
- **R5 — `_clipboard` guarda um `SduiNode` vivo** (`cubit:42`) que pode já não existir na
  árvore após um wrap. Hoje `paste` sempre clona com `cloneWithNewIds` (`:270`, `:300`),
  então o risco está coberto — mas o braço novo de `DropRequiresWrap` em `paste:277` não
  pode assumir que o nó do clipboard ainda está na árvore.
- **R6 — Automatismo surpreendente.** O drop passa a tomar decisão estrutural sozinho.
  Mitigado pela D5 (recado explícito) + D4 (um `Ctrl+Z` reverte).

## 8. Divergências em relação ao plano de gaveta

Conferido contra `develop` pós-item 23. O plano de gaveta está **substancialmente
correto** — os quatro `switch`, o funil de emissão e as linhas do `drop_ops` batem.
Correções incorporadas acima:

1. **F3 e F4 não são fases paralelas separáveis em PRs** — a exaustividade da sealed
   `DropResolution` obriga o mesmo PR (D7). Era `[∥ com F2]` no plano de gaveta.
2. **`Ctrl+Shift+W` é reservado do Chrome** (R2) — o plano dizia "livre"; livre no app,
   não no navegador.
3. **A F1 não precisa mexer no barrel** — `sdui_core.dart:16` já exporta `tree_ops.dart`
   inteiro, sem `show`/`hide`.
4. **`findParent` e `moveNode` já existem** em `tree_ops.dart:18,68` — o inventário do
   plano de gaveta os omitia.
5. **`SpecDiagnostic` mora em `spec_diagnostic.dart`**, não em `diagnose_ops.dart`.
6. **`TreeRowContent` não recebe `isRoot`** — a F6 resolve o rótulo em `TreeRow`.
7. **Não existe VM único da página** — há VMs por área (`status_bar_vm.dart`,
   `inspector_vm.dart`). A F5 cria/estende VM por área, **não** um VM da página inteira:
   um VM único faria a árvore reconstruir quando só o canvas mudou, contra a regra de
   escopo mínimo de rebuild.
8. **As 4 decorações do `SelectableNodeSurface` (`:38-67`) são ramos mutuamente
   exclusivos** de um if/else (drop-target · selecionado · hover · repouso). A marcação de
   erro da F5 **tem de ser aditiva** — um overlay como o `NodeTag` (`:68-73`), não um
   quinto ramo. Implementá-la como `else if` faria o erro sumir justamente quando o nó
   estivesse selecionado, que é quando o dev está olhando para ele.
9. Deslocamentos de linha: `cloneWithNewIds` em `tree_ops.dart:100` (não `:99`); a
   asserção do teste em `drop_ops_test.dart:75-78` (não `:76-77`); `isRoot` declarado em
   `tree_row.dart:16,26` (o `:83` do plano era do chamador, `widget_tree_panel.dart:83`).
10. **Os botões Desfazer/Refazer da top bar já existem** (`editor_top_registrar.dart:60-69`) —
    trabalho do item 23, nada a fazer.

O item 23 **não** invalidou nenhuma fase: ele reforçou a D4, dando o funil único que ela
pedia.

## 9. Perguntas fechadas — **o plano está fechado**

As seis perguntas que este plano levou ao humano foram **respondidas em 2026-08-15**.
Nenhuma decisão de produto ou de recorte está pendente: os especialistas podem começar.

| # | Pergunta | Resposta do humano | Onde virou decisão |
| --- | --- | --- | --- |
| Q1 | Aceitar árvore inválida no documento? | **Não.** Recusa confirmada | D1 |
| Q2 | Auto-wrap no drop além do comando explícito? | **Os dois**, F2 antes de F3+F4 | D6 |
| Q3 | Qual atalho para envolver? | **`Ctrl+G`**; `Ctrl+Shift+W` está morto | D8 |
| Q4 | Excluir a raiz: rótulo ou confirmação? | **Só o rótulo**, sem diálogo | D9 |
| Q5 | Qual o texto do rótulo na raiz? | **"Esvaziar conteúdo"** | D9 |
| Q6 | F3+F4 num PR só, contra o "1 fase = 1 PR"? | **Aceito** como desvio consciente | D7 · **VR-15-01** |

**O que reabre uma decisão:** só um desvio registrado em `variance_report.md` desta
pasta, com aprovação do humano. Especialista que discordar de uma D **para e avisa o
tech-lead** — não corrige o plano por conta própria.

## 10. Roteiro de E2E manual

_Ponto de partida do QA. Em homologação, editor web no Chrome._

1. Criar conteúdo novo (página vazia, sem `root`).
2. Arrastar `text` da paleta → vira a raiz. **Esperado:** aparece no canvas e na árvore.
3. Arrastar `image` da paleta **para o mock do device**. **Esperado:** vira
   `column[text, image]`; a barra de status explica o agrupamento (D5).
4. `Ctrl+Z`. **Esperado:** volta ao `text` sozinho — **uma** tecla, não duas (D4).
5. `Ctrl+Y` (ou `Ctrl+Shift+Z`). **Esperado:** o agrupamento volta.
6. Selecionar o `text`; botão "Envolver em Row". **Esperado:** `row[text]`, com a `row`
   selecionada no inspector.
   - Selecionar um nó e teclar **`Ctrl+G`** (D8). **Esperado:** envolve em `column`, e o
     Chrome **não** reage (nada de favoritar, fechar aba ou abrir busca).
   - Repetir o `Ctrl+G` com o cursor dentro de um campo de texto do inspector.
     **Esperado:** nada acontece (guarda `_isEditingText`).
7. Repetir o passo 3 soltando **na linha da árvore**, **no rodapé da árvore** e **sobre
   um nó do canvas**. **Esperado:** mesmo resultado nos três — a regra única do 8e.
8. `Ctrl+C` num nó, selecionar a raiz folha, `Ctrl+V`. **Esperado:** cola agrupando, não
   recusa.
9. Arrastar `expanded` para fora de uma `Row`/`Column`. **Esperado:** marcação de erro
   **na linha da árvore** e **no nó do canvas**, além da barra de status; corrigir faz a
   marcação sumir.
10. Selecionar a raiz e olhar o tooltip da lixeira. **Esperado:** "Esvaziar conteúdo".
    Clicar, conferir que apaga tudo, e `Ctrl+Z` para voltar.
11. Salvar e **recarregar a página do navegador**. **Esperado:** o conteúdo reabre
    idêntico — a prova de que o spec continua válido (D1).
12. Reordenar por drag dentro da `column` criada pelo wrap. **Esperado:** funciona como
    em qualquer `column` montada à mão.

## 11. Definition of Done

> **O DoD é a cancela do plano — enquanto ele não fecha, a feature não está pronta.**
> Cada linha abaixo é verificável: responde *como eu provo que isto está feito*.

- `flutter analyze` verde no workspace; `dart test` / `flutter test -r compact`
  existentes passando.
- `DropRefusal.noSlotAvailable` **não existe mais** no workspace, e há teste de
  invariante varrendo o catálogo provando que nenhum tipo como raiz produz gesto sem
  destino.
- **E2E da §10 executado e atestado pelo dev humano.** O QA instrumenta o script
  (`instrumentar-e2e`), o humano confere os prints, a evidência fica em
  `evidencias/rodada_MM/`. Roda contra a **UI real em homologação**, não `localhost`
  (lição do item 9g). O roteiro só conta como cumprido se os passos **4** (um único
  `Ctrl+Z`), **6** (o `Ctrl+G` sem o Chrome reagir, e o mesmo `Ctrl+G` inerte dentro de
  campo de texto), **9** (marcação de erro visível **na árvore e no canvas**, não só no
  rodapé) e **11** (o conteúdo reabre após reload) tiverem print próprio — são os quatro
  que provam o que a feature promete; o resto é caminho feliz.
- Bateria da F7 escrita **depois** do E2E.
- Docs vivas nesta pasta: `final_report.md` ao fechar e `variance_report.md`
  (já aberto, com o **VR-15-01**; desvios novos entram como `VR-15-NN`).
  `CHANGELOG` `Unreleased` atualizado **no mesmo PR** da mudança.
- `docs/roadmap.md` e `docs/plans/README.md` atualizados pelo tech-manager: item 38 vira
  `[x]`.
