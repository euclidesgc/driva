# plan.md — Item 38: Destravar o construtor — envolver nó e drop sem beco sem saída

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 4 (Ergonomia do construtor).
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend** (o spec é JSONB opaco).
> **0-dep.** Nasce de relato do dev humano no uso real (2026-08-15).

> ✅ **Numeração e indexação resolvidas (2026-08-15).** A pasta nasceu como `31-`, colidindo com o item 31 do roadmap; foi renomeada para **38** (o roadmap ia até 37) e o plano do `image` virou **39**. O item está indexado em `docs/roadmap.md` › Marco 4 e em `docs/plans/README.md`. **Decisão do humano:** 38 e 39 saem **antes** do item 24.

## 1. Objetivo e recorte

O item **8c** (raiz livre) tornou possível que a raiz da página seja **qualquer** widget do catálogo, inclusive uma **folha** (`text`, `image`, `icon`, `divider`…): o primeiro widget arrastado vira a raiz. O item **8e** tornou `resolveDrop` a regra única dos dois painéis, com o encaixe subindo para o primeiro ancestral que recebe filhos.

Ninguém escreveu a metade que falta: **quando a subida não encontra ancestral nenhum, não sobra destino e a página fica sem saída.** O dev não consegue nem criar o contêiner que faltava, nem tirar de lá o widget que já está.

**Este item é a metade que falta do 8c.**

**Entra:**
1. Operação de **envolver um nó** num contêiner, no kernel (`sdui_core`).
2. **Comando explícito** "Envolver em Column/Row" no editor — a fatia que destrava o dev sozinha.
3. O **drop deixa de recusar**: `resolveDrop` passa a devolver "precisa envolver" em vez de `noSlotAvailable`, e o editor materializa o agrupamento automático, com recado na barra de status do 8e e desfazível num `Ctrl+Z`.
4. **Marcação de problema no próprio nó** (árvore e canvas), hoje só existente na barra de status.
5. Higiene: excluir a raiz **apaga a página inteira** sem aviso — o rótulo e o tooltip passam a dizer isso.

**Fica fora:** aceitar árvore estruturalmente inválida no documento (ver D1 e §8); área de rascunho/multi-raiz; envolver **seleção múltipla** (não existe seleção múltipla hoje); desenvolver o "envolver" para todos os contêineres do catálogo (só `column` e `row` nesta fatia — ver §9).

## 2. Causa confirmada (levantamento de 2026-08-15)

**`packages/sdui_core/lib/src/ops/drop_ops.dart:73-86`** — o laço sobe pelos ancestrais; `findParent(root, rejected.id)` só devolve `null` **na raiz**, e aí a função devolve `DropRefused(DropRefusal.noSlotAvailable)` (`:76`).

**Corolário que vale registrar, porque é a chave do desenho:** `noSlotAvailable` **só acontece quando a cadeia inteira até a raiz não tem slot livre**. Não existe outro caso. Logo, **todo `noSlotAvailable` é resolvível envolvendo um nó** — não há situação em que o gesto seja genuinamente impossível.

O caso já está inclusive coberto por teste, como comportamento esperado: `packages/sdui_core/test/ops/drop_ops_test.dart:76-77` afirma `resolveDrop(leafRoot, 'só') == DropRefused(DropRefusal.noSlotAvailable)`.

**Quem consome a recusa.** Todos os gestos convergem para a mesma função e para a mesma mensagem:

