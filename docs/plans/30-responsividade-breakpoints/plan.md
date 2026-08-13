# plan.md — Item 30: Responsividade — variação de props por breakpoint

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Track contínuo.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend** (o spec é JSONB opaco).
> **Sem dependências duras, mas com uma janela ideal:** fazer **antes do item 20** (componentes). Depois dele, cada componente existente precisaria ser revisitado.

## 1. Objetivo e recorte

O editor tem três presets de dispositivo (`DevicePreset.smartphone/android/tablet`) e molduras realistas (item 6), mas o **spec descreve uma tela só**: o mesmo `padding: 16` e a mesma `column` vão para celular e para tablet. Um produto de SDUI que atende app de celular **e** tablet sem alternativa entrega a mesma tela esticada nos dois — que é exatamente o que ninguém quer.

**Entra:**
1. O conceito de **breakpoint** no kernel (nomes, larguras, resolução).
2. **Override de prop por breakpoint** no spec, aditivo e opcional.
3. Resolução no renderer (a partir da largura disponível, não do preset do editor).
4. No editor: um seletor de "qual breakpoint estou editando", com o Inspector mostrando de onde cada valor vem (herdado ou sobrescrito) e permitindo sobrescrever/limpar.

**Fica fora:** layouts estruturalmente diferentes por breakpoint (trocar `column` por `row`, esconder subárvore) — ver D3 e §7; orientação (retrato/paisagem); densidade/plataforma.

## 2. Decisões

**D1 — Três breakpoints nomeados, fixos no kernel.**
`enum SduiBreakpoint {compact, medium, expanded}` com limiares em largura: `compact < 600`, `medium 600–1023`, `expanded ≥ 1024`. São os limiares do Material 3 — nomes que Flutter developers já conhecem, e evita inventar vocabulário.
Fixos (não configuráveis por projeto) na primeira versão: configurável multiplicaria a superfície e não há caso pedindo.

**D2 — Override aditivo dentro das próprias props do nó, sob uma chave reservada.**
```json
{ "id": "nd_1", "type": "container",
  "props": {
    "padding": {"all": 16},
    "@medium": { "padding": {"all": 24} },
    "@expanded": { "padding": {"all": 32} }
  } }
```
- O valor **base** (fora das chaves `@`) é o `compact` — mobile-first, e o que qualquer spec existente já é.
- `@medium`/`@expanded` carregam **só** o que muda.
- **Resolução em cascata:** `expanded` procura em `@expanded` → `@medium` → base. Assim declarar só `@medium` já melhora tablet e desktop.

Por que dentro de `props` e não num campo irmão (`overrides`): o nó não muda de forma, o schema não muda de contrato, e **spec antigo continua válido sem migração** — a mesma estratégia que `safeArea` (item 8f) e `params` (item 29) usaram. Custo: o prefixo `@` vira reservado no espaço de nomes de props. Nenhuma prop atual começa com `@` (verificado no catálogo), e o descriptor pode barrar no futuro.

**D3 — Só props variam. Estrutura, não.**
Trocar `column` por `row` ou esconder um nó por breakpoint **não entra**. Motivo: seria uma segunda árvore por breakpoint, com todos os problemas de sincronização (mover um nó em compact e não em expanded), e o editor precisaria de três canvas.
**A saída que cobre 80% dos casos sem isso:** a prop `direction` do `wrap`, o `crossAxisCount` do `gridView` e as dimensões (`DimensionValue`, que já aceita px/%/preencher) resolvem a maioria dos layouts responsivos reais **variando por breakpoint**. Se um caso exigir estrutura diferente, a resposta hoje é: dois conteúdos com slugs diferentes.

**D4 — No runtime, o breakpoint vem da largura real disponível — não do dispositivo.**
`LayoutBuilder` no topo do `SduiView` resolve a largura e publica o breakpoint num `InheritedWidget`. Motivo: um app pode renderizar SDUI num painel lateral de 400px num tablet de 1200px; o que importa é a caixa, não o aparelho.

**D5 — A resolução por breakpoint acontece ANTES da resolução de binding.**
Ordem em `_SduiNodeView.build`: (1) achatar props do breakpoint ativo → (2) resolver `{{bindings}}` → (3) chamar o builder.
Motivo: um override pode conter um binding (`"@expanded": {"content": "{{param.tituloLongo}}"}`), e o contrário não faz sentido. **Esta ordem é acordo firmado com o item 29** — ver §6.

