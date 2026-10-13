# FlutterFlow: benchmark de UX e modelo de dados para o editor SDUI do driva

Pesquisa feita em 2026-10-13 na documentação pública (docs.flutterflow.io), no fórum oficial (community.flutterflow.io) e no blog. Em cada tópico, **Documentado** reúne o que a fonte afirma, com a URL. **Inferido** é leitura minha, ou vem de fonte não oficial (fórum), e está marcado assim.
Ressalva geral: a documentação é rasa em controles de UI. Muitas páginas dizem *o que* se configura e não *com que controle*. Onde não encontrei nada, está escrito "não documentado".

---

## 1. Biblioteca de widgets, árvore, wrap/unwrap

### Documentado
- **A paleta tem cinco abas:** Widgets (padrão, agrupados por finalidade), Components (do usuário, mais custom widgets), Templates (blocos prontos, e o usuário pode salvar os próprios), Theme Widgets (widgets estilizados do design system) e a **Floating Widget Palette**, que insere direto do canvas sem abrir o menu lateral. A paleta tem **barra de busca**, e a inserção é por **arrastar para o canvas**. https://docs.flutterflow.io/flutterflow-ui/widget-palette
- **Categorias de widget:** Layout Elements (Row, Column, Stack, Container), Base Elements (Text, Image, Icon, Button), Page Elements (AppBar, FAB, Drawer) e Form Elements (TextField, Radio, Dropdown). https://docs.flutterflow.io/resources/ui/widgets
- **Modelo da árvore:** a raiz é a Page. Contêineres de layout ficam no meio e widgets atômicos nas folhas. https://docs.flutterflow.io/resources/ui/widgets
- **Também dá para inserir pela árvore**, sem arrastar do painel (exemplo do Wrap). https://docs.flutterflow.io/widgets-and-components/widgets/layout-elements/wrap
- **Mover por arraste:** uma linha **azul** marca a posição de irmão. Uma linha **laranja** indica que o alvo aceita filho, e soltar ali torna o widget filho do alvo. https://docs.flutterflow.io/concepts/layouts/wrap
- **Wrap:** menu de contexto (botão direito) → *Wrap Widget* → escolher o pai (exemplo do Tooltip): https://docs.flutterflow.io/resources/ui/widgets/built-in-widgets/tooltip/. Há o atalho **⌘+B** para envolver o selecionado num Stack: https://docs.flutterflow.io/resources/ui/widgets/built-in-widgets/swipeable-stack/
- **Navegação da árvore por teclado** (release de out/2023): ↑/↓ alternam entre pai e filho, ←/→ entre irmãos. https://community.flutterflow.io/c/whats-new-in-flutterflow/post/what-s-new-in-flutterflow-october-23th-2023-KGHbTgAHrC4pQ8P
- **Atalhos gerais:** Undo/Redo (⌘Z / ⇧⌘Z; botão direito na seta abre o histórico de mudanças para saltar a um estado) e **Command Palette** (⌘/Ctrl+K), que busca qualquer recurso e mostra onde ele é usado. A lista completa de atalhos só existe numa imagem. https://docs.flutterflow.io/flutterflow-ui/toolbar
- **Diretriz de profundidade:** manter páginas e componentes com menos de 10 níveis. Acima disso, extrair um componente. https://docs.flutterflow.io/resources/ui/widgets/composing-widgets/
- **O canvas** troca o device (incluindo tamanho custom), alterna light/dark, mostra safe area, bezel, escala de texto, teclado, idioma e erros de overflow. https://docs.flutterflow.io/flutterflow-ui/canvas
- **Generate Dynamic Children:** seção dos widgets multi-filho que gera os filhos a partir de uma lista. https://docs.flutterflow.io/resources/ui/widgets/properties/

### Inferido / não oficial
- **Unwrap (remover o pai e manter os filhos):** não achei em nenhuma fonte. Talvez exista só no menu de contexto.
- **Fórum (não oficial):** a linha da árvore teria ⋮ (com "Wrap with Widget"), + e lixeira no hover. https://community.flutterflow.io/ask-the-community/post/beginner---cant-find-the-three-dots-8865XVlXhClSnuU
- **Padrão útil:** no drag, o feedback visual distingue "inserir como irmão" de "inserir como filho" por cor. Barato de copiar e resolve a ambiguidade do drop.