| Gesto | Caminho | Resultado hoje |
| --- | --- | --- |
| Soltar da paleta no canvas | `.../canvas/canvas_area.dart:34,43` → `EditorCubit.addNode` → `editor_cubit.dart:96-98` | notice `dropNoSlot` |
| Soltar no vazio do device | `canvas_panel.dart:50` → `canvas_area.dart:28-33` (passa a **própria raiz** como alvo) | notice `dropNoSlot` |
| Soltar na linha da árvore | `widget_tree_panel.dart:88` → `addNode` | notice `dropNoSlot` |
| Soltar no rodapé da árvore | `widget_tree_panel.dart:61` | notice `dropNoSlot` |
| Frestas de inserção | `widget_tree_panel.dart:97-100` | **nem são emitidas** (só para `SlotKind.multi`) |
| `Ctrl+V` | `editor_cubit.dart:275-279` | notice `dropNoSlot` |
| `Ctrl+D` | `editor_cubit.dart:228-231` | notice `rootNotDuplicable` |
| Arrastar a raiz | `editor_cubit.dart:121-124`, `:169-172` | notice `rootNotMovable` |

Mensagem única: `'Não há onde encaixar: nenhum widget acima do destino aceita filhos.'` (`.../status_bar/editor_notice_message.dart:17-18`).

**É beco sem saída de verdade?** Quase. Existem exatamente **dois** caminhos, ambos destrutivos e ambos não-descobríveis:

- **(i)** `Ctrl+C` na raiz → `Delete` (que **apaga a página inteira**, `editor_cubit.dart:194-196`) → arrastar `column` da paleta (vira a nova raiz, `:87-91`) → selecionar → `Ctrl+V` (`:275-288`). Funciona porque `_clipboard` sobrevive ao esvaziamento (`:206-208`). Recuperável por `Ctrl+Z`.
- **(ii)** Apagar e remontar à mão, redigitando todas as props.

**Não existe**, hoje: operação de wrap no kernel (`sdui_core/lib/src/ops/` só tem `tree_ops.dart` e `drop_ops.dart`), menu de contexto em nó (nem árvore nem canvas), `WrapIntent` (`page/editor_intents.dart:3-33` lista os oito intents existentes), atalho, ou drop-zone acima da raiz.

**Agravante de perda de trabalho.** O botão de lixeira da raiz diz **"Remover bloco (Delete)"** (`widgets/inspector/inspector_header.dart:57-63`; o mesmo botão em `widgets/widget_tree/tree_row_content.dart:71-78`, entregue a **todas** as linhas incluindo a raiz por `widget_tree_panel.dart:86`) — mas na raiz ele **esvazia o conteúdo inteiro**, sem confirmação e sem aviso. `TreeRow` até recebe `isRoot` (`tree_row.dart:83`), e só o usa para o rótulo (`:42`).

## 3. Precedências — o que já existe

