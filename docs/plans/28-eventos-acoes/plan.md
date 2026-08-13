# plan.md — Item 28: Eventos e ações editáveis no Inspector

> Documento de planejamento. Dono na execução: **tech-lead** + **especialista-apresentacao**. Base: `docs/roadmap.md` › Marco 7.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend** (o spec é JSONB opaco — o backend não sabe o que é uma ação, e continua não sabendo).
> **Precedência recomendada: item 25 entregue.** Sem app cliente, uma ação editável não tem quem a execute — o editor não executa ações por regra do projeto (`CLAUDE.md`: "Binding `{{prop}}` e ações são **dados** — o editor não os executa").

## 1. Objetivo e recorte

O kernel já tem o vocabulário de ação e o renderer já sabe despachar:

```dart
// packages/sdui_core/lib/src/model/sdui_action.dart  → SduiAction {type, params}
// packages/sdui_flutter/lib/src/renderer.dart:39      → SduiRenderer.dispatch(Object? actions)
// packages/sdui_flutter/lib/src/builders/button.dart:10
final onPressed = enabled ? () => r.dispatch(node.events['onPressed']) : null;
```

E `SduiNode.events` existe, é serializado (`sdui_node.dart:49`) e sobrevive ao parse. **O que não existe é qualquer forma de escrever isso.** Nenhum editor, nenhum catálogo de eventos por widget, nenhum catálogo de ações. Um botão montado no editor sai com `events: {}` e é inerte para sempre.

**Entra:**
1. **Catálogo de eventos por widget** (`WidgetDescriptor.events`) — quais gestos cada primitivo oferece.
2. **Catálogo de ações** (`actionCatalog`) — o que uma ação pode fazer, com seus parâmetros **descritos como `PropField`**, reaproveitando inteiro o editor de propriedades já construído no item 9b.
3. **Aba "Eventos" no Inspector** — lista os eventos do widget selecionado, cada um com sua fila de ações (adicionar, reordenar, remover, editar parâmetros).
4. **Renderer despachando** os eventos de gesto nos widgets que fazem sentido.
5. **Showcase** (item 25) implementando um handler de exemplo, que é a prova de que a ação chega ao outro lado.

**Fica fora — recorte deliberado (ver D4):** eventos de **valor** (`onChanged` de `textField`/`switch`/`checkbox`/`slider`/`dropdown`), porque exigem estado de formulário em runtime — isso é o item 29. Também fora: ação `callApi` (idem), condicionais ("se X então Y"), e execução de ação **dentro** do editor (proibida por regra).

## 2. Precedências

| O que já existe | Onde | Uso |
| --- | --- | --- |
| `SduiAction {type, params}` com `fromJson` tolerante (aceita `action` ou `type`) e `toJson` gravando `action` | `sdui_core/lib/src/model/sdui_action.dart` | **Formato travado — não mudar.** O editor grava exatamente o que o `fromJson` lê. |
| `SduiNode.events` (`Map<String, dynamic>`), no `copyWith`, no `toJson` e no `props` | `sdui_core/lib/src/model/sdui_node.dart:19` | Onde as ações moram. Nada a mudar no modelo. |
| `SduiRenderer.dispatch(Object? actions)` — espera uma **`List`** de mapas e chama `onAction` para cada | `sdui_flutter/lib/src/renderer.dart:39` | Define o formato: `events['onPressed']` é uma **lista** de ações, executadas em ordem. |
| `node_schema.dart` preserva `props`/`events` mesmo com o `z.map` só devolvendo chaves declaradas | `sdui_core/lib/src/schema/node_schema.dart:8` | Eventos sobrevivem ao round-trip de parse **hoje** — confirmar no teste. |
| `PropField {key, kind, label, group, options, min, max, helpText, defaultValue, isRequired, isAdvanced, isBindable}` + `FieldKind` com 10 tipos | `sdui_core/lib/src/catalog/prop_field.dart` | **Descreve os parâmetros das ações.** É o reaproveitamento central deste plano. |
| `PropFieldEditor` + os 20 editores de `prop_field/` (string, enum, ícone, cor, dimensão, alinhamento, binding…) | `editor_module/.../widgets/prop_field*` | Editam os parâmetros das ações **sem uma linha nova de editor**. |
| `InspectorPanel` (header + `InspectorPropList`) e `InspectorVm` | `.../widgets/inspector_panel.dart`, `.../page/inspector_vm.dart` | Ganham a segunda aba. |
| `EditorCubit.updateProps` + funil `_emitDocument` | `.../cubit/editor_cubit.dart:199` | Gabarito para `updateEvents`. |
| `tree_ops.updateNodeProps(root, id, patch)` + `_rebuild` | `sdui_core/lib/src/ops/tree_ops.dart:95` | Gabarito para `updateNodeEvents`. |
| `DrivaContent(onAction:)` já no contrato público do runtime | `packages/driva_client` (item 25) | O outro lado já está pronto para receber. |

