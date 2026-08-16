# Plano — O editor devolve a tela ao construtor, e o conteúdo cabe no celular

_Item **41** do roadmap (Marco 4 — Ergonomia do construtor). **Não existe plano de
gaveta**: escopo novo, nascido do pedido do dev humano em 2026-08-15. A matéria-prima
é [`specs.md`](specs.md) + [`prd.md`](prd.md) desta pasta; onde este plano divergir do
PRD, **este manda**, e o motivo está na §8._

> **Regra do "pronto":** `flutter analyze` verde + testes existentes passando. Nunca opinião.
> **Toca backend?** Não — nenhuma linha, em nenhuma fase. **Toca `sdui_core`?** Não.
> **Gate CISO?** Não é obrigatório em nenhuma fase (§4›D3 explica por que a rota de
> preview não abre superfície nova). **0-dep de roadmap:** sim — não antecipa nem
> depende dos itens 24, 26, 28 ou 30.
> **Alvos:** `apps/driva_editor/` (módulos `editor_module` e `core/`). Nada em
> `packages/`, nada em `backend/`.

---

## Estado

**2026-08-15 — plano escrito, nenhuma fase iniciada.** As quatro ambiguidades caras do
`specs.md` foram fechadas pelo humano (A6, A1, A3, A7 — §4›D1 a D4). Duas questões
menores continuam abertas e estão nomeadas na §9; nenhuma delas bloqueia a F1.

**Pré-condição dura, herdada da invariante I6 do `specs.md`:** este item **não abre a F1
nem a F3** antes de o E2E dos itens **38** e **39** estar atestado pelo humano. A F1 mexe
em `canvas_panel.dart`, que é arquivo da F3 do item 39 e está **neste momento** sendo
instrumentado para E2E em `docs/16-image-url-e-props/`. As fases **F2 e F4 podem começar
antes** — não tocam nenhum arquivo dos dois itens (§6).

| Fase | O que entrega | Dono | PR | Estado |
| --- | --- | --- | --- | --- |
| F1 | O piso: os overflows morrem e o mock se ajusta à janela | especialista-apresentacao | — | `[ ]` |
| F2 | Rota `/preview/:projectId/:id` — o conteúdo no celular | especialista-apresentacao + especialista-infra | — | `[ ]` |
| F3 | Painel colapsa numa faixa fina de ícones | especialista-apresentacao | — | `[ ]` |
| F4 | Grupos da paleta colapsáveis | especialista-apresentacao | — | `[ ]` |
| F5 | O layout é lembrado entre sessões | especialista-dominio + especialista-dados + especialista-apresentacao | — | `[ ]` |
| F6 | Modo tela cheia | especialista-apresentacao + especialista-infra | — | `[ ]` |
| F7 | E2E manual em homologação, executado e **atestado pelo humano** | qa instrumenta · dev humano atesta | — | `[ ]` |
| F8 | Bateria automatizada + docs vivas | qa | — | `[ ]` |