| O que | Onde | Uso |
| --- | --- | --- |
| `resolveDrop` / `DropResolution` selada / `DropRefusal` | `sdui_core/lib/src/ops/drop_ops.dart:8,15,49` | Ganha um terceiro caso (D2). |
| `attachNode`, `setChild`, `insertChild`, `_rebuild`, `cloneWithNewIds` | `sdui_core/lib/src/ops/tree_ops.dart:85,100` | Base do `wrapNode` (F1). |
| `descriptorFor(type).slot` (`SlotKind.none/single/multi`) | `sdui_core/lib/src/catalog/widget_descriptor.dart` | Já é quem decide se um nó recebe filhos. |
| `defaultNode(type, id:)` / `defaultProperties` | `sdui_core/lib/src/catalog/widget_catalog.dart:1105` | O contêiner criado pelo wrap nasce com os defaults do catálogo. |
| `EditorCubit._nextNodeId(root)` | `.../cubit/editor_cubit.dart` | Fonte dos ids novos; o wrap precisa de **um** id. |
| `_emitRoot` / `_emitDocument` (funil único de mutação + histórico do item 23) | `.../cubit/editor_cubit.dart` | O wrap+encaixe tem de sair numa **única** emissão (D4). |
| `EditorNoticeKind` (8 casos) + `EditorNoticeMessage.of` | `.../cubit/editor_notice_kind.dart:4`, `.../status_bar/editor_notice_message.dart:6-30` | Onde entra o recado de agrupamento. |
| `EditorStatusBar` + `StatusBarArea` + `DiagnosticRow` (clique seleciona o nó) | `.../status_bar/editor_status_bar.dart:14,59-77`, `page/status_bar_area.dart:13-23`, `.../status_bar/diagnostic_row.dart:29-30` | Mecanismo do 8e que a F5 reusa. |
| `EditorReady.diagnostics` — **getter computado**, não campo | `.../cubit/editor_state.dart:64` (`sdui.diagnoseTree(document.root)`) | ⚠️ recalculado a cada leitura; ver risco R3. |
| `diagnoseTree` (2 regras: `flexOnlyOutsideFlex`, `emptySingleSlot`) | `sdui_core/lib/src/diagnostics/diagnose_ops.dart:14-19` | Já é o vocabulário de "problema do nó". |
| `EditorIntents` + `EditorShortcuts` (`Ctrl+S/Z/Y/D/C/V`, `Delete`, `Esc`) e a guarda anti-campo-de-texto | `page/editor_intents.dart:3-33`, `page/editor_shortcuts.dart:16-19,25-58` | Onde entra o atalho de envolver. |
| `InspectorHeader` já tem `IconButton` de remover | `.../inspector/inspector_header.dart:57-63` | Vizinho natural do botão de envolver (F2). |
| `SelectableNodeSurface` — decorações em **foreground**, `StackFit.passthrough` | `.../canvas/selectable_node_surface.dart:29-76` | Onde a marcação de erro do nó entra sem alterar layout (F5). |
| `TreeRowContent` (conhece `isSelected`/`isDragOver`) | `.../widget_tree/tree_row_content.dart:29-83` | Idem, no painel da árvore (F5). |
| `parseNode` recusa filho em `SlotKind.none` | `sdui_core/lib/src/schema/node_schema.dart` (`'"$type" é folha e não aceita filhos'`) | **A prova que mata a direção (b)** — ver D1. |
| `ContentSpec` tem **um** `root` opcional | `sdui_core/lib/src/model/content_spec.dart:21` | Não há lugar no modelo para "fora da árvore". |

## 4. Decisões de design travadas

### D1 — A árvore continua **sempre válida**. A direção "aceitar inválido e diagnosticar" está **recusada**.

O dev pediu textualmente: _"eles deveriam ser exibidos lá, mas mostrando uma mensagem de erro"_. A necessidade por trás — **"eu teria condições de reorganizar a árvore para corrigir os problemas"** — é atendida integralmente pelas D2/D3 a uma fração do custo. O que está recusado é o **mecanismo**, não o objetivo.

Três razões, todas verificáveis:

1. **O documento deixaria de reabrir.** `parseNode` (`sdui_core/lib/src/schema/node_schema.dart`) recusa `child`/`children` em `SlotKind.none` e recusa `children` em `SlotKind.single`. Um `text` com filho salva, mas **falha no reload** — o conteúdo vira inabrível. Aceitar o estado exigiria afrouxar o schema, e aí a guarda que protege o app do cliente some junto.
2. **Não há onde guardar "fora da árvore".** `ContentSpec` tem um `root` (`content_spec.dart:21`). Multi-raiz ou área de rascunho é um campo novo no spec que atravessa schema, renderer, painel de árvore, painel de JSON, publicação (item 24), a rota pública (item 25 fatia 1, **já no ar**) e o runtime do cliente.
3. **É a reversão explícita de uma decisão registrada.** `docs/12-mover-widgets-safearea/final_report.md:29-32`: _"A guarda estrutural continua no kernel. O que nunca acontece é escrever `children` num slot único ou criar ciclo: isso produziria documento que o próprio `parseContentSpec` recusa no reload."_

**O que damos no lugar, e que é a metade do pedido que realmente importa:** a F5 traz a **marcação de erro no próprio nó** — hoje o problema só aparece na barra de status. O dev passa a ver o erro *onde ele está*, sem que o documento precise ficar inválido para isso.

### D2 — `resolveDrop` ganha um terceiro caso; `noSlotAvailable` some.

