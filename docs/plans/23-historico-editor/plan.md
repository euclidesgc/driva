# plan.md — Item 23: Histórico do editor (desfazer/refazer, atalhos, duplicar/copiar/colar)

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 4.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. Nunca opinião.
> Escopo: `apps/driva_editor` (editor_module) + `packages/sdui_core` (uma op pura nova). **Não toca backend.**

## 1. Objetivo e recorte

O editor não tem `Ctrl+Z`. Um arraste que caiu no ancestral errado, um `Delete` com o nó errado selecionado ou um "voltar ao padrão" clicado sem querer são **irreversíveis** — a única saída é sair sem salvar e perder tudo o que veio depois. É a maior fricção de uso diário do construtor hoje, e é 0-dep.

**Entra:**
1. Pilha de histórico (desfazer/refazer) sobre o documento do editor, com **coalescing** para digitação não virar 1 undo por tecla.
2. Botões desfazer/refazer no topo global (o chassi do item 16c) + atalhos `Ctrl+Z` / `Ctrl+Shift+Z` / `Ctrl+Y`.
3. Operações de teclado que faltam: **duplicar** (`Ctrl+D`), **copiar/colar** (`Ctrl+C`/`Ctrl+V`, área de transferência interna do editor), **Escape** limpa seleção.
4. Extração do bloco `Shortcuts`/`Actions` (hoje inline no `EditorWorkspace`) para um widget dedicado, com a **guarda de foco em campo de texto** que hoje não existe.

**Fica fora:** histórico de versões salvas no servidor (isso é o item 24 — outra coisa: aquilo é histórico *publicado*, isto é histórico *da sessão de edição*), undo de operações da tela do projeto (já existe via snackbar) e undo cross-conteúdo.

## 2. Precedências — o que já existe e será usado (nada aqui é inventado)

Levantado no código em 2026-08-13:

| O que | Onde | Como será usado |
| --- | --- | --- |
| `EditorCubit` com campos privados de mecânica (`_idSequence`, `_noticeSequence`) e `_emitDocument(...)` como **funil único** de toda mutação do documento | `modules/editor_module/presentation/editor/cubit/editor_cubit.dart` | O funil `_emitDocument` é onde o snapshot entra. Nenhuma mutação escapa dele — exceto `updateSafeAreaProps`, que hoje emite direto (ver F1, passo 3). |
| `EditorReady` (`sealed`, `Equatable`) com `copyWith` de campo nullable por função-getter | `.../cubit/editor_state.dart` | Ganha `canUndo`/`canRedo` (bool). |
| `ContentSpec` imutável + `Equatable`, com `copyWith(root: () => ...)` | `packages/sdui_core/lib/src/model/content_spec.dart` | O snapshot **é** a referência ao `ContentSpec` — as ops de árvore já são imutáveis e compartilham estrutura, então guardar 50 snapshots não copia 50 árvores. |
| `SaveIntent` / `DeleteIntent` + `Shortcuts`/`Actions` inline | `.../page/editor_intents.dart` e `.../page/editor_workspace.dart` (linhas 27–38) | Ponto de extensão dos atalhos novos; o bloco sai do `EditorWorkspace`. |
| `AppBarAction.icon({icon, onPressed, tooltip})` — `onPressed: null` desabilita, e o `==` estrutural ignora a identidade do closure (alimenta o dedupe do slot) | `core/widgets/app_shell/app_bar_action.dart` | Botões desfazer/refazer no topo global, sem widget novo. |
| `EditorTopRegistrar` publica `actions:` no `AppShellController` dentro de um `BlocBuilder<EditorCubit, EditorState>` | `.../page/editor_top_registrar.dart` | Lugar onde os dois botões entram. |
| `tree_ops.dart` puro: `findNode`, `findParent`, `attachNode`, `moveNode`, `removeNode`, `updateNodeProps`, `insertChild` | `packages/sdui_core/lib/src/ops/tree_ops.dart` | Base para a op nova de clonagem. |
| `resolveDrop(root, targetId, {movingNodeId})` → `DropAccepted(parentId, index, redirected)` / `DropRefused(refusal)` | `packages/sdui_core/lib/src/ops/drop_ops.dart` | **Colar reusa exatamente esta regra** — colar é um "drop" no nó selecionado. Zero regra nova de encaixe. |
| `defaultNode(type, {required id})` | `packages/sdui_core/lib/src/catalog/widget_catalog.dart:1105` | Não muda; a clonagem é outro caminho. |
| `EditorNotice` + `EditorNoticeKind` + `EditorStatusBar` (rodapé conta o desvio do último arraste) | `.../cubit/editor_notice*.dart`, `.../widgets/status_bar/` | Recados de "nada para desfazer" / "colado no ancestral" reusam o canal existente, sem SnackBar novo. |

