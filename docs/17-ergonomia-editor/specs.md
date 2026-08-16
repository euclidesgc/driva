# Specs — Ergonomia do editor: espaço de tela, grupos e modo preview

> **Estado: discovery em aberto.** Este documento consolida o que foi levantado
> no código e no roadmap e **lista as ambiguidades que ainda esperam decisão do
> humano**. Nada aqui está aprovado. As perguntas em aberto estão marcadas
> **`A#`** e nenhuma fase começa antes de todas fecharem — a regra do time é
> "spec com ambiguidade aberta é chute com cara de certeza".

- **Item no roadmap:** novo, **41**, no Marco 4 (Ergonomia do construtor).
- **Origem:** pedido do dev humano, 2026-08-15, no uso real do editor.
- **Doc viva:** `docs/17-ergonomia-editor/`.

---

## O pedido, nas palavras dele

> "podemos melhorar a responsividade do sistema de uma forma geral, mas também
> gostaria de fazer umas melhorias nas colunas de widgets e de propriedades.
> primeiro faça com que elas possam ser contraídas ou expandidas e os grupos de
> componentes também, cada grupo pode ser contraído ou expandido. também seria
> interessante ter um modo de preview para que eu possa ver na tela do meu
> celular."

São **quatro pedidos de naturezas diferentes**, e eles não têm o mesmo custo nem
a mesma dependência. Tratá-los como um bloco só é o erro que este documento
existe para evitar.

| # | Pedido | Natureza | Estado |
| --- | --- | --- | --- |
| 1 | Responsividade geral do editor | Polimento amplo, sem fim natural | Precisa de recorte (**A1**, **A2**) |
| 2 | Painéis laterais contraíveis | Feature fechada, barata | Precisa de forma (**A3**, **A4**) |
| 3 | Grupos contraíveis | **Metade já entregue** | Precisa de alvo (**A5**) |
| 4 | "Modo de preview no meu celular" | **Ambíguo — três a cinco leituras** | **A6 a A9**, a decisão cara |

---

## O que "responsividade" NÃO é aqui (a confusão que precisa morrer na spec)

O roadmap tem um item **30 — "Responsividade — o spec ganha variação por
breakpoint"**. **Não é isto.** São duas coisas com o mesmo nome:

| | Item 30 (já planejado, `docs/plans/30-responsividade-breakpoints/`) | Este item (41) |
| --- | --- | --- |
| **Quem fica responsivo** | O **conteúdo SDUI** que o cliente publica | A **ferramenta**, o editor Flutter Web |
| **O que muda** | O `ContentSpec` ganha override de prop por breakpoint; o renderer resolve pela largura disponível | O layout do `EditorWorkspace`, do `AppShell` e dos painéis |
| **Quem vê o resultado** | O usuário final do app do cliente | O dev montando a página |
| **Toca o kernel?** | Sim (`sdui_core`, formato do spec) | **Não** — nada em `sdui_core`, nada no JSON |

**Ponto de contato único e conhecido:** o item 30 prevê "um seletor de qual
breakpoint estou editando" na barra do canvas — a mesma barra onde hoje vivem os
presets de dispositivo e o zoom, e onde este item pode encostar. Se este item
mexer nessa barra, deixa o lugar do seletor previsto, não o ocupa.

---

## Estado atual, levantado no código (2026-08-15, pós-itens 38 e 39)

### O layout do editor hoje

Três colunas fixas sob o `ShellRoute` do item 16c, mais um rodapé de problemas:

```
┌─────────────────────────────────────────────────────────────────┐
│ Driva Builder      ↶ ↷  [Salvar] [Publish] ✓Salvo  ☾   (faixa 1)│
│ Projetos › Megazord - App RE › E2E 38 canvas         (faixa 2)  │
├──────────────┬──────────────────────────────┬───────────────────┤
│ Widgets|Árvore│ Mock | JSON                  │ Image  ▣ 🗑        │
│ 🔍 Buscar…    │ [📱][📱][▭]  393×852 🔍 90% 🔍│ 🔍 Buscar prop…   │
│               │                              │                   │
│ Básicos       │        ┌──────────┐          │ CONTEÚDO      ⌃   │
│ [Text][Image] │        │  device  │          │  URL da imagem    │
│ Layout        │        │   mock   │          │  Ajuste           │
│ [Container]…  │        └──────────┘          │ TAMANHO       ⌃   │
│ Formulário    │                              │  Largura / Altura │
│ Listas        │                              │                   │
├──────────────┴──────────────────────────────┴───────────────────┤
│ ✓ Nenhum problema   Text não recebia esse widget — agrupados…    │
└─────────────────────────────────────────────────────────────────┘
```