```dart
final class DropRequiresWrap extends DropResolution {
  const DropRequiresWrap({required this.wrapTargetId, required this.wrapperType});
  final String wrapTargetId;
  final String wrapperType;
}
```

Onde hoje devolve `DropRefused(DropRefusal.noSlotAvailable)` (`drop_ops.dart:76`), passa a devolver `DropRequiresWrap(wrapTargetId: <o alvo apontado>, wrapperType: 'column')`.

Pela análise da §2, `noSlotAvailable` **só** ocorre quando a cadeia até a raiz está sem slot — e esse caso é **sempre** resolvível por wrap. Portanto `DropRefusal.noSlotAvailable` deixa de ser alcançável e **sai do enum**. Sobram `cycle` e `unknownTarget`, que são recusas legítimas. Isso é testável e é o critério de aceite da F3.

**A regra única dos dois painéis (invariante do 8e) é preservada:** quem decide continua sendo o kernel; canvas e árvore só materializam a decisão.

### D3 — Envolve-se **o nó apontado**, não a raiz, e o contêiner padrão é `column`.

`wrapNode(root, 'txt', 'column', newId: 'nd_9')` transforma `txt` em `column(children: [txt])` **no lugar onde `txt` estava** — se `txt` era a raiz, a `column` vira a nova raiz; se era filho de um slot único, a `column` toma o lugar dele naquele slot.

Por que o nó apontado e não a raiz: é onde a intenção do usuário está. Arrastar sobre um `text` que está dentro de `center > padding` e ver o widget aparecer no topo da página seria mais surpreendente do que vê-lo ao lado do `text`.

Por que `column`: é a direção padrão de uma página e é o que o editor implicitamente fazia antes do 8c. `row` fica no comando explícito da F2.

**Nota de correção:** o pai de um nó que dispara wrap nunca é `SlotKind.multi` — se fosse, `_accepts(parent)` seria verdadeiro e a subida teria parado ali. Logo o wrap sempre substitui ou a raiz, ou o ocupante de um slot único. Não há caso de reindexação de lista.

### D4 — Envolver + encaixar é **uma** mutação, **uma** entrada de histórico.

O `Ctrl+Z` (item 23) tem de desfazer o agrupamento **e** a inserção de uma vez. É isso que torna o automatismo aceitável: o editor toma uma decisão estrutural, mas ela custa uma tecla para reverter. Implicação concreta: o cubit compõe `wrapNode` + `attachNode` **antes** de chamar `_emitRoot`/`_emitDocument` uma única vez — nunca duas emissões encadeadas.

### D5 — Nada acontece em silêncio: o agrupamento vira recado na barra de status.

`EditorNoticeKind.dropWrapped` → _"Text não recebia esse widget — os dois foram agrupados numa Column."_ Mesmo padrão do `dropRedirected` do 8e, que já ensinou o usuário a esperar explicação de desvio. Sem cor como único sinal (regra de acessibilidade do CLAUDE.md): texto explícito.

### D6 — O comando explícito existe **além** do automatismo, não em vez dele.

O drop automático cobre o gesto; o comando cobre a intenção deliberada ("quero uma Row aqui") e é o que o usuário usa quando **não** está arrastando nada. Os dois compartilham o mesmo `wrapNode`.

## 5. Fases

### F1 — Kernel: `wrapNode` **[base]** **[sub-agente: especialista-dominio]**

- **`packages/sdui_core/lib/src/ops/tree_ops.dart`** — nova função:
  ```dart
  SduiNode? wrapNode(SduiNode root, String nodeId, String wrapperType, {required String newId});
  ```
  Devolve `null` quando `nodeId` não existe ou quando `wrapperType` não é `SlotKind.multi` no catálogo (envolver em folha ou em slot único não faz sentido e não deve virar exceção). Preserva a subárvore por referência (`properties`/`events` são imutáveis por contrato, como já documentado em `cloneWithNewIds`, `:99`). O contêiner nasce de `defaultNode(wrapperType, id: newId)`.
