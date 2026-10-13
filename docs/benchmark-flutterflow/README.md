# Benchmark FlutterFlow → Driva

Estudo de referência (pasta de apoio, não numerada) para melhorar no Driva cinco frentes: **biblioteca de widgets**, **painel de propriedades por tipo**, **binding**, **componentes reutilizáveis** e **eventos/ações**. Observado em 2026-10-13 num projeto descartável ("Meu teste") do dono, logado por ele.

**O que se copia aqui:** padrões de interação e de modelo de dados. **O que não se copia:** código, ícones, textos e layout pixel a pixel do FlutterFlow. Nada do bundle `dart2js` foi descompilado.

## Fontes e método

| Fonte | O que dá | Onde |
|---|---|---|
| Documentação pública (docs.flutterflow.io) | o que o produto **declara** | [`fonte_docs_publicas.md`](fonte_docs_publicas.md) |
| Observação do app rodando | o que a UI **faz** | [`evidencias/`](evidencias/) — capturas `NN_*.jpg/png` + rótulos da árvore de acessibilidade em `*_texto_acessibilidade.txt` |

O FlutterFlow é Flutter Web em canvas. Ativando a camada de semântica (`flt-semantics-placeholder`), os rótulos de toda a UI viram texto, e é ela a evidência principal; as capturas saem em resolução reduzida e servem de apoio.

**Limite do REA nesta rodada.** O REA (`rea-agents@6.4.0`) foi registrado no Claude Code, mas a observação passiva de navegador dele exige um endpoint CDP local, que o navegador embutido do app não expõe, e o modo com navegador próprio exigiria login, que só o dono faz. A coleta foi feita pelo navegador embutido e **não há Evidence IDs do REA**. Para uma segunda rodada com o REA de fato: abrir o Chrome com `--remote-debugging-port=9222`, o dono loga, e o REA captura (`list_browser_targets` / `capture-web-screenshot`).

Convenção abaixo: **[obs]** = observado na UI (com o número da evidência), **[doc]** = só documentado, **[rec]** = recomendação nossa para o Driva.

## 1. Biblioteca de widgets e árvore

- **[obs 02]** São cerca de 100 widgets em 5 categorias (Commonly Used, Layout, Base, Page, Form), com busca (`Ctrl+F`). A primeira categoria repete os 6 mais usados.
- **[obs 01–02]** O widget **só entra arrastando**; o clique simples não insere, como hoje no Driva. Um contêiner vazio mostra no canvas um marcador de slot ("Example ↓ Column").
- **[obs 13]** O menu de contexto da árvore traz Duplicate, Insert, **Wrap** (`Ctrl+B`), **Replace**, **Remove Widget**, **Copy Widget Style**, **Convert to Component** e **Save as Template**, quase todos com atalho.
- **[obs 12]** Nó com ação ganha um ícone na árvore. Instância de componente tem ícone e cor próprios.
- **[doc]** Ao arrastar, a linha azul indica "entra como irmão" e a laranja "entra como filho". A doc também recomenda no máximo 10 níveis de aninhamento.

**[rec]**
- Manter só o arrastar.
- Acrescentar ao Driva o **marcador de slot vazio** no canvas e o **menu de contexto** com Wrap, Replace, Duplicate, Copiar estilo e Converter em componente.
- Acrescentar o **ícone de "tem ação"** na árvore.

## 2. Painel de propriedades — controle por tipo

**[obs 02, 03, 22–24]** O painel segue a mesma ordem para todo widget: cabeçalho (tipo + nome editável do nó) → **busca de propriedade** → **wrapper comum** (Visibility com Conditional e breakpoints, Opacity, Expansion, Padding, Alignment, Value Key) → **propriedades do tipo** → "Additional Flutter Properties", recolhido.

