# Plano — Navegar funciona no celular, editar funciona no desktop, e o conteúdo cabe nos dois

_Item **41** do roadmap (Marco 4 — Ergonomia do construtor). **Não existe plano de
gaveta**: escopo novo, nascido do pedido do dev humano em 2026-08-15. A matéria-prima é
[`specs.md`](specs.md) + [`prd.md`](prd.md) desta pasta, **mais a evidência de campo de
2026-08-16** (§2.0). Onde este plano divergir do PRD, **este manda**, e o motivo está na
§8._

> **Regra do "pronto":** `flutter analyze` verde + testes existentes passando. Nunca opinião.
> **Toca backend?** Não — nenhuma linha, em nenhuma fase. **Toca `sdui_core`?** Não.
> **Gate CISO?** Não é obrigatório em nenhuma fase (§4›D3 explica por que a rota de
> preview não abre superfície nova). **0-dep de roadmap:** sim — não antecipa nem
> depende dos itens 24, 26, 28 ou 30.
> **Alvos:** `apps/driva_editor/` — módulos `contents_module`, `projects_module`,
> `editor_module` e `core/`. Nada em `packages/`, nada em `backend/`.

---

## Estado

**2026-08-16 — plano revisado. A evidência de campo mudou o recorte e a ordem.** A F2
(rota de preview) está **em execução**. Nenhuma outra fase começou.

As quatro ambiguidades caras do `specs.md` seguem fechadas (A6, A1, A3, A7 — D1 a D4), e
o humano tomou **uma quinta decisão em 2026-08-16**: *"navegar no celular funciona;
editar, não"* (D20). Ela **reabre parcialmente a A1** — de propósito, e com limite
declarado (§4›D20).

**Pré-condição dura, herdada da invariante I6 do `specs.md`:** as fases que tocam
arquivos dos itens 38 e 39 (**F3** e **F5**) não abrem antes do E2E daqueles itens
atestado — a F3 mexe em `canvas_panel.dart`, que está sendo instrumentado em
`docs/16-image-url-e-props/`. **F1, F2 e F4 não tocam nada dos dois** e podem correr já.

| Fase | O que entrega | Dono | PR | Estado |
| --- | --- | --- | --- | --- |
| F1 | **Navegar no celular funciona** — projeto, categorias, lista, busca, diálogos | especialista-apresentacao | — | `[ ]` |
| F2 | Rota `/preview/:projectId/:id` — o conteúdo no celular | especialista-apresentacao + especialista-infra | — | `[-]` |
| F3 | Piso do editor: overflows do shell + "ajustar à janela" | especialista-apresentacao | — | `[ ]` |
| F4 | Grupos da paleta colapsáveis | especialista-apresentacao | — | `[ ]` |
| F5 | Painel do editor colapsa numa faixa fina de ícones | especialista-apresentacao | — | `[ ]` |
| F6 | O layout do editor é lembrado entre sessões | especialista-dominio + especialista-dados + especialista-apresentacao | — | `[ ]` |
| F7 | Modo tela cheia | especialista-apresentacao + especialista-infra | — | `[ ]` |
| F8 | E2E manual em homologação, executado e **atestado pelo humano** | qa instrumenta · dev humano atesta | — | `[ ]` |
| F9 | Bateria automatizada + docs vivas | qa | — | `[ ]` |

