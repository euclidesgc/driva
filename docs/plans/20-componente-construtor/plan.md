# plan.md — Item 20: Componente com construtor próprio

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 8.
> **Precedência dura: item 19** (o `kind` existe em kernel/backend/editor, e a aba Componentes lista e cria).
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**.

## 1. Objetivo e recorte

O item 19 criou o **lugar**. Este cria o **construtor**: abrir um componente leva ao mesmo editor de três painéis, com as diferenças que fazem um componente ser componente — e não uma tela.

**Entra:**
1. Rota e abertura do componente no editor, com o construtor sabendo que está editando um componente.
2. As três diferenças de comportamento: **sem área segura**, **canvas em modo peça** (não tela cheia de dispositivo) e **parâmetros do componente**.
3. Publicação do componente (herda o item 24 sem trabalho).

**Fica fora:** usar o componente dentro de um conteúdo (item 21 — inclusive o nó `component` no catálogo e a expansão no publish), ícone/imagem/vitrine (item 22).

## 2. As três diferenças (e o porquê de cada uma)

**Δ1 — Componente não tem área segura.**
`ContentSpec.safeArea` é **chrome de página** (item 8f): descreve onde a tela começa em relação a notch e barra do sistema. Uma peça reutilizável que carrega `SafeArea` própria produziria recuo duplicado ao ser inserida dentro de uma página que já tem o seu. Então: no modo componente, o Inspector **não** mostra a aba/seção de área segura, e o `safeArea` do spec fica vazio (e o renderer não embrulha).

**Δ2 — O canvas mostra a peça, não o aparelho.**
Um componente não ocupa a tela: renderizá-lo dentro da moldura de iPhone com o resto vazio engana sobre o tamanho real. No modo componente o canvas mostra a peça sobre um fundo neutro, com largura ajustável (um controle "largura do palco") para o usuário ver como ela se comporta em 360 / 768 / largura livre. Os presets de dispositivo somem da toolbar; o zoom fica.

**Δ3 — Componente tem parâmetros.**
O que torna um componente reutilizável de verdade é receber dados de quem o insere (título, imagem, rótulo do botão). Isso é **exatamente** o mecanismo de `ContentParam` do item 29.
> **Bifurcação que precisa de decisão (§7):**
> - **Se o item 29 já estiver entregue:** o componente reusa `ContentSpec.params` e o binding `{{param.titulo}}` sem nenhum mecanismo novo. **É o caminho recomendado.**
> - **Se o 29 não estiver entregue:** entregar o componente **sem parâmetros** (peça estática) e adiar Δ3. Um componente estático já tem valor (cabeçalho padrão, rodapé, card de oferta fixo).
> **Não criar um "parâmetro de componente" paralelo ao `ContentParam`** — seriam dois mecanismos concorrentes para a mesma coisa, e o item 29 teria que unificá-los depois.

## 3. Precedências

| O que | Onde | Uso |
| --- | --- | --- |
| `ContentKind` no kernel, coluna `kind`, filtro na API, aba na tela do projeto | item 19 | Base. |
| `EditorRoutes.editor = '/projects/:projectId/contents/:id/edit'` (`GoRoute` com `EditorPage.pageBuilder`) | `editor_module/editor_routes.dart` | A rota **não muda por causa deste item** (é o mesmo id, na mesma tabela). O modo vem do spec carregado. O `:projectId` entrou no path pelo item 46, não por aqui. |
| `EditorCubit` + `EditorReady.document` como fonte única | `.../cubit/editor_cubit.dart` | `document.kind` já diz o modo — **nenhum parâmetro novo de rota é preciso**. |
| `CanvasToolbar(device, zoom, onChangeDevice, onChangeZoom)` e `DeviceFrame` | `.../widgets/canvas/` | Ganham o modo peça. |
| `InspectorPanel` no modo Página (edita `safeArea`) | `.../widgets/inspector_panel.dart:34` | No modo componente, mostra parâmetros (ou nada). |
| `SduiView.content(spec)` que embrulha em `SduiSafeArea` quando `safeArea != null` | `sdui_flutter/lib/src/sdui_view.dart:53` | O construtor cru `SduiView(node:)` **já** renderiza sem chrome — é o que o modo peça usa. **Nada a mudar no renderer.** |
| Publicação/versões (item 24) | backend + editor | Funciona igual para componente. |

## 4. Fases

### F1 — Modo componente no editor (Δ1 + Δ2)

**Arquivos a modificar:**
- **`.../cubit/editor_state.dart`** — `EditorReady` ganha `bool get isComponent => document.kind == ContentKind.component;` (derivado, não guardado).
- **`.../widgets/inspector_panel.dart`** — sem nó selecionado **e** `isComponent`: mostra o painel de parâmetros (F2) ou o estado vazio explicativo; **não** mostra área segura.
  > O `InspectorPanel` recebe hoje `safeArea` e `onUpdateSafeAreaProps` por construtor. Acrescentar um `bool isComponent` **ou** — melhor — trocar os dois por um objeto `InspectorPageMode` selado (`PageChrome(safeArea, onUpdate)` / `ComponentParams(...)`). A segunda opção evita o par de campos que só valem em um dos modos. Decidir na fase; o plano recomenda a segunda.