**Nada neste plano chama algo que não exista ao fim da fase anterior.** A ordem F1 → F2 → F3 é dura por isso: F2 usa `undo()`/`canUndo` criados na F1; F3 usa `cloneWithNewIds` da F3a e o `EditorShortcuts` da F2.

## 3. Decisões de design travadas (e o porquê)

**D1 — A pilha mora no cubit, os booleanos moram no estado.**
`_past`/`_future` são campos **privados do `EditorCubit`**, na mesma linha de `_idSequence`/`_noticeSequence`. O `EditorReady` ganha só `canUndo`/`canRedo`. Motivo: se as listas entrassem no estado, o `props` do `Equatable` compararia duas listas de até 50 documentos **a cada emit** — exatamente o tipo de custo que o item 3b foi feito para matar. Com booleanos, o `BlocSelector` do topo só reconstrói quando a capacidade muda.

**D2 — Coalescing por chave, sem relógio.**
Digitar "Olá" no Inspector chama `updateProps` 3× e não pode virar 3 undos. Cada entrada de histórico carrega uma `coalesceKey` (`'props:<nodeId>:<propKey>'`); se a **próxima** mutação tem a mesma chave da entrada no topo, ela **substitui** o topo em vez de empilhar. Qualquer outra operação (selecionar outro nó, arrastar, adicionar) empilha normal e quebra a sequência.
Descartado: janela de tempo (`DateTime.now()`), porque tornaria o cubit dependente de relógio e o teste não-determinístico — o projeto não tem injeção de clock e este item não é a hora de introduzir uma.
Consequência aceita: digitar 10 letras, clicar em outro nó e voltar a digitar gera 2 entradas, não 1. É o comportamento que o usuário espera.

**D3 — O snapshot guarda documento **e** seleção.**
Desfazer um "adicionar nó" tem que devolver a seleção anterior, e desfazer para um documento onde o nó selecionado não existe mais não pode deixar `selectedNodeId` apontando para o vazio (`EditorReady.selectedNode` já devolve `null` nesse caso, mas o Inspector piscaria vazio sem explicação). O snapshot é um par.

**D4 — Colar não inventa regra de encaixe: é `resolveDrop`.**
`paste()` resolve o destino com `resolveDrop(root, selectedId ?? root.id)` e, se `redirected`, emite o mesmo `EditorNoticeKind.dropRedirected` que o arraste emite. Um único lugar decide onde um nó pode entrar — a regra que o item 8e estabeleceu.

**D5 — A área de transferência é interna e vive no cubit, não no SO.**
`_clipboard` é um `SduiNode?` privado. Não usamos `Clipboard.setData` (texto do SO) nesta fatia: colar entre abas/documentos exigiria serializar, validar o JSON de volta pelo kernel e tratar spec de outra versão — vira o dobro do escopo. Registrado como evolução futura no §9.

**D6 — Limite de 50 entradas.** Descarta a mais antiga (`removeAt(0)`). Motivo: teto de memória previsível; 50 é o suficiente para uma sessão de trabalho e é o default que editores parecidos usam.

**D7 — `undo` reconcilia o `saveStatus`.**
Se o documento restaurado for **igual** (`==`, e `ContentSpec` é `Equatable`) ao último documento efetivamente salvo, o status volta a `SaveStatus.saved`; senão vira `dirty`. Sem isso, desfazer até o começo deixaria o editor dizendo "não salvo" com o documento idêntico ao do servidor.

## 4. Fases

Legenda: **[∥]** paralelizável com outra fase da mesma linha.

---

### F1 — Kernel do histórico no `EditorCubit` (sem UI)

**Por quê.** Toda a mecânica precisa existir e estar testável antes de qualquer botão ou atalho apontar para ela. Fase sem UI = PR pequeno e verificável por teste de cubit.