Legenda: `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída e revisada pelo QA.

**O que mudou nesta revisão** (2026-08-16): entrou a **F1** (navegação em celular), o
antigo piso do editor virou **F3**, e as fases seguintes deslocaram uma casa. As
decisões **D5** e **D20** são novas ou reescritas; a **D22** corrige um aceite do próprio
DoD que era **improvável em homologação** — detalhe em §4›D22 e §8›8.

---

## 1. Objetivo e recorte

São **dois problemas com o mesmo nome** — "o editor não é responsivo" — e naturezas
opostas. Tratá-los como um só foi o erro que a evidência de campo desfez.

| | **Navegação** (F1) | **Editor** (F3, F5, F7) |
| --- | --- | --- |
| Telas | home de projetos, detalhe do projeto, categorias, lista de conteúdos, diálogos | workspace, canvas, paleta, inspector |
| Largura que dói | **360–412** (celular na mão) | 1024–1440 (janela de laptop) |
| Sintoma | **tela inutilizável**: texto uma letra por linha, campo cortado, painel comendo 66% | tela apertada: mock cortado, breadcrumb estourando |
| Natureza da correção | **comportamento por faixa de largura** — a barra lateral vira outra coisa | mecânica — `Flexible`, piso, escala calculada |
| Meta | **funcionar de verdade no celular** | **funcionar bem no desktop** |
| Evidência | **foto do aparelho** (§2.0) | medição no código (§2.2, §2.3) |

**A decisão do humano que separa os dois (2026-08-16):** *"navegar no celular funciona;
editar, não."* Arrastar widget num celular muda o modelo de interação inteiro — e é para
isso que serve a rota `/preview` da F2. O editor **segue mirando desktop**, e isso é
decisão, não dívida.

**Em uma frase:** o dev abre o projeto no celular e consegue achar, buscar e abrir um
conteúdo; abre o editor no laptop e o mock já está ajustado à janela, os painéis colapsam
e o layout é lembrado; e manda uma URL para o próprio celular para ver o conteúdo no
tamanho real.

**O que este item não é.** Não é o **item 30** ("Responsividade — o spec ganha variação
por breakpoint"). Aquele é o **conteúdo SDUI do cliente** ficando responsivo, no kernel,
no formato do JSON. Este é a **ferramenta** ficando usável, sem tocar em `sdui_core`. A
F1 agora **cria** um `AppBreakpoints` do editor, e a §4›D5 existe para impedir que ele
seja fundido com o do kernel.

---

## 2. O que está quebrado hoje, medido no código

### 2.0 A evidência de campo — 2026-08-16

O dev humano fotografou `hml.driva.duckdns.org` num **Android, modo escuro**. A tela
quebrada **não é o editor**: é o **detalhe do projeto** (`contents_module`) — a tela mais
visitada do produto, porta de entrada de todo conteúdo.

O que a foto mostra:

- AppBar de duas faixas + breadcrumb "Projetos › Megazord - App RE" consumindo altura
  antes de qualquer conteúdo.
- O painel **CATEGORIAS** ocupando **~70% da largura**, confortável e legível ("Todos os
  conteúdos 2", "Divulgar 1", "Home 1").
- O painel de conteúdos espremido no resto, com o texto **descendo uma letra por linha na
  vertical** — "Todos os conteúdos" e, abaixo, "2 conteúdos".
- O campo de busca cortado, mostrando `Busc…`.

> **Arquivar a foto em `docs/17-ergonomia-editor/evidencias/rodada_00/`, como
> `00_evidencia_campo_android.jpg`.** É o "antes" dos itens 24 a 27 do DoD: sem ele, o
> "depois" da F1 não tem contra o que ser comparado. A `rodada_00` é a evidência que
> motivou o trabalho; as rodadas de E2E começam na `rodada_01`.

**Isso reordena o item.** O `specs.md` do PM afirma que o problema é do editor, e essa
leitura estava certa sobre o *que* dói no editor — mas **a tela mais visitada quebra
muito pior**, e num nível diferente: o editor a 1024 fica apertado; a lista de conteúdos
a 412 fica **inutilizável**.

### 2.1 A causa raiz — e ela **não** é o `ResizableSplitView`

A hipótese natural era que o `ResizableSplitView` (280/320, min 200, max 480) fosse o
culpado nas duas frentes. **Não é.** Uma varredura em `apps/driva_editor/lib` devolve
**um único uso**: `editor_workspace.dart:34`. A tela de conteúdos nunca o usou.

**Consequência direta e importante:** consertar o `ResizableSplitView` (F3, F5) **não
melhora em nada** a tela fotografada. São bugs diferentes, em arquivos diferentes, com
mecanismos diferentes. Se as duas frentes tivessem sido tratadas como uma, a F1 teria
sido dada como resolvida pela F3 — e a foto continuaria igual.

**São três causas independentes, e cada uma precisa da própria correção:**

**Causa A — a barra lateral tem largura fixa, numa `Row` crua.**
`project_detail_page.dart:113` monta `SizedBox(width: 272)` seguido de
`VerticalDivider(width: 1)` e `Expanded(child: ContentPanelView)`. **Não há
`LayoutBuilder`, não há `ResizableSplitView`, não há reação a largura nenhuma.**

| Largura da tela | Categorias | Sobra para o conteúdo | % do painel de categorias |
| --- | --- | --- | --- |
| 360 (Android comum) | 272 | **87** | **76%** |
| 412 (Android grande) | 272 | **139** | **66%** |
| 600 | 272 | 327 | 45% |
| 1280 | 272 | 1007 | 21% |

Os 66% a 412 px batem com os "~70%" da foto. **Causa A confirmada e quantificada.**

**Causa B — o cabeçalho do painel de conteúdos tem 220 px fixos e mata o `Expanded`.**
`content_panel_view.dart:140` monta, na mesma `Row`:

```
Expanded(Column[ Text(categoryLabel), Text('N conteúdos') ])
SizedBox(width: 220, child: TextField)   ← fixo
SizedBox(width: 10) · SortControl · SizedBox(width: 10) · ViewModeToggle
```

A `Row` tem `padding` de 24 de cada lado. A 412 px de tela, o painel recebe 139, e a
`Row` fica com **91 px**. Os filhos **não-flexíveis** já pedem 220 + 10 + `SortControl`
+ 10 + `ViewModeToggle` — bem mais de 91.

Numa `Row`, os filhos sem flex são medidos primeiro; o que sobra vai para os flexíveis. O
que sobra aqui é **negativo**, então **o `Expanded` resolve para largura zero**.

**É daí que vem o texto letra por letra.** Um `Text` com `maxWidth: 0` quebra em toda
oportunidade possível — e quando nem uma palavra inteira cabe, o Flutter quebra **por
grafema**. "Todos os conteúdos" desce uma letra por linha. Não é bug de fonte, nem de
`softWrap`: é largura zero.

> **A consequência que mais importa para o plano:** **consertar só a causa A não conserta
> o texto vertical.** Com as categorias fora do caminho, o painel a 412 px ainda tem
> `412 − 48 = 364`, e `220 + 10 + sort + 10 + toggle` continua estourando 364. O
> `Expanded` continua perto de zero. **As duas causas precisam ser corrigidas na mesma
> fase**, ou o E2E reprova com a foto quase idêntica.

**Causa C — os diálogos têm largura fixa maior que o aparelho.**
`content_form_dialog.dart:100` e `category_form_dialog.dart:63` usam
`SizedBox(width: 380)`; `project_form_dialog.dart:192` usa `460`;
`move_content_dialog.dart:34` usa `380`. Um `AlertDialog` ainda soma a própria margem.
**A 360 e a 412 px, nenhum deles cabe** — e "criar conteúdo" é parte do "navegar
funciona".

**O que já se comporta bem** (não mexer): as grades usam
`SliverGridDelegateWithMaxCrossAxisExtent` (`300` na lista de conteúdos, `340` na home de
projetos), que **já adapta a contagem de colunas** sozinha. O risco remanescente não é a
grade — é o **conteúdo do cartão** a 91 px de largura, com `mainAxisExtent: 182` fixo.
Verificar, não presumir (tarefa 5 da F1).

### 2.2 O chrome fixo do editor come o centro, sempre

`ResizableSplitView` monta `SizedBox(280) · handle(6) · Expanded(centro) · handle(6) ·
SizedBox(320)`. **612 px de chrome fixo**, em qualquer tela. O centro fica com
`viewport − 612`, e o widget não tem `LayoutBuilder`: não sabe o tamanho da janela.

### 2.3 O mock não cabe, e o zoom é manual

`CanvasPanel` desenha `Transform.scale(scale: zoom)` sobre a `DeviceFrame`. O `zoom` vem
do `EditorCubit` (`0.9` de fábrica, clampado em `0.4–1.5`) e **só muda por clique nas
lupas**. Não existe "ajustar à janela".

A largura real da moldura **não é** `device.width`: a `DeviceFrame` soma `bezel` dos dois
lados e mais `bezel * 0.55` de cada lado para os botões laterais transbordarem, fora a
borda. E o `CanvasPanel` envolve tudo num `Padding(all: AppSpacing.s32)`.

| Preset | `device.width` | Moldura ≈ | Com o padding ≈ | Altura ≈ |
| --- | --- | --- | --- | --- |
| Smartphone | 393 | 436 | **500** | 880 |
| Android | 412 | 449 | **513** | 939 |
| Tablet | 820 | 888 | **952** | 1224 |

**Correção do PRD:** ele estimou ~863 px para o tablet, contando só o `bezel`. São
**~952** — o preset tablet não cabe numa janela de 1440 (centro de 828) **nem numa de
1600** (centro de 988) com folga. §8›5.

### 2.4 Três overflows do editor que já estão no ar

1. **Breadcrumb (faixa 2).** `AppShellBreadcrumbBar` monta uma `Row` **sem nenhum filho
   flexível**, e o `CrumbLabel` pede `overflow: TextOverflow.ellipsis` num `Text` de
   largura ilimitada — a elipse **nunca dispara**.
2. **Faixa 1.** `AppShellTopBar` monta `wordmark · Spacer · 4 ações · status · tema`. O
   `Spacer` é o único elemento flexível.
3. **Workspace.** Abaixo de 612 px o `Row` do split view estoura.

### 2.5 Nada do layout do editor é lembrado

O arraste do splitter existe, mas o estado é `State` local: **some no refresh e a cada
navegação**. O Inspector colapsa seções desde o item 9b (`PropSection`, com
`initiallyExpanded`), mas **reabre tudo** a cada troca de nó e a cada refresh. Hoje a
**única** chave persistida no app é `preferences.theme_mode`.

### 2.6 Não há caminho nenhum para o aparelho

Não existe rota de preview, e o `projectId` **não está na URL de rota nenhuma do
editor** (`/contents/:id/edit` carrega só o id do conteúdo).

---

## 3. O que já existe e vamos reusar

### 3.1 Navegação (`contents_module`, `projects_module`)

- **`ProjectDetailPage`** — já tem `Scaffold`, já carimba o `ProjectScope` no
  `pageBuilder`, já monta os dois cubits (`CategoryTreeCubit`, `ContentListCubit`).
  **O `Scaffold` que já está lá é o que recebe a gaveta da F1, sem widget novo de
  estrutura.**
- **`CategoryTreeView`** — widget completo e autocontido, recebe tudo por construtor. **É
  o mesmo widget na barra lateral e dentro da gaveta** — nenhuma duplicação.
- **`ContentPanelView`** — `StatefulWidget` com busca *debounced*, ordenação e modo
  grade/lista. É onde a Causa B mora.
- **`ContentsCollection`** — grades com `maxCrossAxisExtent`, que **já adaptam**.
- A seleção de categoria já é reativa por `BlocListener` → `reloadWithFilter`. **Fechar a
  gaveta ao selecionar não precisa de estado novo**: é um `Navigator.pop` no callback que
  já existe.

### 3.2 Editor

- **`ResizableSplitView`** — 53 linhas, `StatefulWidget`, com `_leftWidth`/`_rightWidth`.
  Recebe `left`/`center`/`right` como campos `Widget` **já construídos** pelo `build` do
  `EditorWorkspace`. É essa construção antecipada que faz o `setState` não reconstruir
  painel nenhum — o mecanismo que o item 3b domou e que a §4›D8 protege.
- **`EditorCubit` / `EditorReady`** — já carrega `device` e `zoom`, lidos por
  `BlocSelector` no `CanvasArea`.
- **`DevicePreset`** — enum de 3 entradas com `bezel`, `cornerRadius`, `notch` e
  `safeArea*`.
- **`PropSection`** — colapso do Inspector, com `initiallyExpanded` já no construtor.
- **`WidgetPalettePanel`** — já agrupa por `WidgetCategories.inPaletteOrder` (kernel).
- **`EditorShortcuts` / `editor_intents.dart`** — infra do item 23, pronta para a F7.

### 3.3 Shell, roteador e tema

- **`AppShellController` + `AppShellScope`** — slots `crumbs`, `actions`, `status`, com
  dono por token. **É o canal legítimo do modo imersivo da F7**, e mantém a regra do item
  16c (o shell não lê cubit).
- **`app_router.dart`** — `rootNavigatorKey` e `shellNavigatorKey` separados; as 4 rotas
  vivem dentro do `ShellRoute`. Uma rota irmã no root nasce sem chrome.
- **`ProjectScope`** — singleton no get_it, lido pelo interceptor do Dio que carimba
  `x-project-id`. Escrito em `ProjectDetailPage.pageBuilder` (e, na F2, na página de
  preview).
- **nginx** — `try_files $uri $uri/ /index.html`. **O SPA fallback já cobre qualquer
  caminho.**
- **`core/theme/`** — `AppSpacing`, `AppRadii`, `AppTypography`, `AppDurations`,
  `AppIconSizes`, `EditorColors`, `DeviceMockColors`, barrel `theme.dart`.

### 3.4 Persistência

- **`preferences_module`** é dono do `registerSingleton<SharedPreferences>` e é o
  **primeiro** módulo do `setupInjection` — qualquer módulo posterior já resolve
  `getIt<SharedPreferences>()`. A instância vem do `bootstrap.dart`, antes do primeiro
  frame.
- O padrão da casa está no `PreferencesRepositoryImpl`: chave string privada, model com
  schema **zard** e `tryParse → Either`, ausência **não é erro**.

### 3.5 O que NÃO existe

- **Nenhum `LayoutBuilder`** em `apps/driva_editor/lib/`, e um único `MediaQuery` (dentro
  do mock). Responsividade não é parcial: é inexistente.
- **Nenhum token de tamanho** (`AppSizes`) e **nenhum `AppBreakpoints`**.
- **`qr_flutter` não é dependência** (§9›Q1).
- **`editor_module` não tem persistência local nenhuma.**

---

## 4. Decisões travadas

### D1 — O piso de responsividade **do editor** é: matar os overflows + ligar o ajuste — **[humano, A1]**

Vale **só para o editor**. Nada de comportamento por faixa de largura no workspace, no
canvas, na paleta ou no inspector. O editor **não** precisa abrir em celular. A régua é
objetiva e está no DoD.

**Limite revisado em 2026-08-16:** a A1 excluía comportamento por faixa de largura *da
primeira fatia inteira*. A D20 reabre isso **exclusivamente para as telas de navegação**.
No editor, a A1 continua valendo sem emenda.

### D2 — Painel do editor colapsado vira faixa fina de ícones, não some — **[humano, A3]**

Com a paleta sumida **não há de onde arrastar widget**. O controle de reabrir tem de estar
sempre visível, dentro da própria faixa — não num menu, não só num atalho.

### D3 — O preview no celular é a rota `/preview/:projectId/:id` no próprio editor — **[humano, A6]**

Uma URL sem chrome, servida pelo domínio que já está no ar. **1 fase, zero backend, zero
deployável novo, zero gate CISO.**

Descartadas: **a via API pública + `driva_demo_app`** (3–4 fases com CISO, deployável
novo, antecipa os itens 24 e 26, e **quebraria no dia do item 24** — que já decidiu servir
só o publicado, com `404` sem publicação e sem backfill); e **o modo tela cheia como
substituto** (continua sendo o desktop — entra na F7 porque vale por si, **não** como
resposta ao pedido do celular).

**Por que não precisa de CISO:** não cria endpoint, não muda auth, não amplia o que a API
expõe. O backend não tem auth nenhuma hoje (item 26 aberto) e o rascunho já é alcançável
por quem conhece a URL da API; o que a rota acrescenta é **materializar isso num link que
sai do laptop**, custo que o humano aceitou (A8) e que segue como dívida no risco R3.

### D4 — O preview mostra o último salvo, e diz isso na tela — **[humano, A7]**

Não existe autosave. O fluxo é **salvar → recarregar no celular**, e a página tem de dizer
isso. A forma: uma **pílula flutuante** no rodapé — `Último salvo · HH:MM · toque para
recarregar` — que refaz a busca ao toque. Resolve os dois problemas: comunica a semântica
**e** dá o recarregar sem depender do botão do navegador, que some quando a página está em
tela cheia no celular.

### D5 — **[reescrita em 2026-08-16]** `AppBreakpoints` nasce na F1, com os números do item 30, e governa **só** a navegação

**A versão anterior desta decisão dizia que nenhum breakpoint nasceria.** Ela estava certa
enquanto o escopo era só o editor: com a D1 valendo, tudo era mecânico e um vocabulário de
faixa não teria cliente. **A D20 deu um cliente.** A barra lateral de 272 px não se
conserta com `Flexible`: a 412 px de tela ela tem de **deixar de ser barra lateral**. Isso
é comportamento por faixa, e comportamento por faixa quer nome.

**Decisão:** `core/theme/app_breakpoints.dart`, com os **mesmos limiares do item 30**
(Material 3: compact < 600, medium 600–1023, expanded ≥ 1024), **sem importar o enum
`SduiBreakpoint` do `sdui_core`** (invariante **I3**). Chrome do editor é tema; breakpoint
do spec é kernel. São dois vocabulários com os mesmos números **de propósito**, e o dia em
que alguém "unificar" os dois é o dia em que mexer no layout da ferramenta vira mudança de
formato de JSON do cliente.

**Duas cercas, cobradas na revisão:**
1. **`grep -rn "SduiBreakpoint" apps/driva_editor/lib` = zero.** O editor nunca importa o
   enum do kernel.
2. **`AppBreakpoints` só é consultado em `contents_module` e `projects_module`.** Nenhum
   arquivo de `editor_module` o consulta — a D1 continua valendo lá, e essa é a diferença
   entre "o editor não é responsivo" e "o editor é desktop por decisão".

**E o que continua não sendo breakpoint:** o limiar do menu de overflow da faixa 1 (F3) é
a largura em que **aquela barra específica** para de caber, medida no conteúdo dela. Mora
em `AppSizes.topBarActionsFitWidth`, não em `AppBreakpoints`, e não governa mais nada.

### D6 — O `imageUrlResolver` sai de método privado da `EditorPage` e vira fábrica compartilhada — **[tech-lead, invariante I1]**

Hoje `EditorPage._imageUrlResolverFor(AppConfig)` é `static` e **privado**. A F2 cria uma
segunda página que renderiza SDUI. Duplicar a guarda (`apiBaseUrl.isEmpty || useFakeData →
null`) é como a regressão do item 39 volta: a segunda página esquece a guarda, ou o
resolver inteiro, e **a imagem de host sem CORS falha em silêncio**.

O método vira função de topo em `core/network/image_url_resolver_factory.dart`, e as duas
páginas — os únicos lugares autorizados a tocar o get_it — chamam a mesma função. **A I1
deixa de ser lembrete e vira estrutura**, e por isso tem aceite próprio com print na F2.

### D7 — Esta feature **não** dispara a refatoração do `VR-16-02`, e instala o soquete dela — **[tech-lead]**

O `VR-16-02` registrou que **cinco níveis de repasse por construtor é o teto**, e que o
sexto vira `InheritedWidget` escopado — pago por quem precisar dele.

**Levantamento:** nada novo viaja a cadeia `EditorPage → EditorWorkspace → CenterArea →
CanvasArea → CanvasPanel → PreviewSurface`. O `imageUrlResolver` continua o único
passageiro (a D6 só troca **onde ele é construído**). O que a F3 acrescenta ao
`CanvasPanel` nasce dentro dele, num `LayoutBuilder`. O que a F5 e a F6 acrescentam vai
para `ResizableSplitView`, a **dois** níveis da página. **O sexto nível nunca é alcançado
— esta feature não paga a refatoração.**

O que ela faz é instalar o **soquete**: a F5 monta um `EditorLayoutScope`
(`InheritedNotifier<EditorLayoutController>`) no `EditorWorkspace.build`, porque o gatilho
da tela cheia (F7) vem de fora do split view. **O próximo item que precisar de um sexto
passageiro no caminho do canvas move o `imageUrlResolver` para um escopo análogo — e é ele
que paga.**

### D8 — O colapso e as larguras **não** entram no `EditorCubit` — **[tech-lead, invariante I2]**

Duas razões: o item 30 já reservou assento no `EditorReady` (`editingBreakpoint`) e todo
`emit` é o caminho quente que o item 3b otimizou; e **não precisa** — os painéis chegam ao
`ResizableSplitView` como campos `Widget` já construídos pelo `build` do
`EditorWorkspace`, que não roda quando o split view se atualiza. Instâncias idênticas,
Flutter curto-circuita, **nenhum painel reconstrói**.

**A parte que se erra sem perceber (R5):** o `ValueListenableBuilder` do
`EditorLayoutController` fica **dentro do `build` do `ResizableSplitView`, envolvendo só a
`Row`**. Colocá-lo no `EditorWorkspace.build` reconstrói `LeftPanel`, `CenterArea` e
`InspectorArea` **a cada clique**, desfazendo o item 3b sem sintoma visível.

**Este aceite é de máquina, não de print.** O `State` dos painéis sobrevive ao rebuild:
foco, texto digitado e aba selecionada continuam lá. Está no DoD como teste de widget com
contador de builds — **não invente um print que não prova isto.**

### D9 — A escala de ajuste **não** passa pelo `changeZoom` — **[tech-lead]**

`changeZoom` clampa em `0.4–1.5`. O tablet numa janela de 1024×720 precisa de escala
**abaixo de 0.4** — empurrar o ajuste por ali faria o fit falhar **exatamente no caso que
o motivou**. O cubit guarda só `fitToWindow: bool`; a escala é calculada no widget, num
`LayoutBuilder`, e usada direto no `Transform.scale`.

Corolários:
- **O ajuste nunca amplia além de 100%** (`min(escala, 1.0)`). "Ajustar" é fazer caber.
- **A barra do canvas mostra a escala efetiva.** Mostrar `90%` com o mock a `43%` seria
  uma mentira indistinguível de o fit não funcionar. Isso obriga o `LayoutBuilder` a
  envolver **a `Column` inteira** do `CanvasPanel`, não só o canvas.
- **O `LayoutBuilder` fica FORA do `InteractiveViewer`**, que está com `constrained:
  false`: o filho dele recebe restrição **infinita**, e um `LayoutBuilder` lá dentro
  devolve `Infinity` — a conta vira `NaN`.

### D10 — O tamanho externo da moldura vira propriedade do `DevicePreset` — **[tech-lead]**

A conta da §2.3 hoje mora espalhada no `build` da `DeviceFrame`. Se o ajuste refizer a
conta por fora, as duas divergem no dia em que alguém mexer na moldura — e o sintoma é o
mock cortado por alguns pixels, que ninguém associa à causa. `DevicePreset` ganha `Size
get frameSize`, e **a `DeviceFrame` passa a consumir o mesmo getter**.

### D11 — A persistência é repositório próprio do `editor_module` — **[tech-lead, A4]**

O `preferences_module` é genérico (tema) e o barrel dele **nem exporta** o contrato.
Fazê-lo saber do layout do editor inverte a dependência. O `editor_module` ganha a própria
pilha, no formato do `EditorRepository` que já tem. **Nada novo é bootstrapado**:
`SharedPreferences` já está no get_it. Chave única **`editor.layout`**, espelhando
`preferences.theme_mode`, com um JSON validado por zard.

### D12 — Preferência ausente ou corrompida cai no padrão **em silêncio** — **[PRD]**

Layout salvo **não é dado do usuário**: é conforto. Ausente devolve o padrão em `Right`;
corrompido devolve `Left(ValidationFailure)` e o controller **dobra para o padrão sem
propagar** — nada de banner, nada de tela de erro. **Nunca pode bloquear a abertura do
editor**, e isso tem prova própria no DoD, porque é a linha mais fácil de escrever e mais
fácil de não cumprir.

### D13 — A largura restaurada é **reclampada**, nunca aplicada cega — **[PRD]**

Contra `minPanelWidth`/`maxPanelWidth` (200/480) **e** contra o que a janela atual
comporta.

### D14 — Abaixo do somatório dos mínimos, o workspace **rola na horizontal** — **[tech-lead]**

Os mínimos somam `200 + 200 + 12 + minCentro`. Abaixo disso alguma coisa cede, e as opções
eram encolher os painéis até ficarem inúteis, deixar o centro sumir, ou rolar. **Rolar é a
única degradação honesta** — nada desaparece, nada mente, e não é comportamento por faixa
(D1): é **um** piso mecânico.

Mecânica: `LayoutBuilder` → `rowWidth = max(constraints.maxWidth, somaDosMinimos)` →
`SingleChildScrollView(horizontal, child: SizedBox(width: rowWidth, child: Row(...)))`. O
`SizedBox` é o que mantém o `Expanded` do centro com significado dentro de um viewport de
largura infinita.

### D15 — O modo tela cheia **não** é persistido — **[tech-lead]**

Largura e colapso são hábito de trabalho e ficam salvos (P3). Tela cheia é um momento.
Reabrir o editor já em tela cheia, sem faixa 1 e sem breadcrumb, é entregar o dev numa tela
sem saída óbvia.

### D16 — O controle da tela cheia é um **botão**; o atalho é secundário e verificado no Chrome ao vivo — **[tech-lead]**

O item 39 registrou (§8, item 13) que um aceite escrito a partir da **API do mecanismo**
deu falso: `Ctrl+Shift+W` estava no mapa de `Shortcuts` e nunca chegou ao app — **é o
atalho de fechar a janela do Chrome**. Um modo alcançável só por atalho é um modo que
ninguém acha, e um atalho não verificado é um aceite que mente.

Controle primário = botão sempre visível na barra do canvas. Atalho opcional, e **nenhuma
combinação `Ctrl+Shift+<letra>` entra sem teste ao vivo no Chrome**.

### D17 — O preview é **visual**, não interativo, e sem diagnósticos — **[tech-lead, A9 + item 39›D13]**

`SduiView.content` sem `nodeWrapper` e **com `showDiagnostics: false`**. O segundo ponto
importa: a caixa de diagnóstico mostra a URL e o `error.toString()`, aceitável **só no
editor**. A rota de preview é um link que sai do laptop — diagnóstico ligado ali vazaria
detalhe de infraestrutura para quem receber o link. Interatividade de verdade depende do
**item 28** e está fora (§12).

### D18 — A rota de preview carimba o `ProjectScope` no `pageBuilder` — **[tech-lead]**

O `projectId` está no path por decisão da D3, mas **isso sozinho não basta**: o header
`x-project-id` é carimbado pelo interceptor do Dio a partir do
`getIt<ProjectScope>().projectId`, escrito hoje só quando o usuário passa pela tela do
projeto. Aberta fria no celular, a rota cairia no `DEFAULT_PROJECT_ID` do build e
devolveria **404 inexplicável**. Mesmo padrão do `ProjectDetailPage.pageBuilder`, e seguro
porque a rota de preview é terminal. **O aceite disto não é ler o `pageBuilder`** — é o
print tirado num aparelho que **nunca abriu o editor**.

### D19 — Os parâmetros novos da `EditorPage` são opcionais — **[tech-lead]**

`editor_perf_test.dart` e `canvas_panel_golden_test.dart` montam `EditorPage`
**diretamente**, sem DI registrada. Foi exatamente essa propriedade que quebrou 5 testes no
item 39 e gerou o `VR-16-02`. O `EditorLayoutController` entra como parâmetro
**opcional**; ausente, a página monta um controller em memória com os padrões.

### D20 — **[nova, humano, 2026-08-16]** Navegar no celular funciona; editar, não

A quinta decisão do humano, tomada diante da foto:

- **Home de projetos, detalhe do projeto, categorias, lista de conteúdos, busca e
  diálogos** passam a funcionar de verdade em largura de celular (**360 a 599**).
- **O editor** (workspace, canvas, paleta, inspector) **segue mirando desktop**. Arrastar
  widget num celular muda o modelo de interação inteiro, e a resposta para "ver no
  celular" é a rota `/preview` da F2 — não portar o construtor.

Isso **reabre parcialmente a A1**, que excluía comportamento por faixa de largura da
primeira fatia. A reabertura tem **fronteira declarada e cobrada** (D5›cerca 2): faixa
entra na navegação, não entra no editor.

### D21 — **[nova]** Em faixa `compact`, a barra lateral de categorias vira **gaveta**

As opções eram gaveta, abas ou pilha de navegação.

- **Abas** forçam categorias e conteúdos a uma relação de irmãos que eles não têm — a
  categoria **filtra** a lista, não é um par dela. Trocar seleção viraria trocar de aba,
  e o usuário perderia de vista o que está filtrando.
- **Pilha de navegação** (tela de categorias → tela de lista) é mais trabalho e quebra a
  propriedade de "a mesma tela no desktop e no celular", que é o que mantém uma
  implementação só.
- **Gaveta** reusa o `Scaffold` que a `ProjectDetailPage` **já tem**, reusa o
  `CategoryTreeView` **inteiro e sem alteração**, e mantém o modelo mental do desktop:
  as categorias continuam sendo um painel ao lado, só que sob demanda.

**Decisão: gaveta.** Em `compact`, a `Row` colapsa para só o painel de conteúdos e o
mesmo `CategoryTreeView` vai para `Scaffold.drawer`. Selecionar uma categoria **fecha a
gaveta** — o `BlocListener` que recarrega a lista já existe; fechar é um `Navigator.pop`
no callback.

**O botão de abrir a gaveta fica no cabeçalho do painel de conteúdos, não na faixa 1 do
`AppShell`.** Duas razões: a faixa 1 é `core/widgets/app_shell/`, que a F3 também mexe —
manter a F1 fora de lá deixa as duas fases **totalmente isoladas** e paralelizáveis; e o
`Scaffold` que abre a gaveta é o da `ProjectDetailPage`, que está **abaixo** do shell.

### D22 — **[nova, correção de aceite]** Em homologação **não existe faixa listrada de overflow** — o aceite tem de ser o sintoma, não o indicador

**Este plano, na versão de 2026-08-15, tinha vários aceites da forma "nenhuma faixa
listrada, em homologação". Eles eram improváveis, e teriam passado provando nada.**

O `Dockerfile` roda `flutter build web --release`. O indicador listrado amarelo e preto do
`RenderFlex` é pintado **dentro de um bloco `assert`** — existe em **debug**, e só. Em
release o conteúdo simplesmente vaza ou é cortado, **em silêncio**. Ou seja: em
`hml.driva.duckdns.org` a faixa **nunca** aparece, com bug ou sem bug.

É a mesma armadilha do item 39 (§8›13): aceite escrito a partir da **API do mecanismo**
(`RenderFlex overflow`) em vez do **estado observável**.

**Correção, em três camadas, cada uma honesta sobre o que prova:**

| Camada | Onde | O que se observa | O que prova |
| --- | --- | --- | --- |
| **Sintoma** | homologação, release, aparelho e janela reais | título em **uma linha com reticências**; campo de busca legível; nada cortado na borda direita; mock inteiro | que o usuário não vê o defeito |
| **Indicador** | **build de debug local** (`flutter run -d chrome`) | a faixa listrada | que não há overflow de verdade, e não só overflow escondido |
| **Máquina** | `flutter test` (roda em debug) | `FlutterError.onError` capturado nas larguras de borda | a régua que não depende de olho |

**A camada do meio é a única exceção legítima à regra "E2E em homologação, nunca em
localhost"** (item 9g) — porque o que ela mede **só existe em debug**. Ela é passo próprio
no roteiro (§10›19), marcada como tal, e **não substitui** a camada do sintoma.

---

## 5. Fases

### F1 — Navegar no celular funciona · **[0-dep; ∥ com F2, F3, F4]** · **[sub-agente: especialista-apresentacao]**

É a D20. Cobre as três causas da §2.1 **na mesma fase**, porque corrigir só a Causa A
deixa o texto vertical de pé (§2.1, o alerta em destaque).

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/theme/app_breakpoints.dart` | **novo** — `compact < 600`, `medium 600–1023`, `expanded ≥ 1024` (D5); sem importar o kernel |
| `core/theme/theme.dart` | barrel |
| `.../contents_module/presentation/project_detail/project_detail_page.dart` | `LayoutBuilder`; em `compact` a `Row` colapsa e o `CategoryTreeView` vai para `Scaffold.drawer` (D21) |
| `.../project_detail/widgets/content_panel_view.dart` | o cabeçalho reflui: em `compact`, título e controles empilham; a busca vira `Expanded`; título com `maxLines: 1` + `ellipsis` |
| `.../project_detail/widgets/content_panel/content_panel_header.dart` | **novo** — o cabeçalho sai do `build` do `ContentPanelView` (Gates 1 e 3) |
| `.../project_detail/widgets/content_panel/drawer_toggle_button.dart` | **novo** — o botão da gaveta, só em `compact`, com `Semantics` + tooltip |
| `.../project_detail/widgets/content_form_dialog.dart` · `category_form_dialog.dart` · `move_content_dialog.dart` | `380` → largura que respeita a tela (Causa C) |
| `.../projects_module/.../widgets/project_form_dialog.dart` | `460` → idem |
| `.../content_panel/content_card.dart` | só se a tarefa 5 mostrar que quebra |