Legenda: `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída e revisada pelo QA.

---

## 1. Objetivo e recorte

O editor cresceu por dentro — 24 primitivos, Inspector com seções, árvore com
drag-and-drop — e **a área onde se vê o resultado não cresceu junto**. Este item devolve
espaço de tela ao construtor e dá ao dev um jeito de ver o conteúdo no aparelho, sem
antecipar nada dos itens 24, 26, 28 ou 30.

**Em uma frase:** o dev abre o editor e o mock já está ajustado à janela; colapsa os
painéis que não usa e o mock cresce na hora; acha o widget na paleta sem rolar; e abre
uma URL no celular para ver o conteúdo no tamanho real — tudo sem perder o ajuste no
refresh.

**O que este item não é.** Não é o **item 30** ("Responsividade — o spec ganha variação
por breakpoint"). Aquele é o **conteúdo SDUI do cliente** ficando responsivo, no kernel,
no formato do JSON. Este é a **ferramenta** ficando usável, no Flutter Web do editor,
sem tocar em `sdui_core`. Ver §4›D5, que existe para impedir que alguém funda os dois.

---

## 2. O que está quebrado hoje, medido no código

### 2.1 O chrome fixo come o centro, sempre

`ResizableSplitView` monta `SizedBox(280) · handle(6) · Expanded(centro) · handle(6) ·
SizedBox(320)`. **612 px de chrome fixo**, em qualquer tela. O centro fica com
`viewport − 612`, e não há `LayoutBuilder` nenhum: o widget não sabe o tamanho da janela.

### 2.2 O mock não cabe, e o zoom é manual

`CanvasPanel` desenha `Transform.scale(scale: zoom)` sobre a `DeviceFrame`. O `zoom` vem
do `EditorCubit` (`0.9` de fábrica, clampado em `0.4–1.5` por `changeZoom`) e **só muda
por clique nas lupas**. Não existe "ajustar à janela".

A largura real que a moldura ocupa **não é** `device.width`: a `DeviceFrame` soma
`bezel` dos dois lados (`Container(padding: EdgeInsets.all(bezel))`) e mais
`bezel * 0.55` de cada lado para os botões laterais transbordarem
(`Padding(horizontal: buttonWidth)`), fora a borda de 1 px. E o `CanvasPanel` ainda
envolve tudo num `Padding(all: AppSpacing.s32)`.

| Preset | `device.width` | Moldura ≈ | Com o padding do canvas ≈ | Altura da moldura ≈ |
| --- | --- | --- | --- | --- |
| Smartphone | 393 | 436 | **500** | 880 |
| Android | 412 | 449 | **513** | 939 |
| Tablet | 820 | 888 | **952** | 1224 |

**Correção do PRD:** ele estimou ~863 px para o tablet, contando só `bezel`. São **~952**
— o preset tablet não cabe numa janela de 1440 (centro de 828) e **nem numa de 1600**
(centro de 988) com folga. Registrado na §8.

### 2.3 Três overflows que já estão no ar

1. **Breadcrumb (faixa 2).** `AppShellBreadcrumbBar` monta uma `Row` **sem nenhum filho
   flexível**, e o `CrumbLabel` pede `overflow: TextOverflow.ellipsis` num `Text` de
   largura ilimitada — a elipse **nunca dispara**. Nome de projeto/conteúdo longo estoura
   já a 1280.
2. **Faixa 1.** `AppShellTopBar` monta `wordmark · Spacer · 4 ações · status · tema`. O
   `Spacer` é o único elemento flexível: quando ele chega a zero, a `Row` estoura. Na
   rota do editor são 4 ações (undo, redo, Salvar, Publish) + status + botão de tema.
3. **Workspace.** Abaixo de 612 px o `Row` do split view estoura de verdade.

### 2.4 Nada é lembrado

O arraste do splitter já existe (min 200 / max 480), mas o estado é `State` local do
`ResizableSplitView`: **some no refresh e a cada navegação**. O Inspector já colapsa
seções desde o item 9b (`PropSection`, com `initiallyExpanded`), mas **reabre tudo** a
cada troca de nó e a cada refresh. Hoje a **única** chave persistida no app é
`preferences.theme_mode`.

### 2.5 Não há caminho nenhum para o aparelho

O editor é o único Flutter Web deployado. Não existe rota de preview, e o `projectId`
**não está na URL de rota nenhuma do editor** (`/contents/:id/edit` carrega só o id do
conteúdo).

---

## 3. O que já existe e vamos reusar

### 3.1 Editor

- **`ResizableSplitView`** (`core/widgets/layout/`) — 53 linhas, `StatefulWidget` com
  `_leftWidth`/`_rightWidth` e `_clamp`. Recebe `left`/`center`/`right` como campos
  `Widget` **já construídos** pelo `build` do `EditorWorkspace`. É essa construção
  antecipada que faz o `setState` do split view não reconstruir painel nenhum — o
  mecanismo que o item 3b domou e que a §4›D8 protege.
- **`EditorCubit` / `EditorReady`** — já carrega `device` e `zoom`, com
  `changeDevice`/`changeZoom`, lidos por `BlocSelector` no `CanvasArea`.
- **`DevicePreset`** — enum de 3 entradas com `bezel`, `cornerRadius`, `notch` e
  `safeAreaTop/Bottom`.
- **`PropSection`** — colapso do Inspector, com `initiallyExpanded` já no construtor.
  Ganha um callback na F5; **não é promovido** (I4).
- **`WidgetPalettePanel`** — já agrupa por `WidgetCategories.inPaletteOrder` (kernel),
  com busca por `_query`. Falta o cabeçalho ser clicável.
- **`EditorShortcuts` / `editor_intents.dart`** — infra de `Shortcuts`/`Actions` do item
  23, pronta para receber o atalho da F6.
- **`core/theme/`** — `AppSpacing`, `AppRadii`, `AppTypography`, `AppDurations`,
  `AppIconSizes`, `EditorColors`, `DeviceMockColors`. Barrel `theme.dart`.

### 3.2 Shell e roteador

- **`AppShellController extends ChangeNotifier`** + **`AppShellScope extends
  InheritedNotifier`** — slots `crumbs`, `actions`, `status`; a página publica por
  `AppShellSlot`, com dono por token e publicação sempre em `addPostFrameCallback`. **É o
  canal legítimo do "modo imersivo" da F6, e mantém a regra do item 16c (o shell não lê
  cubit).**
- **`app_router.dart`** — `rootNavigatorKey` e `shellNavigatorKey` separados; as 4 rotas
  existentes vivem **todas** dentro do `ShellRoute`. Uma rota irmã no `routes:` do root
  nasce sem chrome, de graça.
- **`ProjectScope`** (`core/network/project_scope.dart`) — singleton no get_it, campo
  `String projectId` mutável. É lido pelo interceptor do Dio, que carimba
  `x-project-id` em **toda** requisição. Escrito em **um único lugar**:
  `ProjectDetailPage.pageBuilder`.
- **nginx (`apps/driva_editor/deploy/nginx.conf`)** — `location / { try_files $uri $uri/
  /index.html; }`. **O SPA fallback já cobre qualquer caminho**, então
  `/preview/<uuid>/<uuid>` digitado frio no celular resolve. Risco eliminado antes da F2.

### 3.3 Persistência

- **`preferences_module`** é o dono do `registerSingleton<SharedPreferences>` e é o
  **primeiro** módulo registrado no `setupInjection` — qualquer módulo posterior
  (inclusive o `editor_module`) já resolve `getIt<SharedPreferences>()`. A instância vem
  do `bootstrap.dart`, **antes do primeiro frame**.
- O padrão da casa está no `PreferencesRepositoryImpl`: chave string privada
  (`'preferences.theme_mode'`), model `abstract final class` com schema **zard** e
  `tryParse → Either`, ausência **não é erro** (devolve o padrão em `Right`).

### 3.4 O que NÃO existe

- **Nenhum `LayoutBuilder`** em `apps/driva_editor/lib/`, e um único `MediaQuery` (dentro
  do mock, item 8f). Responsividade do editor hoje não é parcial: é inexistente.
- **Nenhum token de tamanho.** `height: 44` da toolbar do canvas, `height: 56` da faixa
  1, `height: 30` da faixa 2, `iconSize: 18` — todos crus. Não há `AppSizes`.
- **Nenhum `AppBreakpoints`** — e §4›D5 decide que **não nasce nesta feature**.
- **`qr_flutter` não é dependência** do editor (§4›D4 e §9›Q1).
- **`EditorCubit` não está no get_it** — é instanciado à mão no `EditorPage.pageBuilder`.
- **`editor_module` não tem nenhuma persistência local** — o `editor_injection.dart` tem
  3 registros (repo + 2 use cases), nenhum toca `SharedPreferences`.

---

## 4. Decisões travadas

### D1 — O piso da responsividade é: matar os overflows + ligar o "ajustar à janela" — **[humano, A1]**

Nada de comportamento por faixa de largura nesta fatia. O editor **não** precisa abrir em
celular; editar SDUI num telefone é outro produto. A régua desta decisão é objetiva e
está no DoD: **não existe largura de janela em que o editor mostre a faixa listrada de
overflow.**

### D2 — Painel colapsado vira faixa fina de ícones, não some — **[humano, A3]**

A razão é dura: com a paleta sumida **não há de onde arrastar widget**. O controle de
reabrir tem de estar sempre visível, dentro da própria faixa — não num menu, não só num
atalho.

### D3 — O preview no celular é a rota `/preview/:projectId/:id` no próprio editor — **[humano, A6]**

Uma URL sem chrome, servida pelo mesmo domínio que já está no ar. **1 fase, zero backend,
zero deployável novo, zero gate CISO.**

Descartadas, com o porquê registrado:
- **A via API pública + `driva_demo_app`** — 3 a 4 fases com CISO obrigatório, exige
  deployável novo, antecipa os itens 24 e 26, e **quebraria no dia em que o item 24
  entrar**: o PRD do 24 já decidiu que `/v1/public` passa a servir **só o publicado**,
  com `404` sem publicação e **sem backfill**. Preview de rascunho por ali é construir
  sobre areia.
- **O modo tela cheia como substituto** — continua sendo o desktop, não o aparelho. Entra
  na F6 porque é barato e vale por si, **não** como resposta ao pedido do celular.

**Por que não precisa de CISO:** a fase não cria endpoint, não muda auth e não amplia o
que a API expõe. O backend não tem auth nenhuma hoje (item 26 aberto) e o rascunho já é
alcançável por quem conhece a URL da API — o que a rota acrescenta é **materializar isso
num link que sai do laptop**, e o humano aceitou esse custo (A8), que segue registrado
como dívida do item 26 no risco R3.

### D4 — O preview mostra o último salvo, e diz isso na tela — **[humano, A7]**

Não existe autosave; salvar é botão / `Ctrl+S`. O fluxo real é **salvar → recarregar no
celular**, e a página tem de dizer isso, senão a primeira coisa que acontece é o dev
concluir que está quebrado. A forma: uma **pílula flutuante** no rodapé do preview —
`Último salvo · HH:MM · toque para recarregar` — que refaz a busca ao toque. Ela resolve
os dois problemas de uma vez: comunica a semântica **e** dá o recarregar sem depender do
botão do navegador, que some quando a página está em tela cheia no celular.

Autosave/ao vivo (polling ou SSE) custaria +2 a +3 fases e fica **fora** (§12).

### D5 — Não nasce `AppBreakpoints` nesta feature, e nenhum número desta feature é um breakpoint — **[tech-lead]**

Com a D1 valendo, **não há comportamento por faixa de largura para tokenizar**. Tudo o
que esta feature faz é mecânico: `Flexible`, piso do centro, `LayoutBuilder`, escala
calculada. Criar `AppBreakpoints` agora seria fabricar um vocabulário sem cliente — e a
chance de alguém depois **fundi-lo** com o `enum SduiBreakpoint {compact, medium,
expanded}` do item 30 (limiares Material 3: 600 / 1024) é alta o bastante para justificar
não criá-lo.

**Quando ele nascer** (item 30, ou uma fatia futura de comportamento por faixa), a
invariante I3 do `specs.md` continua de pé: **usa os mesmos números (600 / 1024) e não
importa o enum do kernel** — chrome do editor é tema, breakpoint do spec é kernel.

**Corolário que o implementador precisa ler:** o limiar do menu de overflow da faixa 1
(F1) **não é um breakpoint**. É a largura em que aquela barra específica para de caber,
medida no próprio conteúdo dela. Mora em `AppSizes` com nome que diz isso
(`topBarActionsFitWidth`), nunca em algo chamado `AppBreakpoints`, e **não** governa
comportamento de mais nada.

### D6 — O `imageUrlResolver` sai de método privado da `EditorPage` e vira fábrica compartilhada — **[tech-lead, invariante I1]**

Hoje `EditorPage._imageUrlResolverFor(AppConfig)` é `static` e **privado**. A F2 cria uma
segunda página que renderiza SDUI. Duplicar a guarda (`apiBaseUrl.isEmpty ||
useFakeData → null`) é como a regressão do item 39 volta: a segunda página esquece a
guarda, ou esquece o resolver inteiro, e **a imagem de host sem CORS falha em silêncio**.

**Decisão:** o método vira uma função de topo em
`core/network/image_url_resolver_factory.dart`, exportada pelo `network.dart`, com o
comentário do porquê preservado. As duas páginas (`EditorPage.pageBuilder` e
`PreviewPage.pageBuilder`) — os únicos lugares autorizados a tocar o get_it — chamam a
mesma função. **A invariante I1 deixa de ser lembrete e vira estrutura**, e por isso ela
tem aceite próprio na F2 (DoD 20), com print, não com grep.

### D7 — Esta feature **não** dispara a refatoração do `VR-16-02`, e instala o soquete dela — **[tech-lead]**

O `VR-16-02` registrou que **cinco níveis de repasse por construtor é o teto**, e que o
sexto vira `InheritedWidget` escopado — pago por quem precisar dele.

**Levantamento:** nada novo viaja a cadeia `EditorPage → EditorWorkspace → CenterArea →
CanvasArea → CanvasPanel → PreviewSurface`. O `imageUrlResolver` continua sendo o único
passageiro (e a D6 só troca **onde ele é construído**, não o caminho). O que a F1
acrescenta ao `CanvasPanel` (a escala de ajuste) nasce **dentro dele**, num
`LayoutBuilder`. O que a F3 e a F5 acrescentam vai para `ResizableSplitView`, que está a
**dois** níveis da página. **O sexto nível nunca é alcançado — esta feature não paga a
refatoração.**

O que ela faz é instalar o **soquete**: a F3 monta um `EditorLayoutScope`
(`InheritedNotifier<EditorLayoutController>`) no `EditorWorkspace.build`, porque o
gatilho da tela cheia (F6) vem de fora do split view. É exatamente o padrão que o
`VR-16-02` nomeou. **O próximo item que precisar de um sexto passageiro no caminho do
canvas move o `imageUrlResolver` para um escopo análogo — e é ele que paga.**

### D8 — O colapso e as larguras **não** entram no `EditorCubit` — **[tech-lead, invariante I2]**

Duas razões:
1. O item 30 já reservou assento no `EditorReady` (`editingBreakpoint`), e todo `emit` é
   o caminho quente que o item 3b otimizou.
2. Não precisa: os painéis chegam ao `ResizableSplitView` como campos `Widget` **já
   construídos** pelo `build` do `EditorWorkspace`, que **não roda** quando o split view
   se atualiza. As instâncias são idênticas, o Flutter curto-circuita e **nenhum painel
   reconstrói** — custa só o `Row`.

**A parte que se erra sem perceber (R6):** o `ValueListenableBuilder` do
`EditorLayoutController` tem de ficar **dentro do `build` do `ResizableSplitView`,
envolvendo só a `Row`**. Colocá-lo no `EditorWorkspace.build`, em volta do
`ResizableSplitView`, reconstrói `LeftPanel`, `CenterArea` e `InspectorArea` **a cada
clique de colapso** — e desfaz o item 3b sem nenhum sintoma visível.

**Este aceite é de máquina, não de print.** Não há estado visível que o denuncie: o
`State` dos painéis sobrevive ao rebuild, então foco, texto digitado e aba selecionada
continuam lá. Está no DoD como teste de widget com contador de builds (F8, DoD 8) —
**não invente um print que não prova isto.**

### D9 — A escala de ajuste **não** passa pelo `changeZoom` — **[tech-lead]**

`EditorCubit.changeZoom` clampa em `0.4–1.5`. O tablet numa janela de 1024×720 precisa de
uma escala **abaixo de 0.4** para caber — ou seja, empurrar o ajuste pelo `changeZoom`
faria o fit falhar **exatamente no caso que motivou o fit**.

**Decisão:** o cubit guarda só `fitToWindow: bool`. A escala é calculada no widget, num
`LayoutBuilder`, e usada direto no `Transform.scale`. O clamp `0.4–1.5` continua valendo
para o zoom **manual**, que é o que ele sempre foi.

Corolários:
- **O ajuste nunca amplia além de 100%** (`min(escala, 1.0)`). "Ajustar" é fazer caber,
  não encher a tela; para maior existe o zoom manual.
- **A barra do canvas mostra a escala efetiva.** Se ela mostrasse `90%` enquanto o mock
  está a `43%`, a barra mentiria — e a mentira é indistinguível do fit não estar
  funcionando. Isso obriga o `LayoutBuilder` a envolver **a `Column` inteira** do
  `CanvasPanel` (toolbar + canvas), não só o canvas.
- **O `LayoutBuilder` fica FORA do `InteractiveViewer`.** O `InteractiveViewer` está com
  `constrained: false`, então o filho dele recebe restrição **infinita** — um
  `LayoutBuilder` lá dentro devolve `Infinity` e a conta do ajuste vira `NaN`.

### D10 — O tamanho externo da moldura vira propriedade do `DevicePreset` — **[tech-lead]**

A conta da §2.2 (`bezel` dos dois lados + `bezel * 0.55` de botão de cada lado) hoje mora
espalhada dentro do `build` da `DeviceFrame`. Se o ajuste recalcular essa conta por
conta própria, as duas divergem no dia em que alguém mexer na moldura — e o sintoma é o
mock cortado por alguns pixels, que ninguém associa à causa.

**Decisão:** `DevicePreset` ganha `Size get frameSize`, e **a `DeviceFrame` passa a
consumir o mesmo getter**. Uma conta, um lugar.

### D11 — A persistência é repositório próprio do `editor_module`, não ampliação do `preferences_module` — **[tech-lead, A4]**

O `preferences_module` é genérico (tema); o barrel dele **nem exporta** o contrato
`PreferencesRepository`. Fazê-lo saber do layout do editor inverte a dependência: um
módulo genérico passaria a conhecer um específico.

**Decisão:** `editor_module` ganha a própria pilha, no mesmo formato do
`EditorRepository` que já tem — entidade `EditorLayout` (Equatable, domain puro),
contrato `abstract interface class` devolvendo `Either<Failure, T>`, **um use case por
operação**, model com schema **zard** e impl com o único `try/catch`. **Nada novo é
bootstrapado:** `SharedPreferences` já está no get_it, registrado pelo
`preferences_module`, que é o primeiro do `setupInjection`.

Chave única: **`editor.layout`**, espelhando `preferences.theme_mode`. Um JSON só,
validado por zard na leitura.

### D12 — Preferência ausente ou corrompida cai no padrão **em silêncio** — **[PRD]**

Layout salvo **não é dado do usuário**: é conforto. Ausente devolve o padrão em `Right`
(padrão do `PreferencesRepositoryImpl`); corrompido devolve `Left(ValidationFailure)` e o
`EditorLayoutController` **dobra para o padrão sem propagar** — nada de banner, nada de
tela de erro. **Nunca pode bloquear a abertura do editor**, e isso tem prova própria no
DoD (item 25), porque é a linha mais fácil de escrever e mais fácil de não cumprir.

### D13 — A largura restaurada é **reclampada**, nunca aplicada cega — **[PRD]**

Contra `minPanelWidth`/`maxPanelWidth` (200/480) **e** contra o que a janela atual
comporta. Uma largura de 480 salva num monitor grande, restaurada numa janela de 1024,
não pode produzir painel maior do que cabe.

### D14 — Abaixo do somatório dos mínimos, o workspace **rola na horizontal** — **[tech-lead]**

Os mínimos somam `200 + 200 + 12 + minCentro`. Abaixo disso alguma coisa tem de ceder, e
as opções eram: encolher os painéis até ficarem inúteis, deixar o centro sumir, ou
rolar. **Rolar é a única degradação honesta** — nada desaparece, nada mente, e não é
"comportamento por faixa de largura" (D1): é **um** piso mecânico, não uma faixa.

Mecânica: `LayoutBuilder` → `rowWidth = max(constraints.maxWidth, somaDosMinimos)` →
`SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: rowWidth,
child: Row(...)))`. O `SizedBox` é o que mantém o `Expanded` do centro com significado
dentro de um viewport de largura infinita.

### D15 — O modo tela cheia **não** é persistido — **[tech-lead]**

Largura e colapso são hábito de trabalho e ficam salvos (P3). Tela cheia é um momento.
Reabrir o editor já em tela cheia, sem faixa 1 e sem breadcrumb, é entregar o dev numa
tela sem saída óbvia. Fica em memória, e `Esc` sai.

### D16 — O controle da tela cheia é um **botão**; o atalho é secundário e verificado no Chrome ao vivo — **[tech-lead]**

O item 39 registrou (§8, item 13) que um aceite escrito a partir da **API do mecanismo**
deu falso: `Ctrl+Shift+W` estava no mapa de `Shortcuts` e nunca chegou ao app — **é o
atalho de fechar a janela do Chrome**. Um modo tela cheia alcançável só por atalho é um
modo que ninguém acha, e um atalho não verificado é um aceite que mente.

**Decisão:** o controle primário é um botão na barra do canvas, sempre visível. O atalho
é opcional, e **nenhuma combinação `Ctrl+Shift+<letra>` entra sem teste ao vivo no
Chrome**. O aceite do atalho é o print do modo ligado logo após teclar (DoD 23).

### D17 — O preview é **visual**, não interativo, e sem diagnósticos — **[tech-lead, A9 + item 39›D13]**

`SduiView.content` sem `nodeWrapper` (nada de seleção de nó) e **com
`showDiagnostics: false`**. O segundo ponto importa: o item 39 decidiu que a caixa de
diagnóstico mostra a URL e o `error.toString()`, e que isso é aceitável **só no editor**.
A rota de preview é um link que sai do laptop — diagnóstico ligado ali vazaria detalhe de
infraestrutura para quem receber o link. Interatividade de verdade (tocar botão e a ação
acontecer) depende do **item 28** e está fora (§12).

### D18 — A rota de preview carimba o `ProjectScope` no `pageBuilder` — **[tech-lead]**

O `projectId` está no path por decisão da D3, mas **isso sozinho não basta**: o header
`x-project-id` é carimbado pelo interceptor do Dio a partir do
`getIt<ProjectScope>().projectId`, que hoje só é escrito quando o usuário passa pela tela
do projeto. Aberta fria no celular, a rota cairia no `DEFAULT_PROJECT_ID` do build e
devolveria **404 inexplicável**.

`PreviewPage.pageBuilder` escreve `getIt<ProjectScope>().projectId = projectId` antes de
montar o cubit — mesmo padrão do `ProjectDetailPage.pageBuilder`, que é o único outro
escritor. É seguro porque a rota de preview é terminal: sem chrome, sem navegação para
outras rotas do editor.

**O aceite disto não é ler o `pageBuilder`** — é o print tirado num aparelho que **nunca
abriu o editor** (DoD 19).

### D19 — Os parâmetros novos da `EditorPage` são opcionais — **[tech-lead]**

`editor_perf_test.dart` e `canvas_panel_golden_test.dart` montam `EditorPage`
**diretamente**, sem container de DI registrado. Foi exatamente essa propriedade —
widget testável sem bootstrap da aplicação — que quebrou 5 testes no item 39 e gerou o
`VR-16-02`.

**Decisão:** o `EditorLayoutController` entra na `EditorPage` como parâmetro
**opcional**; ausente, a página monta um controller em memória com os padrões. Os testes
existentes continuam montando `EditorPage()` sem DI. Quem constrói o controller
persistido continua sendo só o `pageBuilder`.

---

## 5. Fases

### F1 — O piso: os overflows morrem e o mock se ajusta à janela · **[base]** · **[∥ com F2, F4]** · **[sub-agente: especialista-apresentacao]**

É a D1 do humano, verbatim: matar os overflows **e** ligar o ajuste. As duas metades
entram no mesmo PR porque foi assim que o humano definiu o piso, e porque nenhuma das
duas vale sozinha como "o editor parou de brigar comigo".

**Vem primeiro, e não é só por ser o maior retorno isolado.** É **pré-requisito para as
fases seguintes serem prováveis num print.** Com o zoom fixo em `Transform.scale`,
colapsar a paleta libera 280 px que viram **fundo cinza** — o mock não cresce um pixel. A
F3 sem a F1 entrega um par de prints em que nada de relevante muda, e um aceite que não
se enxerga é um aceite que não existe.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/theme/app_sizes.dart` | **novo** — `canvasToolbarHeight`, `topBarHeight`, `breadcrumbBarHeight`, `minCenterWidth`, `panelRailWidth` (usado na F3), `topBarActionsFitWidth` |
| `core/theme/theme.dart` | barrel, exporta `app_sizes.dart` |
| `core/widgets/app_shell/app_shell_breadcrumb_bar.dart` | `Flexible` em cada `CrumbLabel` — a elipse passa a disparar |
| `core/widgets/app_shell/app_shell_top_bar.dart` | `LayoutBuilder`; abaixo de `topBarActionsFitWidth` as ações colapsam num menu de overflow |
| `core/widgets/app_shell/app_shell_actions_overflow_menu.dart` | **novo** — o menu (Gate 1: widget próprio, não `Widget _buildMenu()`) |
| `core/widgets/layout/resizable_split_view.dart` | `LayoutBuilder`, piso do centro, reclamp contra a janela, rolagem horizontal da D14 |
| `.../editor/device_preset.dart` | `Size get frameSize` (D10) |
| `.../editor/widgets/canvas/device_frame.dart` | passa a consumir `frameSize` (D10) |
| `.../editor/widgets/canvas/fit_scale.dart` | **novo** — `double fitScaleFor({required Size frame, required Size viewport})`, função pura e testável |
| `.../editor/widgets/canvas_panel.dart` | `LayoutBuilder` em volta da `Column` (D9), escala efetiva |
| `.../editor/widgets/canvas/canvas_toolbar.dart` | botão "Ajustar à janela" (toggle) + percentual efetivo; tokeniza `height: 44` e `iconSize: 18` |
| `.../editor/page/canvas_area.dart` | o `BlocSelector` passa a carregar `fitToWindow` |
| `.../editor/cubit/editor_state.dart` | `EditorReady` ganha `fitToWindow` (default `true`, P5) |
| `.../editor/cubit/editor_cubit.dart` | `toggleFitToWindow()`; `changeZoom` passa a desligar o fit |