**Arquivos a criar:**

- **`apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_history_entry.dart`** — classe `EditorHistoryEntry` (imutável, `Equatable`).
  Campos: `final ContentSpec document`, `final String? selectedNodeId`, `final String? coalesceKey`.
  Construtor `const EditorHistoryEntry({required this.document, this.selectedNodeId, this.coalesceKey})`.
  Sem lógica — é um par nomeado. Fica em arquivo próprio pelo Gate 3 (uma classe por arquivo); **não** entra como `part of` do cubit porque não é subestado do `sealed`.

**Arquivos a modificar:**

- **`.../cubit/editor_state.dart`** — em `EditorReady`:
  - dois campos novos `final bool canUndo` e `final bool canRedo`, ambos `= false` no construtor;
  - entram no `copyWith` (tipo `bool?`, sem função-getter — não são nullable) e no `props`.
  - **Nada mais muda aqui.** `selectedNode` e `diagnostics` seguem derivados.

- **`.../cubit/editor_cubit.dart`**:
  1. Campos privados novos, junto de `_idSequence`:
     ```
     final List<EditorHistoryEntry> _past = [];
     final List<EditorHistoryEntry> _future = [];
     SduiNode? _clipboard;                 // usado só na F3
     ContentSpec? _lastSavedDocument;
     static const int _maxHistory = 50;
     ```
  2. **`_pushHistory(EditorReady current, {String? coalesceKey})`** — privado. Regra:
     - se `_past.isNotEmpty && coalesceKey != null && _past.last.coalesceKey == coalesceKey` → **não empilha** (a entrada do topo já representa o estado "antes" desta sequência de digitação);
     - senão empilha `EditorHistoryEntry(document: current.document, selectedNodeId: current.selectedNodeId, coalesceKey: coalesceKey)`;
     - `if (_past.length > _maxHistory) _past.removeAt(0)`;
     - `_future.clear()` — mutação nova mata o "refazer" (comportamento padrão de editor).
  3. **`_emitDocument(...)` ganha um parâmetro nomeado `String? coalesceKey`** e chama `_pushHistory(current, coalesceKey: coalesceKey)` **antes** do `emit`. Como todas as mutações de árvore passam por ele (`addNode`, `moveNode`, `addNodeAt`, `moveNodeAt`, `removeNode`, `updateProps`), o histórico fica completo por construção.
     - Só `updateProps` passa `coalesceKey`; monta-a com as chaves do `patch`: `'props:$id:${patch.keys.join(",")}'`.
  4. **`updateSafeAreaProps` emite direto hoje** (linhas 208–219) e escaparia do histórico. Passa a chamar `_pushHistory(current, coalesceKey: 'safeArea:${patch.keys.join(",")}')` antes do `emit`, com os mesmos `canUndo/canRedo` no `copyWith`. **Este é o ponto fácil de esquecer** — está listado explicitamente por isso.
  5. **`undo()`** público:
     - `if (state is! EditorReady || _past.isEmpty) return;` (opcional: `_emitNotice(current, EditorNoticeKind.nothingToUndo)` — ver F2, item do enum);
     - empilha o estado atual em `_future` (com a `coalesceKey` do topo de `_past`, para o redo colapsar igual);
     - `final entry = _past.removeLast();`
     - emite `current.copyWith(document: entry.document, selectedNodeId: () => entry.selectedNodeId, saveStatus: _statusFor(entry.document), canUndo: _past.isNotEmpty, canRedo: true, notice: () => null)`.
  6. **`redo()`** — espelho exato de `undo()`, trocando as pilhas.
  7. **`_statusFor(ContentSpec document)`** privado → `document == _lastSavedDocument ? SaveStatus.saved : SaveStatus.dirty` (D7).
  8. **`loadContent`** passa a limpar as pilhas (`_past.clear(); _future.clear();`) e a registrar `_lastSavedDocument = content` antes de emitir `EditorReady`. Sem isso, reabrir um conteúdo herdaria o histórico do anterior.
  9. **`save()`** registra `_lastSavedDocument = current.document` no caminho de sucesso (dentro do `fold`/`isRight`), **antes** do `emit` final. Não mexe nas pilhas.
  10. Todo `emit` de `EditorReady` que hoje existe precisa carregar `canUndo`/`canRedo` coerentes. Para não espalhar isso por 10 lugares: `_emitDocument` e `undo`/`redo` são os únicos que mudam as pilhas, então basta eles setarem os dois booleanos; os demais (`selectNode`, `changeDevice`, `changeZoom`, `save`) usam `copyWith` e **herdam** os valores atuais — correto por construção.