**Tarefas:**

1. **[paralela: não — primeiro]** `AppBreakpoints` (D5), com as duas cercas da decisão.
2. **[paralela: sim]** Causa A: `LayoutBuilder` na `ProjectDetailPage` + gaveta em
   `compact` (D21), reusando o `CategoryTreeView` **sem alterá-lo**.
3. **[paralela: sim]** Causa B: extrair `ContentPanelHeader`, empilhar em `compact`,
   busca `Expanded`, título com `maxLines: 1` + `TextOverflow.ellipsis`.
   _As duas metades são obrigatórias: a segunda é o que faz o modo de falha ser
   **truncar**, não **descer letra por letra**, se algum irmão voltar a espremer._
4. **[paralela: sim]** Causa C: os quatro diálogos.
5. **[paralela: sim]** **Verificar, não presumir:** home de projetos e cartão de conteúdo
   a 360 e 412. As grades usam `maxCrossAxisExtent` e **já adaptam a contagem de
   colunas**; o risco é o **conteúdo do cartão** numa coluna estreita, com `mainAxisExtent:
   182` fixo. Corrigir o que quebrar; se nada quebrar, registrar que foi verificado.

**Aceite (validável — escrito como o print que o prova):**

1. **A foto refeita.** Mesmo aparelho, mesmo projeto, mesmo modo escuro da §2.0: **"Todos
   os conteúdos" aparece em UMA linha horizontal**, com reticências se não couber. _É o
   par direto com `evidencias/rodada_00/00_evidencia_campo_android.jpg`. Sem o "antes", o
   "depois" não prova nada._