---

## 2. Painel de propriedades

### Documentado: seções
- **Seções do painel:** nome do widget (editável), Actions, Backend Query, Generate Dynamic Children, Animations, Documentation + Semantic Labels e **Additional Flutter Properties**. Esta última é um editor livre de argumentos nomeados do construtor, um por linha; não aceita `key`/`child`/`children` nem duplicar o que o painel já controla, e aplica só no código gerado e no Test Mode, não no canvas. https://docs.flutterflow.io/resources/ui/widgets/properties/
- O conteúdo do painel muda com a seleção: Page Properties ou Widget Properties. https://docs.flutterflow.io/flutterflow-ui/builder
- **Configuração do painel:** o usuário pode manter seções comuns recolhidas. https://docs.flutterflow.io/flutterflow-ui/canvas
- **Bulk edit:** shift+clique em vários widgets edita as propriedades em comum. https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/

### Documentado: controle por tipo de propriedade

| Tipo | Controle | Fonte |
|---|---|---|
| Cor | picker com gradiente custom, HEX/RGB + alpha e lista de **Theme Colors** (Primary, Secondary, Background…) abaixo; pode ser ligada a variável, inclusive string CSS | https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/ |
| Gradiente | ângulo em graus, lista de stops (cor + ponto 0–1) e "Add Color"; no Text, tipo Linear/Radial com presets | https://docs.flutterflow.io/resources/ui/widgets/container ; https://docs.flutterflow.io/resources/ui/widgets/text |
| Largura/altura | pixels fixos, **% da tela ou do pai**, ou **infinito** (preencher); também por alça de arraste no canvas ou por Responsive Value | https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/ |
| Min/Max W/H | px ou % | https://docs.flutterflow.io/resources/ui/widgets/container |
| Padding | em px; uniforme ou por lado | https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/ |
| Margin | não documentado | — |
| Alinhamento | **grade 3×3** (9 posições) mais campos X/Y de −1 a 1 | https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/ |
| Números em geral | ↑/↓ ajustam o valor; com Shift, de 10 em 10 | idem |
| Opacidade | 0–1, com opção de animar (duração + curva) | idem |
| Visibilidade | condicional (expressão), toggle "Show in UI Builder" (só no canvas) e responsiva (ícones de device ligáveis) | idem ; https://docs.flutterflow.io/concepts/layouts/responsive/ |
| Raio de borda | Uniform ou Independent (TL/TR/BL/BR) | https://docs.flutterflow.io/resources/ui/widgets/image |
| Borda | cor, largura e raio | https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/ |
| Sombra | cor (tema/picker/hex com alpha), Blur, Spread, Offset X, Offset Y | https://docs.flutterflow.io/resources/ui/widgets/container |
| Imagem | dropdown de origem (Network/Asset/Uploaded File), campo de URL ou upload/picker de asset, imagem dark separada, BoxFit em dropdown, blur hash, imagem de erro | https://docs.flutterflow.io/resources/ui/widgets/image |
| Ícone | catálogo Material + FontAwesome + ícones custom (aba própria); tamanho e cor no painel | https://docs.flutterflow.io/resources/ui/widgets/icons ; https://docs.flutterflow.io/concepts/design-system |
| Texto | valor direto **ou Set from Variable**; com variável aparecem Max Character e Overflow (Clip/Ellipsis/Fade/Visible); formatação numérica, moeda; Text Align; line height; Max Lines; Auto Size | https://docs.flutterflow.io/resources/ui/widgets/text |
| Booleano | toggle (Clip Content, Safe Area, Cached…) | https://docs.flutterflow.io/resources/ui/widgets/container |
| Enum | dropdown (BoxFit, curva de animação, overflow) | https://docs.flutterflow.io/resources/ui/widgets/image |
| Animação implícita | curva em dropdown + duração em ms | https://docs.flutterflow.io/resources/ui/widgets/container |
| Estados do botão | blocos separados de estilo para Disabled e Hover (cor, borda, elevação) | https://docs.flutterflow.io/resources/ui/widgets/button |