**Tarefas** (as três primeiras são disjuntas em arquivo — **paralelizáveis dentro da
fase**):

1. **[paralela: sim]** Overflow do shell: `Flexible` nos crumbs + menu de overflow na
   faixa 1 + `AppSizes`.
2. **[paralela: sim]** Piso do centro no `ResizableSplitView` (D14).
3. **[paralela: sim]** `DevicePreset.frameSize` + `DeviceFrame` consumindo (D10).
4. **[paralela: não — depende de 3]** `fitScaleFor` + `LayoutBuilder` no `CanvasPanel` +
   `fitToWindow` no cubit + botão e percentual na toolbar.
5. **[paralela: não — por último]** Regravar `goldens/canvas_panel*.png`. **A descrição
   do PR cita o diff visual**; regravação sem citação reprova (mesma régua do item 39,
   DoD 4).

**Aceite (validável — escrito como o print que o prova):**

1. **Janela 1024×720, preset Tablet:** as **quatro quinas da moldura** aparecem dentro da
   área do canvas, e a barra do canvas mostra um percentual **abaixo de 40%**. _O
   percentual abaixo de 40 é a parte que importa: é o que prova que a escala não passou
   pelo clamp `0.4–1.5` do `changeZoom` (D9). Hoje, no mesmo estado, a moldura sai pela
   direita e por baixo e a barra mostra `90%`._