2. **O painel de categorias não come a tela:** na mesma foto, **não há barra lateral** —
   há o botão da gaveta no cabeçalho. Tocá-lo abre a gaveta com as categorias legíveis
   (segunda foto).
3. **A gaveta fecha ao selecionar:** tocar em "Divulgar" na gaveta → a gaveta fecha **e** a
   lista mostra só os conteúdos de Divulgar. _Par de fotos; se a gaveta ficar aberta por
   cima da lista filtrada, reprova._
4. **A busca é usável:** o campo aparece com o hint legível (não `Busc…`), e digitar
   filtra. _Foto do campo com texto digitado._
5. **Criar conteúdo cabe (Causa C):** o diálogo "Novo conteúdo" aberto no aparelho, com
   os dois botões de ação visíveis **sem rolagem horizontal**.
6. **A fronteira da faixa (D5):** a 599 px de largura de janela, gaveta; a 601, barra
   lateral. _Dois prints — é o que prova que existe faixa e onde ela está._
7. **O editor não foi afetado** — prova de máquina: `grep -rn "AppBreakpoints"
   apps/driva_editor/lib/modules/editor_module` = **zero** (D5›cerca 2).

**O que este aceite NÃO prova:** que o editor funciona no celular. Não funciona, e é
decisão (D20). O aceite 7 é o que impede que alguém "aproveite a viagem".

---

### F2 — Rota `/preview/:projectId/:id` — o conteúdo no celular · **[0-dep; EM EXECUÇÃO]** · **[sub-agente: especialista-apresentacao + especialista-infra]**

Não afetada pela evidência de campo. Segue como está.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/network/image_url_resolver_factory.dart` | **novo** — a fábrica que sai da `EditorPage` (D6) |
| `core/network/network.dart` | barrel |
| `.../editor/editor_page.dart` | chama a fábrica; o método privado morre |
| `modules/editor_module/editor_routes.dart` | `preview = '/preview/:projectId/:id'`, `previewName`, `static GoRoute get previewRoute` |
| `app_router.dart` | a rota entra no `routes:` do **root**, irmã do `ShellRoute` — nasce sem chrome |
| `.../presentation/preview/preview_page.dart` | **nova** página; `pageBuilder` carimba o `ProjectScope` (D18) |
| `.../presentation/preview/cubit/preview_cubit.dart` + `preview_state.dart` (`part of`) | `sealed`: `PreviewLoading` / `PreviewReady(spec, fetchedAt)` / `PreviewFailure`; reusa `LoadContentUseCase` |
| `.../presentation/preview/widgets/last_saved_pill.dart` | **novo** — a pílula da D4 |
| `.../presentation/preview/widgets/preview_share_dialog.dart` | **novo** — a URL, copiável, com "abrir em nova aba" |
| `.../editor/widgets/canvas/canvas_toolbar.dart` | botão que abre o diálogo |

**Tarefas:**

1. **[paralela: não — primeiro]** Extrair a fábrica do resolver (D6) e apontar a
   `EditorPage` para ela. _Sem comportamento novo; entra primeiro para o resto da fase já
   nascer usando a fábrica._
2. **[paralela: sim]** Rota + `PreviewCubit` + `PreviewPage` (`showDiagnostics: false`,
   D17; `ProjectScope` carimbado, D18).
3. **[paralela: sim]** A pílula "último salvo" (D4).
4. **[paralela: sim]** O diálogo com a URL no editor.
5. **[paralela: sim — descartável]** **QR code.** Exige `qr_flutter`, a **única
   dependência nova** de toda a feature. **Cai sem quebrar a fase** (§9›Q1).

**Aceite (validável — escrito como o print que o prova):**

8. **Foto de celular real** (não emulador) com o conteúdo ocupando a tela, **sem faixa 1,
   sem breadcrumb, sem painéis**, com a URL `https://hml…/preview/<projectId>/<id>`
   visível na barra do navegador do aparelho.
9. **A prova do `ProjectScope` (D18):** a foto do item 8 é tirada num **aparelho ou aba
   anônima que nunca abriu o editor**. _Se só funcionar depois de passar pela tela do
   projeto, reprova — é o 404 inexplicável que a D18 existe para evitar._
10. **A prova da invariante I1 (D6):** o conteúdo do item 8 **inclui a `image` com a URL
    sem ACAO do item 39**, e na foto ela aparece **carregada**. _Caixa "falhou" = o
    resolver não chegou à página nova. É a regressão exata do item 39, e reprova._
11. **A prova da D4 — dois pares, e é o par que prova:** (a) editar no desktop **sem
    salvar** → tocar na pílula → **não muda**; (b) **Salvar** → tocar → **muda**. _Sem o
    par (a), o item prova só que a pílula recarrega._
12. **A pílula diz o que mostra:** "Último salvo" legível na foto.

**O que este aceite NÃO prova:** que o preview é seguro para compartilhar. Não é — link
sem tranca, aceito (A8), dívida do item 26 no risco R3.

---

### F3 — Piso do editor: overflows do shell + "ajustar à janela" · **[dep. E2E do 38/39]** · **[∥ com F1, F2, F4]** · **[sub-agente: especialista-apresentacao]**