### Documentado: binding e tema
- **"Set from Variable"** é o ponto único de binding. As fontes são o estado da página/componente, propriedades globais e constantes. Antes de ligar, o valor pode passar por **transformações**: concatenar, If/Then/Else e operações de lista (Map, Filter, Sort, Unique, First Few, Item at Index, Count, Is Set And Not Empty). https://docs.flutterflow.io/resources/data-representation/variables/
- **Responsive Value** é uma das fontes do mesmo menu, com um valor por breakpoint (Mobile/Tablet/Desktop/Wide). Os breakpoints moram no tema. https://docs.flutterflow.io/concepts/layouts/responsive/
- **Widget State** (texto de um TextField, valor de um checkbox) aparece no menu de variáveis. O de um componente é acessível ao pai por Widget State → componente → widget. https://docs.flutterflow.io/concepts/state-management/widget-state/
- **Copy variable:** copia a lógica de um binding e cola em outra propriedade. https://docs.flutterflow.io/resources/ui/widgets/widget-commonalities/
- **Tema:**
  - 16 cores predefinidas, editáveis separadamente em light e dark, mais cores custom.
  - Tipografia com fonte Primary e Secondary e estilos (Display/Headline/Title…), cada um com tamanho, peso, cor, letter spacing e itálico; estilos responsivos por device.
  - **Theme Widgets:** um estilo nomeado de um único widget (ex.: botão primário). Aplicá-lo **sobrescreve** as propriedades já definidas, **exceto as ligadas por variável**, e o usuário ainda pode editar depois.
  - https://docs.flutterflow.io/concepts/design-system