**Passo a passo (ordem de execução dentro da fase):**
1. Criar `EditorHistoryEntry` (não depende de nada).
2. Adicionar `canUndo`/`canRedo` no `EditorReady` — `flutter analyze` já deve continuar verde (campos com default).
3. Adicionar campos privados + `_pushHistory` + `_statusFor` no cubit.
4. Plugar `_pushHistory` no `_emitDocument` e no `updateSafeAreaProps`.
5. Escrever `undo()`/`redo()`.
6. Ajustar `loadContent` e `save()`.

**Critério de aceite (validável no papel, antes de codar):**
- Toda mutação do documento passa por `_emitDocument` **ou** por `updateSafeAreaProps` — confirmado por leitura: não há outro `emit` que troque `document` no cubit hoje.
- `undo()` com pilha vazia é no-op seguro (não emite, não quebra).
- Nenhum `emit` novo fora de `EditorReady` (o `sealed` continua exaustivo).
- Nenhuma dependência nova no `pubspec.yaml`.

**Riscos e regressões:**
- **R1.** `EditorReady.props` cresce em 2 campos → o `BlocBuilder` do `EditorPage` usa `buildWhen: previous.runtimeType != current.runtimeType`, então não é afetado; o `EditorTopRegistrar` reconstrói e é justamente o que queremos. Os painéis usam `BlocSelector` — não afetados.
- **R2.** Se alguém adicionar no futuro um `emit` de documento fora do funil, o histórico ganha buraco silencioso. Mitigação: comentário de **porquê** no `_emitDocument` (permitido pela regra de comentários: é invariante não-óbvia) e o teste `editor_cubit_test.dart` de F4 que cobre cada mutação.

---

### F2 — Atalhos, guarda de foco e botões no topo  **[∥ com F3a]**

**Por quê.** Sem tecla e sem botão, o kernel da F1 é invisível. Esta fase também **corrige um risco latente**: hoje o `Shortcuts` do `EditorWorkspace` mapeia `Delete` globalmente, e atalhos novos como `Ctrl+D` não são interceptados pelo `EditableText` — ou seja, apertar `Ctrl+D` com o cursor num campo do Inspector duplicaria o nó em vez de digitar. A guarda entra junto.

**Arquivos a criar:**

- **`.../presentation/editor/page/editor_shortcuts.dart`** — `class EditorShortcuts extends StatelessWidget`, recebe `required this.child`. Encapsula o par `Shortcuts` + `Actions` que hoje está inline no `EditorWorkspace` (linhas 27–38) e acrescenta os novos. Lê o cubit por `context.read<EditorCubit>()`.
  Mapa de atalhos:
  | Tecla | Intent | Ação |
  | --- | --- | --- |
  | `Ctrl+S` | `SaveIntent` (existe) | `cubit.save()` |
  | `Delete` | `DeleteIntent` (existe) | `cubit.removeSelected()` |
  | `Ctrl+Z` | `UndoIntent` | `cubit.undo()` |
  | `Ctrl+Shift+Z` e `Ctrl+Y` | `RedoIntent` | `cubit.redo()` |
  | `Ctrl+D` | `DuplicateIntent` | `cubit.duplicateSelected()` (chega na F3) |
  | `Ctrl+C` | `CopyNodeIntent` | `cubit.copySelected()` (F3) |
  | `Ctrl+V` | `PasteNodeIntent` | `cubit.paste()` (F3) |
  | `Escape` | `ClearSelectionIntent` | `cubit.selectNode(null)` |

  **Guarda de foco** — um getter privado no widget:
  ```
  bool get _isEditingText =>
      FocusManager.instance.primaryFocus?.context?.widget is EditableText;
  ```
  usado dentro de cada `CallbackAction.onInvoke` das ações que colidem com edição de texto (`Delete`, `Ctrl+D`, `Ctrl+C`, `Ctrl+V`, `Escape`): retorna `null` sem agir quando `true`. `Ctrl+S`, `Ctrl+Z` e `Ctrl+Y` **não** levam guarda — salvar e desfazer com o cursor no campo é o que o usuário espera (e o `EditableText` já trata o `Ctrl+Z` do próprio texto antes, por estar mais fundo na árvore).
  > O comentário de **porquê** vai aqui: por que a guarda existe (colisão com `EditableText`), não o que a linha faz.