2. **O ajuste é reativo:** arrastar a borda da janela de 1440 para ~900 **sem tocar em
   nada** muda o percentual na barra entre os dois prints. _Falha se o percentual for o
   mesmo — significa que a escala foi calculada uma vez._
3. **Manual vence (P5):** um clique em `+` desliga o ajuste — o toggle "Ajustar" aparece
   **não-selecionado** e o percentual entra na faixa manual. Clicar em "Ajustar" de volta
   religa. _Dois prints, estados visualmente distintos._
4. **Breadcrumb a 1280 com nome de conteúdo de ~80 caracteres:** o último crumb aparece
   **com reticências**. _Hoje: faixa listrada. Print antes/depois._
5. **Faixa 1 a 700 e a 560:** o botão de overflow aparece **e o print é com o menu
   aberto**, mostrando "Salvar" e "Publish" dentro dele. _O `⋮` visível não basta: um
   menu que abre vazio passaria no aceite e reprovaria na prática._
6. **Workspace a 560** (abaixo dos 612 de chrome fixo): **nenhuma faixa listrada**; a
   barra de rolagem horizontal da D14 aparece.
7. **Invariante I1 sobreviveu ao `canvas_panel.dart`:** a `image` com a URL sem ACAO do
   item 39 **continua carregando** no mock, e a aba Network mostra
   `…/v1/media/proxy?url=…`. _Este é o aceite próprio da I1 nesta fase — print, não grep._

**O que este aceite NÃO prova:** que o editor é usável abaixo de 612 px. Não é, e não
pretende ser (D1). O aceite 6 prova apenas que ele **degrada em vez de estourar**.

---

### F2 — Rota `/preview/:projectId/:id` — o conteúdo no celular · **[0-dep; ∥ com F1, F4]** · **[sub-agente: especialista-apresentacao + especialista-infra]**

**Por que aqui e não no fim** (mudança de ordem em relação ao PRD — §8): é a única fase
cujo E2E exige **hardware físico e o ambiente de homologação real**. Se o SPA fallback,
o `ProjectScope` ou o resolver não se comportarem no aparelho, é melhor descobrir na
segunda fase do que na véspera do fechamento. E ela é 0-dep de verdade: não toca
`ResizableSplitView`, nem a paleta, nem o shell.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/network/image_url_resolver_factory.dart` | **novo** — a fábrica que sai da `EditorPage` (D6) |
| `core/network/network.dart` | barrel |
| `.../editor/editor_page.dart` | passa a chamar a fábrica; o método privado morre |
| `modules/editor_module/editor_routes.dart` | `preview = '/preview/:projectId/:id'`, `previewName`, `static GoRoute get previewRoute` |
| `app_router.dart` | a rota entra no `routes:` do **root**, irmã do `ShellRoute` — nasce sem chrome |
| `.../editor/presentation/preview/preview_page.dart` | **nova** página, `static Widget pageBuilder` (único toque no get_it; carimba o `ProjectScope`, D18) |
| `.../editor/presentation/preview/cubit/preview_cubit.dart` + `preview_state.dart` (`part of`) | `sealed`: `PreviewLoading` / `PreviewReady(spec, fetchedAt)` / `PreviewFailure(failure)`; reusa `LoadContentUseCase` |
| `.../editor/presentation/preview/widgets/last_saved_pill.dart` | **novo** — a pílula da D4 |
| `.../editor/presentation/preview/widgets/preview_share_dialog.dart` | **novo** — mostra a URL, copiável, com "abrir em nova aba" |
| `.../editor/widgets/canvas/canvas_toolbar.dart` | botão que abre o diálogo |

**Tarefas:**

1. **[paralela: não — primeiro]** Extrair a fábrica do resolver (D6) e apontar a
   `EditorPage` para ela. _Mudança sem comportamento novo; entra primeiro para o resto da
   fase já nascer usando a fábrica._
2. **[paralela: sim]** Rota + `PreviewCubit` + `PreviewPage` (com `showDiagnostics:
   false`, D17, e o `ProjectScope` carimbado, D18).
3. **[paralela: sim]** A pílula "último salvo" (D4).
4. **[paralela: sim]** O diálogo com a URL no editor.
5. **[paralela: sim — descartável]** **QR code.** Exige `qr_flutter` no pubspec, a
   **única dependência nova** de toda a feature. **Esta tarefa pode cair sem quebrar a
   fase** — o diálogo com a URL copiável é o entregável obrigatório. Ver §9›Q1: é decisão
   do humano no PR.

**Aceite (validável — escrito como o print que o prova):**

8. **Foto de celular real** (não emulador do DevTools) mostrando o conteúdo renderizado
   ocupando a tela, **sem faixa 1, sem breadcrumb, sem painéis**, com a URL
   `https://hml…/preview/<projectId>/<id>` visível na barra do navegador do aparelho.
9. **A prova do `ProjectScope` (D18):** a foto do item 8 é tirada num **aparelho ou aba
   anônima que nunca abriu o editor**. _Se o preview só funcionar depois de passar pela
   tela do projeto, o aceite reprova — é o 404 inexplicável que a D18 existe para
   evitar._
10. **A prova da invariante I1 (D6):** o conteúdo usado no item 8 **inclui a `image` com
    a URL sem ACAO do item 39**. Na foto, a imagem aparece **carregada**. _Se aparecer a
    caixa "falhou", o resolver não chegou à página nova — é a regressão exata que o item
    39 acabou de matar, e o aceite reprova._
11. **A prova da D4 — dois pares de prints, e é o par que prova, não o print:**
    (a) editar no desktop **sem salvar** → tocar na pílula no celular → o conteúdo
    **não muda**; (b) **Salvar** no desktop → tocar na pílula → o conteúdo **muda**.
    _Sem o par (a), o item não prova "último salvo" — prova só que a pílula recarrega._
12. **A pílula diz o que está mostrando:** o texto "Último salvo" aparece legível na
    foto do aparelho.

**O que este aceite NÃO prova:** que o preview é seguro para compartilhar com terceiros.
Não é — é um link sem tranca, aceito pelo humano (A8) e registrado como dívida do item 26
no risco R3.

---

### F3 — Painel colapsa numa faixa fina de ícones · **[depende de F1]** · **[∥ com F4]** · **[sub-agente: especialista-apresentacao]**