| Tipo | Controle no FlutterFlow | Driva hoje |
|---|---|---|
| Número | campo + ícone de variável; slider quando há faixa (Opacity) | campo + slider com min/max ✅ |
| Dimensão | campo + alternância **PX/%** + botão **∞** (valor `inf`); Min/Max W/H com o mesmo controle | px/%/preenche ✅ (falta Min/Max) |
| Cor | amostra + hex + limpar; o seletor tem tom/matiz/**alfa**/RGB e a **lista pesquisável de cores do tema** por papel (Primary, Secondary, Primary Text…) | flex_color_picker, sem cor de tema ❌ |
| Espaçamento | modo uniforme/por lado + diagrama T/L/R/B + reset | por lado ✅ |
| Alinhamento | X/Y numéricos + grade 3×3 + reset | grade 3×3 ✅ |
| Raio | uniforme/por canto + **4 campos em volta de um desenho de canto** + token do tema | ❌ |
| Borda | cor, largura, estilo (Solid…), **lados** (4 toggles) | ❌ |
| Sombra/gradiente | switch que expande o editor, com token do tema | ❌ |
| Tipografia | **estilo do tema como base** ("Body Medium · 14px") + sobrescritas: família, peso, I/U/S, tamanho, cor, altura de linha, espaçamento, alinhamento (4 botões), linhas máx., sombras | ❌ |
| Enum curto | botões segmentados com ícone (alinhamento de texto) | grupo de ícones ✅ |
| Enum longo | dropdown | dropdown ✅ |
| Booleano | switch | switch ✅ |
| Ícone | — (não observado) | dropdown só com nome ❌ |

### 2b. Anatomia do painel por widget (rodada 2, evidências 25–32)

Painel completo de 14 tipos em [`evidencias/25-32_painel_por_widget.txt`](evidencias/25-32_painel_por_widget.txt). O que se repete:

- **[obs]** **O painel muda inteiro conforme a seleção**, mas sempre na mesma ordem:
  1. wrapper comum;
  2. bloco "\<Tipo\> Properties";
  3. sub-blocos por *parte* do widget. O Button tem Text, Default Style, Disable, Hover e Icon. O TextField tem Text, Label, Hint, Input Decoration e Additional.
- **[obs]** **O estilo de texto é um editor composto reutilizado**: aparece igual no Text, no Button, no TextField (3 vezes: texto, label e hint), no DropDown, no RadioButton (normal e selecionado) e no Snack Bar.
- **[obs 26]** Os editores **trocam de forma pelo modo**:
  - o raio uniforme vira slider + campo, e o raio por canto vira 4 campos em volta de um desenho;
  - o padding é um diagrama L/T/R/B com **copiar/colar valor**, token e reset.
- **[obs 27]** Os **estados** são blocos ligados por switch:
  - "Disable Options" recebe uma condição booleana (binding), a opção "Preview in UI Builder" e as cores do estado;
  - "Hover Style" recebe preenchimento, borda, cor do texto/ícone e elevação.
- **[obs 30]** Há **editor de lista** nas opções do DropDown e do RadioButton:
  - cada item tem um campo, binding e botão de remover;
  - há "Add Option" e "Add Option Labels" (rótulo ≠ valor);
  - a lista inteira pode ser ligada a uma variável.
- **[obs 25, 31]** **Enums visuais** são botões de ícone: eixo principal (6), eixo cruzado (4), Box Fit (7), alinhamento de texto (4). Enums longos ficam em dropdown.
- **[obs 28]** O **ícone** é escolhido num modal com busca, abas por biblioteca (Material 8825 e Font Awesome 1606) e grade de prévias.
- **[obs 31]** A **imagem** traz o tipo de origem (Network/Asset…), o caminho com botão de busca, o Box Fit e um raio com slider.
- **[obs]** **Margin não é universal**: só aparece onde o widget a tem nativamente (DropDown, RadioButton). O espaço externo genérico é feito com o Padding do wrapper.
- **[obs]** As **cores padrão sempre apontam para um papel do tema** (Primary, Alternate, Info, Secondary Background, Error), nunca para hex.
- **[obs 32]** "Additional Flutter Properties" é um **editor de código Dart livre**. **Não se aplica a SDUI**, porque o renderer só desenha o que conhece.
- **[inconclusivo]** A seleção múltipla com Shift no canvas não funcionou nesta rodada; só a documentação afirma que ela existe.

### 2c. Editores dinâmicos (evidências 33–34 e [`evidencias/33-34_editores_dinamicos.txt`](evidencias/33-34_editores_dinamicos.txt))

O editor não tem forma fixa. Três mecanismos aparecem:

