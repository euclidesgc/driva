# Specs — Ergonomia do editor: espaço de tela, grupos e modo preview

> **Estado: rodada 01 fechada (A1–A10 → D1–D4, D20 no `plan.md`); rodada 02
> fechada em 2026-08-16.** Este documento consolida o que foi levantado no
> código e no roadmap. As perguntas da rodada 01 estão marcadas **`A#`** e todas
> foram respondidas; a **rodada 02** (itens 5.3 e 1.2 do `feedback_rodada_01.md`)
> tem seção própria no fim. A regra do time continua valendo: "spec com
> ambiguidade aberta é chute com cara de certeza".

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

## Rodada 02 (2026-08-16) — a árvore como alvo de arraste (5.3) e o colapso total (1.2)

> **Estado: fechada.** As perguntas que abriram esta rodada foram respondidas
> pelo dev humano em 2026-08-16. O que sobrou está marcado **`P#`** (proposta do
> PM, aberta a veto), não `A#`: **nenhuma ambiguidade bloqueia o plano.**

Origem: `feedback_rodada_01.md`, itens **5.3** e **1.2**. O feedback os tratava
como uma unidade, porque declarava que o 5.3 destravaria o 1.2. **O discovery
mostrou que não destravava — e que não precisava.**

### O que ele pediu, nas palavras dele

> "Se eu puder visualizar a árvore de widgets e o painel de widgets ao mesmo
> tempo, eu posso arrastar um widget e soltar ele no local exato onde eu quero e
> se eu arrastar por exemplo uma column para exatamente um container deveria
> aparecer a opção de envolver container com column, mas se eu arrastar a column
> para exatamente acima do container, ou seja entre outros dois widgets eu não
> estaria fazendo o comando de envolver com coluna, e sim adicionando uma column
> à árvore de widgets naquela posição. (…) Note que deve ser possível arrastar
> componentes do painel de widgets bem como arrastar componentes existentes do
> painel de árvore."

E, sobre o colapso total:

> "a paleta contraída precisa ser descontraída para poder ser utilizada. A
> feature de contração das paletas serve para aumentar o espaço visível por
> qualquer motivo que seja, apenas isso."

### A A3 **não** foi reaberta — o 1.2 era outra coisa