## 3. Precedências

| O que | Onde | Uso |
| --- | --- | --- |
| `SduiNode.properties` (mapa livre) e `copyWith` | `sdui_core/lib/src/model/sdui_node.dart` | Onde os overrides moram (D2). |
| `node_schema.dart` preserva `props` inteiro (não filtra chaves) | `sdui_core/lib/src/schema/node_schema.dart:8` | **Overrides sobrevivem ao parse sem mudança de schema** — confirmar no teste. |
| `_SduiNodeView.build` (um `StatelessWidget` por nó) | `sdui_flutter/lib/src/renderer.dart:50` | Ponto único de achatamento (D5). |
| `DimensionValue` (px / % / preencher) e `AlignmentValue` | `sdui_core/lib/src/model/` | Já resolvem parte da responsividade **sem** breakpoint — a base sobre a qual isto soma. |
| `DevicePreset` (largura/altura/recuo por preset) e `CanvasToolbar` | `editor_module/.../device_preset.dart`, `.../canvas/canvas_toolbar.dart` | O preset do canvas passa a **derivar** o breakpoint ativo. |
| `InspectorPropList` + `PropFieldEditor` + `PropResetButton` ("voltar ao padrão") | `.../widgets/inspector/`, `.../prop_field/` | O botão de reset já existe e vira o "limpar override" — mesma UI, significado adjacente. |
| `EditorCubit.updateProps(id, patch)` → `updateNodeProps` (merge, `null` remove) | `.../cubit/editor_cubit.dart:199`, `sdui_core/.../tree_ops.dart:95` | Precisa de uma variante que escreve **dentro** do bloco `@bp` (F3). |

## 4. Fases

### F1 — Kernel: breakpoint e achatamento  **[base]**

- **`sdui_core/lib/src/model/sdui_breakpoint.dart`** (novo) — o enum da D1 + `static SduiBreakpoint forWidth(double)` + `String get overrideKey` (`'@medium'`) + `List<SduiBreakpoint> get fallbackChain`.
- **`sdui_core/lib/src/ops/breakpoint_ops.dart`** (novo) —
  ```dart
  Map<String, dynamic> flattenProps(Map<String, dynamic> properties, SduiBreakpoint bp);
  ```
  Aplica a cascata da D2 e **remove** as chaves `@*` do resultado. Devolve **o mesmo mapa por referência** quando não há nenhuma chave `@` (otimização idêntica à do item 29 — o caso comum não aloca).
  Mais: `bool hasOverride(props, bp, propKey)` e `Map<String,dynamic> setOverride(props, bp, propKey, value)` — usados pelo editor, mas puros e testáveis aqui.
- **`sdui_core.dart`** — exports.

**Aceite:** props sem `@` passam idênticas (mesma referência); `expanded` sem `@expanded` cai em `@medium`; sem nenhum, cai no base; chave `@` desconhecida (`@foo`) é **ignorada**, não quebra.

### F2 — Renderer: resolver pela largura  **[depende de F1]**

- **`sdui_flutter/lib/src/layout/sdui_breakpoint_scope.dart`** (novo) — `InheritedWidget` com o breakpoint corrente; `static SduiBreakpoint of(context)` com default `compact` (mantém tudo que existe funcionando).
- **`sdui_flutter/lib/src/sdui_view.dart`** — envolve a árvore num `LayoutBuilder` que calcula o breakpoint pela `maxWidth` e publica no scope (D4). Parâmetro `SduiBreakpoint? forcedBreakpoint` para o **editor** forçar o breakpoint do canvas independentemente do tamanho real do palco.
- **`sdui_flutter/lib/src/renderer.dart`** — em `_SduiNodeView.build`, achatar antes de tudo (D5).

**Aceite:** os goldens existentes (`renderer_golden_test.dart`) passam **sem alteração** (prova de aditividade); teste novo: mesmo nó desenha padding 16 em 500px e 32 em 1200px.

### F3 — Editor: editar por breakpoint  **[depende de F1+F2]**