**Arquivos a modificar:**

- **`.../page/editor_intents.dart`** — cinco `Intent`s novos, cada um `const` e vazio, no mesmo arquivo dos dois existentes: `UndoIntent`, `RedoIntent`, `DuplicateIntent`, `CopyNodeIntent`, `PasteNodeIntent`, `ClearSelectionIntent`.
  > **Exceção consciente ao Gate 3** (uma classe por arquivo): o arquivo já é uma **família de Intents** agrupados, no mesmo espírito do `*_enum.dart` que a regra permite. Se a revisão preferir, quebrar em `page/intents/*.dart` com barrel — decidir na `revisar-fase`, não bloqueia.
- **`.../page/editor_workspace.dart`** — remove o `Shortcuts`/`Actions`/`Focus` inline e passa a montar `EditorShortcuts(child: Scaffold(...))`. O `Focus(autofocus: true)` migra para dentro do `EditorShortcuts` (é parte do mecanismo de teclado, não do layout). **Arquivo encolhe** — bom sinal.
- **`.../page/editor_top_registrar.dart`** — no `actions:` publicado, **antes** do botão Salvar:
  ```
  AppBarAction.icon(icon: Icons.undo, tooltip: 'Desfazer (Ctrl+Z)',
      onPressed: state.canUndo ? cubit.undo : null),
  AppBarAction.icon(icon: Icons.redo, tooltip: 'Refazer (Ctrl+Shift+Z)',
      onPressed: state.canRedo ? cubit.redo : null),
  ```
  `onPressed: null` desabilita e o `==` estrutural do `AppBarAction` já considera `(other.onPressed == null) == (onPressed == null)` — então o slot só republica quando a **capacidade** muda, não a cada tecla. Isso não é sorte: é o motivo pelo qual D1 colocou `canUndo/canRedo` no estado como bool.
- **`.../cubit/editor_notice_kind.dart`** — (opcional, decidir na fase) `nothingToUndo`/`nothingToRedo`. **Recomendação: não adicionar.** Botão desabilitado + atalho no-op já comunicam; um recado no rodapé a cada `Ctrl+Z` extra vira ruído. Se adicionar, o `EditorNoticeMessage` precisa do texto correspondente — não esquecer o `switch` exaustivo.

**Passo a passo:**
1. Criar os `Intent`s (nada depende deles ainda).
2. Criar `EditorShortcuts` mapeando **só** os atalhos cujas ações já existem (`save`, `removeSelected`, `undo`, `redo`, `selectNode(null)`).
3. Trocar o `EditorWorkspace` para usar o widget novo → `flutter analyze` verde, comportamento atual preservado.
4. Adicionar os dois `AppBarAction.icon` no registrar.
5. **Só então** (ou na F3, se paralelizar) plugar `Ctrl+D`/`Ctrl+C`/`Ctrl+V` — ver "ordem de instanciação" abaixo.

**Ordem de instanciação (a regra de não chamar o que não existe):**
Se F2 e F3 forem PRs paralelos, o `EditorShortcuts` da F2 **não pode** referenciar `cubit.duplicateSelected()`/`copySelected()`/`paste()` — eles nascem na F3. Duas saídas, escolher uma no início da fase:
- **(a) recomendada** — F2 entrega só os atalhos de métodos existentes; F3 acrescenta as três linhas do mapa + os três `Intent`s. O acoplamento fica num arquivo só e o conflito de merge é trivial.
- (b) F2 declara os `Intent`s e deixa as ações fora do mapa até a F3 — pior, porque deixa `Intent` órfão no repo.

**Critério de aceite:**
- Com foco num campo de texto do Inspector: `Delete` apaga caractere (não o nó); `Ctrl+D` não duplica; `Ctrl+C` copia texto.
- Sem foco em campo: `Delete` apaga o nó selecionado (comportamento atual preservado).
- Botão desfazer nasce desabilitado num conteúdo recém-aberto e habilita depois da primeira mutação.
- Nenhum `SnackBar` novo; nenhuma cor/spacing hardcoded (Gate 4) — os botões vêm do `AppBarAction`, que já é temado.