É a D1, verbatim. As duas metades entram no mesmo PR porque foi assim que o humano definiu
o piso do editor, e porque nenhuma vale sozinha como "o editor parou de brigar comigo".

**Precede a F5 e a F7, e não é só por ser o maior retorno isolado.** É **pré-requisito
para elas serem prováveis num print**: com o zoom fixo no `Transform.scale`, colapsar a
paleta libera 280 px que viram **fundo cinza** — o mock não cresce um pixel. A F5 sem a F3
entrega um par de prints em que nada de relevante muda.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/theme/app_sizes.dart` | **novo** — `canvasToolbarHeight`, `topBarHeight`, `breadcrumbBarHeight`, `minCenterWidth`, `panelRailWidth` (F5), `topBarActionsFitWidth` |
| `core/widgets/app_shell/app_shell_breadcrumb_bar.dart` | `Flexible` em cada `CrumbLabel` — a elipse passa a disparar |
| `core/widgets/app_shell/app_shell_top_bar.dart` | `LayoutBuilder`; abaixo de `topBarActionsFitWidth` as ações colapsam num menu |
| `core/widgets/app_shell/app_shell_actions_overflow_menu.dart` | **novo** (Gate 1) |
| `core/widgets/layout/resizable_split_view.dart` | `LayoutBuilder`, piso do centro, reclamp, rolagem horizontal (D14) |
| `.../editor/device_preset.dart` | `Size get frameSize` (D10) |
| `.../editor/widgets/canvas/device_frame.dart` | consome `frameSize` (D10) |
| `.../editor/widgets/canvas/fit_scale.dart` | **novo** — `double fitScaleFor({required Size frame, required Size viewport})`, pura e testável |
| `.../editor/widgets/canvas_panel.dart` | `LayoutBuilder` em volta da `Column` (D9) |
| `.../editor/widgets/canvas/canvas_toolbar.dart` | botão "Ajustar à janela" + percentual efetivo; tokeniza `height: 44` e `iconSize: 18` |
| `.../editor/page/canvas_area.dart` | o `BlocSelector` carrega `fitToWindow` |
| `.../editor/cubit/editor_state.dart` · `editor_cubit.dart` | `fitToWindow` (default `true`, P5); `toggleFitToWindow()`; `changeZoom` desliga o fit |

**Tarefas:**

1. **[paralela: sim]** Overflow do shell: `Flexible` nos crumbs + menu na faixa 1 +
   `AppSizes`.
2. **[paralela: sim]** Piso do centro no `ResizableSplitView` (D14).
3. **[paralela: sim]** `DevicePreset.frameSize` + `DeviceFrame` consumindo (D10).
4. **[paralela: não — dep. 3]** `fitScaleFor` + `LayoutBuilder` no `CanvasPanel` +
   `fitToWindow` + botão e percentual na toolbar.
5. **[paralela: não — por último]** Regravar `goldens/canvas_panel*.png`. **A descrição do
   PR cita o diff visual**; regravação sem citação reprova (régua do item 39).

**Aceite (validável — escrito como o print que o prova):**

13. **Janela 1024×720, preset Tablet:** as **quatro quinas da moldura** dentro da área do
    canvas, e a barra do canvas **abaixo de 40%**. _O percentual abaixo de 40 é a parte
    que importa: prova que a escala não passou pelo clamp do `changeZoom` (D9). Hoje a
    moldura sai pela direita e por baixo e a barra mostra `90%`._
14. **O ajuste é reativo:** arrastar a borda da janela de 1440 para ~900 **sem tocar em
    nada** muda o percentual entre os dois prints. _Iguais = escala calculada uma vez._
15. **Manual vence (P5):** um clique em `+` desliga o ajuste — toggle **não-selecionado**,
    percentual na faixa manual; clicar em "Ajustar" religa. _Dois prints, distintos._
16. **Breadcrumb a 1280 com nome de ~80 caracteres:** o último crumb **com reticências, em
    uma linha**. _Camada do sintoma, D22._
17. **Faixa 1 a 700 e a 560:** o botão de overflow aparece **e o print é com o menu
    aberto**, mostrando "Salvar" e "Publish" dentro. _O `⋮` visível não basta: um menu que
    abre vazio passaria no aceite e reprovaria na prática._
18. **Workspace a 560:** a rolagem horizontal da D14 aparece e **nenhum conteúdo some na
    borda direita**. _Camada do sintoma, D22 — a faixa listrada é o passo 19 do roteiro,
    em build de debug._
19. **Invariante I1 sobreviveu ao `canvas_panel.dart`:** a `image` sem ACAO do item 39
    **continua carregando** no mock, e a aba Network mostra `…/v1/media/proxy?url=…`.
    _Print, não grep._

---

### F4 — Grupos da paleta colapsáveis · **[0-dep; ∥ com F1, F2, F3]** · **[sub-agente: especialista-apresentacao]**

**Arquivos:** `.../widgets/widget_palette/palette_category_section.dart` (**novo**),
`palette_category_header.dart` (**novo**), `widget_palette_panel.dart` (o laço do
`ListView` delega; sai a árvore inline do `build`).

**Decisões locais:** **não usar `ExpansionTile`**; **não promover** o `PropSection` para
`core/widgets/` (I4 — os itens 38 e 39 acabaram de mexer no Inspector). O widget novo
nasce na pasta da paleta. **Sabendo da I5** (o item 8b, "dobrar seções" do painel JSON, é
o terceiro cliente), a API do cabeçalho fica genérica — `label`, `trailing`, `isExpanded`,
`onToggle` — mas a **promoção é item futuro, não este**.

**Busca com grupos fechados:** com filtro ativo, os grupos com resultado são **forçados
abertos** sem tocar no conjunto de colapsados; ao limpar, tudo volta. Mecanicamente:
`isExpanded = query.isEmpty ? !fechados.contains(cat) : true` — sem mutação durante a
filtragem.

**Tarefas:** 1. **[paralela: sim]** `PaletteCategoryHeader` + `PaletteCategorySection`.
2. **[paralela: não — dep. 1]** `WidgetPalettePanel` delega; colapsados no `State` do
painel (a persistência é a F6).

**Aceite (validável — escrito como o print que o prova):**

20. **Os quatro grupos fechados:** só 4 cabeçalhos, cada um com chevron e **contagem de
    widgets**, e **sem barra de rolagem**. _Hoje, com 24 primitivos, a lista rola a
    1366×900._
21. **`Listas` aberto e os outros três fechados:** os itens cabem **sem rolar**.
22. **A borda que prova de verdade — trio de prints:** 4 grupos fechados → digitar `col`
    → **`Layout` abre com o `Column` visível** → limpar a busca → **os 4 fechados de
    novo**. _Sem isto, buscar com tudo fechado parece "não achou nada". Um print só não
    prova: é o trio._
23. **A regra do catálogo continua de pé** — prova de máquina: nenhum literal de nome de
    categoria em `.../widgets/widget_palette/`; a ordem vem de
    `WidgetCategories.inPaletteOrder`.

---

### F5 — Painel do editor colapsa numa faixa fina de ícones · **[dep. F3]** · **[∥ com F4]** · **[sub-agente: especialista-apresentacao]**

**Arquivos:** `.../editor/page/editor_layout.dart` (**novo** — valor imutável,
Equatable), `editor_layout_controller.dart` (**novo** — `ValueNotifier<EditorLayout>`,
D8), `editor_layout_scope.dart` (**novo** — `InheritedNotifier`, o soquete da D7),
`core/widgets/layout/resizable_split_view.dart` (**o `ValueListenableBuilder` fica aqui
dentro, em volta da `Row`** — D8), `core/widgets/layout/panel_rail.dart` +
`panel_rail_button.dart` (**novos**), `left_panel.dart` (expõe a aba corrente),
`editor_workspace.dart` (monta o scope), `editor_page.dart` (controller **opcional**,
D19).

**Tarefas:** 1. **[paralela: não]** `EditorLayout` + controller + scope.
2. **[paralela: sim]** `PanelRail` + `PanelRailButton` (Gates 1, 3 e 4).
3. **[paralela: não — dep. 1 e 2]** `ResizableSplitView` controlado.

**Aceite (validável — escrito como o print que o prova):**

24. **Paleta colapsada:** a faixa fina com os ícones **Widgets** e **Árvore** visíveis, **e
    o percentual do canvas subiu** em relação ao print anterior. _O percentual é a metade
    que prova que o espaço foi para o mock e não para o fundo._
25. **Os dois painéis colapsados:** duas faixas, mock no maior tamanho, **os dois
    controles de reabrir visíveis**.
26. **A faixa é atalho, não só interruptor (D2):** com a paleta colapsada, clicar no ícone
    **Árvore** reabre o painel **na aba Árvore**.
27. **A borda que a A3 decidiu:** o print do item 24 mostra o controle de reabrir **dentro
    da faixa**. _Reprova se o único caminho de volta for atalho ou menu escondido._

**O que este aceite NÃO prova:** que os painéis não reconstroem no toggle (D8). Não há
print para isso — é teste de widget na F9.

---

### F6 — O layout do editor é lembrado entre sessões · **[dep. F4 + F5]** · **[sub-agente: especialista-dominio + especialista-dados + especialista-apresentacao]**

Fase própria, depois da F4 e da F5, **de propósito**: uma pilha de persistência escrita uma
vez, servindo quatro clientes que já existem (larguras, painéis, grupos da paleta, seções
do Inspector). Escrevê-la antes seria escrevê-la duas vezes.

**Arquivos:** `domain/entities/editor_layout.dart` · `domain/repositories/
editor_layout_repository.dart` · `domain/use_cases/get_editor_layout_use_case.dart` +
`save_editor_layout_use_case.dart` · `data/models/editor_layout_model.dart` (zard) ·
`data/repositories/editor_layout_repository_impl.dart` (chave `editor.layout`, **único
`try/catch`**) · `editor_injection.dart` (+3 registros) · `editor_page.dart` ·
`editor_layout_controller.dart` · `.../inspector/prop_section.dart` (ganha
`onExpandedChanged`).

**Decisões locais:** gravação **com debounce** (arrastar o splitter emite continuamente;
gravar a cada frame vira tempestade de escrita), cancelada no `dispose`; **reclamp** na
restauração (D13); **seções do Inspector lembradas globalmente pelo rótulo do grupo**, não
por tipo de nó (P3 — §9›Q2).

**Aceite (validável — escrito como o print que o prova):**

28. **O refresh:** arrastar a paleta para ~460, colapsar o Inspector, fechar 3 grupos, dar
    **F5**. O print depois é **equivalente** ao de antes.
29. **A navegação, que é o incômodo real:** sair para a tela do projeto pelo breadcrumb e
    reentrar. **Mesmo estado.** _É o relato do PM: "o dev alarga a paleta, sai da tela,
    volta e está tudo como antes." Um aceite só de refresh deixaria de fora o caso que
    dói._
30. **O reclamp (D13):** largura salva em 480, reduzir a janela para 1024, recarregar → o
    painel aparece **estreitado**, e nada some na borda direita.
31. **A corrupção (D12) — a linha mais fácil de escrever e de não cumprir:** gravar lixo em
    `localStorage` na chave `flutter.editor.layout` e recarregar. **O editor abre
    normalmente**, em 280/320, tudo expandido, sem banner. _Reprova se a tela ficar branca,
    der erro, ou ficar carregando._

---

### F7 — Modo tela cheia · **[dep. F5]** · **[sub-agente: especialista-apresentacao + especialista-infra]**

**Arquivos:** `core/widgets/app_shell/app_shell_scope.dart` (o sinal imersivo, com dono por
token) · `app_shell_slot.dart` · `app_shell.dart` (esconde as duas faixas — **o shell
continua sem ler cubit**, regra do item 16c) · `editor_layout_controller.dart`
(`isFullscreen`, em memória, D15) · `canvas_toolbar.dart` (o botão, D16) ·
`editor_shortcuts.dart` + `editor_intents.dart` (`Esc`; atalho opcional e verificado) ·
`status_bar_area.dart` (o rodapé **permanece** com erro — P2).

**Aceite (validável — escrito como o print que o prova):**

32. **Modo ligado:** sem faixa 1, sem faixa 2, sem painéis, mock ocupando a tela — **e o
    controle de sair visível no print**. _Um modo tela cheia sem saída visível é armadilha,
    não feature._
33. **`Esc` devolve o layout intacto:** o print depois do `Esc` bate com o imediatamente
    anterior à entrada — mesmas larguras, mesmos colapsos.
34. **A borda P2 — par de prints, senão não prova nada:** entrar em tela cheia **com um
    erro de diagnóstico no rodapé** → o rodapé **continua visível**; entrar **sem erro** →
    some. _Esconder erro num modo novo reintroduziria o sintoma que o item 38 corrigiu._
35. **O atalho, se houver (D16):** print do modo ligado **logo após teclar, no Chrome real
    em homologação**. _Se o navegador capturar, reprova e o atalho muda._

---

### F8 — E2E manual em homologação, executado e atestado · **[dep. F1–F7]** · **[qa instrumenta · dev humano atesta]**

O QA roda a skill `instrumentar-e2e`: script idempotente e auto-limpante para o que a
máquina alcança, e deixa para o humano o que exige olho e mão — **os dois aparelhos
físicos (F1 e F2), acima de tudo**. Roteiro na §10. Evidências em
`docs/17-ergonomia-editor/evidencias/rodada_MM/`.

**Nenhuma linha de teste automatizado é escrita antes desta fase estar atestada** (cap. 22).

---

### F9 — Bateria automatizada + docs vivas · **[por último]** · **[qa]**

| Alvo | Teste |
| --- | --- |
| `AppBreakpoints` | fronteiras: 599 → compact, 600 → medium, 1023 → medium, 1024 → expanded |
| **`ProjectDetailPage`** | a 360 e 412: **sem barra lateral, com gaveta**; a 1280: **com barra lateral, sem gaveta** |
| **`ContentPanelView`** | a 360: o título renderiza em **uma linha** (`maxLines: 1`) e o `Text` reporta truncamento — **o teste que trava o retorno do texto vertical** |
| **Regressão de overflow** | widget test com `tester.view.physicalSize` em **360, 412, 560, 599, 600, 612, 700, 1024, 1280, 1440**, capturando `FlutterError.onError` — **zero** overflow. _Roda em debug: é a única camada que enxerga o indicador (D22). `editor_perf_test.dart` já tem o helper `enlarge(tester)` como precedente._ |
| Diálogos | a 360: largura do diálogo ≤ largura da tela |
| `fitScaleFor` | 3 presets × viewports de 612, 700, 1024, 1280, 1440; e o caso que exige escala < 0.4 (D9) |
| Breadcrumb | crumb longo em largura restrita → trunca, sem overflow |
| `EditorLayoutModel` (zard) | válido · ausente · corrompido · largura fora dos limites |
| Reclamp (D13) | largura salva maior que a janela → clampada |
| **Gate de rebuild (D8)** | contador de builds: **colapsar não reconstrói `LeftPanel`, `CenterArea` nem `InspectorArea`** — o teste que substitui o print que não existe |
| Paleta | 4 grupos colapsam; busca força abrir e **restaura** ao limpar |
| Tela cheia | `Esc` restaura; rodapé permanece com erro |
| `PreviewCubit` | `bloc_test`: loading → ready; falha → `PreviewFailure` |

Depois: `final_report.md`, `CHANGELOG` (`Unreleased`), `docs/roadmap.md` (item 41 `[x]`),
`docs/plans/README.md`.

---

## 6. Ordem de PRs, precedências e o que fica bloqueado

```
 ┌─ F1 (navegação no celular) ────────────────────────────────────┐
 │                                                                │
 ├─ F2 (rota de preview)  [em execução] ──────────────────────────┤
 │                                                                ├─ F8 (E2E) ─ F9 (bateria)
 ├─ F4 (grupos da paleta) ────────────────────────┐               │
 │                                                ├─ F6 (memória) ┤
 └─ F3 (piso do editor) ─┬─ F5 (colapso) ─────────┘               │
                         └─ F7 (tela cheia) ──────────────────────┘