Depende da F1 por dois motivos: a F1 reescreve o `ResizableSplitView` (piso e
`LayoutBuilder`), e sem o ajuste da F1 o ganho desta fase **não aparece no print** (o
espaço liberado vira fundo cinza).

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `.../editor/page/editor_layout.dart` | **novo** — `EditorLayout`, valor imutável (Equatable): larguras, colapsos, grupos fechados |
| `.../editor/page/editor_layout_controller.dart` | **novo** — `ValueNotifier<EditorLayout>`, escopado no módulo (D8) |
| `.../editor/page/editor_layout_scope.dart` | **novo** — `InheritedNotifier` montado no `EditorWorkspace.build` (o soquete da D7) |
| `core/widgets/layout/resizable_split_view.dart` | passa a ler colapso/larguras do controller; **o `ValueListenableBuilder` fica aqui dentro, em volta da `Row`** (D8) |
| `core/widgets/layout/panel_rail.dart` | **novo** — a faixa fina de ícones (D2) |
| `core/widgets/layout/panel_rail_button.dart` | **novo** — botão da faixa, com `Semantics` + tooltip |
| `.../editor/page/left_panel.dart` | expõe a aba corrente para a faixa reabrir na aba certa |
| `.../editor/page/editor_workspace.dart` | monta o `EditorLayoutScope` |
| `.../editor/editor_page.dart` | recebe o controller como parâmetro **opcional** (D19) |

**Tarefas:**

1. **[paralela: não]** `EditorLayout` + `EditorLayoutController` + `EditorLayoutScope`.
2. **[paralela: sim]** `PanelRail` + `PanelRailButton` (Gates 1 e 3: widgets próprios,
   arquivo por widget; Gate 4: largura da faixa e duração da animação em `AppSizes` /
   `AppDurations`).
3. **[paralela: não — depende de 1 e 2]** `ResizableSplitView` controlado, com o
   `ValueListenableBuilder` no lugar certo.

**Aceite (validável — escrito como o print que o prova):**

13. **Paleta colapsada:** a faixa fina aparece com os ícones **Widgets** e **Árvore**
    visíveis, **e o percentual na barra do canvas subiu** em relação ao print anterior.
    _O percentual é a metade que prova que o espaço foi para o mock e não para o fundo._
14. **Os dois painéis colapsados ao mesmo tempo:** duas faixas, mock no maior tamanho,
    **os dois controles de reabrir visíveis**. _É o caso de borda que o PRD listou como
    permitido._
15. **A faixa é atalho, não só interruptor (D2):** com a paleta colapsada, clicar no
    ícone **Árvore** reabre o painel **na aba Árvore**, não na Widgets.
16. **A borda que a A3 decidiu:** o print do item 13 mostra o controle de reabrir
    **dentro da faixa**. _Reprova se o único caminho de volta for atalho de teclado ou
    menu — com a paleta colapsada não há de onde arrastar widget._

**O que este aceite NÃO prova:** que os painéis não reconstroem no toggle (D8). Não há
print para isso — é o teste de widget da F8 (DoD 8).

---

### F4 — Grupos da paleta colapsáveis · **[0-dep; ∥ com F1, F2, F3]** · **[sub-agente: especialista-apresentacao]**

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `.../editor/widgets/widget_palette/palette_category_section.dart` | **novo** — a seção (cabeçalho + itens) |
| `.../editor/widgets/widget_palette/palette_category_header.dart` | **novo** — o cabeçalho clicável, com chevron, rótulo e contagem |
| `.../editor/widgets/widget_palette_panel.dart` | o laço do `ListView` delega à seção; sai a árvore inline do `build` |

**Decisões locais:** **não usar `ExpansionTile`**; **não promover** o `PropSection` para
`core/widgets/` (I4 — os itens 38 e 39 acabaram de mexer no Inspector). O widget novo
nasce na pasta da paleta. **Sabendo da I5** (o item 8b, "dobrar seções" do painel JSON, é
o terceiro cliente à vista), a API do cabeçalho fica genérica — `label`, `trailing`,
`isExpanded`, `onToggle` — mas a **promoção para `core/widgets/` é item futuro, não
este**.

**Busca com grupos fechados:** com filtro ativo, os grupos com resultado são **forçados
abertos** sem tocar no conjunto de colapsados; ao limpar o filtro, tudo volta ao que o
dev deixou. Mecanicamente: `isExpanded = query.isEmpty ? !fechados.contains(cat) : true`
— sem mutação de estado durante a filtragem.

**Tarefas:**

1. **[paralela: sim]** `PaletteCategoryHeader` + `PaletteCategorySection`.
2. **[paralela: não — depende de 1]** `WidgetPalettePanel` delega; estado dos colapsados
   no `State` do painel (a persistência é a F5).

**Aceite (validável — escrito como o print que o prova):**

17. **Os quatro grupos fechados:** só 4 cabeçalhos visíveis, cada um com o chevron na
    direção do fechado e a **contagem de widgets do grupo**, e **sem barra de rolagem** no
    painel. _Hoje, com 24 primitivos, a lista rola numa tela de 1366×900._
18. **`Listas` aberto e os outros três fechados:** os itens de `Listas` cabem **sem
    rolar**.
19. **A borda que prova de verdade — par de prints:** com os 4 grupos fechados, digitar
    `col` na busca → o print mostra **`Layout` aberto com o `Column` visível**; limpar a
    busca → o print seguinte mostra **os 4 grupos fechados de novo**. _Sem isto, buscar
    com tudo fechado parece "não achou nada". Um print só não prova: é o par._
20. **A regra do catálogo continua de pé** — prova de máquina: nenhum literal de nome de
    categoria em `.../widgets/widget_palette/`; a ordem vem de
    `WidgetCategories.inPaletteOrder`. _`grep -rn "Básicos\|Layout'\|Formulário\|Listas"
    apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/widget_palette/`
    = zero._

---

### F5 — O layout é lembrado entre sessões · **[depende de F3 + F4]** · **[sub-agente: especialista-dominio + especialista-dados + especialista-apresentacao]**

Fase própria, e depois da F3 e da F4, **de propósito**: uma pilha de persistência escrita
uma vez, servindo quatro clientes que já existem (larguras, colapso dos painéis, grupos
da paleta, seções do Inspector). Escrevê-la antes seria escrevê-la duas vezes.

**Arquivos:**

| Arquivo | Camada |
| --- | --- |
| `.../editor_module/domain/entities/editor_layout.dart` | domain — a entidade sai da `presentation` da F3 e desce para cá |
| `.../editor_module/domain/repositories/editor_layout_repository.dart` | domain — `getLayout()` / `saveLayout(EditorLayout)`, `Either<Failure, T>` |
| `.../editor_module/domain/use_cases/get_editor_layout_use_case.dart` | domain — um use case por operação |
| `.../editor_module/domain/use_cases/save_editor_layout_use_case.dart` | domain |
| `.../editor_module/data/models/editor_layout_model.dart` | data — schema **zard**, `encode` → JSON string, `tryParse` → `Either` |
| `.../editor_module/data/repositories/editor_layout_repository_impl.dart` | data — `SharedPreferences`, chave `editor.layout`, **único `try/catch`** |
| `.../editor_module/editor_injection.dart` | +3 registros (repo lazy singleton, 2 factories) |
| `.../editor/editor_page.dart` | o `pageBuilder` resolve os use cases e monta o controller persistido (D19: parâmetro opcional) |
| `.../editor/page/editor_layout_controller.dart` | carrega no início, dobra `Left` para o padrão (D12), grava com debounce |
| `.../editor/widgets/inspector/prop_section.dart` | ganha `onExpandedChanged`; `initiallyExpanded` passa a vir do controller |

**Decisões locais:**
- **Gravação com debounce.** Arrastar o splitter emite continuamente; gravar a cada frame
  vira tempestade de escrita no `localStorage`. Debounce curto, cancelado no `dispose`.
- **Reclamp na restauração (D13).**
- **Seções do Inspector são lembradas globalmente pelo rótulo do grupo**, não por tipo de
  nó — layout é hábito de trabalho, não atributo do documento (P3 do PRD). Ver §9›Q2.

**Aceite (validável — escrito como o print que o prova):**

21. **O refresh:** arrastar a paleta para ~460, colapsar o Inspector, fechar 3 grupos da
    paleta, dar **F5 no navegador**. O print depois do refresh é **equivalente** ao de
    antes — mesma largura, mesmo colapso, mesmos grupos fechados.
22. **A navegação, que é o incômodo real:** do editor, voltar à tela do projeto pelo
    breadcrumb e reentrar no conteúdo. **Mesmo estado.** _É o relato do PM: "o dev alarga
    a paleta, sai da tela, volta e está tudo como antes." Um aceite que só cobrisse o
    refresh deixaria o caso que dói de fora._
23. **O reclamp (D13):** com largura salva em 480, reduzir a janela para 1024 e
    recarregar → o painel aparece **estreitado**, sem faixa listrada. _Reprova se aparecer
    com 480 numa janela que não comporta._
24. **A corrupção (D12) — a linha mais fácil de escrever e de não cumprir:** com o
    DevTools, gravar lixo em `localStorage` na chave `flutter.editor.layout` e recarregar.
    **O editor abre normalmente**, em 280/320, tudo expandido, sem banner de erro.
    _Reprova se a tela ficar branca, der erro, ou ficar carregando._

**O que este aceite NÃO prova:** o gate de rebuild da D8. É de máquina (DoD 8).

---