## 3. Decisões travadas

**D1 — Formato no spec (travado pelo `dispatch` e pelo `SduiAction`):**
```json
"events": {
  "onPressed": [
    { "action": "navigate", "params": { "slug": "detalhes" } },
    { "action": "showMessage", "params": { "text": "Abrindo…", "tone": "info" } }
  ]
}
```
Lista, sempre — mesmo com uma ação só. Ordem = ordem de execução. Chave `action` (não `type`) porque é o que o `SduiAction.toJson` já grava.

**D2 — Eventos são declarados no `WidgetDescriptor`, como as props.**
`WidgetDescriptor` ganha `final List<EventField> events`, default `const []`. `EventField {key, label, helpText?}`. Motivo: a regra do projeto é "paleta, inspector e defaults derivam 100% do `widget_catalog.dart`" — evento hardcoded no Inspector quebraria isso. Widget novo com evento novo = uma linha no descriptor, zero código no editor.

**D3 — Parâmetros de ação são `PropField`.**
`ActionDescriptor {type, label, iconName, category, fields: List<PropField>}`. O editor de uma ação é literalmente o mesmo `PropFieldEditor` da aba de propriedades, com os mesmos estados, o mesmo "voltar ao padrão" e o mesmo botão de binding (`isBindable`) — que já prepara o terreno do item 29 sem nenhum trabalho extra.
> Este é o motivo pelo qual este item é muito mais barato do que parece: **90% da UI já foi construída no item 9b.**

**D4 — Só eventos de gesto nesta fatia.**
`onPressed`/`onTap`/`onLongPress`. Eventos de valor (`onChanged`) exigem que o widget tenha **estado** em runtime (o valor digitado, o switch ligado) e que a ação possa ler esse valor — isso é contexto de dados, item 29. Tentar os dois juntos dobra o escopo e mistura duas discussões.
Consequência visível: no Inspector, um `textField` selecionado mostra a aba Eventos **vazia com explicação** ("eventos de valor chegam com o contexto de dados"), não uma aba escondida — o usuário precisa saber que existe e que ainda não está lá.

**D5 — Ações da primeira leva (4):**
| type | label | params (`PropField`) | quem executa |
| --- | --- | --- | --- |
| `navigate` | Abrir conteúdo | `slug` (string, obrigatório), `replace` (bool, avançado) | app cliente |
| `openUrl` | Abrir link | `url` (string, obrigatório), `external` (bool) | app cliente |
| `showMessage` | Mostrar mensagem | `text` (string, obrigatório, bindable), `tone` (enum: info/success/warning/error) | app cliente |
| `goBack` | Voltar | — | app cliente |
Nenhuma delas é executada pelo editor. `callApi` fica para o item 29 (precisa de dados e de tratamento de resposta).

**D6 — O editor não valida semântica de ação, só forma.**
Se o `slug` do `navigate` apontar para um conteúdo que não existe, **isso não é erro de edição** — o conteúdo pode ser criado depois, ou existir só em produção. O que o editor faz: um **aviso** (não erro) no `diagnoseTree` quando o slug referenciado não existe no projeto aberto. Aviso não bloqueia publicar (item 24, D5). Coerente com a filosofia do item 8e: "o editor deixa soltar onde quiser e lista o que ficou fora do lugar".

**D7 — O runtime não ganha dependência para executar ação.**
`driva_client` **não** adiciona `url_launcher` nem navegação opinativa. Ele entrega `SduiAction` tipada ao `onAction` do app. Quem sabe navegar é o app. O **showcase** implementa um handler completo como referência copiável. Motivo: um SDK que impõe router/launcher é rejeitado pelo primeiro cliente que já tem os seus.

## 4. Fases

### F1 — Kernel: catálogo de eventos e de ações  **[∥ com F2]**

**Arquivos a criar em `packages/sdui_core/lib/src/catalog/`:**
- **`event_field.dart`** — `class EventField extends Equatable {final String key; final String label; final String? helpText;}`.
- **`action_descriptor.dart`** — `class ActionDescriptor extends Equatable {final String type; final String label; final String iconName; final List<PropField> fields;}` + `PropField? fieldOf(String key)` no mesmo estilo do `WidgetDescriptor.fieldOf`.
- **`action_catalog.dart`** — `const List<ActionDescriptor> actionCatalog = [...]` (as 4 da D5) + `ActionDescriptor? actionDescriptorFor(String type)` (espelho de `descriptorFor`).