```

| PR | Fase | Pode começar quando |
| --- | --- | --- |
| 1 | **F1** | **Já** — nada em comum com 38/39, nem com a F2 em voo |
| 2 | F2 | **em execução** |
| 3 | F4 | **Já** — só a paleta |
| 4 | F3 | **Depois do E2E dos itens 38 e 39 atestado** — mexe em `canvas_panel.dart` |
| 5 | F5 | Depois do PR 4 |
| 6 | F7 | Depois do PR 5 |
| 7 | F6 | Depois dos PRs 3 e 5 |
| — | F8 | Depois de 1–7 em homologação |
| 8 | F9 | Depois do atestado humano da F8 |

**Três frentes correm em paralelo hoje: F1, F2 e F4.** Nenhuma compartilha arquivo com
outra — verificado, não presumido:

- **F1** fica em `contents_module`, `projects_module` e `core/theme/app_breakpoints.dart`.
- **F2** fica em `preview/`, `editor_page.dart`, `editor_routes.dart`, `app_router.dart`,
  `core/network/` e `canvas_toolbar.dart`.
- **F4** fica em `widget_palette/`.

**O único ponto de atrito real do plano** é `canvas_toolbar.dart`, tocado pela F2 (botão
do preview), pela F3 (botão de ajustar) e pela F7 (botão de tela cheia). A F2 chega lá
primeiro; **o PR 4 rebase antes de mergear**.

**O que fica bloqueado até a F3 entrar:** a F5 e a F7 — não só por arquivo, mas por
**prova**: sem o ajuste, o ganho de espaço das duas não aparece em print nenhum.

---

## 7. Riscos

**R1 — "Responsividade em geral" não tem critério de pronto.** Mitigado pela separação da
§1: a navegação tem um piso de faixa (D5) e a foto como "antes"; o editor tem um piso
mecânico (D1). Dois critérios objetivos, nenhum "melhorar em geral".

**R2 — Consertar a frente errada.** Era o risco maior antes da §2.1, e virou fato
documentado: o `ResizableSplitView` **não** é usado na tela quebrada. Mitigado por a F1
ser fase própria, com aceite próprio, na foto do aparelho.

**R3 — O preview é uma porta sem tranca.** Não piora o estado atual (o editor inteiro já é
aberto e o backend não tem auth), mas materializa o rascunho num link que sai do laptop.
Aceito (A8). **Entra na tabela de débitos vivos do roadmap quando a F2 mergear.**

**R4 — Perder o `imageUrlResolver` numa tela nova.** Mitigado estruturalmente pela D6 (uma
fábrica, duas páginas) e cobrado por **dois** aceites com print: o 19 (F3) e o 10 (F2).

**R5 — Desfazer o item 3b sem perceber.** O `ValueListenableBuilder` no lugar errado
reconstrói os três painéis a cada clique, **sem sintoma visível**. D8 diz onde ele vai; o
teste de máquina é o único guarda.

**R6 — Aceite improvável no ambiente real.** Foi o que a D22 pegou: metade dos aceites de
overflow da versão anterior deste plano media um indicador que **não existe em release**.
Mitigado pelas três camadas da D22. **Vale como lembrete permanente: antes de escrever
"nenhuma faixa listrada", pergunte em que build ela é pintada.**

**R7 — Conflito com trabalho em voo.** A F2 está em execução; a F1 e a F4 não tocam nada
dela (§6). O item 39 está sendo instrumentado em `docs/16-`, e a F3 está bloqueada até o
atestado. O item 24 planeja mexer em `core/widgets/app_shell/` — a F3 e a F7 mexem lá; como
o 24 não começou, o atrito é futuro.

**R8 — Golden do `canvas_panel` quebra na F3.** Esperado. Regravar é legítimo; **regravar
sem citar o diff visual na descrição do PR reprova**.

**R9 — A F1 crescer além de um PR de relance.** Ela cobre três causas e cinco tarefas. Se
a tarefa 5 (verificação da home e do cartão) revelar quebra estrutural no `ContentCard`,
**o tech-lead parte a F1 em duas no momento do PR** — projeto/categorias/busca numa, cartão
e home noutra — e registra em `variance_report.md`. Está previsto, não é desvio.

---

## 8. Divergências em relação ao recorte do PRD

| # | O PRD dizia | Este plano faz | Por quê |
| --- | --- | --- | --- |
| 1 | 4 fases: overflows+fit · colapso+persistência · paleta+tela cheia · bateria, mais o preview separado | **9 fases** | Ver as linhas abaixo |
| 2 | **O problema é do editor** | **São dois problemas**, e a navegação quebra pior | Evidência de campo de 2026-08-16 (§2.0). A tela mais visitada renderiza texto **uma letra por linha** a 412 px. O `specs.md` não tinha essa informação |
| 3 | Preview como "fatia 2", depois de tudo | **F2, em execução desde cedo** | É a única fase cujo E2E exige **hardware físico e homologação real**; descobrir tarde que o aparelho não abre a rota é o pior lugar para descobrir. E é 0-dep de verdade |
| 4 | Colapso **e** persistência na mesma fase | **F5 e F6 separadas** | A pilha serve **quatro** clientes. Escrita antes de os quatro existirem, seria escrita duas vezes. E colapso sem memória já é fatia vertical utilizável |
| 5 | Tela cheia junto dos grupos da paleta | **F7, própria** | Muda a **API pública do `AppShell`** (`core/widgets/`), preocupação de revisão diferente de mexer na paleta |
| 6 | Preset Tablet precisa de **~863 px** de centro | **~952 px** | O PRD contou só o `bezel`. A `DeviceFrame` soma `bezel * 0.55` de cada lado (botões laterais) e o `CanvasPanel` envolve num padding de 32. §2.3 |
| 7 | "Tokens de breakpoint, só se A1 pedir; o discovery recomenda adiar" | **`AppBreakpoints` nasce na F1** | A D20 deu um cliente: a barra lateral de 272 px não se conserta com `Flexible` — a 412 px ela tem de deixar de ser barra lateral. Isso é faixa, e faixa quer nome (D5) |
| 8 | **"Nunca `RenderFlex overflow`"; "a régua é não existir estado em que o editor mostre faixa listrada"; prova em homologação** | **A faixa listrada não é aceite de homologação** (D22) | `flutter build web --release`: o indicador é pintado dentro de um `assert` e **não existe em release**. O aceite anterior teria passado provando nada — a mesma armadilha do item 39 |
| 9 | "A1 excluiu comportamento por faixa de largura" | **Reaberto, só para a navegação** | D20, decisão do humano de 2026-08-16, com fronteira cobrada por grep (D5›cerca 2) |
| 10 | Analytics em 5 eventos | **Fora** (§12) | Não existe pipeline de analytics no editor hoje |

---

## 9. O que ainda precisa do humano

**As cinco decisões caras estão fechadas** (A6 → D3, A1 → D1, A3 → D2, A7 → D4, e a de
2026-08-16 → D20). Sobraram duas questões pequenas; **nenhuma bloqueia a F1**:

**Q1 — Entra `qr_flutter` no pubspec?** A **única dependência nova** de toda a feature. Sem
QR, alcançar o preview no celular é copiar uma URL com **dois UUIDs** — funciona, e é chato
o bastante para o dev não usar. Sem build_runner, pacote pequeno. **Recomendação: entra.**
É a tarefa 5 da F2, a última, e **cai sem quebrar a fase**.

**Q2 — O colapso das seções do Inspector é lembrado por rótulo de grupo (global) ou por
tipo de nó?** Este plano adota **global por rótulo** (P3: layout é hábito de trabalho, não
atributo do documento) — é o que faz o Inspector parar de reabrir tudo a cada troca de nó,
que é o incômodo concreto. **Veto fácil na revisão da F6.**

---

## 10. Roteiro de E2E manual

**Em homologação** (`https://hml.driva.duckdns.org`), **nunca em localhost** — lição
permanente do item 9g. **Exceção única e declarada: o passo 19** (D22). O que está marcado
**[olho]** ou **[mãos]** é do humano.