### F6 — Modo tela cheia · **[depende de F3]** · **[sub-agente: especialista-apresentacao + especialista-infra]**

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/widgets/app_shell/app_shell_scope.dart` | `AppShellController` ganha o sinal imersivo (com dono por token, como os outros slots) |
| `core/widgets/app_shell/app_shell_slot.dart` | publica o sinal |
| `core/widgets/app_shell/app_shell.dart` | esconde faixa 1 e faixa 2 quando imersivo — **o shell continua sem ler cubit** (regra do item 16c) |
| `.../editor/page/editor_layout_controller.dart` | `isFullscreen` (em memória, D15) |
| `.../editor/widgets/canvas/canvas_toolbar.dart` | o botão (controle primário, D16) |
| `.../editor/page/editor_shortcuts.dart` + `editor_intents.dart` | `Esc` para sair; atalho de entrada opcional e verificado (D16) |
| `.../editor/page/status_bar_area.dart` | o rodapé **permanece** se houver erro ou aviso (P2) |

**Aceite (validável — escrito como o print que o prova):**

25. **Modo ligado:** sem faixa 1, sem faixa 2, sem painéis, mock ocupando a tela — **e o
    controle de sair visível no print**. _Um modo tela cheia sem saída visível é uma
    armadilha, não uma feature._
26. **`Esc` devolve o layout intacto:** o print depois do `Esc` bate com o print
    imediatamente anterior à entrada — **mesmas larguras, mesmos colapsos**.
27. **A borda P2 — par de prints, senão não prova nada:** entrar em tela cheia **com um
    erro de diagnóstico no rodapé** → o rodapé **continua visível**; entrar **sem erro** →
    o rodapé some. _Esconder erro num modo novo reintroduziria o sintoma que o item 38
    acabou de corrigir._
28. **O atalho, se houver (D16):** print do modo ligado **logo após teclar a combinação,
    no Chrome real em homologação**. _Se o navegador capturar a combinação, o aceite
    reprova e o atalho muda. Lição do `Ctrl+Shift+W`._

---

### F7 — E2E manual em homologação, executado e atestado · **[depende de F1–F6]** · **[dono: qa instrumenta · dev humano atesta]**

O QA roda a skill `instrumentar-e2e`: script idempotente e auto-limpante para o que a
máquina alcança (larguras de janela, presença de overflow, contrato de persistência,
prints automatizáveis via CDP), e deixa para o humano o que exige olho e mão — **o
celular, acima de tudo**. Roteiro na §10. Evidências em
`docs/17-ergonomia-editor/evidencias/rodada_MM/`, prints numerados pelo item do DoD.

**Nenhuma linha de teste automatizado é escrita antes desta fase estar atestada** (cap. 22
do livro).

---

### F8 — Bateria automatizada + docs vivas · **[por último, depois do E2E atestado]** · **[dono: qa]**

Skill `escrever-testes`. No mínimo:

| Alvo | Teste |
| --- | --- |
| `fitScaleFor` | tabela: 3 presets × viewports de 612, 700, 1024, 1280, 1440; e o caso que exige escala < 0.4 (D9) |
| Regressão de overflow | widget test que monta o workspace com `tester.view.physicalSize` em **560, 612, 700, 1024, 1280, 1440** e captura `FlutterError.onError` — **zero** erro de overflow. _O `editor_perf_test.dart` já tem o helper `enlarge(tester)` como precedente._ |
| Breadcrumb | crumb longo em largura restrita → o `Text` trunca, sem overflow |
| `EditorLayoutModel` (zard) | válido · ausente · corrompido · largura fora dos limites |
| Reclamp (D13) | largura salva maior que a janela → clampada |
| **Gate de rebuild (D8)** | contador de builds nos painéis: **colapsar não reconstrói `LeftPanel`, `CenterArea` nem `InspectorArea`** — este é o teste que substitui o print que não existe |
| Paleta | 4 grupos colapsam; busca força abrir e **restaura** ao limpar |
| Tela cheia | `Esc` restaura o layout; rodapé permanece com erro |
| `PreviewCubit` | `bloc_test`: loading → ready; falha → `PreviewFailure` |

Depois: `final_report.md`, `CHANGELOG` (`Unreleased`), `docs/roadmap.md` (item 41 `[x]`),
`docs/plans/README.md`.

---

## 6. Ordem de PRs, precedências e o que fica bloqueado

```
        ┌─ F1 (piso + fit) ──┬── F3 (colapso) ──┬── F5 (memória) ──┐
        │                    │                  │                  │
início ─┤                    └── F6 (tela cheia)┘                  ├─ F7 (E2E) ─ F8 (bateria)
        │                                                          │
        ├─ F2 (rota de preview) ───────────────────────────────────┤
        │                                                          │
        └─ F4 (grupos da paleta) ──────────────────────────────────┘
```

| PR | Fase | Pode começar quando |
| --- | --- | --- |
| 1 | F1 | **Depois do E2E dos itens 38 e 39 atestado** — mexe em `canvas_panel.dart` |
| 2 | F2 | **Já** — não toca arquivo dos itens 38/39 |
| 3 | F4 | **Já** — só a paleta |
| 4 | F3 | Depois do PR 1 |
| 5 | F6 | Depois do PR 4 |
| 6 | F5 | Depois dos PRs 3 e 4 |
| — | F7 | Depois de 1–6 em homologação |
| 7 | F8 | Depois do atestado humano da F7 |

**O que fica bloqueado até a F1 entrar:** a F3 e a F6. Não por dependência de arquivo
apenas — por dependência de **prova**: sem o ajuste, o ganho de espaço das duas não
aparece em print nenhum.

**Colisões internas a vigiar:** `resizable_split_view.dart` é tocado pela F1 (piso) e
pela F3 (colapso), em PRs sequenciais. `canvas_toolbar.dart` é tocado pela F1 (fit), pela
F2 (botão do preview) e pela F6 (botão de tela cheia) — **três fases, e duas delas
paralelas (F1 ∥ F2)**. Quem abrir o PR 2 rebase antes de mergear o PR 1, ou o conflito é
certo. É o único ponto de atrito real do plano.

---

## 7. Riscos

**R1 — "Responsividade em geral" não tem critério de pronto.** Mitigado pela D1: o piso é
mecânico e o aceite é objetivo (nenhum overflow entre 560 e a tela cheia).

**R2 — Colapso pode não ser o que resolve.** O splitter já existe e o Inspector já
colapsa; o que **não** existe é memória de nada disso, nem o ajuste. Há chance real de o
incômodo do dev ser "não é lembrado" e "o mock não se ajusta", e não "falta colapsar".
Por isso a F1 vem primeiro e a F5 existe como fase própria.

**R3 — O preview é uma porta sem tranca.** Não piora o estado atual (o editor inteiro já
é aberto e o backend não tem auth), mas materializa o rascunho num link que sai do
laptop. Aceito pelo humano (A8). **Entra na tabela de débitos vivos do roadmap quando a
F2 mergear**, para o item 26 herdar.

**R4 — Perder o `imageUrlResolver` numa tela nova.** Mitigado estruturalmente pela D6 (uma
fábrica, duas páginas) e cobrado por **dois** aceites com print: o 7 (F1) e o 10 (F2).

**R5 — Desfazer o item 3b sem perceber.** O `ValueListenableBuilder` no lugar errado
reconstrói os três painéis a cada clique, **sem sintoma visível**. D8 explica onde ele
vai; o DoD 8 é o único guarda, e é de máquina.

**R6 — Conflito com trabalho em voo.** O item 39 está sendo instrumentado para E2E em
`docs/16-` **agora**, e um especialista está em
`apps/driva_editor/.../prop_field/`. Esta feature não toca `prop_field/`; toca
`canvas_panel.dart` (item 39) só na F1, que está bloqueada até o atestado. O item 24
planeja mexer em `core/widgets/app_shell/` (dois chips de status) — a F1 e a F6 mexem lá;
como o 24 nem começou, o atrito é futuro, não presente.

**R7 — Golden do `canvas_panel` quebra na F1.** É esperado (a toolbar ganha botão, o
painel ganha `LayoutBuilder`). Regravar é legítimo; **regravar sem citar o diff visual na
descrição do PR reprova** — mesma régua do item 39.

**R8 — Entrar antes de fechar 38 e 39.** Nenhum dos dois tem `final_report.md`; as
baterias (F7 do 38, F5 do 39) não existem. §Estado transforma isso em pré-condição dura
para as fases que colidem, e libera as que não colidem.

---

## 8. Divergências em relação ao recorte do PRD

| # | O PRD dizia | Este plano faz | Por quê |
| --- | --- | --- | --- |
| 1 | **F1** overflows + fit · **F2** colapso + persistência · **F3** paleta + tela cheia · **F4** bateria — e o preview como fatia separada | **8 fases**, com a persistência isolada e o preview como **F2** | Ver linhas 2 a 4 |
| 2 | Preview como "fatia 2", depois de tudo | **F2, logo depois do piso** | É a única fase cujo E2E exige **hardware físico e homologação real**; descobrir tarde que o aparelho não abre a rota é o pior lugar para descobrir. E ela é 0-dep de verdade — não toca split view, paleta nem shell |
| 3 | Colapso **e** persistência na mesma fase | **F3 (colapso) e F5 (memória) separadas** | A pilha de persistência serve **quatro** clientes (larguras, painéis, grupos da paleta, seções do Inspector). Escrita antes de os quatro existirem, seria escrita duas vezes. E colapso sem memória já é fatia vertical utilizável |
| 4 | Tela cheia junto dos grupos da paleta ("meia fase") | **F6, própria** | Ela muda a **API pública do `AppShell`** (`core/widgets/`), preocupação de revisão diferente de mexer na paleta do editor |
| 5 | Preset Tablet precisa de **~863 px** de centro | **~952 px** | O PRD contou só o `bezel`. A `DeviceFrame` soma também `bezel * 0.55` de cada lado para os botões laterais, e o `CanvasPanel` envolve tudo num padding de 32. §2.2 |
| 6 | "Tokens de breakpoint, se A1 pedir" | **Nenhum token de breakpoint nasce** (D5) | Com A1 = piso mecânico, não há comportamento por faixa para tokenizar. Criar o vocabulário sem cliente é convidar a fusão com o item 30 |
| 7 | A1 dizia "o fit é o maior retorno isolado" | Confirmado, **e promovido a pré-requisito de prova** | Sem o fit, colapsar painel libera espaço que vira fundo cinza: a F3 não teria print que mostrasse o ganho |

---

## 9. O que ainda precisa do humano

**As quatro decisões caras estão fechadas** (A6 → D3, A1 → D1, A3 → D2, A7 → D4) e não se
reabrem. Sobraram duas questões pequenas, **nenhuma bloqueia a F1**:

**Q1 — Entra `qr_flutter` no pubspec?** É a **única dependência nova** de toda a feature.
Sem QR, alcançar o preview no celular é copiar uma URL com **dois UUIDs** e mandar para
si mesmo — funciona, e é chato o bastante para o dev não usar. Com QR, aponta a câmera.
Sem build_runner, pacote pequeno. **Recomendação: entra.** É a tarefa 5 da F2, a última, e
**cai sem quebrar a fase** se o humano preferir não adicionar dependência — decisão no PR.

**Q2 — O colapso das seções do Inspector é lembrado por rótulo de grupo (global) ou por
tipo de nó?** Este plano adota **global por rótulo** (P3 do PRD: layout é hábito de
trabalho, não atributo do documento) — é mais simples e é o que faz o Inspector parar de
reabrir tudo a cada troca de nó, que é o incômodo concreto. Por tipo de nó custaria pouco
mais, mas troca "o Inspector lembra do meu jeito" por "o Inspector lembra de cada tipo",
que é outra promessa. **Veto fácil na revisão da F5.**

Fora isso, **o plano está fechado**: nenhuma fase depende de resposta pendente.

---

## 10. Roteiro de E2E manual

**Em homologação** (`https://hml.driva.duckdns.org`), **nunca em localhost** — lição
permanente do item 9g. O QA instrumenta o que der; o que está marcado **[olho]** ou
**[mãos]** é do humano.