**Arquivos a modificar:**
- **`widget_descriptor.dart`** — `final List<EventField> events;` com default `const []`; entra no `props`.
- **`widget_catalog.dart`** — declarar os eventos nos primitivos da D4:
  `button` → `onPressed`; `container` e `card` → `onTap`; `image` e `icon` → `onTap`.
  > **Verificar ao implementar:** o `button` já lê `node.events['onPressed']` no builder, então esta chave **precisa** ser exatamente `onPressed` — mudar o nome quebraria o único evento que já funciona.
- **`ops/tree_ops.dart`** — `SduiNode updateNodeEvents(SduiNode root, String id, Map<String, dynamic> patch)`, cópia fiel de `updateNodeProps` trocando `properties` por `events` (merge; valor `null` remove a chave).
- **`sdui_core.dart`** — exportar `event_field.dart`, `action_descriptor.dart`, `action_catalog.dart`.

**Critério de aceite:** `dart test` do `sdui_core` passa; um `SduiNode` com `events` sobrevive a `toJson`→`parseNode` sem perder nada (teste novo em `content_schema_test.dart`/`node` — **verificar se já existe**; o comentário do `node_schema.dart:8` afirma que sim).

**Risco:** `WidgetDescriptor.props` muda (campo novo) → `widget_catalog_test.dart` pode ter asserts de igualdade que quebram. Trabalho trivial, mas contar com ele.

---

### F2 — Renderer: despachar os gestos  **[∥ com F1 se os nomes de evento estiverem congelados]**

**Arquivos a modificar em `packages/sdui_flutter/lib/src/builders/`:**
- **`container.dart`**, **`card.dart`**, **`image.dart`**, **`icon.dart`** — embrulhar o widget construído em `GestureDetector(onTap: node.events['onTap'] == null ? null : () => r.dispatch(node.events['onTap']), child: ...)`.
  > **Só embrulhar quando há evento** — `onTap: null` num `GestureDetector` é inofensivo, mas o widget extra na árvore não é: muda hit-testing e pode capturar toque destinado a um filho. Construir o `GestureDetector` condicionalmente.
- **`button.dart`** — nada a fazer (já despacha).
- **Exceção de gate registrada:** estes arquivos são os *builders do registry*, explicitamente **fora** do Gate 1 (`CLAUDE.md` › Design system).

**Critério de aceite:** widget test em `packages/sdui_flutter/test/` — nó `container` com `events.onTap` chama `onAction` uma vez por toque, com o `SduiAction` certo; sem `events`, nenhum `GestureDetector` extra na árvore (`find.byType(GestureDetector)` conta zero).

---

### F3 — Editor: aba Eventos no Inspector

**Precedência dura:** F1 (catálogos e `updateNodeEvents`).

**Arquivos a modificar:**
- **`.../cubit/editor_cubit.dart`** — `void updateEvents(String id, Map<String, dynamic> patch)`, espelho de `updateProps`, chamando `sdui.updateNodeEvents` e passando pelo **`_emitDocument`**.
  > **Contrato do item 23:** passar pelo funil é o que dá desfazer/refazer de graça. Se este método emitir direto, abre buraco no histórico. Registrado no plano 23 §6 e repetido aqui de propósito.
  > `coalesceKey`: **não** usar. Mexer em ação é operação discreta, não digitação contínua — cada mudança é um passo de undo. Exceção: o campo de texto de um parâmetro (ex.: `url`) — aí sim usar `'event:$id:$eventKey:$index:$paramKey'` para não gerar um undo por tecla.
- **`.../page/inspector_area.dart`** e **`.../widgets/inspector_panel.dart`** — o corpo do painel vira `TabBar`/`TabBarView` de duas abas ("Propriedades", "Eventos") **quando há nó selecionado**. Sem nó (modo Página, do item 8f), continua só a lista da área segura — página não tem eventos nesta fatia.
  > **Cuidado com rebuild:** a aba selecionada é estado **local** do painel (`StatefulWidget` pequeno), nunca do cubit — trocar de aba não pode reconstruir canvas nem árvore (regra de escopo mínimo).
- **`.../page/inspector_vm.dart`** — nada muda: o `InspectorVm` já carrega o `node` inteiro, e `node.events` vem junto. **Confirmado por leitura.** (O `==` compara `node`, que é `Equatable` e inclui `events` no `props` — então mudar um evento **já** invalida o VM corretamente.)