> ⚠️ **Três avisos antes de abrir a rodada.**
> 1. **O modo fake mascara a rodada inteira.** Com `USE_FAKE_DATA=true` a fábrica do
>    resolver devolve `null` de propósito (D6) e os passos 12 e 17 ficam sem sentido.
>    Confirme na aba Network que há chamada real à API.
> 2. **Os passos de largura precisam da janela do navegador redimensionada de verdade**,
>    não do emulador de dispositivo do DevTools — e os passos de celular precisam de
>    **aparelho físico**, não de emulador. A foto da §2.0 foi tirada num aparelho.
> 3. **Não procure a faixa listrada em homologação: ela não existe em release** (D22). O
>    que se observa aqui é o **sintoma**; o indicador é o passo 19.

**Preparar:**

| Rótulo | O que | Para quê |
| --- | --- | --- |
| `APARELHO` | Um celular físico (o da foto da §2.0, se possível) | passos 1 a 6, 15 a 18 |
| `CT_LONGO` | Um conteúdo com nome de ~80 caracteres | passo 8 |
| `CT_IMG` | Um conteúdo com um `image` usando a **URL sem ACAO** do item 39 | passos 7, 12, 17 |
| `ANONIMO` | Aba anônima ou aparelho que **nunca abriu o editor** | passo 16 |

**Bloco A — navegação no celular (F1)**

1. **[mãos]** Abrir o projeto no `APARELHO`. **Esperado:** "Todos os conteúdos" em **uma
   linha horizontal**, com reticências se não couber; **sem barra lateral**; botão de
   gaveta no cabeçalho. _(DoD 24, 25)_
2. **[mãos]** Tocar no botão da gaveta. **Esperado:** categorias legíveis, com as
   contagens. _(DoD 25)_
3. **[mãos]** Tocar em "Divulgar". **Esperado:** a gaveta **fecha** e a lista mostra só
   Divulgar. _Par de fotos; gaveta aberta por cima da lista filtrada reprova._ _(DoD 26)_
4. **[mãos]** Tocar na busca e digitar. **Esperado:** hint legível (não `Busc…`), e a lista
   filtra. _(DoD 27)_
5. **[mãos]** "Novo conteúdo". **Esperado:** o diálogo cabe, com os dois botões visíveis,
   **sem rolagem horizontal**. _(DoD 28)_
6. **[mãos]** Home de projetos no `APARELHO`. **Esperado:** cartões legíveis, nada cortado.
   _(DoD 29)_
7. **[olho]** Janela de desktop a **599** e a **601**. **Esperado:** 599 → gaveta; 601 →
   barra lateral. _Dois prints: é o que prova onde a faixa está._ _(DoD 30)_

**Bloco B — piso do editor (F3)**

8. **[olho]** `CT_LONGO` a **1280**. **Esperado:** o último crumb **em uma linha, com
   reticências**. _(DoD 33)_
9. **[olho]** Janela a **700** e a **560**. **Esperado:** botão de overflow na faixa 1 —
   **abra o menu** e confirme "Salvar" e "Publish" dentro; a 560, rolagem horizontal no
   workspace e **nada sumindo na borda direita**. _(DoD 34, 35)_
10. **[olho]** `CT_IMG` numa janela de **1024×720**, preset **Tablet**. **Esperado:** as
    quatro quinas da moldura visíveis e a barra do canvas **abaixo de 40%**. _(DoD 31)_
11. **[olho]** Arrastar a borda da janela de 1440 para ~900 sem tocar em nada.
    **Esperado:** o percentual muda sozinho. Depois: um clique em `+` → toggle "Ajustar"
    **não-selecionado**; clicar em "Ajustar" religa. _(DoD 32)_
12. **[olho]** Ainda em `CT_IMG`: a imagem carrega e a aba Network mostra
    `…/v1/media/proxy?url=…`. _Caixa "falhou" = a F3 perdeu o resolver; pare a rodada._
    _(DoD 36)_

**Bloco C — painéis, paleta, memória e tela cheia (F4 a F7)**

13. **[olho]** Colapsar a paleta; depois o Inspector. **Esperado:** faixas finas com os
    ícones, **o percentual do canvas sobe**, os dois controles de reabrir visíveis. Com a
    paleta colapsada, clicar em **Árvore** reabre **na aba Árvore**. _(DoD 37, 38, 39)_
14. **[olho]** Fechar os 4 grupos da paleta; digitar `col`; limpar. **Esperado:** fechados
    sem rolagem → `Layout` abre com `Column` visível → **volta a fechar**. _Três prints; o
    terceiro é o que prova._ _(DoD 40, 41)_
15. **[olho]** Arrastar a paleta para ~460, colapsar o Inspector, fechar 3 grupos, dar
    **F5**. Depois: sair pelo breadcrumb e reentrar. **Esperado:** tudo como estava nas
    duas vezes. Depois: largura salva em 480, janela para 1024, recarregar → painel
    **estreitado**. Depois: lixo em `localStorage` na chave `flutter.editor.layout` +
    reload → **o editor abre normalmente**, sem banner. _(DoD 42, 43, 44, 45)_
16. **[olho]** Tela cheia pelo botão. **Esperado:** sem faixas, sem painéis, **e o controle
    de sair visível**. `Esc`: volta com as mesmas larguras e colapsos. Repetir **com um
    erro no rodapé**: o rodapé **permanece**; sem erro, some. Se houver atalho: teclá-lo no
    Chrome. _(DoD 46, 47, 48, 49)_

**Bloco D — preview no aparelho (F2)**

17. **[mãos]** Abrir o diálogo de preview e levar a URL ao `ANONIMO`. **Esperado:**
    conteúdo em tela cheia, sem faixa 1, sem breadcrumb, sem painéis, URL visível na barra
    do navegador. Na mesma foto, a `image` de `CT_IMG` **carregada**. _(DoD 50, 51, 52)_
18. **[mãos]** Editar `CT_IMG` no desktop **sem salvar** → tocar na pílula. **Esperado:**
    **nada muda**. Depois **Salvar** → tocar. **Esperado:** muda. E a pílula diz "Último
    salvo". _(DoD 53, 54)_

**Bloco E — a camada do indicador (D22), e a única exceção ao "nunca localhost"**

19. **[olho]** **Em build de debug local** (`flutter run -d chrome --target
    apps/driva_editor/lib/main_dev.dart --dart-define-from-file=apps/driva_editor/config/dev.json`),
    repetir as larguras de borda: **360, 412, 560, 599, 600, 612, 700, 1024, 1280, 1440**,
    na tela de projeto **e** no editor. **Esperado: nenhuma faixa listrada em nenhuma
    delas.** _Este passo roda em localhost **porque o indicador de overflow só existe em
    debug** (D22). Ele **não substitui** os passos 1 a 12: aqueles provam que o usuário não
    vê o defeito; este prova que o defeito não está apenas escondido._

---

## 11. Definition of Done

**O item 41 só está pronto quando todas as linhas abaixo estiverem marcadas.** Cada linha
diz **como se prova** — nada aqui se atesta por opinião.

### 11.1 Cancela de máquina

| # | Item | Como se prova |
| --- | --- | --- |
| 1 | `flutter analyze` verde no workspace | saída do comando, zero issues, no PR |
| 2 | Suíte existente passando (`flutter test -r compact`) em `sdui_core`, `sdui_flutter` e `driva_editor` | saída no PR |
| 3 | **Zero linha em `packages/`** | `git diff --stat origin/develop -- packages/` = vazio, em **todos** os PRs |
| 4 | **Zero linha em `backend/`** | `git diff --stat origin/develop -- backend/` = vazio |
| 5 | Golden do `canvas_panel` regravado **com o diff visual citado na descrição do PR 4** | regravação sem citação **reprova** |
| 6 | **Gate 1** — nenhuma função/método novo que retorna `Widget` fora do permitido | leitura do diff; nenhum `Widget _buildX(` novo |
| 7 | **Gate 4** — nenhum tamanho, duração ou cor cru nos arquivos tocados | `grep` nos arquivos do diff: só tokens |
| 8 | **Gate de rebuild (D8)** — colapsar **não** reconstrói `LeftPanel`, `CenterArea` nem `InspectorArea` | teste de widget com contador de builds (F9). **É de máquina: não existe print que prove isto, e nenhum foi inventado** |
| 9 | **O editor não importa o breakpoint do kernel** (D5›cerca 1) | `grep -rn "SduiBreakpoint" apps/driva_editor/lib` = **zero** |
| 10 | **`AppBreakpoints` não vazou para o editor** (D5›cerca 2, D20) | `grep -rn "AppBreakpoints" apps/driva_editor/lib/modules/editor_module` = **zero** |
| 11 | CI verde em todos os PRs — a mesma régua do humano | checks do GitHub |

### 11.2 Aceite por fase