- **`.../page/canvas_area.dart`** e **`.../widgets/canvas/canvas.dart`** — no modo componente, montar `ComponentStage` no lugar do `DeviceFrame`.
- **`.../widgets/canvas/component_stage.dart`** (novo) — fundo neutro (token de `EditorColors`), largura controlada, a peça centralizada com `SduiView(node: root)` **sem** `safeArea`.
- **`.../widgets/canvas/canvas_toolbar.dart`** — no modo componente, troca o `SegmentedButton` de dispositivos por um seletor de largura do palco (360 / 768 / livre). **Extrair dois widgets** (`DeviceSelector` e `StageWidthSelector`) em vez de encher a toolbar de `if` — Gate 1/3.
- **`.../cubit/editor_cubit.dart`** — `void changeStageWidth(double)`, espelho de `changeZoom` (inclusive o `clamp`). Guardar em `EditorReady.stageWidth`.
- **`.../page/editor_top_registrar.dart`** — o breadcrumb e o rótulo mudam ("Componente" em vez de "Conteúdo"); o botão Publicar continua igual.

**Aceite:** abrir um componente mostra o palco e nenhuma moldura de aparelho; o Inspector de página não oferece área segura; abrir um conteúdo continua **exatamente** como hoje (regressão coberta pelos goldens existentes do canvas).

### F2 — Parâmetros do componente (Δ3) — **condicional ao item 29**

**Se o item 29 estiver entregue:**
- `.../widgets/inspector/data/page_data_panel.dart` (criado lá) é reaproveitado no modo componente, mostrando **só a seção Parâmetros** (componente não declara fontes de dados próprias — quem busca dado é a tela que o hospeda; ver D-abaixo).
- `EditorCubit.updateParams` já existe (item 29 F3).

> **Decisão travada:** componente **não** tem `dataSources` próprios. Motivo: um componente que busca dados sozinho vira uma tela dentro da tela — N instâncias fariam N requisições, e a página perde o controle do carregamento. Componente recebe dados **por parâmetro**. Se algum caso exigir o contrário, é discussão de produto, não de implementação.

**Se o item 29 não estiver entregue:** F2 **não acontece**; o painel mostra "Parâmetros chegam com o contexto de dados (item 29)" e o item 20 fecha só com Δ1+Δ2.

### F3 — Testes

- Widget test: modo componente esconde área segura e moldura; modo conteúdo mantém.
- Golden novo do `ComponentStage`.
- `editor_cubit_test.dart`: `changeStageWidth` com clamp; `isComponent` derivado do documento.

## 5. Mapa de paralelismo

```
F1 ──► F3
  └──► F2 (só se o item 29 estiver pronto; independente da F1 depois que o modo existe)
```

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 19 — herança direta**, nenhuma contradição.
- **Item 24 (publicação) — funciona sem mudança**, mas com uma consequência que o item 21 vai precisar: **publicar um componente não republica os conteúdos que o usam**. Isso é intencional (previsibilidade), e é a razão de o item 21 precisar de "onde é usado" + republicação em massa. **Anotado no plano 21.**
- **Item 29 (dados) — dependência opcional declarada** (Δ3). O plano 29 não precisa saber de componente; a relação é de mão única.
- **Item 23 (histórico)** — nenhum contato; o histórico funciona igual nos dois modos.
- **Item 8f (área segura)** — o comportamento entregue lá continua intacto para conteúdos. O modo componente é uma **exclusão**, não uma mudança.
- **Itens 28 e 29 — três planos mexem no mesmo widget, acertado na revisão cruzada de 2026-08-13.** O `InspectorPanel` é alvo de: abas no modo **nó** (28: Propriedades/Eventos), abas no modo **página** (29: Área segura/Dados) e o modo **componente** deste plano. Se cada um resolver do seu jeito, o arquivo vira uma pilha de `if`. **Acordo:** o modo do painel vira um `sealed class InspectorPageMode` (`PageChrome` / `ComponentParams`) — proposto na F1 daqui — e as abas usam um `InspectorTabs` comum, extraído por quem chegar segundo (acordo registrado nos planos 28 e 29). **Quem executar primeiro entre os três deixa a estrutura pronta para os outros dois.**

## 7. Perguntas para o humano

1. **Executar o item 20 antes ou depois do 29?** Depois é melhor (componente com parâmetro é o produto de verdade). Antes é possível e entrega valor menor.
2. **Larguras do palco:** 360/768/livre atende? Ou preferir uma régua contínua?
3. **Componente pode conter outro componente?** Assumido **sim**, com limite de profundidade a definir no item 21 (onde a expansão acontece) — aqui não muda nada.