> ⚠️ **Dois avisos antes de abrir a rodada.**
> 1. **O modo fake mascara a rodada inteira.** Com `USE_FAKE_DATA=true` a fábrica do
>    resolver devolve `null` de propósito (D6) e os passos 3 e 11 ficam sem sentido.
>    Confirme na aba Network que há chamada real à API antes de começar.
> 2. **Os passos de largura de janela precisam da janela do navegador redimensionada de
>    verdade**, não do emulador de dispositivo do DevTools — o emulador não muda a
>    largura do `MediaQuery` do jeito que o `LayoutBuilder` do editor enxerga em todos os
>    casos. Use a borda da janela.

**Preparar:**

| Rótulo | O que | Para quê |
| --- | --- | --- |
| `CT_LONGO` | Um conteúdo cujo **nome tenha ~80 caracteres** | passo 4 |
| `CT_IMG` | Um conteúdo com um `image` usando a **URL sem ACAO** do item 39 | passos 3 e 11 |
| `APARELHO` | Um celular que **nunca abriu o editor** (ou aba anônima) | passos 10 a 13 |

1. **[olho]** Abrir `CT_IMG` numa janela de **1024×720**, preset **Tablet**. **Esperado:**
   as quatro quinas da moldura visíveis e a barra do canvas abaixo de **40%**. _(DoD 14)_
2. **[olho]** Arrastar a borda da janela de 1440 para ~900 sem tocar em nada.
   **Esperado:** o percentual muda sozinho. _(DoD 15)_
3. **[olho]** Ainda em `CT_IMG`: a imagem carrega, e a aba Network mostra
   `…/v1/media/proxy?url=…`. **Esperado:** carregada. _Se aparecer a caixa "falhou", a F1
   perdeu o resolver — pare a rodada._ _(DoD 17)_
4. **[olho]** Abrir `CT_LONGO` a **1280**. **Esperado:** o último crumb com reticências,
   sem faixa listrada. _(DoD 12)_
5. **[olho]** Estreitar para **700** e depois **560**. **Esperado:** menu de overflow na
   faixa 1 — **abra o menu** e confirme "Salvar" e "Publish" dentro; nenhuma faixa
   listrada; a 560, rolagem horizontal no workspace. _(DoD 12, 13)_
6. **[olho]** Um clique em `+` no zoom. **Esperado:** o toggle "Ajustar" fica
   **não-selecionado**. Clicar em "Ajustar" religa. _(DoD 16)_
7. **[olho]** Colapsar a paleta. **Esperado:** faixa fina com os ícones **Widgets** e
   **Árvore**, e **o percentual do canvas sobe**. Colapsar também o Inspector: duas
   faixas, os dois controles de reabrir visíveis. _(DoD 18, 19)_
8. **[olho]** Com a paleta colapsada, clicar no ícone **Árvore** da faixa. **Esperado:**
   reabre **na aba Árvore**. _(DoD 20)_
9. **[olho]** Fechar os 4 grupos da paleta; depois digitar `col` na busca; depois limpar.
   **Esperado:** fechados sem rolagem → `Layout` abre com o `Column` visível → **volta a
   fechar**. _Três prints; o terceiro é o que prova._ _(DoD 21, 22)_
10. **[mãos]** No editor, abrir o diálogo de preview e levar a URL ao `APARELHO` (QR ou
    cópia). **Esperado:** o conteúdo em tela cheia, sem faixa 1, sem breadcrumb, sem
    painéis, num aparelho que **nunca abriu o editor**. _Foto do aparelho, com a URL
    visível._ _(DoD 26, 27)_
11. **[mãos]** Na mesma foto, conferir a `image` de `CT_IMG`. **Esperado:** **carregada**.
    _Caixa "falhou" = a rota nova não repassou o resolver. Reprova._ _(DoD 28)_
12. **[mãos]** Editar `CT_IMG` no desktop **sem salvar** → tocar na pílula no celular.
    **Esperado:** **nada muda**. Depois **Salvar** → tocar de novo. **Esperado:** muda.
    _(DoD 29)_
13. **[olho]** A pílula diz "Último salvo". _(DoD 30)_
14. **[olho]** Arrastar a paleta para ~460, colapsar o Inspector, fechar 3 grupos, dar
    **F5**. **Esperado:** tudo como estava. Depois: voltar ao projeto pelo breadcrumb e
    reentrar. **Esperado:** tudo como estava. _(DoD 31, 32)_
15. **[olho]** Com largura salva em 480, reduzir a janela para 1024 e recarregar.
    **Esperado:** painel estreitado, sem faixa listrada. _(DoD 33)_
16. **[olho]** No DevTools, gravar lixo em `localStorage` na chave
    `flutter.editor.layout` e recarregar. **Esperado:** o editor **abre normalmente** em
    280/320, tudo expandido, sem banner de erro. _(DoD 34)_
17. **[olho]** Entrar em tela cheia pelo botão. **Esperado:** sem faixas, sem painéis, **e
    o controle de sair visível**. `Esc`: volta com as mesmas larguras e colapsos. _(DoD
    35, 36)_
18. **[olho]** Repetir o passo 17 **com um erro de diagnóstico no rodapé**. **Esperado:**
    o rodapé **permanece**. Sem erro: some. _(DoD 37)_
19. **[olho]** Se houver atalho de entrada: teclá-lo no Chrome. **Esperado:** entra no
    modo. _Se o navegador capturar, o atalho muda — não o aceite._ _(DoD 38)_

---

## 11. Definition of Done

**O item 41 só está pronto quando todas as linhas abaixo estiverem marcadas.** Cada linha
diz **como se prova** — nada aqui se atesta por opinião.

### 11.1 Cancela de máquina

| # | Item | Como se prova |
| --- | --- | --- |
| 1 | `flutter analyze` verde no workspace | saída do comando, zero issues, colada no PR |
| 2 | Suíte existente passando (`flutter test -r compact`) em `sdui_core`, `sdui_flutter` e `driva_editor` | saída no PR |
| 3 | **Zero linha em `packages/sdui_core` e `packages/sdui_flutter`** | `git diff --stat origin/develop -- packages/` = vazio, em **todos** os PRs |
| 4 | **Zero linha em `backend/`** | `git diff --stat origin/develop -- backend/` = vazio |
| 5 | Golden do `canvas_panel` regravado **com o diff visual citado na descrição do PR 1** | o PR mostra antes/depois; regravação sem citação **reprova** |
| 6 | **Gate 1** — nenhuma função/método novo que retorna `Widget` fora do permitido | leitura do diff na `revisar-fase`; nenhum `Widget _buildX(` novo |
| 7 | **Gate 4** — nenhum tamanho, duração ou cor cru nos arquivos tocados | `grep -n "height: [0-9]\|EdgeInsets.all([0-9]\|Color(0x" ` nos arquivos do diff = só tokens |
| 8 | **Gate de rebuild (D8)** — colapsar **não** reconstrói `LeftPanel`, `CenterArea` nem `InspectorArea` | teste de widget com contador de builds (F8). **É de máquina: não existe print que prove isto, e nenhum foi inventado** |
| 9 | **Nenhum `AppBreakpoints` nasceu** (D5) | `grep -rn "AppBreakpoints\|SduiBreakpoint" apps/driva_editor/lib` = **zero** |
| 10 | CI verde em todos os PRs — a mesma régua do humano | checks do GitHub |