**Arquivos a criar em `.../widgets/inspector/events/`:**
- **`event_list.dart`** — `InspectorEventList`: recebe `node`, `descriptor.events`, `onUpdateEvents`; uma seção por `EventField`.
- **`event_section.dart`** — um evento: título (label do `EventField`), a fila de ações e o botão "Adicionar ação".
- **`action_tile.dart`** — uma ação da fila: ícone + label, alça para reordenar, menu remover, e expansão com os `PropFieldEditor` dos `fields` do `ActionDescriptor`.
- **`action_picker_dialog.dart`** — escolher o tipo de ação (lista do `actionCatalog`, com ícone e descrição).
- **`empty_events_message.dart`** — o estado vazio explicativo da D4.

**Reaproveitamento obrigatório (não reimplementar):** `PropFieldEditor` para cada parâmetro; `ReorderableListView` para a fila; `RowIconButton` (`core/widgets/buttons/`) para as ações de linha; tokens de `core/theme/` para tudo.

**Critério de aceite:**
- Selecionar um `button` → aba Eventos mostra "Ao tocar" com fila vazia e botão adicionar.
- Adicionar `navigate`, preencher `slug`, ver o JSON do painel de preview (item 7/8) mostrar exatamente o formato da D1.
- Reordenar duas ações muda a ordem no JSON.
- Remover a última ação de um evento **remove a chave** do `events` (não deixa `"onPressed": []` no spec).
- Um `text` selecionado → aba Eventos com a mensagem da D4, não uma aba quebrada.
- Desfazer (`Ctrl+Z`, item 23) reverte a adição de uma ação.

---

### F4 — Diagnóstico de slug inexistente (D6)  **[∥ com F5]**

**Arquivos a modificar:**
- **`sdui_core/lib/src/diagnostics/spec_diagnostic.dart`** — `DiagnosticCode.unknownNavigateTarget`.
- **`sdui_core/lib/src/diagnostics/diagnose_ops.dart`** — `diagnoseTree` ganha um parâmetro **opcional** `Set<String> knownSlugs = const {}`; com o conjunto vazio (default), **não** emite este diagnóstico.
  > O default vazio é o que preserva compatibilidade: `EditorReady.diagnostics` chama `diagnoseTree(document.root)` hoje sem argumento, e o kernel é Dart puro — não pode buscar slugs sozinho.
- **`editor_module/.../cubit/editor_state.dart`** — `EditorReady` ganha `final Set<String> knownSlugs` (vindo do cubit, que os recebe da lista de conteúdos do projeto ao abrir) e passa para o `diagnoseTree`.
  > **Precedência a respeitar:** isso exige que o editor conheça os slugs do projeto. O `EditorCubit` hoje **não** carrega a lista de conteúdos. Duas opções: (a) `LoadContentUseCase` passa a devolver também os slugs do projeto — mexe no contrato; (b) o `EditorPage.pageBuilder` já tem acesso ao `getIt` e poderia buscar via `GetContentsUseCase` do `contents_module`. **(b) viola a regra** "nenhum módulo importa o interno de outro" a menos que passe pelo barrel público — `contents_module.dart` exporta o quê? **Verificar antes de decidir.** Se o barrel não expõe o use case, a opção correta é **(a)**.
  > **Se essa checagem mostrar que custa caro, cortar a F4 inteira.** Ela é o item de menor valor do plano e não bloqueia nada.

---

### F5 — Showcase: handler de referência  **[∥ com F4]**

**Precedência dura:** item 25 (o app existe).

**Arquivos a modificar em `apps/driva_showcase/`:**
- `lib/action_handler.dart` — `void handleDrivaAction(BuildContext context, SduiAction action)` com `switch (action.type)` cobrindo as 4 ações da D5: `navigate` troca o slug da tela, `openUrl` mostra um diálogo com a URL (sem `url_launcher`, D7), `showMessage` usa `SnackBar`, `goBack` usa `Navigator.maybePop`.
- `README.md` do showcase — este handler é **o exemplo que o cliente copia**; documentar como tal.

---

### F6 — Testes (por último)

- `sdui_core`: `action_catalog_test.dart` (todo descriptor tem type único; todo `PropField` de ação tem label e group), `tree_ops_test.dart` (+`updateNodeEvents`), round-trip de `events` no schema.
- `sdui_flutter`: dispatch por gesto (F2), e o teste de que **sem** evento não há `GestureDetector`.
- Editor: `editor_cubit_test.dart` (+`updateEvents` gera histórico), widget test do `InspectorEventList` (adicionar/remover/reordenar, e a remoção que apaga a chave).
- **Golden**: acrescentar um caso ao `inspector_prop_list_golden_test.dart` ou criar `inspector_events_golden_test.dart` — a aba nova é visual.