**Riscos e regressões:**
- **R3 — o `Focus(autofocus: true)` migrando de lugar.** Se ele sair de cima do `Scaffold`, atalhos podem parar de chegar. Mitigação: manter a mesma posição relativa (`EditorShortcuts` envolve o `Scaffold`, com o `Focus` interno) e validar no E2E manual antes de fechar a fase.
- **R4 — `Ctrl+Y` no navegador.** Em Chrome, `Ctrl+Y` não é reservado (diferente de `Ctrl+W`/`Ctrl+T`); `Ctrl+Shift+Z` também é livre. `Ctrl+S` já é interceptado hoje sem problema — precedente resolvido.
- **R5 — Web + `MacOS`.** `SingleActivator(..., control: true)` não pega `Cmd` no macOS. O editor é Flutter Web e o público-alvo hoje é o dev no Linux/Chrome; registrar como polimento (usar `meta: true` em paralelo) e **não** bloquear a fase.

---

### F3a — Op de clonagem no kernel  **[∥ com F2]**

**Por quê.** Duplicar e colar precisam de uma subárvore com **ids novos** — colar o mesmo id duas vezes quebraria `findNode`, a seleção e o `ValueKey` do renderer. Isso é operação pura de árvore: mora no `sdui_core`, não no editor. Fase minúscula e 100% testável sem Flutter.

**Arquivos a modificar:**
- **`packages/sdui_core/lib/src/ops/tree_ops.dart`** — função nova, ao lado das existentes:
  ```
  SduiNode cloneWithNewIds(SduiNode node, String Function() nextId)
  ```
  Recursiva: devolve `node.copyWith(id: nextId(), child: () => node.child == null ? null : cloneWithNewIds(node.child!, nextId), children: [for (final c in node.children) cloneWithNewIds(c, nextId)])`. `properties` e `events` são reaproveitados por referência (são imutáveis por contrato do `SduiNode`).
  Sem export novo: `tree_ops.dart` já é exportado inteiro por `sdui_core.dart` (linha 16).

**Critério de aceite:** dado um nó com filho e netos, o clone tem a mesma forma, mesmos `properties`/`events`, e **nenhum** id em comum com o original (verificável coletando os ids das duas árvores e cruzando os conjuntos).

> **Segundo cliente desta função (revisão cruzada de 2026-08-13):** o item 21 (componentes) usa `cloneWithNewIds` na expansão do componente no momento do publish. Se o item 21 for executado **antes** deste, a função nasce lá e esta fase some — conferir antes de começar. A assinatura acordada é a mesma nos dois planos.

**Riscos:** nenhum sobre código existente — é função nova, ninguém chama ainda. É exatamente por isso que ela pode ir em paralelo com a F2.

---

### F3 — Duplicar, copiar e colar no cubit (+ ligação nos atalhos)

**Precedência dura:** exige `cloneWithNewIds` (F3a) e o `EditorShortcuts` (F2).

**Por quê.** São as três operações que o usuário tenta fazer por reflexo e hoje não existem — reconstruir um card com 6 filhos à mão é o tipo de tarefa que faz abandonar a ferramenta.

**Arquivos a modificar:**