- **Tokens de espaçamento/raio:** a doc do tema não documenta. Há um pedido no fórum (https://community.flutterflow.io/discussions/post/design-constants-theme-widgets-gapWJL2DOE1rdl0), e a doc do CLI lista "design tokens" como item editável (https://docs.flutterflow.io/flutterflow-cli/build/), sem descrever o formato.

### Inferido
- O padrão de toda propriedade parece ser este: **valor literal | token do tema | Set from Variable (com Responsive Value como caso especial)**. Para o driva, isso equivale a um campo com três modos, mantendo `{{binding}}` como dado.
- Não está documentado como um campo ligado aparece no painel (chip? cor?) nem como se desliga um binding. É preciso ver na UI.

---

## 3. Componentes

### Documentado
- **Criar:**
  - do zero: Add → Add Component → Create Blank Component;
  - de um widget: botão direito na **raiz da subárvore** → **Convert to Component**;
  - também por template, por IA (descrição em texto) e importando de Figma.
  - https://docs.flutterflow.io/resources/ui/components/creating-components
- **Parâmetros:** definidos selecionando a raiz do componente e ligados depois aos widgets e triggers internos. Aceitam os tipos de dado padrão (String, Integer, Double, Boolean, Color, DateTime, Image/Video/Audio Path, JSON, Enum, Custom Data Type, Document, LatLng, List…; https://docs.flutterflow.io/resources/data-representation/data-types) e mais três tipos especiais:
  - **Action** (callback);
  - **Widget Builder** (slot tipado, que pode ter parâmetros próprios e preview no editor; https://docs.flutterflow.io/resources/ui/components/widget-builder/);
  - **Child Widget** (slot livre, posição fixa, sem restrição de tipo; https://docs.flutterflow.io/resources/ui/components/child-widget).
- **Valores por instância:** cada instância recebe os seus no painel de propriedades. Inserção pela aba Components da paleta. **Recursão** é permitida (um componente contém a si mesmo). Em lista dinâmica, usa-se uma key única. https://docs.flutterflow.io/resources/ui/components/using-components
- **Estado local (Component State):**
  - cada variável tem tipo, Is List, valor inicial e Nullable;
  - só muda pela ação **Update Component State**, cuja opção Update Type escolhe entre rebuild da página, rebuild só do componente ou nenhum rebuild;
  - escopo restrito ao componente.
  - Ciclo de vida: **On Initialization** (roda de novo se o componente for ocultado e reexibido, e por instância em lista) e **On Dispose** (roda antes do Dispose da página).
  - https://docs.flutterflow.io/resources/ui/components/component-lifecycle
- **Callbacks:** um parâmetro do tipo Action pode ter parâmetros próprios. O pai monta o action flow e lê os valores em "Callback Parameters". O filho dispara com a ação **Execute Callback**. Retorno não está documentado. https://docs.flutterflow.io/resources/ui/components/callbacks
- **Propagação:** editar o componente atualiza **todas as instâncias** automaticamente. https://docs.flutterflow.io/resources/ui/components
- **Entre projetos (Libraries):**
  - versões publicadas a partir da main, com auto-incremento, e prereleases nas branches;
  - o projeto consumidor atualiza **manualmente** ("Update to Latest Version") e pode reverter;
  - o design system do projeto consumidor prevalece sobre o da lib.
  - https://docs.flutterflow.io/resources/projects/libraries
- **Componente × Theme Widget × Template:** o Theme Widget estiliza um widget; o Template é layout de vários widgets (cópia); o Componente acrescenta comportamento e ações. https://docs.flutterflow.io/concepts/design-system

### Inferido
- **Detach** de instância (virar cópia solta) e **override** de propriedade interna por instância não aparecem na doc. Fora dos parâmetros declarados, a instância parece não ter override.

---

## 4. Ações e eventos (Action Flow Editor)

### Documentado
- **Modelo:** trigger + ações. Os triggers são fixos, dados pela plataforma e não criados pelo usuário. Cada trigger tem seu próprio editor de nós, e o trigger é escolhido por busca. https://docs.flutterflow.io/resources/functions/action-flow-editor
- **Triggers por widget:**
  - qualquer widget: On Tap, On Double Tap, On Long Press;
  - TextField: On Submit;
  - Dropdown, CheckboxGroup, Slider, Radio, ChoiceChips: On Selected;
  - PageView: On Page Swipe;
  - ToggleIcon: On Toggle;
  - PinCode: On Completed/On Change;
  - Count Controller: On Count Changed;
  - **Gesture Detector** num Container expõe o conjunto completo do Flutter (tap down/up/cancel, secundário/terciário, force press, drags horizontal/vertical, pan, scale).
  - https://docs.flutterflow.io/resources/functions/action-triggers
- Formulários também têm On Focus Change e On Change. https://docs.flutterflow.io/concepts/state-management/widget-state/
- **Página:** On Page Load, On Phone Shake, **On Shortcut Press** (que não dispara com TextField focado) e On Dispose. **Componente:** On Initialization e On Dispose. https://docs.flutterflow.io/resources/ui/pages/page-lifecycle/ ; https://docs.flutterflow.io/resources/ui/components/component-lifecycle
- **Nós do fluxo:**
  - Add Action;
  - **Add Conditional Action** (booleano com dois ramos);
  - **Add Loop** (while), com **Break** para sair;
  - **Add Parallel** (dois ramos concorrentes);
  - Paste Action(s);
  - **Action Blocks**, reaproveitáveis, com parâmetros e retorno.
  - https://docs.flutterflow.io/resources/functions/action-flow-editor ; https://docs.flutterflow.io/resources/functions/loops/
- **Condicionais:** um toggle **Multiple Conditions** converte If/Else em If / Else If / Else. As condições se combinam por AND/OR, com os operadores =, ≠, <, >, ≤, ≥, Is Set e Is Not Set. https://docs.flutterflow.io/resources/functions/conditional-logic
- **Sequencial vs não bloqueante:** a execução é síncrona por padrão; cada ação espera a anterior. Ações assíncronas podem ser marcadas **Non Blocking** (sem `await`), só quando o que vem depois não depende delas. Bottom sheet, dialog e áudio têm a opção própria. https://docs.flutterflow.io/resources/control-flow-concepts/ ; https://docs.flutterflow.io/concepts/navigation/bottom-sheet/
- **Action outputs:** a ação que retorna valor pede um **Action Output Variable Name**, e as ações seguintes do fluxo leem esse valor. Exemplos: biometria (bool), bottom sheet, query do Firestore. Alguns pickers gravam o resultado em Widget State. https://docs.flutterflow.io/resources/functions/utility-actions/
- **API Call** ramifica em TRUE/FALSE, sucesso ou falha. https://docs.flutterflow.io/actions/actions/backend-database/api-call
- **Tipos de ação (lista parcial):**
  - Navegação: Navigate To, Navigate Back, Replace Route (https://docs.flutterflow.io/actions/actions/navigation);
  - Estado: Update App/Page/Component State, cada uma com Update Type de rebuild, mais a ação Rebuild (https://docs.flutterflow.io/actions/actions/state-management/update-app-state);
  - Utilitárias: Copy to Clipboard, Set Dark Mode, Send Email/SMS, Call Number, Color/DateTime Picker, Biometric (https://docs.flutterflow.io/resources/functions/utility-actions/);
  - Widget/UI: Clear TextField, controle de SwipeableStack.
- **Action Blocks:** escopo App, Page ou Component; o escopo define o estado que o bloco enxerga. https://docs.flutterflow.io/resources/functions/action-blocks/
- **Diagnóstico:** um ícone de bug no editor lista os erros de todos os fluxos do widget. Erros bloqueiam a compilação. https://docs.flutterflow.io/resources/functions/action-flow-editor ; https://docs.flutterflow.io/flutterflow-ui/toolbar

### Inferido
- Uma ação "Terminate"/"Stop flow" genérica não aparece na doc consultada (só o Break de loop).
- O resultado de uma ação fica disponível **por nome** às ações seguintes. Para o driva, isso significa que o spec de ações precisa de um campo `outputName` e de referência por nome, com escopo léxico dentro do fluxo.

---

## 5. Persistência do projeto

### Documentado
- **O projeto é um conjunto de arquivos YAML particionados**, cada um endereçado por uma **file key** hierárquica:
  - globais: `app-state`, `app-details`, `folders`…;
  - coleções por id;
  - páginas e widgets em caminhos que combinam o id da página, o contorno da árvore e o **id do nó** (ex.: um nó Column com id próprio);
  - código custom em chaves próprias.
  - **Toda edição visual é gravada nesse schema** (UI e API são duas visões do mesmo dado).
  - https://docs.flutterflow.io/resources/projects/settings/project-apis
- **Exemplo público (`app-state`):** uma lista de `fields`. Cada campo tem `parameter` com `identifier` (`name` + `key` curta única), `dataType.scalarType` e `description`, mais `persisted` (bool). Mesma URL.
- **Project API (beta, plano pago):**
  - `listPartitionedFileNames` devolve também `versionInfo`, com a versão do particionador e um *fingerprint* do schema;
  - `projectYamls` exporta um zip em base64;
  - `validateProjectYaml` devolve erros com linha e coluna;
  - `updateProjectByYaml` recebe um mapa file key → conteúdo, vários arquivos por chamada;
  - **validar antes de gravar** é a prática recomendada.
  - Mesma URL.
- **CLI/agentes:**
  - escrita com **concorrência otimista** (push rejeitado se o projeto mudou desde o snapshot; o agente relê e tenta de novo);
  - rollback pelo histórico de versões do builder;
  - dependências de lib congeladas (versão) ou vivas (`current`/`latest`).
  - A página também menciona um workspace local com pasta `dsl/` e `generated_code/`. Não confirmei isso numa segunda busca, então trate como incerto.
  - https://docs.flutterflow.io/flutterflow-cli/build/
- **Branching e version control** nativos no builder. https://docs.flutterflow.io/flutterflow-ui/toolbar

### Inferido
- O nó tem id estável e separado do nome exibido. Renomear o widget atualiza o binding das ações (https://docs.flutterflow.io/resources/functions/action-flow-editor), o que indica referência por id, não por nome.
- Particionar por página e por nó permite gravar e validar parcialmente e evita conflito de escrita. Para o driva, que hoje grava o spec inteiro em JSONB, isso seria uma evolução; não é urgente.
- O schema completo do YAML não é público. Só existe referência de terceiros (MCP comunitário `ff-mcp`), que não consultei como fonte.

---

## Lacunas que só a observação da UI resolve
1. A existência e o lugar do **Unwrap**, o conteúdo completo do menu de contexto da árvore e a lista completa de atalhos (a doc mostra só uma imagem).
2. Como um campo **ligado a variável** aparece no painel, como se desfaz o binding e se há valor default/fallback.
3. O controle exato de **dimensão**: seletor de unidade px/%/∞ em dropdown ou toggle.
4. O controle de **padding/margin** (quatro campos? link de "uniforme"?) e se margin existe como propriedade ou se é feito por wrap em Padding.
5. Como o **text style do tema** é escolhido no Text (dropdown?) e como fica o override parcial de fonte/peso/cor.
6. A **forma visual** do Action Flow Editor: grafo de nós vs lista, como os ramos paralelos e condicionais são desenhados, e como o output aparece no menu de variáveis.
7. Se a instância de componente tem **override** ou **detach**.