Fatos que importam para as quatro frentes:

0. **Os painéis já são redimensionáveis por arraste.** `ResizableSplitView`
   (`apps/driva_editor/lib/core/widgets/layout/resizable_split_view.dart`) já
   entrega o splitter: esquerda nasce com **280**, direita com **320**, com
   `minPanelWidth: 200` e `maxPanelWidth: 480`. **Mas:** o estado é local
   (`State`), some no refresh e a cada navegação; e as larguras são
   `SizedBox` fixos com o canvas em `Expanded` — **não há `LayoutBuilder`,
   nenhuma reação ao tamanho da janela**. Numa janela estreita o centro é
   espremido primeiro e, abaixo de ~600 px, o `Row` estoura.
1. **A paleta já tem grupos** — `Básicos`, `Layout`, `Formulário`, `Listas` —
   com cabeçalho de seção **sem controle de colapso**. São **24 primitivos**
   (item 9, track contínuo, ainda crescendo), e a lista já exige rolagem numa
   tela de 1366×900.
2. **O Inspector já tem seções colapsáveis** — entregue no item **9b**
   ("seções colapsáveis e busca de propriedade"). No print, `CONTEÚDO ⌃` e
   `TAMANHO ⌃` têm o chevron e respondem. **Metade do pedido 3 já está no ar.**
3. **A barra do canvas já tem zoom** (`90%` com lupas) e **três presets de
   dispositivo**. O item 4 do roadmap registra que o teto de altura foi
   **revertido** justamente porque "o zoom já resolve o encaixe".
4. **`DevicePreset` é um enum com três entradas**, todas retrato:
   `smartphone` 393×852, `android` 412×915, `tablet` 820×1180 — cada uma com
   `bezel`, `cornerRadius`, `notch` e `safeAreaTop/Bottom` (item 8f).
   `apps/driva_editor/lib/modules/editor_module/presentation/editor/device_preset.dart`.
5. **O editor não reage a tamanho de tela em lugar nenhum.** Uma varredura no
   `apps/driva_editor/lib/` inteiro devolve **zero `LayoutBuilder`** e **um
   único `MediaQuery`** — e esse único é o `device_frame.dart` injetando a safe
   area **dentro do mock** (item 8f), ou seja, não tem nada a ver com a janela.
   `core/theme/` tem `app_spacing`, `app_radii`, `app_typography`,
   `app_durations`, `app_icon_sizes` e as paletas — **não tem
   `app_breakpoints`**. Responsividade do editor hoje não é "parcial": é
   inexistente, e nasceria como token (Gate 4). **Restrição herdada:** o item 30
   já fixou o vocabulário de breakpoint do **spec** —
   `enum SduiBreakpoint {compact, medium, expanded}` no `sdui_core`, com os
   limiares Material 3 (compact < 600, medium 600–1023, expanded ≥ 1024). Um
   `AppBreakpoints` do editor deve **usar os mesmos números**, para não nascerem
   dois vocabulários, mas **sem importar o enum do kernel** — chrome do editor é
   tema; breakpoint do spec é kernel.
6. **Salvar é explícito, não automático.** Botão "Salvar" + chip de status
   ("Salvo"), com o histórico do item 23 reconciliando esse status. **O que
   existe fora do editor é sempre o último salvo** — fato central para o
   pedido 4.
7. **O `projectId` não está na URL.** `ProjectScope` é um objeto em memória no
   `get_it` com `_defaultProjectId = 'default'`, preenchido pela navegação.
   Uma URL aberta fria (num celular, por exemplo) cai no projeto `default`.
8. **Auth ainda é o header `x-project-id`** (item 26 pendente). Quem alcança a
   API com um id lê e escreve o projeto inteiro.