- **`packages/sdui_core/lib/sdui_core.dart`** — export.

**Aceite:** envolver a raiz troca a raiz e mantém a subárvore intacta (igualdade `Equatable` do nó original preservada); envolver o ocupante de um slot único mantém o pai e troca só o `child`; `wrapperType` folha ou single → `null`; `nodeId` inexistente → `null`; o resultado passa por `parseContentSpec` num round-trip `toJson`→`parse`.

### F2 — Editor: comando "Envolver em…" **[depende de F1]** **[∥ com F3]** **[sub-agente: especialista-apresentacao]**

**Esta é a fatia mínima que destrava o dev.** É mergeável sozinha, não muda nenhuma semântica de drop e resolve o beco sem saída relatado.

- **`.../cubit/editor_cubit.dart`** — `void wrapSelected(String wrapperType)`: usa `_nextNodeId(root)`, chama `sdui.wrapNode`, emite uma vez por `_emitRoot`/`_emitDocument`, e **seleciona o contêiner criado** (é o que o usuário vai querer configurar em seguida).
- **`.../cubit/editor_notice_kind.dart`** + **`.../status_bar/editor_notice_message.dart`** — `nodeWrapped`.
- **`.../widgets/inspector/inspector_header.dart`** — botão ao lado do de remover, abrindo Column/Row. **Gate 2/3:** widget próprio, arquivo próprio (`.../inspector/wrap_node_button.dart`), tokens de `core/theme/`, `Semantics`/tooltip.
- **`.../page/editor_intents.dart`** + **`.../page/editor_shortcuts.dart`** — `WrapIntent`. Atalho sugerido `Ctrl+Shift+W` (livre; confirmar em §7 Q3), sob a mesma guarda anti-campo-de-texto de `:16-19,46-58`.

**Aceite:** com a raiz `text` selecionada, "Envolver em Column" produz `column[text]`, a `column` fica selecionada, a paleta volta a aceitar drop, e um `Ctrl+Z` desfaz tudo numa tecla. Envolver um nó no meio da árvore não mexe em irmãos.

### F3 — Kernel: `DropRequiresWrap` **[depende de F1]** **[∥ com F2]** **[sub-agente: especialista-dominio]**

- **`packages/sdui_core/lib/src/ops/drop_ops.dart`** — o caso da D2; `DropRefusal.noSlotAvailable` sai do enum.
- **`packages/sdui_core/test/ops/drop_ops_test.dart:76-77`** — o teste que hoje afirma a recusa passa a afirmar `DropRequiresWrap`. É a **prova da mudança de comportamento** e vai citado no PR.

**Aceite:** raiz folha → `DropRequiresWrap(wrapTargetId: 'só', wrapperType: 'column')`; cadeia de slots únicos ocupados até a raiz → idem, apontando o alvo apontado; `cycle` e `unknownTarget` intocados; **nenhum** caminho do kernel devolve mais "sem destino".

### F4 — Editor: o drop agrupa em vez de recusar **[depende de F2+F3]** **[sub-agente: especialista-apresentacao]**

- **`.../cubit/editor_cubit.dart`** — os quatro `switch` sobre `resolveDrop` (`:96`, `:131`, `:243`, `:277`) ganham o braço `DropRequiresWrap`: compõe `wrapNode` + `attachNode`/`moveNode` e emite **uma** vez (D4), com notice `dropWrapped`.
- **`.../cubit/editor_notice_kind.dart`** — `dropNoSlot` sai (não é mais alcançável), `dropWrapped` entra. `_kindOf(DropRefusal)` (`:385-388`) encolhe para dois casos.
- **`.../widgets/widget_tree_panel.dart:97-100`** — as frestas de inserção hoje só existem para `SlotKind.multi`. **Decisão de recorte:** ficam como estão nesta fatia; a fresta acima de uma raiz folha é ergonomia adicional, não desbloqueio (§9).