O `feedback_rodada_01.md` §1.2 lia "contrair até sumir" como pedido de **remover
o painel da tela**, o que colidia de frente com a **A3/D2** ("faixa fina de
ícones, não some", justificada por "com a paleta sumida não há de onde arrastar
widget"). O discovery gastou uma rodada nessa colisão. **Ela não existia.**

A referência que ele mandou — arquivada em
`docs/17-ergonomia-editor/referencias/chrome_sidebar_colapsada.png` — é a
sidebar do Chrome recolhida: **faixa vertical fina de ícones**, com o botão de
expandir (`⇥`) no topo. O painel **não some**; vira faixa com affordance de
retorno permanente.

**Isso é a D2, literalmente, e é a F5 já planejada.** Consequências, registradas
para não serem reinventadas depois:

- **A A3 fica de pé, sem emenda.** A D2 do `plan.md` não muda uma palavra.
- **O 1.2 é absorvido pela F5.** Não vira fase nova, não vira item de roadmap.
- **O veredito do discovery — "o 5.3 não destrava o 1.2" — está correto e é
  irrelevante**, porque o 1.2 nunca precisou ser destravado. Fica registrado
  como caminho percorrido, não como escopo.
- **Nada de segunda origem do gesto de criar.** Flyout de paleta,
  clique-para-adicionar, `+` por nó e command palette foram levantados no
  discovery como o preço de a paleta sumir de verdade. **A paleta não some.
  Nenhum deles entra.** Registrados em "Fora de escopo".
- **A faixa esquerda encolhe de dois botões para um.** Com a Árvore saindo do
  painel esquerdo (ver abaixo), o `PanelRail` esquerdo perde o botão "Árvore" e
  fica só com **expandir** — exatamente o print do Chrome. O **aceite 26 da F5**
  ("clicar no ícone Árvore reabre o painel na aba Árvore") **perde o objeto e
  precisa ser reescrito** para a aba "Propriedades".

### O layout: a Árvore vai para a direita (decisão do humano)

**Decidido: opção (b).** A **Árvore** passa a ocupar o painel **direito**; as
**Propriedades** viram a **aba ao lado de Widgets** no painel esquerdo.

| | hoje | depois |
| --- | --- | --- |
| Painel esquerdo | abas `Widgets` \| `Árvore` | abas `Widgets` \| `Propriedades` |
| Painel direito | Propriedades | **Árvore** |
| Colunas | 3 | **3** |

**O que isso compra:** paleta e árvore visíveis **ao mesmo tempo**, que é a
premissa inteira do 5.3 — sem custar largura. O piso do workspace continua
`412 + minCentro`, a largura do canvas não muda, e **o aceite 17-A da F3
sobrevive intacto**. A alternativa de três painéis laterais foi descartada: ela
subiria o piso para `618 + minCentro` (~938 px) e cortaria o canvas de 988 para
~700 px a 1600 px de janela — o oposto do objetivo do item 41.

**Trade-off aceito por ele:** o arraste da paleta até a árvore atravessa o
canvas. É percurso longo de ponteiro, e torna o autoscroll da árvore
(§"Riscos herdados") uma tarefa, não um detalhe.

### O gesto: **menu de destino** ao soltar no corpo do nó

**Decisão do humano (H6), 2026-08-16.** Nas palavras dele:

> "Eu mencionei a column, mas esse deve ser o comportamento padrão para qualquer
> widget, não só column, ok? (…) podemos simplificar com essas opções que são as
> possíveis, certo? Ex: **Inserir acima, Inserir dentro, Inserir abaixo, Envolver
> com**, daí o user escolher o que quer e a gente não precisa se preocupar com o
> arrastar na fresta."

Soltar no **corpo** de um nó **abre um menu com quatro opções**; o usuário
escolhe. Vale para **todo o catálogo**, não só `column`.

#### A P7 deixou de existir — e não por ter sido resolvida

A rodada anterior desta spec propôs a **P7**: uma regra para o que o corpo do nó
significa, derivada de `SlotKind` e da presença de fresta. **Essa regra foi
removida.** O motivo importa e fica registrado para não ser reinventado:

> **A decisão de desenho tornou a P7 vazia, não a respondeu.** A P7 existia para
> resolver "como o usuário adivinha qual das três coisas vai acontecer". Com o
> menu, **não há o que adivinhar: o sistema pergunta.** Uma regra que ninguém
> precisa decorar não é uma regra melhor — é uma regra que não precisa existir.

A tabela `SlotKind` → semântica **não morreu; mudou de função**. Ela deixa de
dizer *qual gesto significa o quê* e passa a dizer *quais opções do menu ficam
habilitadas*. Ver §"O menu, opção por opção".

#### Fresta e menu convivem — **decidido pelo humano (H8), 2026-08-16**

Ele disse "não precisa se preocupar com o arrastar na fresta". Isso admitia duas
leituras, e ele confirmou a segunda:

- **remover as frestas** — mas elas já funcionam desde o item 8e; removê-las é
  trabalho, não economia. E se **todo** drop virar menu, montar uma tela de 20
  widgets vira **20 diálogos**;
- **deixar de depender** delas para desambiguar — que é o que o menu resolve.

**H8 — Confirmado. As frestas ficam:**

| Onde se solta | O que acontece | Por quê |
| --- | --- | --- |
| **Fresta** (6 px, entre dois nós) | insere ali, **direto, sem menu** | é onde não existe ambiguidade nenhuma: a posição **é** a resposta |
| **Corpo do nó** (34 px) | abre o **menu de destino** | é exatamente onde hoje há adivinhação |

**Duas semânticas, não três**, e **nenhuma exige mira fina**: o corpo do nó
recuperou os 34 px inteiros porque parou de disputá-los com as outras duas. Quem
quer velocidade usa a fresta; quem quer certeza usa o corpo.

**A razão que fechou a decisão:** o que ele descreveu como imprevisível era soltar
**em cima** de um widget. A fresta nunca teve ambiguidade — a posição *é* a
resposta. Trocar as duas por menu resolveria um problema que a fresta não tem, e
cobraria um clique a mais em todo drop.

#### O menu, opção por opção

As **quatro opções aparecem sempre** — menu de tamanho estável, e "Envolver com"
continua **descobrível** mesmo quando o alvo da vez não a aceita. O que varia é
o que está habilitado.

| Opção | Desabilitada quando | Depende de |
| --- | --- | --- |
| **Inserir acima** | o alvo é a **raiz** (ver P13) | o **pai** do alvo |
| **Inserir dentro** | o alvo é `SlotKind.none`; ou é `single` **já ocupado** | o **alvo** |
| **Inserir abaixo** | o alvo é a **raiz** (ver P13) | o **pai** do alvo |
| **Envolver com** | o **widget arrastado** é `SlotKind.none` | o **widget arrastado** |

**Os dois motivos são de eixos diferentes, e é isso que o `SlotKind.none`
expõe.** "Inserir dentro" olha para o **alvo**; "Envolver com" olha para o
**arrastado**. Arrastar uma `Column` sobre um `Text`: "Inserir dentro" fica
cinza (o texto não recebe), **"Envolver com" fica habilitada** (a column
envolve o texto muito bem). Arrastar um `Text` sobre qualquer coisa: "Envolver
com" fica cinza, porque quem não pode envolver é o arrastado.

**As palavras que aparecem na tela**, para o motivo ser lido e não deduzido:

- alvo `SlotKind.none` → **"Text não recebe filhos"**
- alvo `single` ocupado → **"Container já tem um filho"**
- arrastado `SlotKind.none` → **"Text não pode envolver"**
- alvo é a raiz → **"A raiz não tem irmãos"**

#### Desabilitada com o motivo — não habilitada-e-depois-erro (P12, assumido)

Ele propôs: *"Deixa sempre as opções (…) disponível e o sistema diz o que
acontece após a escolha do user, se aceita ou se mostra o erro."*

**A spec assume a variante desabilitada-com-motivo, e a divergência está
registrada e ainda não foi respondida por ele.** A razão tem nome:

> Deixar clicar numa ação que não age é **exatamente** o padrão que o **item 39**
> nos custou caro — três dos sete casos da §11.0 do `plan.md` são disso
> (`loadingBuilder` passado e nunca renderizado, `width: 0` legítimo e invisível,
> `Ctrl+Shift+W` mapeado e nunca recebido). O controle presente que não produz
> efeito é o defeito mais caro do repositório, e ele já tem jurisprudência.

O motivo **visível ao lado da opção cinza** entrega o que ele quer — *o sistema
diz o que acontece* — **antes** do clique em vez de depois, e sem gastar uma
mensagem de erro para explicar uma escolha que nunca deveria ter sido oferecida.

**Com o `wrapNode` estendido aos 12 (P8), quase nada fica cinza.** O
`SlotKind.none` é o resto irredutível.

#### P13 — A raiz é o caso que o menu criou (pendência do dev)

"Inserir acima" e "Inserir abaixo" pedem um **pai** que receba o irmão. **A raiz
não tem pai.** Hoje esse caso é resolvido em silêncio: `resolveDrop` devolve
`DropRequiresWrap` e o editor **envolve a raiz numa `column` sozinho**, avisando
só depois (`EditorNoticeKind.dropWrapped`).

Com um menu que existe para acabar com a adivinhação, manter uma ação composta
escondida atrás de "Inserir acima" contradiz o desenho. **Duas saídas, e é
decisão dele:**

- **(a)** as duas ficam **cinzas** na raiz, com "A raiz não tem irmãos" — honesto,
  e o usuário usa "Envolver com" explicitamente se quiser o mesmo efeito;
- **(b)** ficam **habilitadas** e realizam o wrap implícito, **dizendo-o no
  próprio rótulo** ("Inserir acima — envolve a raiz em Column").

**A spec assume (a)**, por ser a que não esconde operação composta atrás de
rótulo simples.

### O que muda de contrato (não é regressão acidental)

O caso **`'soltar sobre uma linha manda o alvo, não o índice'`** em
`apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/widget_tree_panel_test.dart`
codifica hoje "**corpo do nó = adicionar como filho**". A P7 troca isso por
"corpo = envolver" para `none`, `single` ocupado e `multi`.

**É troca de semântica declarada, não quebra a corrigir.** O teste muda junto,
no mesmo PR, e a descrição do PR nomeia a troca. A semântica antiga não é
perdida: ela sobrevive onde é a única saída (`single` vazio) e foi substituída
pelas frestas onde elas já cobriam (`multi`).

### Envolver com quê: `wrapNode` só aceita 6 dos 12

`wrapNode` (`packages/sdui_core/lib/src/ops/tree_ops.dart:127`) abre com
`if (descriptorFor(wrapperType)?.slot != SlotKind.multi) return null;`. Os
wrappers `SlotKind.single` — **`container`, `card`, `padding`, `center`,
`sizedBox`, `expanded`** — devolvem `null` **em silêncio** (em `wrapSelected` é
um `assert`, que só existe em debug).

Com "Envolver com" virando **item permanente de menu**, isso deixa de ser
limitação e vira mentira: ver a opção, escolhê-la e nada acontecer é o caso 2/3
da §11.0 do `plan.md` — controle presente na API, sem efeito na tela. O menu
**agrava** o problema em relação ao hover, porque uma opção de menu promete mais
do que um realce.

**P8 — Estender `wrapNode` para `SlotKind.single`. APROVADO pelo dev.** O alvo
vai para `child` em vez de `children`. A mudança é pequena porque `_rebuild`
**já** trata o alvo sentado num slot único (`tree_ops.dart:139`,
`current.copyWith(child: () => wrapper)`); falta só montar o wrapper com `child`
quando o descriptor for `single`. Teste em
`packages/sdui_core/test/ops/tree_ops_test.dart`.

**Por que estender em vez de esconder para os 6:** `container` e `padding` são os
envelopes mais pedidos de um builder. Um "Envolver com" que recusa justamente
eles obriga o dev a descobrir a regra na mão, uma tentativa por tipo.

Wrappers possíveis depois da P8: **12** (`multi` + `single`). Impossíveis: os
`SlotKind.none`, e para esses a opção aparece **cinza com o motivo ao lado**
(P12), não escondida — menu de tamanho estável.

### O nó inválido residente na árvore — **aprovado como fase própria (H7)**

Ele pediu:

> "deve ser possível validar se tal componente pode ser soltado naquela posição
> sem quebrar a árvore de widgets. Nesse caso o widget até poderia aparecer na
> lista mas marcado como erro até que o user arraste ele pro local adequado ou
> exclua ele da árvore."

**Decisão do humano (H7), 2026-08-16: entra, como fase própria — PR separado,
depois desta entrega.** O PM havia recomendado o contrário, e o registro de por
que a recomendação caiu importa mais do que a recomendação.

**A recomendação de recusa dizia:** o drop que produziria um nó inválido **não
existe**. `resolveDrop` nunca devolve árvore inválida — ele aceita, **redireciona**
para o primeiro ancestral que recebe (`DropAccepted.redirected`), ou pede **wrap**
(`DropRequiresWrap`). As duas únicas recusas genuínas são `unknownTarget` (alvo
sumiu) e `cycle` (mover um nó para dentro de si mesmo), e nenhuma das duas se
resolve deixando o nó marcado na árvore.

**O que derrubou a recomendação: o menu de destino (H6) cria a causa que não
existia.** Enquanto o destino era inferido pelo sistema, o sistema só inferia
destinos que funcionam — daí "não há drop que produza inválido". Com o menu, **o
usuário escolhe**, e pode escolher um destino que o sistema não realiza. A
premissa da recusa era verdadeira sobre o código de ontem e deixou de ser sobre o
desenho de hoje.

**A ordem que isto impõe:** a fase do nó inválido vem **depois** da fase do menu.
Antes dela, não há como produzir o estado que ela trata — e uma fase que constrói
marcação de erro sem um caminho que a produza não tem como ser testada.

**O motivo de arquitetura, que é o mais caro:** um nó inválido residente
significa que o `PageSpec` em edição passa a poder estar **temporariamente
inválido**. Isso abre três frentes que não são de UI:

1. **Política de salvar** — bloqueia? salva marcado? avisa? Hoje o rascunho vai
   para o backend como JSONB **sem interpretação** (o backend não lê spec), então
   um spec inválido faz round-trip e chega ao item 24 (publicação) e ao app
   cliente.
2. **O rodapé de problemas ganha um tipo novo** — hoje ele diz "Nenhum problema"
   e o item 38 acabou de fazer dele a fonte de verdade dos erros.
3. **O kernel passa a ter dois níveis de validade** (parseável vs. correto), e
   `parsePageSpec` é hoje a única porta de entrada.

**As três frentes acima são o escopo da fase própria** — e a primeira, a política
de salvar, é a que precisa ser decidida pelo humano antes de a fase abrir. Não é
detalhe de implementação: define se um spec marcado como inválido pode chegar ao
item 24 (publicação) e ao app cliente.

**O que ela ganha de graça mais adiante:** quando o catálogo ganhar restrições de
composição ("`listView` só aceita filhos `listItem`"), que hoje não existem — o
`_accepts` só olha `SlotKind`, nunca o tipo do filho —, a marcação já estará
construída e passa a cobrir também esse caso.

**O que acontece com o drop recusado até lá — e não é silêncio.** O item
39 ensinou que recusa muda não é recusa. As três recusas (`unknownTarget`,
`cycle`, e a nova "wrapper é `SlotKind.none`") passam a ser **visíveis durante o
gesto**: o realce do alvo vira estado de recusa (cor + ícone + cursor, nunca só
cor — regra de a11y), e ao soltar, o rodapé registra o motivo. Isso é **tarefa
desta entrega**, e é o substituto honesto do nó marcado.

### Riscos herdados que esta rodada carrega para o plano

Levantados no discovery técnico e **não resolvidos pela decisão de layout** —
o `plan.md` precisa de tarefa para cada um:

- **R-a — largura por slot, não por painel.** A largura mora no `State` de
  `_ResizableSplitViewState` indexada pelo **slot**, não pelo painel. Trocar
  Árvore ↔ Propriedades faz o Inspector herdar a largura da paleta no primeiro
  frame. Problema de `Key`, barato — e **silencioso**, que é o que o torna
  perigoso.
- **R-b — zero testes na estrutura que vai ser invertida.**
  `ResizableSplitView`, `LeftPanel`, `CenterArea` e `InspectorArea` **não têm um
  teste**. Inverter as colunas hoje passa na suíte inteira. **Rede antes da
  mudança estrutural** — aceita pelo tech-manager, registrada como pré-requisito
  no PRD. Não contraria "bateria por último": é rede de refatoração, não bateria
  da feature.
- **R-c — a árvore permanente liga o caminho quente que a D8 protege.** Hoje o
  `TabBarView` desmonta a Árvore fora de foco (é a causa do defeito 1.1). Como
  painel permanente, o `BlocSelector` com `_structureKey` — que **serializa a
  árvore inteira em string a cada `emit`** — e o `_buildRows` recursivo passam a
  rodar em toda mudança estrutural, o usuário olhando ou não.
- **R-d — sem autoscroll na árvore durante o arraste.** `ListView` comum, nenhum
  `ensureVisible`. Nó abaixo da dobra é **inalcançável mid-drag**. Tolerável
  enquanto o canvas era o alvo principal; **bloqueio** agora que a árvore é.
- **R-e — criar widget segue 100% dependente de ponteiro.** `PaletteItem` é
  `Draggable` sem `Semantics`. **Não é bloqueio** (a paleta não some mais), mas
  é dívida registrada: não há caminho por teclado para criar um widget.
- **R-f — dois goldens com duas causas.** `goldens/canvas_device_mock.png` (que
  captura o `CanvasPanel`, o `Expanded` do centro) e o caso `'editor pronto monta
  os três painéis'` de `editor_perf_test.dart` (que assere `find.text('Widgets')`
  e `find.text('Árvore')` como **rótulos de aba**) quebram. A F3 **também**
  regrava esse mesmo golden. **A ordem importa e cada regravação precisa nomear
  a sua causa** — dois motivos no mesmo arquivo é onde a régua do item 39 deixa
  de discriminar.

### Impacto no item 21 (registrar, não resolver)

`docs/plans/21-aba-componentes-editor/plan.md` especifica *"uma **terceira aba**
do painel esquerdo — ao lado de Widgets e Árvore"*. Depois desta rodada seria
**ao lado de Widgets e Propriedades**. A TabBar não morre, muda de conteúdo — o
item 21 continua encaixando, com o texto do plano dele desatualizado. **Registrado
aqui; a correção é do plano do 21.**

### Decisões do humano nesta rodada

- **H1 — O incômodo é ver árvore e paleta ao mesmo tempo**, não a falta de um
  alvo de drop (que já existe). Responde a Q1.
- **H2 — Semântica por zona, sem tecla modificadora:** corpo do nó = envolver;
  fresta = inserir irmão naquela posição. Responde a Q4 pela opção (a).
- **H3 — As duas origens de arraste valem:** da paleta **e** de nó existente
  dentro da árvore.
- **H4 — Colapsar painel é só ganhar espaço visível**, e o painel colapsado
  precisa ser expandido para voltar a ser usado. Mantém a A3/D2; absorve o 1.2
  na F5.
- **H5 — Layout:** Árvore para o painel direito, Propriedades para a aba ao lado
  de Widgets. Responde a Q3 pela opção (b).

### Propostas do PM nesta rodada (abertas a veto)

- ~~**P7** — a regra do corpo do nó.~~ **Vazia desde a H6:** o menu de destino
  removeu a adivinhação que a P7 existia para regular.
- **P8** — estender `wrapNode` para `SlotKind.single`; affordance escondida só
  para `SlotKind.none`.
- ~~**P9** — nó inválido residente sai de escopo.~~ **Recusada pelo humano
  (H7):** entra como fase própria, depois da fase do menu. A recusa visível
  durante o gesto continua nesta entrega, como ponte até lá.
- **P10 — Ordem de entrega:** rede de teste (R-b) → **F3** → troca de colunas →
  kernel (P8) → o gesto → F5. **A F3 antes da troca de colunas** porque as duas
  regravam `canvas_device_mock.png`, e sequenciá-las é o que mantém uma causa por
  regravação (R-f). O kernel corre em paralelo com a troca de colunas: são
  camadas diferentes e não se tocam.

---

## Fora de escopo (declarado, para não voltar como surpresa)

- **Item 30** — variação do spec por breakpoint. Nome parecido, problema outro.
- **Item 24** — publicação e versionamento. Este item não antecipa nada dele,
  e **não deve** construir sobre a rota pública servindo rascunho.
- **Item 26** — auth. Uma URL de preview aberta é dívida registrada, não
  resolvida aqui.
- **Item 28** — eventos e ações. Preview interativo de verdade depende dele.
- **Layout do editor para celular** — se A1 responder (iii), vira item próprio.

**Acrescentado na rodada 02:**

- **Nó inválido residente na árvore, marcado como erro** — **não é mais fora de
  escopo do item**, e sim **fase própria depois da fase do menu** (H7). Fora
  desta *entrega*, dentro do item. A política de salvar um spec marcado como
  inválido é decisão pendente do humano antes de a fase abrir.
- **Segunda origem do gesto de criar** — paleta como flyout/overlay,
  clique-para-adicionar, `+` por nó da árvore, command palette (`Ctrl+K`). Foram
  levantados no discovery como o preço de a paleta sumir de verdade. **A paleta
  não some** (H4), então nenhum deles tem justificativa agora. Registrados para
  não voltarem como ideia solta.
- **Três painéis laterais** — descartado por custo de largura: piso de ~938 px e
  canvas caindo de 988 para ~700 px a 1600 px. Contradiz o objetivo do item 41.
- **Caminho por teclado para criar widget** — a dívida do **R-e** fica registrada,
  não paga aqui.
- **Remover os botões "Envolver em Column/Row" da F2 do item 38** — decisão
  explícita do dev: o 5.3 é **adição**, não substituição. O comando existente
  fica.

---

## Decisões do humano que sustentam esta spec

**Rodada 01 (A1–A10).** Respondidas e registradas nominalmente no `plan.md` como
**D1** (A1), **D2** (A3), **D3** (A6), **D4** (A7) e **D20** (a decisão de
2026-08-16 sobre celular). A **Q2** do plano (colapso do Inspector por rótulo ou
por tipo de nó) segue como decisão do PM com veto fácil na revisão da F6.

**Rodada 02 (5.3 + 1.2).** **H1** a **H5**, na seção da rodada 02 acima. As
propostas do PM em aberto são **P7** a **P10**, todas com veto fácil antes de a
fase abrir.