9. **O estado de visualização já mora no `EditorCubit`.** `EditorReady` carrega
   `device` e `zoom`, com `changeDevice`/`changeZoom` e o zoom clampado em
   `0.4–1.5`; o `CanvasArea` os lê por `BlocSelector`. Ressalva dupla: **nada
   disso é persistido** (volta ao padrão a cada abertura), e o **item 30 já tem
   reserva de assento ali** (`EditingBreakpoint` no `EditorReady`). Por isso o
   tech-lead recomenda **não** empurrar o estado de colapso para dentro do
   `EditorCubit` — ele já carrega documento, histórico e visualização, e ganharia
   um quarto assunto.
10. **Uma rota fora do `ShellRoute` é trivial.** O `app_router.dart` já tem
    `rootNavigatorKey` e `shellNavigatorKey` separados, com as quatro rotas
    dentro do shell. Uma rota irmã, sem as duas faixas, é uma linha no `routes:`
    do root — o que importa para a leitura (d) do pedido 4.
11. **O shell tem um canal legítimo para "modo imersivo".**
    `AppShellController extends ChangeNotifier` + `InheritedNotifier`: a página
    publica dados no slot e o shell desenha. Esconder as faixas pode passar por
    ali **sem** o shell ler cubit — a regra do item 16c continua de pé.
12. **A persistência do layout não tem porta pronta.** O `preferences_module`
    existe (item 3, `shared_preferences`), mas seu `PreferencesRepository` só
    conhece tema e o barrel público não o exporta. Guardar layout do editor é
    ou ampliar aquele módulo (que passaria a saber do editor) ou um repositório
    próprio no `editor_module` sobre o `SharedPreferences` já registrado no
    `get_it`. Decisão do plano, não da spec — mas não é "de graça".

### O que já existe fora do editor (importa para o pedido 4)

A **fatia 1 do item 25** fechou o loop SDUI, documentada em `docs/13-loop-sdui/`
(a pasta é `13` por ordem cronológica de doc — **não existe "item 13"** no
roadmap; ele agrupa "11–14. Tela do projeto" numa linha só):

- `GET /v1/public/contents[/:slug]`, autenticado pelo header **`x-driva-key`**
  (`Project.publishableKey`), com `ETag`/`304`, `Cache-Control: max-age=60` e
  CORS liberado só nesse prefixo.