**Aceite:** o cenário literal do relato — página com raiz `text`, arrastar `image` da paleta para o mock → vira `column[text, image]`, a barra de status explica, `Ctrl+Z` volta ao `text` sozinho. Mesmo resultado soltando na árvore, no rodapé da árvore e no vazio do device. `Ctrl+V` com raiz folha também cola.

### F5 — Marcação de problema no nó **[depende de nada; ∥ com tudo]** **[sub-agente: especialista-apresentacao]**

A metade do pedido do dev que sobrevive à D1: hoje o problema só existe na barra de status (`status_bar_area.dart:13-23` é o **único** consumidor de `diagnostics`; nem `TreeRowContent` nem `SelectableNodeSurface` os recebem).

- **`.../page/…_vm.dart`** — os diagnósticos passam a ser **agrupados uma vez** em `Map<String, List<SpecDiagnostic>>` por `nodeId` e distribuídos aos dois painéis. ⚠️ **Não** propagar o getter `EditorReady.diagnostics` cru (risco R3).
- **`.../widget_tree/tree_row_content.dart`** — ícone de erro/aviso na linha, com tooltip trazendo a mensagem. Nunca só cor.
- **`.../canvas/selectable_node_surface.dart`** — quarta decoração em **foreground** (o `Stack` já é `clipBehavior: Clip.none` + `StackFit.passthrough`, `:31-36`, então não altera layout).

**Aceite:** um `expanded` fora de `Row`/`Column` aparece marcado na árvore **e** no canvas, além da barra; a marcação some ao corrigir; nenhum golden de canvas muda para documento **sem** diagnóstico.

### F6 — Higiene: excluir a raiz apaga a página **[0-dep; ∥ com tudo]** **[paralela]**

- **`.../inspector/inspector_header.dart:57-63`** e **`.../widget_tree/tree_row_content.dart:71-78`** — quando o nó é a raiz, rótulo/tooltip viram **"Esvaziar conteúdo"**. `TreeRow` já recebe `isRoot` (`tree_row.dart:83`) e hoje só o usa no rótulo (`:42`).
- Sem diálogo de confirmação: o `Ctrl+Z` do item 23 cobre, e um diálogo a cada exclusão de bloco seria pior. **Confirmar em §7 Q4.**

**Aceite:** o tooltip na raiz diz o que o botão faz; nos demais nós nada muda.

### F7 — Testes automatizados (por último)

- `sdui_core/test/ops/tree_ops_test.dart` — `wrapNode` (os 5 casos da F1) + round-trip `toJson`/`parseContentSpec`.
- `sdui_core/test/ops/drop_ops_test.dart` — `DropRequiresWrap`; **teste de invariante**: varrer o catálogo montando cada tipo como raiz e afirmar que nenhum devolve recusa por falta de destino.
- `apps/driva_editor/test/.../editor_cubit_test.dart` (`bloc_test`) — `wrapSelected`; `addNode` sobre raiz folha; **`Ctrl+Z` desfaz wrap+drop numa única entrada** (D4); notice correta.
- Widget test — botão de envolver no `InspectorHeader`, marcação de erro na `TreeRow`.

## 6. Mapa de paralelismo

```
F1 ─┬─► F2 ─┬─► F4 ──► F7
    └─► F3 ─┘
F5 ──────────────────► F7      (independente)
F6 ──────────────────► F7      (independente)
```

**F2 sozinha já é entregável** — ver §10.

## 7. Perguntas para o humano