## 5. Mapa de paralelismo

```
F1 (kernel) ─┬─► F3 (inspector) ─┬─► F6 (testes)
             │                    │
F2 (renderer)┘                    │
                       F4 (diagnóstico) ─┤
                       F5 (showcase) ────┘
```
- **F1 e F2 em paralelo** desde que os nomes de evento (`onPressed`, `onTap`) estejam congelados — estão, na D5/F1.
- **F4 e F5 são folhas independentes**; F4 é cortável.

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 23 (histórico) — contrato honrado:** `updateEvents` passa pelo `_emitDocument` (F3). A `coalesceKey` de parâmetro de texto usa um formato **diferente** do de props (`event:` vs `props:`), então não há colisão de chave entre editar uma prop e editar um parâmetro de ação do mesmo nó. **Verificado.**
- **Item 24 (publicação) — compatível.** Ações inválidas geram **aviso**, e avisos não bloqueiam publicar (D5 de lá). Se a operação quiser que slug inexistente **bloqueie**, é mudar a severidade na F4 — e aí o plano 24 muda junto. **Não fazer isso sem decisão explícita:** transformaria "publicar" em refém de um conteúdo que talvez só exista em produção.
- **Item 25 (entrega) — dependência satisfeita e reforçada:** o `onAction` do `DrivaContent` foi colocado no contrato **desde a primeira versão** do package justamente para este item não exigir breaking change. Confirmado no plano 25 §6.
- **Item 29 (dados) — fronteira definida aqui:** eventos de valor e `callApi` ficam lá. O plano 29 **precisa** reaproveitar `ActionDescriptor`/`actionCatalog` desta fatia em vez de criar um segundo mecanismo. Três costuras acertadas na revisão cruzada de 2026-08-13:
  1. **`diagnoseTree` muda de assinatura nos dois planos** (aqui quer `knownSlugs`, lá quer o `ContentSpec` inteiro). **Fazer uma vez só, no item que chegar primeiro:** `diagnoseTree(ContentSpec spec, {Set<String> knownSlugs = const {}})`. Se este item vier primeiro, já adotar essa forma na F4 em vez da versão com só `knownSlugs`.
  2. **`TabBar` do Inspector:** este plano põe abas no modo **nó** (Propriedades/Eventos); o 29 põe no modo **página** (Área segura/Dados). **Extrair um `InspectorTabs` reutilizável** em `inspector/` — quem chegar segundo faz a extração, quem chegar primeiro já deixa o widget separado se for barato.
  3. **`dispatch` resolvendo params:** o 29 acrescenta a resolução de binding nos params da ação, no momento do dispatch. É **aditivo** sobre o que esta fase entrega — nada aqui precisa antecipar isso.
- **Item 9 (catálogo) — nova obrigação:** todo primitivo novo com gesto passa a declarar `events` no descriptor. O plano 9 (processo "como adicionar um widget") tem que citar isso, senão widgets novos nascem sem evento silenciosamente.

## 7. Definition of Done

- [ ] `flutter analyze` verde; `dart test`/`flutter test` verdes nos 3 pacotes + editor.
- [ ] JSON gerado no painel de preview bate exatamente com a D1.
- [ ] E2E manual: montar botão com 2 ações no editor → publicar (item 24) → showcase reage às duas, na ordem.
- [ ] Nenhum editor de propriedade novo foi escrito (se foi, o reaproveitamento da D3 falhou — revisar).
- [ ] `CHANGELOG.md` › `Unreleased`; `docs/28-eventos-acoes/final_report.md`.
- [ ] `docs/roadmap.md`: item 28 `[x]`.

## 8. Perguntas para o humano

1. **`navigate` aponta para slug de conteúdo ou para rota do app do cliente?** O plano assume **slug de conteúdo** (o driva conhece), com o app traduzindo para a sua navegação. A alternativa (rota nativa do app) é mais flexível e menos verificável.
2. **A fila de ações precisa de condicional já ("só executa se…")?** Assumido que não — vira item próprio depois do 29.
3. **Aba ou seção?** O plano assume **abas** no Inspector. Se você preferir uma seção colapsável no fim da lista de propriedades (menos clique, mais rolagem), é uma troca de F3 sem impacto no resto.