- **[obs] A forma muda com o modo do próprio editor.**
  - Padding "uniforme" é uma linha só, com slider + campo + variável. "Por lado" é o diagrama L/T/R/B.
  - O raio funciona igual: uniforme é slider; por canto são 4 campos em volta de um desenho.
- **[obs] O conjunto de campos muda com uma escolha anterior.**
  - Um switch revela um sub-editor: Disable, Hover, Box Shadow, Gradient.
  - O tipo do parâmetro decide se aparece "Default" ou "+ Add Parameter".
  - A fonte do binding decide se aparece "Available Options".
  - "Add Option Labels" revela um campo de rótulo por opção.
  - "Multiple conditions" troca a condição única por uma lista AND/OR.
- **[obs] Há resumo compacto e editor completo.** O estilo de texto mostra uma linha de resumo e abre o editor inteiro. As seções recolhem.
- **[não confirmado]** Layout que muda pela largura do painel: o painel não redimensionou nesta rodada.

**[rec]** Para o Driva:
- declarar no catálogo, e não no editor, **modos de editor** e **visibilidade condicional** (`visibleWhen` no `PropField`);
- cada editor ter **resumo compacto + forma expandida**.

**[rec]** O Driva já tem a base certa (`FieldKind` + `typed_prop_editor`). O que falta, em ordem de valor:
1. **Busca de propriedade** no topo do inspector.
2. **Wrapper comum** separado das propriedades do tipo.
3. Editores **raio por canto**, **borda**, **sombra** e **gradiente**.
4. **Estilo de texto com base no tema**.
5. Seletor de **ícone com prévia e busca** (item 49).
6. **Cor do tema** no seletor de cor, que depende do item 48.

## 3. Binding — "Set from Variable"

- **[obs 04]** O ícone de variável ao lado de cada propriedade abre um seletor **tipado** ("Type: String"), com busca e as fontes Page Parameters, Global Properties, Combine Text, Conditional Value, Inline Function, Custom Functions, Random/Sample Data e Custom Code Expression.
- **[obs 05]** O binding tem 4 partes:
  - a **fonte**;
  - uma **transformação** ("Available Options");
  - o **valor padrão** para quando a variável vem vazia;
  - o **"UI Builder Display Value"**, que é o que o canvas mostra na edição.
- **[obs 05]** No painel, o campo vira um **chip laranja** com o nome da fonte.
- **[obs 17]** Ao **remover** o binding, o campo volta ao literal anterior: o literal fica guardado por baixo.
- **[obs 17]** Fontes de tipo incompatível aparecem **desabilitadas**, e há "criar parâmetro" ali mesmo.
- **[obs 18]** A validação acontece no próprio diálogo: "A default value is required".
- **[obs 10]** **O mesmo seletor** serve à condição de uma ação ("Type: Boolean") e aos parâmetros de ação: é **um único seletor de expressão tipada para o produto inteiro**.

**[rec]** Este é o achado que estrutura todo o resto. Hoje o Driva guarda o binding como texto livre (`{{prop}}`). Modelar no `sdui_core` um **valor de propriedade com três formas** — literal | token do tema | binding `{source, path, transform?, default, preview}` — **preservando o literal** sob o binding. Esse único modelo serve a propriedades, parâmetros de ação, condições e parâmetros de componente, e é o centro do item 29.

## 4. Componentes reutilizáveis

- **[obs 13–14]** "Convert to Component" sobre um nó da árvore pede nome e descrição. A subárvore vira componente, abre num **editor próprio** (`?component=<Nome>`, canvas do tamanho do conteúdo) e, na página, é trocada por uma **instância**.
- **[obs 15]** Cada parâmetro tem nome, descrição, tipo, *Is List*, *Required* e *Default*. Os tipos incluem os de dado (String, Integer, Double, Boolean, Color, Icon, ImagePath, DateTime, JSON, Enum…) e três especiais:
  - **Action**, que é um callback;
  - **Widget Builder**, um slot tipado;
  - **Child Widget**, um slot livre.