1. **A recusa da direção (b) (aceitar árvore inválida) está aceita?** O argumento duro é o `parseNode`: o conteúdo deixaria de reabrir. A F5 entrega a parte visível do que foi pedido. **Se o humano quiser (b) mesmo assim, este plano não serve** — vira outro item, com mudança de schema e impacto no item 24/25 já no ar.
2. **Auto-wrap no drop (F4) ou só o comando explícito (F2)?** A recomendação é **os dois**, nesta ordem. O único argumento contra o F4 é "o editor decidiu por mim" — e o `Ctrl+Z` de uma tecla o neutraliza.
3. **`Ctrl+Shift+W` para envolver?** Está livre no `EditorShortcuts`.
4. **Excluir a raiz (F6): só mudar o rótulo, ou pedir confirmação?** Recomendo só o rótulo — undo já cobre e diálogo em toda exclusão irrita.
5. **Numeração:** ver o aviso do topo. `31`/`32` já estão ocupados no roadmap; os livres são `38`/`39`.

## 8. Direções avaliadas e descartadas

| Direção | Custo | Risco | Veredito |
| --- | --- | --- | --- |
| **(a) Auto-wrap puro** | Baixo | Editor decide estrutura sozinho | **Adotada, mas não sozinha** — vira a F4, em cima do wrap explícito da F2. Sozinha deixaria o usuário sem como pedir uma `Row`. |
| **(b) Aceitar inválido + diagnosticar** | **Alto** | Conteúdo não reabre (`parseNode`); campo novo no spec; atinge itens 24/25 já no ar; reverte decisão registrada do 8e | **Recusada** (D1). A metade visível vira a F5. |
| **(c) Só comando explícito** | Muito baixo | Não descobrível; o gesto de arrastar continua recusando | **Insuficiente sozinha** — mas é exatamente a fatia mínima (F2). |
| **(d) Combinação (c)→(a) com `wrapNode` único no kernel** | Baixo/médio | — | **Recomendada.** Uma operação de kernel serve os dois; a regra única do 8e é preservada; o automatismo nasce depois do comando, e não antes. |

Também descartadas, com motivo: **drop-zone permanente acima da raiz** (resolve a raiz, não a cadeia de slots únicos); **forçar `column` como raiz obrigatória** (reverte o 8c, que foi pedido de produto); **bloquear folha como raiz na paleta** (mesma reversão, e mata a página de um `text` só, que é legítima).

## 9. Evoluções deixadas de fora (registro)

- **Envolver em qualquer contêiner** do catálogo (`card`, `container`, `padding`, `center`, `stack`) — o `wrapNode` já aceita `SlotKind.single`? **Não**: nesta fatia só `multi`. Ampliar é trivial depois.
- **Desenvolver ("unwrap")** — remover um contêiner promovendo os filhos. É a operação irmã e vai faltar assim que a de envolver existir.
- **Frestas de inserção acima/abaixo da raiz** na árvore.
- **Menu de contexto de nó** (botão direito) na árvore e no canvas — não existe nenhum hoje; seria a casa natural de envolver/desenvolver/duplicar/remover.
- **Seleção múltipla + "envolver a seleção"** — o padrão do FlutterFlow; depende de seleção múltipla, que não existe.
- **`helpText` do `PropField` é renderizado em lugar nenhum** (`grep` em `apps/driva_editor/lib`: zero ocorrências), embora exista no modelo e seja preenchido em `safe_area_descriptor.dart:21,64`. Está no plano do item `image` (§F2 de lá), que é quem tem uso concreto para ele.

## 10. Definition of Done

- `flutter analyze` verde no workspace; `dart test`/`flutter test -r compact` existentes passando.
- `DropRefusal.noSlotAvailable` **não existe mais** no kernel, e há teste de invariante varrendo o catálogo que prova que nenhum tipo como raiz produz gesto sem destino.
- E2E manual em homologação, roteiro mínimo: página nova → soltar `text` (vira raiz) → soltar `image` no mock → vira `column[text, image]` com recado na barra → `Ctrl+Z` → volta ao `text` sozinho → "Envolver em Row" pelo botão → `row[text]` → salvar → **recarregar a página** (prova que o spec reabre) → arrastar para reordenar dentro da `row`.
- Docs vivas em `docs/NN-<nome>/` (final_report + CHANGELOG `Unreleased`), e o `docs/plans/README.md` + `docs/roadmap.md` atualizados **pelo tech-manager**.