- **`.../cubit/editor_cubit.dart`** — três métodos públicos novos, todos seguindo o padrão dos existentes (`state is! EditorReady` → return; `root == null` → return):
  1. **`void copySelected()`** — `_clipboard = current.selectedNode` (o `EditorReady.selectedNode` já resolve o nó a partir do id). Não emite estado — copiar não muda documento. **Mas** o usuário precisa de retorno visual: emitir um `EditorNotice` de `nodeCopied` (novo valor no `EditorNoticeKind` + texto no `EditorNoticeMessage`, ambos com `switch` exaustivo a atualizar).
  2. **`void duplicateSelected()`** — sem clipboard: pega `selectedNode`, recusa se for a raiz (`_emitNotice(current, EditorNoticeKind.rootNotMovable)` já existe e serve — ou um `rootNotDuplicable` novo, decidir na fase), clona com `cloneWithNewIds(node, () => _nextNodeId(root))`, descobre o pai com `sdui.findParent(root, node.id)`, insere **logo depois do original** com `sdui.attachNode(root, parent.id, indexDoOriginal + 1, clone)` e seleciona o clone.
     > `_nextNodeId(root)` já garante unicidade contra a árvore atual, mas é chamado várias vezes durante a clonagem — como ele incrementa `_idSequence` a cada chamada, os ids saem distintos entre si. **Invariante a verificar no código**: `_nextNodeId` usa `microsecondsSinceEpoch` + `_idSequence++`, então duas chamadas no mesmo microssegundo ainda diferem pelo sequence. OK.
  3. **`void paste()`** — se `_clipboard == null`, no-op (ou notice `clipboardEmpty`). Senão: alvo = `selectedNodeId ?? root.id`; `switch (sdui.resolveDrop(root, alvo))` exatamente como `addNode` faz — `DropRefused` emite o notice traduzido por `_kindOf`; `DropAccepted` clona (`cloneWithNewIds`), faz `attachNode(root, parentId, index, clone)`, seleciona o clone e propaga `redirected` como `EditorNoticeKind.dropRedirected`.
     - **Caso da raiz vazia:** se `root == null`, colar vira "o nó colado é a nova raiz" — mesmo caminho que `addNode` já tem para `root == null`. Tratar explicitamente, senão `paste()` num conteúdo vazio não faz nada e parece bug.
  4. `_clipboard` **não** é limpo por `loadContent` — copiar num conteúdo e colar em outro na mesma sessão é comportamento desejável e sai de graça. Registrar a decisão.

- **`.../cubit/editor_notice_kind.dart`** + **`.../widgets/status_bar/editor_notice_message.dart`** — os valores novos (`nodeCopied`, e o que a fase decidir para clipboard vazio/raiz). **Atenção:** o `switch` do `EditorNoticeMessage` é exaustivo — adicionar valor no enum **quebra o build** até tratar. Isso é proteção, não problema.
- **`.../page/editor_shortcuts.dart`** — plugar `DuplicateIntent`/`CopyNodeIntent`/`PasteNodeIntent` nas ações (com a guarda `_isEditingText`).

**Passo a passo:**
1. `copySelected` (mais simples, não mexe em árvore).
2. `duplicateSelected` (usa `findParent` + `attachNode`, já existentes).
3. `paste` (usa `resolveDrop`, já existente).
4. Ligar os três no `EditorShortcuts`.
5. Adicionar item "Duplicar" no menu de contexto da árvore **se** já houver um — checar `widget_tree/tree_row.dart` na hora; **se não houver, não criar menu novo nesta fase** (escopo).

**Critério de aceite:**
- Duplicar um `card` com 3 filhos gera um irmão logo abaixo, com 4 ids novos, e a seleção vai para o clone.
- Colar sobre um `text` (que não recebe filhos) **não** cancela: sobe para o primeiro ancestral que recebe e o rodapé conta o desvio — mesma regra do arraste (item 8e).
- Cada uma das três operações é **uma** entrada de histórico (passam por `_emitDocument`, sem `coalesceKey`).

**Riscos:**
- **R6 — id duplicado.** Se `cloneWithNewIds` for chamado com um gerador que colida com a árvore, `findNode` passa a achar o nó errado. Mitigação: o gerador é sempre `() => _nextNodeId(root)`, que já testa contra a árvore. Teste dedicado na F4.
- **R7 — clipboard com nó de outro spec.** Fora de escopo por D5 (clipboard interno, mesma sessão, mesmo catálogo). Se o item 24/25 introduzir specs de versões diferentes na mesma sessão, revisitar.

---

### F4 — Bateria automatizada (por último, após o E2E manual)

Conforme o método: só depois do E2E atestado.

- **`apps/driva_editor/test/modules/editor_module/presentation/editor/cubit/editor_cubit_test.dart`** (arquivo **existe** — acrescentar grupos, não recriar): `bloc_test` para undo/redo (empilha, desfaz, refaz), coalescing (3 `updateProps` na mesma prop = 1 undo), `_future` limpo por mutação nova, teto de 50, `saveStatus` voltando a `saved` (D7), duplicar/copiar/colar, e o caso "colar em alvo que não recebe filhos redireciona".
- **`packages/sdui_core/test/ops/tree_ops_test.dart`** (existe): grupo para `cloneWithNewIds` — forma preservada, ids todos novos, props/events preservados.
- **Widget test novo** `.../presentation/editor/page/editor_shortcuts_test.dart`: com foco em `EditableText`, `Ctrl+D` não chama o cubit; sem foco, chama. Usa `mocktail` (`MockEditorCubit extends MockCubit<EditorState> implements EditorCubit`), padrão já usado no repo.