- **[obs 16]** O parâmetro **Action** tem os seus próprios parâmetros: o callback devolve valores para quem usa o componente.
- **[obs 14]** O componente tem **estado local** ("Local Component State Variables").
- **[obs 20]** Dentro do componente aparece a ação **Execute Callback** (escolhe o callback e tem a opção *Non-Blocking*). Ela **não existe na página**: a disponibilidade de ações depende do contexto.
- **[obs 21]** No painel da instância ficam o wrapper comum, os **Component Parameters** como campos (com binding) e o callback como botão que abre **o mesmo editor de fluxo**. Os obrigatórios são marcados com `*`.
- **[doc]** Editar o componente propaga a mudança para todas as instâncias. O componente também tem eventos de ciclo de vida (ao iniciar e ao ser descartado).

**[rec]**
- Novo `kind: "component"` no envelope do spec, com `params` tipados (reaproveitando o `FieldKind` mais `action` e `slot`) e estado local.
- No conteúdo, um nó de instância **por referência** (`componentId` + mapa de valores de parâmetro).
- Isso concretiza os itens 20 e 21. A ação "Converter em componente" sobre a árvore é a porta de entrada mais barata para o usuário.

## 5. Eventos e ações

- **[obs 06–07]** A aba **Actions** do widget tem uma lista de gatilhos ("On Tap · 1 action") + "Add New Trigger". Os gatilhos dependem do widget: para um Text, é a lista inteira do `GestureDetector` (tap, duplo toque, toque longo, force press, drags…).
- **[obs 06]** As ações vêm em **12 categorias**, com busca que mostra a categoria em breadcrumb. O catálogo completo está em `evidencias/03-11_texto_acessibilidade.txt`.
- **[obs 06]** A disponibilidade é **contextual**: "State Management" só oferece "Rebuild Page" numa página sem estado, e "Animation" fica vazia sem animação definida.
- **[obs Show Snack Bar]** Os parâmetros de uma ação usam **os mesmos editores de propriedade** dos widgets, inclusive estilo de texto e cor do tema.
- **[obs 08–11, 19]** O **Action Flow Editor** é um modal em 3 colunas:
  - à esquerda, os gatilhos, com contador de erros;
  - no centro, o fluxo em nós, com "+" entre nós e ↑↓ para reordenar;
  - à direita, o painel do nó.
- **[obs 08–11, 19]** O "+" oferece **Action, Conditional, Loop, Parallel, Try/Catch e Paste**. A condicional desenha os ramos TRUE/FALSE com junção.
- **[obs rede]** A validação roda num web worker e alimenta os contadores de erro.

**[rec]** Para o item 28, que já tem plano:
- **gatilhos declarados por widget no `widget_catalog.dart`**, ao lado das props;
- **ações como descriptors** com parâmetros `PropField`, para reaproveitar os editores do inspector, como o FlutterFlow faz;
- fluxo **sequencial + condicional** primeiro, deixando loop, parallel e try/catch para depois;
- `nonBlocking` e `outputName` por ação.

A lista de gatilhos por widget e os ciclos de vida da página e do componente alimentam o item 32.

## Mapa para o roadmap

| Item | O que este estudo entrega a ele |
|---|---|
| **9** (catálogo, em andamento) | catálogo de widgets do FF como fila de referência; wrapper comum; busca de propriedade |
| **48** (tema/tokens) | cor do tema por papel, estilo de texto do tema como base, token em raio/sombra/gradiente |
| **29** (contexto de dados) | o modelo literal \| tema \| binding com default e prévia, e o seletor tipado único |
| **28** (eventos/ações) | gatilhos por widget, ação como descriptor, fluxo sequencial + condicional |
| **32** (gatilhos/ciclos) | lista de gatilhos do `GestureDetector`; ciclo de vida do componente |
| **20, 21, 36** (componentes) | `kind: component`, parâmetros tipados com callback e slot, Converter em componente, painel da instância |
| **49** (ícones) | seletor com prévia e busca |

## Decisão pendente do dono

**Por onde começar.** Recomendação: **o modelo de valor (literal | token | binding) no `sdui_core`, como primeira entrega do item 29**. Inspector, parâmetros de ação, condições e parâmetros de componente dependem dele. Começar pelos editores visuais ou pelas ações antes disso obriga a refazê-los quando o modelo mudar. O custo é mexer no schema do spec, que é contrato com o app cliente: pede versão do `specVersion` e leitura compatível do binding `{{prop}}` atual.