- `apps/driva_demo_app` — Flutter Android/iOS/**Web**, consome a API e renderiza
  com `SduiView`. **Não está deployado**: `docs/deploy/coolify.md` lista três
  recursos (banco, backend, editor). Roda local via `tool/run_demo.sh`, e
  aponta para hml com `API=https://api-hml.driva.duckdns.org`.
- **A rota pública serve o rascunho, não uma versão publicada** — desvio
  `VR-13-01`, registrado e aceito, com a recomendação explícita de "não abrir
  para nenhum cliente real antes do item 24".

**E aqui está a armadilha de sequenciamento:** o item **24** já tem specs e PRD
escritos (`docs/14-publicacao-versionamento/`), e a decisão **4** dele diz que
`/v1/public` passa a servir **só a versão publicada, com `404` quando não houver
publicação**; a decisão **5** diz que **não há backfill** — todo conteúdo
existente nasce "nunca publicado". Ou seja:

> Qualquer coisa que hoje mostre o rascunho no celular **através da rota
> pública** deixa de funcionar no dia em que o item 24 entrar. Preview de
> **rascunho** precisa de caminho próprio, e esse caminho **não está no escopo
> do item 24** (o PRD dele não menciona preview em lugar nenhum).

---

## As quatro frentes, com o que se sabe e o que falta decidir

### Frente 1 — Responsividade do editor

**A conta, medida no código:** o chrome fixo do workspace é
**280 + 320 + 12** (dois handles de 6) = **612 px**. O centro fica com
`viewport − 612`, sempre, em qualquer tela.

| Viewport | Centro disponível | O que acontece |
| --- | --- | --- |
| 1280 | 668 | OK |
| 1024 | 412 | Mock de celular precisa de ~457 → **aparece cortado**. Não dá erro: o `InteractiveViewer` só permite arrastar |
| 1440 | 828 | **O preset Tablet (820) precisa de ~863 — não cabe.** Ou seja, o preset tablet é hoje praticamente inutilizável |
| < 612 | negativo | `RenderFlex overflow` de verdade |

**E há dois defeitos que já estão no ar, independentes de tela pequena:**

- **Os breadcrumbs da faixa 2 têm ellipsis mas não têm `Flexible`** — a elipse
  nunca dispara e o `Row` estoura com nome de projeto/conteúdo longo, **já a
  1280**. Isso não é polimento futuro: é bug hoje.
- **A faixa 1 estoura abaixo de ~700 px** (4 ações + status + tema no editor).

**O que muda a percepção mais que tudo:** o zoom é **manual** (0.4–1.5) e **não
existe "ajustar à janela"**. O dev que reduz a janela precisa descobrir sozinho
que tem de mexer no zoom. A leitura do tech-lead — que endosso — é que **o fit
automático é o maior retorno isolado de todo o pedido**: boa parte do que o dev
sente como "falta de responsividade" é o mock não se ajustar.

**A pergunta que resta** é se, além de matar os overflows e ligar o fit, o
editor precisa de comportamento por faixa de largura — e qual é o piso.

**Ambiguidades: A1, A2.**

### Frente 2 — Painéis laterais contraíveis

Pedido fechado e barato. **O arraste de redimensionamento já existe** — o
`ResizableSplitView` está no ar com min 200 / max 480 — mas **nada é lembrado**:
toda navegação e todo refresh devolvem 280/320. Isso é provavelmente parte do
incômodo que gerou o pedido: o dev alarga a paleta, sai da tela, volta e está
tudo como antes.

O que falta decidir é a **forma** do colapso (some de vez ou vira faixa fina de
ícones) e se o estado — colapso **e** largura arrastada — **sobrevive ao
refresh**.

**Onde o estado mora (resolvido no discovery técnico):** dentro do próprio
`ResizableSplitView`, junto das larguras que ele já governa — **não** no
`EditorCubit`. A razão é mecânica: os painéis chegam ao split view como campos
`Widget` já construídos pelo `build` do workspace, que **não roda** quando o
split view chama `setState`; as instâncias são idênticas, o Flutter
curto-circuita e **nenhum painel reconstrói** — o `setState` custa só o `Row`.
Pelo cubit seria pior: todo `emit` é o caminho quente que o item 3b domou.

Ressalva: se o botão de colapso ficar no AppBar global ou num atalho, o gatilho
vem de fora — aí entra um `EditorLayoutController` (`ValueNotifier`) escopado no
módulo, no mesmo padrão do controller do AppShell. Continua fora do cubit. Se os
botões ficarem nos cabeçalhos dos próprios painéis, nem isso é preciso.

**Ambiguidades: A3, A4.**

### Frente 3 — Grupos contraíveis

**Metade já está entregue** (Inspector, item 9b): widget próprio, agrupando por
`PropField.group`, com resumo quando fechado e key por grupo para o estado não
migrar ao filtrar. **Mas ele não lembra nada** — reabre tudo expandido a cada
troca de tipo de nó selecionado e a cada refresh.

O gap declarado é a **paleta**: ela **já agrupa** (o kernel define
`Básicos`/`Layout`/`Formulário`/`Listas` e a ordem, em
`WidgetCategories.inPaletteOrder`; 24 widgets em 4 grupos) — falta o cabeçalho
ser clicável.

**Isso reformula a pergunta.** Metade do que o dev pediu já existe. Ou o
cabeçalho do Inspector não está convidando ao clique, ou o que incomoda é que o
aberto/fechado **não é lembrado**. As duas hipóteses levam a entregas
diferentes, e só ele sabe qual é.

Há também uma ambiguidade de vocabulário: no driva, **"componente"** é termo
reservado (item 20 — widget reutilizável do cliente, com aba própria prevista no
item 21). O pedido diz "grupos de componentes", e quase certamente se refere aos
**grupos de widgets da paleta** — mas "quase certamente" não escreve spec.

Restrição do discovery: **não usar `ExpansionTile`**, e **não promover** o
`PropSection` para `core/widgets/` agora (invariante **I4**) — widget novo para
a paleta, unificação depois.

**Ambiguidade: A5.**

### Frente 4 — "Modo de preview para ver na tela do meu celular"

A frase admite **cinco** leituras, que diferem em **uma ordem de grandeza** de
custo e em **dependência de roadmap**. As letras abaixo são as mesmas que o
tech-lead usou no discovery técnico, para o plano e a spec falarem a mesma
língua.

| Leitura | Em uma linha | Custo (tech-lead) | Depende de |
| --- | --- | --- | --- |
| **(a)** | App demo publicado, consumindo a API pública | **3–4 fases, com CISO** | Deployável novo + item 24 quebra depois |
| **(b)** | Tela cheia dentro do editor | **barato** (quase de graça com a frente 2) | nada |
| **(c)** | Mock de dispositivo melhor (presets, rotação) | **barato**, incremental | nada |
| **(d)** | Rota de preview no próprio editor, aberta por URL/QR no aparelho | **1 fase** | nada |
| **(e)** | O aparelho acompanha a edição **ao vivo** | **+2 fases** sobre (a) ou (d) | decisão de arquitetura |

#### (a) Ver no celular de verdade, via a API pública + app demo

O celular abre o `driva_demo_app` (versão web) apontado para o conteúdo.

- **Já existe:** a rota pública, a chave publicável, o app demo compilando para
  web e consumindo o spec.
- **Falta:** o backend aceitar a chave **por query string** (hoje só
  `@Headers('x-driva-key')` — QR code não manda header), **rate limit** no
  prefixo público (`VR-13-04`), e o app demo virar **deployável** (não tem
  Dockerfile, está fora do Coolify, e chave/slug são compile-time).
- **Implicações:** a chave publicável numa URL vira link compartilhável e
  printável, e `GET /v1/public/contents` **sem slug lista os conteúdos do
  projeto**. **Antecipa os itens 24 e 26**, e **quebra no dia do item 24**
  (rascunho deixa de ser servido, sem backfill). Custo: **3–4 fases, com CISO
  obrigatório** — e a maior parte é infraestrutura que não é o que o dev pediu.

#### (d) Ver no celular de verdade, via uma rota de preview no próprio editor

O editor **já é Flutter Web e já tem o renderer**. Uma rota fora do `ShellRoute`
— sem AppBar, sem painéis, só o `SduiView` ocupando a tela real do aparelho —
servida pelo mesmo domínio que já está no ar (`hml.driva.duckdns.org`), com QR
code no editor apontando para ela.

Rota `/preview/:projectId/:id`.

- **Já existe tudo de que ela precisa:** o editor é o único Flutter Web
  deployado; o **nginx já tem SPA fallback** (URL digitada no celular funciona);
  o editor já usa **path URL strategy**; o `go_router` aceita **rota irmã fora
  do `ShellRoute`** (o `rootNavigatorKey` já está separado do
  `shellNavigatorKey`), o que dá tela sem AppBar de graça; e o renderer já está
  dentro do editor (`SduiView`), então o preview é **fiel** ao mock.
- **Falta:** 1 rota + 1 página + o botão que mostra a URL/QR.
- **Não toca backend, não cria deployável, não precisa de CISO.**
  **Custo: 1 fase.**
- **Detalhe obrigatório:** o `projectId` tem que estar **na URL**. O backend
  escopa `GET /v1/contents/:id` por projeto via header, e esse header vem de um
  escopo global (`ProjectScope`) carimbado só quando o usuário passa pela tela
  do projeto. Aberta fria no celular, a rota cairia no projeto `default` → **404
  inexplicável**.
- **Segurança, sem drama:** o backend **não tem auth nenhuma** hoje (item 26
  aberto), o CRUD do rascunho é aberto e a listagem de projetos devolve a chave
  publicável. O rascunho **já** está acessível a quem conhece a URL da API. O QR
  não acrescenta o vazamento — acrescenta **materializá-lo num link que sai do
  laptop**. É essa a diferença que o humano precisa aceitar ou recusar (**A8**).

#### (b) Modo tela cheia dentro do editor

Esconde painéis, AppBar e rodapé; fica só o mock. É a frente 2 levada ao
extremo, com um atalho de teclado e `Esc` para sair.

- **Custo: meia fase**, depois da frente 2. O atalho é uma linha (a infra de
  `Shortcuts` do item 23 está pronta) e o AppBar some por um sinal no controller
  do AppShell, que as páginas já alimentam. **Risco zero.**
- **Limite:** entrega "mock grande no desktop" — **não** o celular. Se o que ele
  quer é o aparelho na mão, (b) não responde ao pedido.

#### (c) Melhorar o mock de dispositivo

- **Já existe:** três presets com moldura realista (item 6) e safe area real
  (item 8f); zoom **manual** de 0.4 a 1.5.
- **Falta, em ordem de retorno:** o **"ajustar à janela"** (fit) — que não
  existe e é, segundo o discovery técnico, **o maior retorno isolado de todo o
  pedido**; presets além dos três; e a rotação.
- **Custo: 1 fase** (fit + presets), **2 se entrar rotação**. Rotação não é
  trivial: a moldura posiciona os botões por fração da altura e o recorte da
  câmera assume o topo.
- **Encosta no item 30** — mesma toolbar do canvas.

#### (e) A variante que atravessa todas: ao vivo ou último salvo?

**Não existe autosave.** Salvar é botão / `Ctrl+S`. Então (a) e (d) mostram o
**último salvo**, e o fluxo real é "Salvar → refresh no celular". **É a primeira
coisa que vai frustrar o dev se o PRD não disser.**

Se "ver na tela do meu celular" significa **mexer no editor e ver mudar no
aparelho sozinho**, nenhuma das leituras acima entrega isso. Realtime no backend
hoje: **zero**. Caminho barato: autosave com debounce + polling curto na página
de preview — **+2 fases** sobre a (d). Caminho "certo" (SSE/WebSocket): **3+
fases**, num backend que ainda não tem bateria de teste (item 40).

**Ambiguidades: A6, A7, A8, A9.**

---

## Invariantes que o discovery técnico deixou (não são opções — são cercas)

**I1 — O `imageUrlResolver` viaja por oito arquivos, e qualquer tela nova tem
que carregá-lo adiante.** A F3 do item 39 injetou o resolver por repasse:
`editor_page.dart` → `editor_workspace.dart` → `center_area.dart` →
`canvas_area.dart` → `canvas_panel.dart` → `canvas/preview_surface.dart` (mais
`core/network/network.dart` e o resolver). São **exatamente** os arquivos que
as frentes 1, 2 e 4 mexem. Uma rota de preview que esqueça de repassá-lo faz a
imagem de host sem CORS voltar a falhar em silêncio — o sintoma que o item 39
acabou de matar. Isso é invariante de plano, não lembrete.

**I2 — O colapso de painel mora dentro do `ResizableSplitView`, não no
`EditorCubit`.** Ver o fato 9 e a frente 2. Se o gatilho vier de fora (AppBar ou
atalho), entra um `EditorLayoutController` (`ValueNotifier`) escopado no módulo —
nunca o cubit.

**I3 — `AppBreakpoints` do editor usa os limiares do item 30 (600/1024), sem
importar o enum do kernel.** Ver o fato 5.

**I4 — Não promover widget do Inspector agora.** Os itens 38 e 39 acabaram de
mexer em `inspector_area.dart`, `inspector_panel.dart`, `left_panel.dart`,
`widget_tree_panel.dart`, `preview_surface.dart` e nos tokens. Promover
`PropSection` para `core/widgets/` no meio disso é convidar retrabalho.

**I5 — O colapso de grupo tem um terceiro cliente à vista.** O item **8b**
(legibilidade do JSON, ainda `[ ]`) prevê "dobrar seções" no painel JSON. Se
nascer um `CollapsibleSection`, ele deve ser desenhado sabendo disso — **sem**
juntar os itens agora.

**I6 — Pré-condição de fechamento, não desta feature.** Nem `docs/15-…` nem
`docs/16-…` têm `final_report.md`; o roadmap ainda marca F2/F3/F4 do item 39
como `[ ]` embora estejam em `develop`; e faltam a F7 do 38 e a F5 do 39 (as
baterias). Abrir frente nova antes de pagar isso é construir sobre dois itens
sem atestado nem teste. **Registrado para o tech-manager, não resolvido aqui.**

---

## Ambiguidades abertas (nenhuma fase começa antes de fecharem)

| # | Pergunta | Opções e o que cada uma custa |
| --- | --- | --- |
| **A1** | O piso de responsividade é só **matar os overflows + ligar o fit**, ou o editor precisa de **comportamento por faixa de largura**? | (i) Só os overflows + fit: **1 fase**, e resolve os defeitos que estão no ar hoje · (ii) Mais tokens de breakpoint e comportamento por faixa: **+1 fase**, que o tech-lead adiaria · (iii) Layout para celular: outro projeto |
| **A2** | Existe um **caso concreto doendo**, ou é "melhorar em geral"? | Sabemos de três defeitos objetivos (breadcrumb estoura a 1280; preset Tablet não cabe nem a 1440; sem fit). Se o incômodo dele for outro, o recorte muda |
| **A3** | Painel colapsado **some** ou vira **faixa fina de ícones**? | Some: mais canvas, mais barato · Faixa: continua acessível, custo médio. Nota: com a paleta colapsada **não há de onde arrastar widget** — o controle de reabrir precisa estar sempre visível |
| **A4** | O colapso — **e a largura já arrastável** — são **lembrados** entre sessões? | Lembrar: **meia fase**; `shared_preferences` já é dependência e o `preferences_module` tem a pilha pronta. De carona conserta as larguras, que hoje se perdem no refresh · Não lembrar: 280/320 sempre, o comportamento atual |
| **A5** | **Reformulada.** O Inspector já colapsa desde o item 9b, mas **não lembra** (reabre expandido a cada troca de nó e a cada refresh). O que incomoda: falta o colapso na **paleta**, ou falta o estado ser **lembrado** nos dois? | Só a paleta: **1 fase** · Paleta + memória nos dois: mesma fase, e provavelmente é o que ele quer · Se for a aba "Componentes" do item 21: não existe ainda |
| **A6** | **A pergunta cara.** Preview no celular = **(d) rota no próprio editor**, **(a) app demo publicado**, **(b) tela cheia**, ou **(c) mock melhor**? | **(d): 1 fase**, 0-dep, sem backend, sem CISO, mostra o rascunho · **(a): 3–4 fases com CISO**, exige deployável novo, antecipa os itens 24 e 26 e **quebra quando o 24 entrar** · (b): meia fase, mas é o desktop, não o celular · (c): 1 fase, e o fit já entra no piso |
| **A7** | O celular mostra o **último salvo** (Salvar → refresh) ou precisa **acompanhar ao vivo**? | Último salvo: já incluído em (a)/(d). **Não existe autosave** — o fluxo é manual · Ao vivo: **+2 fases** (autosave debounced + polling) ou **3+** (SSE/WebSocket, num backend sem bateria de teste) |
| **A8** | Materializar o rascunho **num link que sai do laptop** é aceitável agora? | O backend já não tem auth nenhuma e o rascunho já é acessível a quem conhece a URL da API — o QR não cria o vazamento, cria o **link compartilhável**. Aceitar: 0 custo, vira dívida do item 26 · Recusar: entra token de preview e o custo sobe |
| **A9** | "Modo preview" deixa de **editar** e passa a **interagir** (tocar botão, digitar no campo)? | Só visual: já é o que (b)/(d) entregam · Interativo de verdade: o clique hoje seleciona nó, e ação só existe com o **item 28** — sem ele, botão não faz nada |
| **A10** | Se entrarem presets novos: **qual é o aparelho dele?** | Um preset com as medidas reais do aparelho dele pode entregar boa parte do pedido 4 por quase nada — e a resposta também informa (d) |

---

## Fora de escopo (declarado, para não voltar como surpresa)

- **Item 30** — variação do spec por breakpoint. Nome parecido, problema outro.
- **Item 24** — publicação e versionamento. Este item não antecipa nada dele,
  e **não deve** construir sobre a rota pública servindo rascunho.
- **Item 26** — auth. Uma URL de preview aberta é dívida registrada, não
  resolvida aqui.
- **Item 28** — eventos e ações. Preview interativo de verdade depende dele.
- **Layout do editor para celular** — se A1 responder (iii), vira item próprio.

---

## Decisões do humano que sustentam esta spec

_Nenhuma ainda._ Este documento está no estado "perguntas levantadas". Assim que
as respostas de **A1–A10** chegarem, elas entram aqui nominalmente e o PRD é
consolidado a partir delas.