## 5. Mapa de paralelismo

```
F1 ──────────────► F2 ──────────► F3 ──► F4
      │              ▲             ▲
      └── F3a ───────┴─────────────┘
```
- **F1 e F3a podem começar juntos** (pessoas/agentes diferentes): uma mexe só no editor, a outra só no kernel — zero arquivo em comum.
- **F2 depende só da F1** (precisa de `undo()`/`canUndo`).
- **F3 é o encontro** das duas linhas.
- **F4 é serial e final** por regra de método.

Sugestão de PRs: `feature/<issue>-historico-editor-kernel` (F1), `feature/<issue>-clone-subtree` (F3a), `feature/<issue>-atalhos-editor` (F2), `feature/<issue>-duplicar-colar` (F3). Cada um verde na CI antes do próximo.

## 6. Impacto em planos anteriores / posteriores

Este é o **primeiro** plano da série — não há anterior a contradizer. Para os posteriores, ficam registradas as pegadas que eles precisam respeitar:

- **Item 24 (publicação).** Vai acrescentar campos ao `EditorReady` (status de publicação) e provavelmente um `publish()` no cubit. **Contrato a manter:** `publish()` não pode mexer nas pilhas de histórico, e o `_lastSavedDocument` da D7 passa a ter um irmão (`_lastPublishedDocument`) — o plano 24 já assume isso no seu §2.
- **Item 28 (eventos/ações).** Vai editar `node.events` pelo Inspector. Se usar `updateProps`, ganha histórico de graça; se criar um `updateEvents`, **tem que passar pelo `_emitDocument`** ou abre buraco no histórico. Registrado no plano 28.
- **Item 30 (breakpoints).** Se props virarem "props por breakpoint", a `coalesceKey` da D2 precisa incluir o breakpoint ativo, senão editar a mesma prop em dois breakpoints colapsa em uma entrada só. Registrado no plano 30.
- **Item 21 (aba Componentes).** Instância de componente é um nó como outro qualquer; `cloneWithNewIds` funciona sem mudança, **desde que** a referência ao componente viva em `properties` (e não no `id`). Registrado no plano 21.
- **Item 29 (contexto de dados) — melhoria de assinatura, decidida na revisão cruzada de 2026-08-13.** A F3 daquele plano precisa que o funil aceite mudanças no `ContentSpec` que **não** são no `root` (parâmetros e fontes de dados). A saída limpa é `_emitDocument` receber **`ContentSpec` inteiro** em vez de `SduiNode? newRoot`.
  **Recomendação: já nascer assim aqui.** Fica `void _emitDocument(EditorReady current, ContentSpec document, {Object? selectedNodeId, EditorNotice? notice, String? coalesceKey})`, e cada chamador monta `current.document.copyWith(root: () => newRoot)`. Ganho imediato: o `updateSafeAreaProps` (passo 4 da F1) deixa de ser caso especial e passa pelo funil como todo mundo — **o buraco de histórico some por construção em vez de por lembrança**. Custo: seis chamadas a ajustar, todas no mesmo arquivo.

## 7. Definition of Done

- [ ] `flutter analyze` verde no workspace inteiro.
- [ ] `flutter test` (editor) e `dart test` (sdui_core) existentes passando, mais os grupos novos da F4.
- [ ] E2E manual: desfazer/refazer por botão e por tecla; digitação longa no Inspector desfaz em bloco; duplicar/colar; `Delete`/`Ctrl+D` com foco em campo de texto **não** afetam a árvore.
- [ ] Gates de design: nenhuma função que retorna `Widget` (G1), widget novo em arquivo próprio no tier certo (G2/G3), zero cor/spacing hardcoded (G4).
- [ ] `CHANGELOG.md` › `Unreleased` atualizado no mesmo PR de cada fase.
- [ ] `docs/roadmap.md`: item 23 marcado `[x]` no fechamento.