- **`.../cubit/editor_state.dart`** — `EditorReady` ganha `final SduiBreakpoint editingBreakpoint` (default `compact`).
- **`.../cubit/editor_cubit.dart`** — `void changeBreakpoint(SduiBreakpoint)`; e `updateProps` passa a escrever **no bloco do breakpoint ativo** quando ele não é o base, via `setOverride` (F1). **Continua passando pelo `_emitDocument`** (contrato do item 23).
- **`.../widgets/canvas/canvas_toolbar.dart`** — seletor de breakpoint. **Decisão de UX:** amarrar ao `DevicePreset` (escolher tablet muda o breakpoint) **ou** deixar independente? O plano recomenda **derivar do preset por default, com override manual** — dois controles independentes confundem, mas às vezes é preciso ver `expanded` numa moldura pequena.
- **`.../widgets/inspector/prop_field_shell.dart`** (ou onde o rótulo da prop é montado — **confirmar**) — indicar visualmente o estado de cada prop: **herdado** (do base/medium) ou **sobrescrito aqui**. Ícone + texto no tooltip, nunca só cor (acessibilidade).
- **`.../widgets/prop_field/prop_reset_button.dart`** — no modo breakpoint, "voltar ao padrão" vira **"remover override"** (apaga a chave do bloco `@bp`, o valor volta a ser herdado). Rótulo e tooltip mudam conforme o contexto.

**Aceite:** editar padding em `medium` **não** altera o valor em `compact`; a prop sobrescrita aparece marcada; remover o override devolve o valor herdado; o JSON do painel (item 7/8) mostra exatamente o formato da D2.

### F4 — Testes
Kernel: `breakpoint_ops_test.dart` (cascata, referência preservada, chave desconhecida). Renderer: o teste de largura da F2 + goldens intocados. Editor: `editor_cubit_test.dart` (escrita no bloco certo, remoção de override) + widget test da marcação no Inspector.

## 5. Mapa de paralelismo

```
F1 ──┬─► F2 ──► F3 ──► F4
     └─────────┘   (F3 pode começar assim que F1 existir, se o canvas usar forcedBreakpoint só no fim)
```

## 6. Impacto nos outros planos (revisão cruzada)

- **Item 29 (dados) — ordem acordada e registrada nos dois planos:** achatamento de breakpoint **antes** da resolução de binding (D5). Os dois itens acrescentam uma transformação no **mesmo** ponto (`_SduiNodeView.build`); se cada um inventar sua camada, o renderer ganha duas passagens concorrentes e a ordem vira acidente. **Quem chegar primeiro deixa o ponto preparado para o segundo** (uma função `_effectiveProperties(node, context)` que aplica as transformações em sequência).
- **Item 21 (componentes) — obrigação:** a expansão do componente no publish **copia os nós inteiros**, incluindo as chaves `@*`. Como `cloneWithNewIds` usa `copyWith` preservando `properties` por referência, isso funciona **de graça** — mas precisa de teste explícito, senão um refactor futuro pode achatar props na expansão e matar a responsividade dos componentes. Anotado no plano 21.
- **Item 23 (histórico) — obrigação:** a `coalesceKey` de `updateProps` (`'props:$id:${patch.keys}'`) **precisa incluir o breakpoint ativo**, senão editar a mesma prop em `compact` e depois em `medium` colapsa numa entrada só de histórico e o `Ctrl+Z` desfaz as duas. Já registrado no plano 23 §6.
- **Item 9 (catálogo) — decisão herdada:** todo `PropField` passa a poder ter override, ou só um subconjunto (tamanho/espaçamento/direção)? O plano assume **todos** (simples e previsível); se virar poluição visual no Inspector, restringir por um flag no `PropField` (`isResponsive`). Anotado no plano 9.
- **Item 24 (publicação)** — overrides viajam na versão publicada. Nenhum trabalho extra.
- **Item 8f (área segura)** — `ContentSpec.safeArea` **não** ganha override por breakpoint nesta fatia (o recuo do sistema já é dinâmico por dispositivo). Registrado para não virar dúvida.

## 7. Perguntas para o humano

1. **Três breakpoints Material (D1) atendem?** A alternativa comum é dois (celular/tablet).
2. **Executar antes do item 20 (componentes)?** Recomendo **sim**, pela janela: depois, cada componente existente precisa ser revisitado para ganhar overrides.
3. **Estrutura por breakpoint (D3) é mesmo dispensável no primeiro momento?** Se o caso "menu vira gaveta no celular" for obrigatório desde já, este item cresce muito e precisa de outro desenho.