| # | Item | Como se prova |
| --- | --- | --- |
| 12 | Os **7 critérios da F1** atestados | `revisar-fase` do QA no PR 1 |
| 13 | Os **5 critérios da F2** atestados | `revisar-fase` do QA no PR 2 |
| 14 | Os **7 critérios da F3** atestados | `revisar-fase` do QA no PR 4 |
| 15 | Os **4 critérios da F4** atestados | `revisar-fase` do QA no PR 3 |
| 16 | Os **4 critérios da F5** atestados | `revisar-fase` do QA no PR 5 |
| 17 | Os **4 critérios da F6** atestados | `revisar-fase` do QA no PR 7 |
| 18 | Os **4 critérios da F7** atestados | `revisar-fase` do QA no PR 6 |
| 19 | Nenhum desvio das decisões **D1–D22** sem `variance_report.md` aprovado **pelo humano** | desvios numerados `VR-17-NN`, com "como estava / por que mudou / o que mudou" |

### 11.3 E2E — **faz parte do DoD, não é apêndice**

**A feature não está pronta enquanto o roteiro da §10 não tiver sido executado e atestado
pelo dev humano.**

| # | Item | Como se prova |
| --- | --- | --- |
| 20 | O roteiro da §10 executado **em homologação** — com a exceção única e declarada do passo 19 (D22) | a URL do ambiente aparece nos prints; o passo 19 aparece rotulado como debug local |
| 21 | A rodada correu **contra o backend real**, não em modo fake | a aba Network mostra chamada a `hml`. Em modo fake o resolver é `null` de propósito (D6) e **os passos 12 e 17 ficam mascarados** |
| 22 | Os passos de celular correram em **aparelho físico**, não em emulador | as fotos são de aparelho, como a da §2.0 |
| 23 | **QA instrumenta** o que der (skill `instrumentar-e2e`); o que exige olho e mão fica para o humano | scripts em `docs/17-ergonomia-editor/`, copiados para dentro da rodada |
| 24 | **O dev humano confere os prints e atesta.** Ninguém mais atesta E2E | atestado escrito no `final_report.md`, com data |
| 25 | A foto de campo da §2.0 arquivada em `evidencias/rodada_00/00_evidencia_campo_android.jpg` **antes** da F1 mergear | o arquivo existe. _É o "antes" dos itens 24 a 29; sem ele, o "depois" não tem comparação_ |
| 26 | Evidência da rodada em **`evidencias/rodada_MM/`**, prints nomeados `<NN>_<descricao>.png` pelo número deste DoD | a pasta existe e tem os prints |
| 27 | E2E reprovado → o tech-lead conserta e o QA abre **`rodada_MM+1`**; a anterior **não é apagada** | histórico de rodadas |

### 11.4 A matriz que prova o que a feature promete — **não o caminho feliz**

Esta feature corrige **falhas que hoje não avisam**: o texto que desce letra por letra sem
erro nenhum no console, o mock cortado sem mensagem, o layout que se perde sem aviso, a
imagem que some em silêncio. Um E2E que só percorra o caminho feliz **não prova nada
aqui**. Cada linha é um par ou trio de prints em que os estados têm de ser **visualmente
distintos**.

| # | O que a feature promete | Print exigido | Reprova se |
| --- | --- | --- | --- |
| 28 | O título não desce letra por letra | foto do aparelho: **uma linha horizontal**, com reticências se não couber — pareada com `rodada_00` | qualquer texto vertical, **ou** o "antes" não existir para comparar |
| 29 | As categorias não comem a tela | foto sem barra lateral + foto da gaveta aberta | a barra lateral aparecer em `compact` |
| 30 | A gaveta fecha ao selecionar | par: toque em "Divulgar" → gaveta fechada **e** lista filtrada | a gaveta ficar aberta sobre a lista |
| 31 | A busca é usável no celular | foto do campo com hint legível e texto digitado | `Busc…` |
| 32 | Criar conteúdo cabe (Causa C) | diálogo com os dois botões visíveis, sem rolagem horizontal | qualquer botão fora da tela |
| 33 | A home de projetos funciona no celular | foto com cartões legíveis | conteúdo de cartão cortado |
| 34 | A faixa existe e está em 600 (D5) | par: 599 → gaveta; 601 → barra lateral | os dois estados forem iguais |
| 35 | **O editor não foi "aproveitado" pela faixa** (D20) | prova de máquina, DoD 10 | qualquer `AppBreakpoints` em `editor_module` |
| 36 | O mock cabe na janela | Tablet a 1024×720, **quatro quinas visíveis**, barra **abaixo de 40%** | a moldura sair da área, **ou** a barra travar em 40% — a escala passou pelo clamp (D9) |
| 37 | O ajuste é reativo | dois prints, 1440 → ~900, sem tocar em nada: percentuais diferentes | percentuais iguais |
| 38 | Manual vence o ajuste (P5) | toggle **selecionado** × **não-selecionado**, percentuais diferentes | os dois estados forem visualmente iguais |
| 39 | O breadcrumb trunca | `CT_LONGO` a 1280, uma linha com reticências | duas linhas, ou texto cortado na borda |
| 40 | A faixa 1 não engole ação | print **com o menu de overflow aberto**, mostrando "Salvar" e "Publish" | só o `⋮` aparecer: um menu vazio passaria e reprovaria na prática |
| 41 | O workspace estreito degrada em vez de sumir | a 560: rolagem horizontal, **nada sumindo na borda direita** | conteúdo cortado sem rolagem |
| 42 | **Não há overflow escondido** (D22) | passo 19, **em debug local**: nenhuma faixa listrada em 360, 412, 560, 599, 600, 612, 700, 1024, 1280, 1440 | qualquer faixa. _E se este item for "provado" com print de homologação, **reprova por construção**: lá a faixa não existe_ |
| 43 | Painel do editor colapsado continua alcançável (D2) | faixa fina com o controle de reabrir **dentro dela** | o único caminho de volta for atalho ou menu escondido |
| 44 | Colapsar dá espaço **ao mock** | par com o **percentual do canvas subindo** | o percentual não mudar — o espaço virou fundo cinza |
| 45 | Buscar com grupos fechados acha | trio: fechados → `col` abre `Layout` → limpar **fecha de novo** | o terceiro print não voltar ao estado do primeiro |
| 46 | O layout sobrevive ao **refresh** | antes/depois de `F5` | qualquer diferença |
| 47 | O layout sobrevive à **navegação** | antes/depois de sair pelo breadcrumb e voltar | qualquer diferença. _É o incômodo relatado; o refresh sozinho não cobre_ |
| 48 | Largura salva é reclampada (D13) | 480 salvo, janela em 1024, após recarregar | painel maior que a janela |
| 49 | Preferência corrompida **não bloqueia** (D12) | lixo em `flutter.editor.layout` + reload → editor abre em 280/320 | tela branca, erro, ou carregando eterno |
| 50 | O preview abre **frio** no aparelho (D18) | foto de celular que **nunca abriu o editor**, URL visível | 404, ou só funcionar depois de passar pela tela do projeto |
| 51 | O preview **não perde o resolver** (D6 / I1) | na mesma foto, a `image` sem ACAO **carregada** | caixa "falhou" — é a regressão exata do item 39 |
| 52 | O preview mostra o **último salvo** (D4) | par: editar sem salvar → pílula → **não muda**; salvar → pílula → **muda** | o primeiro par mudar |
| 53 | Tela cheia tem saída visível | print do modo ligado **com o controle de sair** | nenhum controle visível |
| 54 | Tela cheia **não esconde erro** (P2) | par: com erro → rodapé fica; sem erro → some | o rodapé sumir com erro. _Reintroduziria o sintoma que o item 38 corrigiu_ |
| 55 | O atalho, se houver, **chega ao app** (D16) | print do modo ligado logo após teclar, **no Chrome real** | o navegador capturar. _Lição do `Ctrl+Shift+W`: o `SingleActivator` no mapa não prova nada_ |

**Os itens 28, 42, 51 e 54 são a cancela.** Se o texto ainda desce letra por letra, se há
overflow escondido atrás do release, se a imagem voltou a falhar em silêncio, ou se a tela
cheia esconde erro, nada mais no DoD importa.

### 11.5 Fechamento

| # | Item | Como se prova |
| --- | --- | --- |
| 56 | **Bateria automatizada (F9) escrita DEPOIS do E2E atestado**, nunca antes | o PR 8 é posterior em data ao atestado do item 24 |
| 57 | Gate do CISO onde o agente for acionado | registro do agente `ciso`. _Nenhuma fase o exige por construção (D3), mas o registro de "não se aplica, e por quê" fica_ |
| 58 | `CHANGELOG` `Unreleased` atualizado **no mesmo PR** de cada mudança | o diff do PR contém o CHANGELOG |
| 59 | Se a Q1 for aprovada, `qr_flutter` documentado como dependência nova na descrição do PR 2 | o PR cita a dependência e o porquê |
| 60 | Docs vivas: `final_report.md` ao fechar; `variance_report.md` no primeiro desvio (`VR-17-01`) | os arquivos existem |
| 61 | `docs/roadmap.md` — o item **41** entra no Marco 4 e vira `[x]`; o débito do R3 entra na tabela de débitos vivos | as linhas marcadas |
| 62 | `docs/plans/README.md` atualizado com a doc viva do 41 | o índice |

---

## 12. Fora de escopo — evoluções registradas

- **Editar SDUI no celular** — arrastar widget num telefone é outro modelo de interação e
  outro produto. **D20 decidiu explicitamente que o editor mira desktop.** A resposta para
  "ver no celular" é a rota `/preview` (F2).
- **Item 30** — variação do spec por breakpoint. Nome parecido, problema outro. O
  `AppBreakpoints` da F1 usa os **mesmos números** e **não** importa o enum do kernel (D5).
- **Item 24** — publicação e versionamento. Este item **não** constrói sobre a rota pública
  servindo rascunho (D3).
- **Item 26** — auth. A URL de preview aberta é dívida registrada (R3), não resolvida.
- **Item 28** — eventos e ações. Preview **interativo** depende dele (D17).
- **Preview ao vivo** (autosave + polling, ou SSE/WebSocket) — +2 a +3 fases, num backend
  sem bateria de teste (item 40). A D4 fecha em "último salvo".
- **Rotação (paisagem) do mock** — a moldura posiciona botões por fração da altura e o
  recorte da câmera assume o topo. Item próprio.
- **Presets de dispositivo além dos três.**
- **Faixa `medium`/`expanded` com layout próprio na navegação** — a F1 usa **só** a
  fronteira `compact` (600). As outras duas ficam definidas em `AppBreakpoints` para o
  vocabulário nascer inteiro, mas **sem cliente** nesta fatia.
- **"Dobrar seções" do painel JSON** — é o item **8b**, terceiro cliente do colapso (I5). A
  F4 desenha sabendo dele, **sem** juntar os itens.
- **Promover o colapso (paleta / Inspector / JSON) para `core/widgets/`** — a unificação só
  se paga com os três clientes no ar. I4 proíbe agora.
- **Analytics** — os cinco eventos do PRD não entram: **não existe pipeline de analytics no
  editor hoje**. Registrado para quando existir; o `editor_viewport_width_bucket` é o que
  diria em que larguras o editor é realmente usado.