### 11.2 Aceite por fase

| # | Item | Como se prova |
| --- | --- | --- |
| 11 | Os **7 critérios da F1** atestados | `revisar-fase` do QA no PR 1 |
| 12 | Os **5 critérios da F2** atestados | `revisar-fase` do QA no PR 2 |
| 13 | Os **4 critérios da F3** atestados | `revisar-fase` do QA no PR 4 |
| 14 | Os **4 critérios da F4** atestados | `revisar-fase` do QA no PR 3 |
| 15 | Os **4 critérios da F5** atestados | `revisar-fase` do QA no PR 6 |
| 16 | Os **4 critérios da F6** atestados | `revisar-fase` do QA no PR 5 |
| 17 | Nenhum desvio das decisões **D1–D19** sem `variance_report.md` aprovado **pelo humano** | a pasta `docs/17-ergonomia-editor/`, desvios numerados `VR-17-NN` com "como estava / por que mudou / o que mudou" |

### 11.3 E2E — **faz parte do DoD, não é apêndice**

**A feature não está pronta enquanto o roteiro da §10 não tiver sido executado e
atestado pelo dev humano.**

| # | Item | Como se prova |
| --- | --- | --- |
| 18 | O roteiro da §10 executado **em homologação**, não em localhost | a URL do ambiente aparece nos prints |
| 19 | A rodada correu **contra o backend real**, não em modo fake | a aba Network mostra chamada a `hml`. Em modo fake o resolver é `null` de propósito (D6) e **os passos 3 e 11 ficam mascarados** |
| 20 | **QA instrumenta** o que der em script idempotente e auto-limpante (skill `instrumentar-e2e`); o que exige olho e mão fica para o humano | scripts em `docs/17-ergonomia-editor/`, copiados para dentro da rodada |
| 21 | **O dev humano confere os prints e atesta.** Ninguém mais atesta E2E | atestado escrito no `final_report.md`, com data |
| 22 | Evidência arquivada em **`docs/17-ergonomia-editor/evidencias/rodada_MM/`**, prints nomeados `<NN>_<descricao>.png` pelo número do item deste DoD | a pasta existe e tem os prints |
| 23 | E2E reprovado → o tech-lead conserta e o QA abre **`rodada_MM+1`**; a rodada anterior **não é apagada** | histórico de rodadas |

### 11.4 A matriz que prova o que a feature promete — **não o caminho feliz**

Esta feature corrige, entre outras coisas, **falhas que hoje não avisam**: o mock cortado
sem mensagem, o layout que se perde sem aviso, a imagem que some em silêncio. Um E2E que
só percorra o caminho feliz **não prova nada aqui**. Cada linha abaixo é um par ou trio de
prints em que os estados têm de ser **visualmente distintos**.

| # | O que a feature promete | Print exigido | Reprova se |
| --- | --- | --- | --- |
| 24 | O mock cabe na janela | Tablet a 1024×720, **quatro quinas visíveis**, barra **abaixo de 40%** | a moldura sai da área, **ou** a barra trava em 40% — significa que a escala passou pelo clamp do `changeZoom` (D9) |
| 25 | O ajuste é reativo | dois prints, 1440 → ~900, **sem tocar em nada**: percentuais diferentes | os percentuais forem iguais |
| 26 | Manual vence o ajuste (P5) | toggle **selecionado** × **não-selecionado**, com percentuais diferentes | os dois estados forem visualmente iguais |
| 27 | O editor não estoura | 560, 612, 700, 1024, 1280, 1440 — **antes e depois** | **qualquer** largura mostrar faixa listrada |
| 28 | A faixa 1 não engole ação | print **com o menu de overflow aberto** mostrando "Salvar" e "Publish" | só o `⋮` aparecer: um menu vazio passaria e reprovaria na prática |
| 29 | O breadcrumb trunca | `CT_LONGO` a 1280, com reticências | faixa listrada |
| 30 | Painel colapsado continua alcançável (D2) | faixa fina com o controle de reabrir **dentro dela** | o único caminho de volta for atalho ou menu escondido |
| 31 | Colapsar dá espaço **ao mock** | par de prints com o **percentual do canvas subindo** | o percentual não mudar — o espaço virou fundo cinza |
| 32 | Buscar com grupos fechados acha | trio: fechados → `col` abre `Layout` → limpar **fecha de novo** | o terceiro print não voltar ao estado do primeiro |
| 33 | O layout sobrevive ao **refresh** | antes/depois de `F5` | qualquer diferença |
| 34 | O layout sobrevive à **navegação** | antes/depois de sair pelo breadcrumb e voltar | qualquer diferença. _É o incômodo relatado; o refresh sozinho não cobre_ |
| 35 | Largura salva é reclampada (D13) | 480 salvo, janela em 1024, após recarregar | painel maior que a janela, ou faixa listrada |
| 36 | Preferência corrompida **não bloqueia** (D12) | lixo em `flutter.editor.layout` + reload → editor abre em 280/320 | tela branca, erro, ou carregando eterno |
| 37 | O preview abre **frio** no aparelho (D18) | foto de celular que **nunca abriu o editor**, URL visível | 404, ou só funcionar depois de passar pela tela do projeto |
| 38 | O preview **não perde o resolver** (D6 / I1) | na mesma foto, a `image` sem ACAO **carregada** | caixa "falhou" — é a regressão exata do item 39 |
| 39 | O preview mostra o **último salvo** (D4) | par: editar sem salvar → pílula → **não muda**; salvar → pílula → **muda** | o primeiro par mudar: o preview não está mostrando o salvo |
| 40 | Tela cheia tem saída visível | print do modo ligado **com o controle de sair** | nenhum controle visível |
| 41 | Tela cheia **não esconde erro** (P2) | par: com erro → rodapé fica; sem erro → some | o rodapé sumir com erro. _Reintroduziria o sintoma que o item 38 corrigiu_ |
| 42 | O atalho, se houver, **chega ao app** (D16) | print do modo ligado logo após teclar, **no Chrome real** | o navegador capturar. _Lição do `Ctrl+Shift+W`: o `SingleActivator` no mapa não prova nada_ |

**Os itens 27, 38 e 41 são a cancela.** Se o editor ainda estoura, se a imagem voltou a
falhar em silêncio, ou se a tela cheia esconde erro, nada mais no DoD importa.

### 11.5 Fechamento

| # | Item | Como se prova |
| --- | --- | --- |
| 43 | **Bateria automatizada (F8) escrita DEPOIS do E2E atestado**, nunca antes | o PR 7 é posterior em data ao atestado do item 21 |
| 44 | Gate do CISO nas fases em que o agente for acionado | registro do agente `ciso`. _Nenhuma fase o exige por construção (D3), mas o registro de "não se aplica, e por quê" fica_ |
| 45 | `CHANGELOG` `Unreleased` atualizado **no mesmo PR** de cada mudança | o diff do PR contém o CHANGELOG |
| 46 | Se a Q1 for aprovada, `qr_flutter` documentado como dependência nova na descrição do PR 2 | o PR cita a dependência e o porquê |
| 47 | Docs vivas desta pasta: `final_report.md` ao fechar; `variance_report.md` aberto no primeiro desvio (`VR-17-01`) | os arquivos existem |
| 48 | `docs/roadmap.md` — o item **41** entra no Marco 4 e vira `[x]`; o débito do R3 entra na tabela de débitos vivos | as linhas marcadas |
| 49 | `docs/plans/README.md` atualizado com a doc viva do 41 | o índice |

---

## 12. Fora de escopo — evoluções registradas

- **Item 30** — variação do spec por breakpoint. Nome parecido, problema outro (§1, D5).
- **Item 24** — publicação e versionamento. Este item **não** constrói sobre a rota
  pública servindo rascunho (D3).
- **Item 26** — auth. A URL de preview aberta é dívida registrada (R3), não resolvida.
- **Item 28** — eventos e ações. Preview **interativo** depende dele (D17).
- **Preview ao vivo** (autosave debounced + polling, ou SSE/WebSocket) — +2 a +3 fases,
  num backend que ainda não tem bateria de teste (item 40). A D4 fecha em "último salvo".
- **Rotação (paisagem) do mock** — a moldura posiciona botões por fração da altura e o
  recorte da câmera assume o topo. Item próprio.
- **Presets de dispositivo além dos três** — barato, mas não é o que trava ninguém agora.
- **Comportamento por faixa de largura no editor** e **layout do editor para celular** —
  A1 os excluiu; se voltarem, viram item próprio.
- **"Dobrar seções" do painel JSON** — é o item **8b**, terceiro cliente do colapso (I5).
  A F4 desenha sabendo dele, **sem** juntar os itens.
- **Promover o colapso (paleta / Inspector / JSON) para `core/widgets/`** — a unificação
  só se paga com os três clientes no ar. I4 proíbe agora.
- **Analytics** — os cinco eventos propostos no PRD (`editor_panel_toggled`,
  `editor_palette_group_toggled`, `editor_fullscreen_entered/_exited`,
  `editor_layout_restored`, `editor_viewport_width_bucket`) não entram: **não existe
  pipeline de analytics no editor hoje**. Registrado para quando existir — o
  `editor_viewport_width_bucket` é o que responderia a A1 com dado em vez de suposição.
