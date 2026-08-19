# Specs — Chrome da página: barra de topo (appBar) e barra do sistema

**Item:** 43 (reescopado — absorve o pedido novo de 2026-08-17)
**Discovery:** 2026-08-17, PM
**Origem:** uso real — APK release do `apps/driva_demo_app` contra homologação, em Android físico
**Status:** discovery aberto — **nenhuma fase começa antes de as ambiguidades fecharem**

> **Procedência: auditada pelo `tech-lead` em 2026-08-17.** O levantamento
> original foi feito pelo PM; um tech-lead conferiu depois **cada afirmação
> técnica contra o código**, incluindo o SDK do projeto. O §3 (os
> três consumidores) e a A2 foram validados e **corrigidos** — a A2 estava
> apoiada em duas premissas falsas sobre a `AppBar`, e a recomendação sobrevive
> por outras razões, agora escritas. As correções estão no texto, com ponteiro.
>
> ⚠️ **A versão do Flutter importa, e é fonte de erro já cometido.** Todo ponteiro
> para dentro do SDK neste documento é **Flutter 3.44.9** — a versão que o projeto
> declara (`.puro.json` → `{"env": "3.44.9"}`) e que a CI fixa
> (`.github/workflows/ci.yml:41`). O `default` do puro na máquina do dev aponta
> para **3.38.6**, então um `flutter` cru no `PATH` resolve para a versão errada:
> a primeira rodada desta auditoria conferiu tudo contra a 3.38.6 e **todos os
> números de linha do SDK saíram errados** (o comportamento não divergiu; a
> numeração, sim). Ao conferir qualquer ponteiro daqui, use
> `~/.puro/envs/3.44.9/flutter/`.
>
> **Três achados da auditoria mudam o recorte, e o `plan.md` depende deles:**
> 1. **A casca do app de demonstração não foi removida em `develop`** — ainda
>    está lá (`content_page.dart:34-48`), e o `content_meta_bar.dart` também. A
>    remoção existe só na branch parada `parked/demo-app-internet-e-casca`, e
>    estava alocada à fatia 2 do item 25. O §"De onde veio" foi reescrito, e isso
>    abriu a **A14** — **decidida pelo humano em 2026-08-17**: a tela de conteúdo
>    passa a ser deste item e vira a **F0**.
> 2. **A pílula "último salvo" do `/preview` fica no rodapé**, não no topo
>    (`preview_content.dart:72-75`) — só o banner de falha colide com a barra.
> 3. **A `AppBar` é composável fora do `Scaffold`**, e sozinha já traz o
>    `AnnotatedRegion` e o botão de voltar. O que ela perde fora do `Scaffold` é
>    outra coisa — ver a A2 reescrita.
>
> **Estado das decisões.** A **A14 está decidida** (humano, 2026-08-17 — a que
> destravava as outras). Seguem abertas as onze ambiguidades originais e a **A12**
> (ordem em relação ao E2E do item 41); a A13 saiu da mesa e virou a restrição
> **R1**, porque não tinha alternativa a escolher. Das abertas, as que mudam o
> recorte são a **A2** e a **A12**.

---

## O pedido, nas palavras dele

> "precisamos de fidelidade entre o construtor web e o app. talvez a gente
> esteja precisando de um componente de appbar no catálogo de widgets"

O pedido tem duas metades e só uma está no texto. A metade explícita é **a barra
de topo**. A metade implícita — e que é a razão de o pedido existir — é
**fidelidade**: o que o dev monta no editor tem que ser o que aparece no
aparelho. A appBar é o sintoma; a fidelidade é o requisito.

## De onde veio: o aparelho físico

O dev gerou um APK release do app de demonstração apontado para homologação e
abriu um conteúdo publicado real num Android físico. O que ele viu não era o que
ele tinha montado. O app desenhava **casca própria**:

- uma `AppBar` do `Scaffold` com título e botão de recarregar, e
- um rodapé de debug com a data do spec e o `etag`.

Nada disso vem do spec. Era chrome do app de demonstração, escrito quando ele
era só um provador de conceito do renderer — e que passou a mentir no instante
em que virou o instrumento de conferir fidelidade.

**A casca continua no ar — corrigido pela auditoria do tech-lead (2026-08-17).**
O discovery original afirmava que ela "já foi removida nesta sessão". Não foi, em
`develop`:

- `apps/driva_demo_app/lib/modules/published_module/presentation/content/page/content_page.dart:34-48`
  ainda monta `Scaffold(appBar: AppBar(title: Text(slug), actions: [IconButton
  recarregar]), body: ContentBody(), bottomNavigationBar: ContentMetaBar())`;
- `.../content/view/content_meta_bar.dart` **não foi apagado**;
- e há uma **segunda** `AppBar` própria do app de demonstração, na tela de
  catálogo (`.../catalog/page/catalog_page.dart:37`) — essa é chrome legítimo de
  uma tela que **não** é a do conteúdo, e pode ficar.

A remoção existe apenas na branch parada `parked/demo-app-internet-e-casca`, e o
tech-manager decidiu em 2026-08-17 que ela **entra na fatia 2 do item 25**, não
antes. Ou seja: a mentira que originou o pedido **ainda está de pé**, e a lacuna
que ela esconde é a mesma.

A lacuna, dita sem depender da remoção: o spec **não tem como pedir uma barra de
topo**. O conteúdo que o dev testou tem `safeArea: {"top": false, "enabled":
true}` — foi construído de propósito para desenhar sob a barra de status, o que
torna a lacuna visível: sem appBar no spec, quem quisesse uma barra teria que
desenhá-la à mão com um `container` + `text`, sem elevação ao rolar, sem
coordenação com a área segura e sem integração com a barra do sistema.

**Consequência de plano — resolvida pela A14 (humano, 2026-08-17).** A promessa
nº 4 do PRD ("o app de demonstração não desenha nada que não venha do spec") não
seria entregável por este item enquanto a tela de conteúdo pertencesse ao item
25. O humano moveu essa tela para cá: ela vira a **F0**, e a promessa passa a ser
deste item. Ver **A14** para a fronteira exata.

---

## Estado atual, levantado no código (2026-08-17)

Tudo abaixo é **fato verificado**, com caminho.

### 1. O precedente existe e é exatamente esta classe de problema — o item 8f

`SafeArea` **não** virou widget do catálogo. Virou **chrome da página**, e a
razão está escrita no próprio código:

`packages/sdui_core/lib/src/catalog/safe_area_descriptor.dart`

> "Chrome da página, não um nó do documento: fica **fora** do `widgetCatalog`
> de propósito. Toda página é embrulhada por uma área segura, então ela não
> aparece na paleta, não entra na árvore e não pode ser selecionada — o
> Inspector edita estas props quando nenhum widget está selecionado."

O padrão, ponta a ponta, é de cinco peças:

| Peça | Arquivo | O que faz |
| --- | --- | --- |
| Descriptor fora do catálogo | `packages/sdui_core/lib/src/catalog/safe_area_descriptor.dart` | `safeAreaDescriptor` — mesmos `PropField` de um widget normal (7 delas, todas `isBindable: false`), mas `parseNode` recusa `type: "safeArea"` |
| Campo na entidade | `packages/sdui_core/lib/src/model/content_spec.dart` | `final Map<String, dynamic> safeArea` (default `const {}`) — **mapa cru de props**, igual a `SduiNode.properties`; no `copyWith`, no `toJson` (omitido quando vazio) e na igualdade |
| Validação | `packages/sdui_core/lib/src/schema/content_schema.dart` | **fora** do envelope zard: lê `json['safeArea']` cru, só checa `is! Map`; ausente → `const {}`. **Nenhuma chave interna é validada** — a resolução de default é do renderer, via descriptor |
| Renderer | `packages/sdui_flutter/lib/src/layout/sdui_safe_area.dart` + `sdui_view.dart` | `_flag(key)` cai em `safeAreaDescriptor.defaultValueOf(key)` quando a chave falta |
| Editor (tudo em `apps/driva_editor/lib/modules/editor_module/presentation/`) | `editor/page/inspector_area.dart:40` (ramo sem seleção, `onUpdateSafeAreaProps`), `editor/cubit/editor_cubit.dart:456` (`updateSafeAreaProps`) e `:464` (o `coalesceKey: 'safeArea:...'` que faz o undo agrupar), `editor/page/inspector_vm.dart` (o campo `safeArea` do VM, `inspector_area.dart:26`), `editor/widgets/widget_tree/page_tree_row.dart:50` (a linha "Página · área segura") | `InspectorPropList` deixou de depender de `SduiNode` — recebe `ownerKey` + `properties` + `descriptor` + `onUpdateProps` (`editor/widgets/inspector/inspector_prop_list.dart:15-18`), então **serve nó e página com o mesmo código** |

**Backend: zero trabalho.** `backend/src/contents/contents.service.ts:183` é a
**única** linha que olha dentro do spec, e só compara `spec['specVersion']`;
`safeArea` nunca é citado — o JSONB passa reto. Vale igual para `appBar`.

**Consequência de custo:** a máquina de editar chrome de página **já existe e é
genérica**.

### 2. O que o `SduiView` monta hoje

`packages/sdui_flutter/lib/src/sdui_view.dart` — 71 linhas, o arquivo inteiro é
o contrato. O trecho abaixo está **elidido** (o `SduiRenderer` é construído em
`:59-65`, com `registry`, `onAction`, `nodeWrapper`, `showDiagnostics` e
`imageUrlResolver`); a forma do `build` é fiel:

```dart
Widget build(BuildContext context) {
  final root = node;
  if (root == null) return const SizedBox.shrink();   // não aplica nem safeArea
  final rendered = renderer.render(context, root);
  final pageChrome = safeArea;
  if (pageChrome == null) return rendered;
  return SduiSafeArea(properties: pageChrome, child: rendered);
}
```

- `SduiView.content(spec)` passa `spec.root` e `spec.safeArea`; o construtor cru
  `SduiView(node:)` **não** recebe chrome (`safeArea: null` = "nó solto").
- **Não há `Scaffold` em lugar nenhum do `sdui_flutter`.** O `Scaffold` é sempre
  do consumidor. O arquivo importa `package:flutter/widgets.dart`, não
  `material.dart`.

### 3. Os três consumidores — e onde está o custo de verdade

São **exatamente três** em produção — conferido varrendo todos os usos de
`SduiView` no repo. O módulo do editor é **`editor_module`**, não `pages_module`
(o discovery original abreviava o caminho e o encobria).

| # | Onde | Como embrulha |
| --- | --- | --- |
| 1 | `apps/driva_demo_app/lib/modules/published_module/presentation/content/view/rendered_content_view.dart:19` | dentro do `Scaffold(body:)` do app; **sem scroll próprio** |
| 2 | `apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/canvas/preview_surface.dart:103-138` (`SduiView.content` em `:108`) | `GestureDetector` > **`SingleChildScrollView`** > `SduiView.content` |
| 3 | `apps/driva_editor/lib/modules/editor_module/presentation/preview/widgets/preview_content.dart:35-53` (`SduiView.content` em `:49`) | `Stack` > **`Positioned.fill`** > `ScrollConfiguration` > `RefreshIndicator` > `LayoutBuilder` > **`SingleChildScrollView`** > `ConstrainedBox(minHeight:)` > `SduiView.content` |

Há ainda um **quarto ponto de entrada, hoje inerte**:
`packages/sdui_flutter/lib/src/driva_content.dart:10-14` — o `DrivaContent(slug:)`
do SDK é um stub que lança `UnimplementedError` mandando usar
`SduiView.content(spec)`. Não é consumidor hoje, mas é **o arquivo onde a
sub-pergunta da A2 (contrato do SDK) vai aterrissar** quando o item 25 o
implementar. Registrar aqui evita que a decisão se perca.

**O custo não é `Scaffold` aninhado** — isso o Flutter tolera. **É o scroll.** Em
dois dos três consumidores a rolagem fica **fora** do `SduiView`, o que entrega
altura infinita para dentro dele. Tanto um `Scaffold` quanto um
`Column`+`Expanded` estouram nessa condição.

**A auditoria confirma o diagnóstico e derruba metade do risco.** Nos dois
consumidores do editor, a caixa **externa** ao `SingleChildScrollView` já tem
altura limitada — o canvas recebe a dele do `Positioned.fill` da moldura
(`device_frame.dart:104-117`) e o `/preview` do próprio `Positioned.fill` +
`LayoutBuilder` (`preview_content.dart:37,42-48`). Migrar a rolagem para dentro é
mover o `SingleChildScrollView` um nível abaixo, **não** inventar uma restrição de
altura que não existe. É trabalho, não pesquisa.

**E o consumidor 1 tem um defeito não catalogado que esta feature conserta de
carona:** o app de demonstração **não rola de jeito nenhum** hoje
(`rendered_content_view.dart:19` dentro de `Scaffold(body:)`, sem scroll em lugar
nenhum) — conteúdo mais alto que a tela estoura. Vale virar aceite da fase do
renderer, senão a correção passa despercebida e ninguém a prova.

**Portanto, escolha o que escolher, a barra de topo obriga a rolagem a migrar
para dentro do `SduiView.content` nos três consumidores.** Esse é o maior custo
da feature, e ele **não some** trocando `Scaffold` por `Column` — ver **A2**.

**Desenho proposto (PM) para cobrir os três sem ramificar:**
`SduiView.content` vira a página (`Scaffold(appBar:, body: <scroll>)`) e ganha um
parâmetro opcional `Widget Function(BuildContext, Widget scrollable)? bodyWrapper`
— o demo app passa `null`, o `/preview` embrulha em
`ScrollConfiguration + RefreshIndicator`, o canvas embrulha no `GestureDetector`.

**Três curto-circuitos escondem a barra numa página vazia** (`root == null`) e
todos precisam ser revistos, senão o editor mente:
`sdui_view.dart:58` (`SizedBox.shrink()`), `rendered_content_view.dart:16`
(`EmptyRootView`) e `preview_surface.dart:106` (`EmptyPreview`).

### 4. O que cada consumidor herda, e o que dá trabalho

- **App de demonstração — herda de graça.** Só precisa parar de montar o
  `Scaffold` externo e não curto-circuitar o `EmptyRootView`.
- **Device mock do canvas — herda de graça, e com sinergia.** Confirmado com
  ponteiro: `device_frame.dart:104-117` injeta `device.safeAreaPadding` em
  `padding` e `viewPadding` de um `MediaQuery`, então o `Scaffold` do renderer
  consumiria o recuo igual ao aparelho. E `device_status_bar.dart:9-10` **foi
  escrito para não pintar fundo** ("desenha só os ícones sobre o que já está
  atrás… (item 43)" — o comentário nomeia este item), sendo montado como
  **overlay** por cima do conteúdo (`device_frame.dart:118-125`,
  `Positioned(top: 0)` + `IgnorePointer`). Os ícones do sistema aparecem sobre a
  cor da appBar sem mudança nenhuma. **Isto é entrega da F3 do item 41 (PR #153,
  mergeada)** — ver os Riscos herdados.
- **`/preview` — tem trabalho próprio, e ele é menor do que o discovery dizia.**
  Só o **banner de falha** é `Positioned(top: AppSpacing.s16)`
  (`preview_content.dart:59-71`) e ficaria atrás da appBar. A pílula "último
  salvo" está no **rodapé** (`preview_content.dart:72-79`,
  `Positioned(bottom: AppSpacing.s16)`) e **não colide com a barra** — a
  afirmação original de que as duas estavam no topo era falsa. Resta o
  `ConstrainedBox(minHeight: constraints.maxHeight)` (`:45-48`), que precisa
  descontar a altura da barra.

### 5. O que o catálogo já sabe editar — e o que não sabe

`packages/sdui_core/lib/src/catalog/field_kind.dart`:

```
string · doubleNum · intNum · dimension · boolean · color ·
enumeration · edgeInsets · alignment · iconName
```

Os dez são exatamente estes — conferido, nem um a mais.

Cor no spec é **string `#RRGGBB` ou `#AARRGGBB`**, parseada por `parseColor`
(`packages/sdui_flutter/lib/src/parsing/parsers.dart:9`), e editada pelo
`editor/widgets/prop_field/color_editor.dart` (`flex_color_picker` em `:7`, **8
swatches** em `:28-37`, campo hex em `:45-47,75-77`). O item 44 acabou de
consertar o título vazando do modal (`roadmap.md:196`, `[x]` em 2026-08-17):
**o seletor de cor está saudável, é reuso puro.**

**Logo, todas as props candidatas do v1 são de tipos que o Inspector já desenha
— custo de editor: zero widget novo.**

**A exceção é `actions`**, e ela tem **dois** bloqueios, não um:

1. **Não existe kind de lista.** Os 10 `FieldKind` são escalares ou objeto fixo;
   todo o Inspector é `chave → valor` num mapa plano agrupado por `field.group`.
   Um editor de array-de-objetos é widget novo do zero.
2. **O editor não sabe autorar evento nenhum.** `grep -rn "events" apps/driva_editor/lib`
   → **zero ocorrências** (confirmado, e zero também sem distinguir maiúsculas). A
   palavra só existe no kernel: `sdui_core/lib/src/model/sdui_node.dart:10,19,30,38,49,61`
   e `schema/node_schema.dart:8,37,39,109`. `SduiAction` existe
   (`sdui_core/lib/src/model/sdui_action.dart:3`) e o renderer despacha via
   `onAction` (`sdui_flutter/lib/src/renderer.dart:10,28,61-65`), mas a autoria é o
   **item 28**. E há um detalhe estrutural: o plano do 28 põe as ações em
   **`SduiNode.events`** (`docs/plans/28-eventos-acoes/plan.md:35,97,109`) — e a
   appBar como chrome **não é um `SduiNode`**, logo não tem onde pendurar evento sem
   inventar um formato paralelo que o 28 teria que unificar depois.

### 6. A retrocompatibilidade tem um jeito certo e um jeito que quebra tudo

`content_schema.dart:48` faz `?? const {}` e `content_spec.dart:13` tem
`this.safeArea = const {}`. Para o `safeArea` isso está certo: **mapa vazio
significa "tudo no padrão"**, e o padrão do descriptor é `enabled: true`
(`safe_area_descriptor.dart:24`), resolvido no renderer por
`sdui_safe_area.dart:19-22` (`_flag` cai em `safeAreaDescriptor.defaultValueOf`).
Ausência = área segura ligada, que é o que se quer.

**Clonar isso com um `enabled: true` daria barra em tudo.** Todo conteúdo já
publicado ganharia uma barra de topo que ninguém pediu, na primeira vez que o app
cliente atualizasse o renderer — regressão visual silenciosa em produção.

**O jeito certo mantém o padrão do 8f intacto e inverte um único valor:** o
`appBarDescriptor` tem um `enabled` **com `defaultValue: false`**. Então:

```
appBar ausente  → {}  → enabled cai no default false → sem barra   ✅ todo conteúdo de hoje
appBar {}       → idem
appBar {"enabled": true, ...}                        → com barra
appBar {"enabled": false, "title": "..."}            → sem barra, props preservadas
```

Isso é melhor do que tornar o campo anulável (a outra saída possível): com o
`enabled`, desligar a barra no Inspector **não apaga** o título e as cores que o
usuário já configurou — ele religa e está tudo lá. É também exatamente a forma
que o `safeAreaDescriptor.enabled` já tem, então o Inspector, o `copyWith`, o
`toJson` e o undo não precisam de caso especial nenhum.

### 7. Nada disso existe hoje

Zero ocorrência de `AppBar`, `Scaffold`, `SystemUiOverlayStyle`,
`statusBarIconBrightness` ou `AnnotatedRegion` em `packages/sdui_core/lib` e
`packages/sdui_flutter/lib` — **confirmado, os cinco em zero.** (Há `Scaffold` só
nos testes do renderer, o que é normal: teste precisa de host.)

**Corrigido pela auditoria — "a única `AppBar` do repo é a do editor" é falso nos
dois sentidos:**

- As `AppBar` de verdade do repo estão no **app de demonstração**:
  `content_page.dart:35` (a casca que originou o pedido) e `catalog_page.dart:37`
  (a tela de catálogo, chrome legítimo).
- O shell do editor (item 16c, `core/widgets/app_shell/`) **não usa `AppBar`
  nenhuma** — é chassi próprio de `Row`/`Column`. O que existe lá é o *tipo de
  dado* `AppBarAction` (`core/widgets/app_shell/app_bar_action.dart:9`, com o
  enum `AppBarActionKind` em `:3`).

**A colisão a vigiar, portanto, não é com um widget — é com o nome
`AppBarAction`/`AppBarActionKind` do editor.** O widget do renderer não pode se
chamar `AppBar` (colide com o Material), e o descriptor não deve reusar esses
nomes de tipo, que já querem dizer outra coisa neste repo.

---

## A decisão de fundo: appBar é chrome, não nó do catálogo

O pedido do dev sugere "um componente de appbar no catálogo". **A recomendação é
não fazer assim** — mas a razão que o discovery original deu estava errada, e a
auditoria a substituiu.

> **Corrigido.** O texto anterior afirmava: *"`AppBar` não é um widget composável:
> é o slot `appBar:` do `Scaffold`"*, e que fora do `Scaffold` ela perde o botão
> de voltar (`Navigator.canPop`). **Falso, verificado no Flutter 3.44.9:**
> `AppBar` é um `StatefulWidget implements PreferredSizeWidget`
> (`app_bar.dart:189`), sem `assert` de `Scaffold` em ponto nenhum do `build`; ela
> usa `Scaffold.maybeOf` (`app_bar.dart:831,912`) e o resultado nulo é tolerado
> (`scaffold?.hasDrawer ?? false`, `:921`). O botão de voltar vem de
> `ModalRoute.of(context)?.impliesAppBarDismissal` (`app_bar.dart:1013`, getter em
> `widgets/routes.dart:2256-2258`) — **não** do `Scaffold` e **não** de
> `Navigator.canPop`. Uma `AppBar` dentro de uma `Column` desenha o botão de
> voltar normalmente.

**Onde isso deixa o argumento.** "Precisa de `Scaffold`" **não** é razão para
manter a appBar fora do catálogo — ela funciona composta. A razão é a de sempre,
e é a de posição: um nó arrastável não tem como impedir duas barras, ou uma barra
no meio da árvore. Isso vale independentemente de `Scaffold`.

O que a `AppBar` de fato perde fora de um `Scaffold` é assunto da **A2** (quem
monta o `Scaffold`), não da A1 — e lá a lista está verificada, com a retratação
de duas razões que eu mesmo tinha escrito errado.

Como nó do catálogo, ela seria arrastável para qualquer lugar. Nada impediria:

- uma appBar **dentro de uma `Row`**, espremida ao lado de um botão;
- **duas** appBars na mesma página;
- uma appBar **no meio** da árvore, com conteúdo acima dela;
- uma appBar como **raiz** (o item 8c permite qualquer widget como raiz).

Cada um desses casos é um documento válido pelo schema e sem sentido na tela. A
alternativa seria escrever regra de posição só para ela — que é o que o
`diagnoseTree` já faz para `expanded`/`spacer`
(`packages/sdui_core/lib/src/diagnostics/diagnose_ops.dart:14`, com
`_flexOnlyTypes` em `:9,28-41`).

> **Corrigido.** O discovery dizia que o `diagnoseTree` faz isso "de forma
> custosa". **Falso:** é varredura recursiva O(n) de passada única, e o único
> chamador de produção é `preview_surface.dart:58` — no `initState` e no handler
> de mudança de documento, atrás de um throttle (`preview_surface.dart:49-50,
> 68-70`), **não por frame**. Também não é uma regra só: há uma segunda,
> `_wrapperTypes` (`diagnose_ops.dart:12,43-53`), para slot único vazio.

**O custo real da opção "catálogo" é conceitual, não de CPU:** cada exceção de
posição é uma regra que a paleta, o drop, o `diagnoseTree` e o inspector precisam
conhecer e manter em acordo — e ela mente para o usuário, que arrasta um item que
o editor depois recusa. É o mesmo preço do `expanded`/`spacer`, pago de novo.

O repo já resolveu essa mesma classe de problema uma vez, no item 8f, e a
solução tem nome e lugar: **chrome da página**. Ver **A1**.

---

## A fusão com o item 43 — **já executada**

> **Corrigido pela auditoria.** Esta seção foi escrita como proposta, quando o
> discovery ainda tramitava como um item novo. A fusão **já aconteceu**:
> `docs/roadmap.md:63` já traz o item 43 com o texto reescopado ("Chrome da
> página: barra de topo (appBar) e barra do sistema", reescopado em 2026-08-17),
> `[ ]`, e **já aponta para `docs/43-chrome-da-pagina/`**, que existe. O que segue
> abaixo é o **registro da razão**, não uma decisão pendente. Segue valendo que
> **não há plano de gaveta** para o 43 em `docs/plans/`.

O item 43 original — **"Estilo da barra do sistema como chrome da página"**,
pedido do humano em 2026-08-16 — prometia a mesma coisa, na mesma camada:

> "o estilo vira **dado do spec**, ao lado do `safeArea` (mesmo lugar, mesma
> natureza de chrome, editado pelo Inspector quando nenhum nó está selecionado)
> [...] Toca **três camadas**: `sdui_core` (descriptor + schema), `sdui_flutter`
> (`AnnotatedRegion` no `SduiView`) e o editor (Inspector + o desenho no mock)."

E já carrega uma pendência de formato explícita:

> ⚠️ "refinar o formato da prop (um `systemBars` próprio ou campos dentro do
> `safeArea`) no discovery."

**São o mesmo trabalho**, por três razões — a terceira é a decisiva:

1. **Mesmíssimo mapa de arquivos.** Mesmo `ContentSpec`, mesmo bloco do Inspector
   sem seleção, mesmo `SduiView`, mesmo desenho no mock, e **o mesmo E2E em
   aparelho físico** — que é a parte cara: só o dev humano tem o aparelho, e nem
   o editor nem o `/preview` provam o sintoma.
2. **A decisão em aberto do 43 é a decisão que a appBar força.** "Um `systemBars`
   próprio ou campos dentro do `safeArea`" é exatamente "como o chrome de página
   se estrutura no `ContentSpec`" (**A9**). Decidir isso duas vezes com quinze
   dias de intervalo produz duas formas incompatíveis.
3. **Acoplamento técnico duro, verificado no Flutter 3.44.9.** `AppBar` já
   embrulha a si mesma num `AnnotatedRegion<SystemUiOverlayStyle>`
   (`app_bar.dart:1229`), resolvendo o estilo em `app_bar.dart:1216-1225` por
   `widget.systemOverlayStyle ?? appBarTheme.systemOverlayStyle ??
   defaults.systemOverlayStyle ?? _systemOverlayStyleForBrightness(...)` — e o
   último elo recebe `ThemeData.estimateBrightnessForColor(effectiveBackgroundColor)`,
   isto é, a **luminância da cor de fundo da barra** (não a cor crua, como o texto
   original sugeria). Ou seja: **havendo appBar, é a cor de fundo dela que decide
   se o relógio some** — não a cor de fundo da página. Implementar o 43 sem saber
   se existe appBar modela o contraste contra a coisa errada, e a regra se
   reescreve na semana seguinte.

**Recomendação: um item só (43, reescopado), em fases, com um E2E físico no fim
— e o estilo da barra do sistema saindo como fase/PR própria logo depois do
modelo de chrome estar de pé, não no fim da fila.** Ver **A7**.

**Numeração: 43 — e a decisão já está executada.** O 43 está no roadmap **no
lugar de precedência certo** (Marco 1b, logo depois do 8f, entre os chromes de
página), já tem decisão do humano registrada, e a pasta `docs/43-chrome-da-pagina/`
já é a apontada por `docs/roadmap.md:63`.

> **Duas justificativas do texto original eram falsas, e a auditoria as
> substitui:**
> 1. *"A convenção do repo é numerar a pasta pelo item de roadmap."* **Falso como
>    regra.** O `CLAUDE.md` define `NN` como número de sequência **na ordem de
>    desenvolvimento**, e há contraexemplos vivos: `docs/17-ergonomia-editor/` é o
>    **item 41** (`roadmap.md:122`) e `docs/16-image-url-e-props/` é o **item 39**
>    (`roadmap.md:91`). O que é verdade é que as pastas **novas** passaram a usar o
>    número do item (`24`, `43`, `46`) — a convenção mudou na prática sem o
>    `CLAUDE.md` acompanhar. Vale reconciliar, fora deste item.
> 2. *"Criar um 48 obrigaria a matar o 43."* **Sem efeito: o 48 já existe** e é
>    outra coisa — "Tema e design tokens do projeto, em cascata"
>    (`roadmap.md:74`), criado no mesmo dia. O slot está ocupado.

---

## Ambiguidades abertas

Nenhuma fase começa antes de fecharem. Cada uma traz as opções, o que cada uma
custa, e a recomendação do PM — que é recomendação, não decisão.

### A1 — Onde a appBar mora: chrome da página ou widget do catálogo?

| Opção | O que ganha | O que custa |
| --- | --- | --- |
| **(a) Chrome da página** — `ContentSpec.appBar`, editado no Inspector quando nada está selecionado | Coerente com o 8f e com o 43; **impossível ter duas, ou uma dentro de uma `Row`, ou uma no meio da árvore** — a posição deixa de ser um estado inválido possível | Não aparece na paleta — o dev precisa descobrir que se edita clicando fora de tudo (mitigado: a linha "Página · área segura" da árvore já é esse ponto de entrada e passa a listar o que a página tem) |
| **(b) Descriptor no catálogo** — `type: "appBar"` arrastável | Descoberta imediata: está na paleta, como todo o resto | O nó **renderiza como `AppBar` de verdade em posição** — mas de segunda classe: sem `scrolledUnder` e sem coordenação do recuo do topo — **dois dos três wrappers que a A2 precifica** (o terceiro, o do teclado, é do body e independe desta escolha). E continua exigindo **regra de posição só para ela** (o custo conceitual do `expanded`/`spacer`, ver acima), que é o custo que decide |
| **(c) Híbrido** — chrome, mas com uma entrada na paleta que liga o `appBar` da página | Descoberta da (b) com a integridade da (a) | A paleta passa a ter um item que não vira nó; é uma mentira de UI que vai precisar de explicação para sempre |

**Recomendação: (a).** É o que o Flutter permite modelar honestamente, o repo já
tem o precedente montado e genérico, e a perda de descoberta é barata de mitigar
dentro da própria (a).

### A2 — Quem monta o `Scaffold`? (**a que decide a arquitetura**)

Esta destrava as outras, porque decide o que o `SduiView.content` devolve.
Lembrando o §3: **a rolagem migra para dentro do `SduiView` em qualquer das
opções (a) e (b)** — esse custo não é discriminante.

| Opção | O que ganha | O que custa |
| --- | --- | --- |
| **(a) O `SduiView.content` devolve um `Scaffold`** (com `appBar:` nulo quando não há), + `bodyWrapper` opcional para os hosts | **O spec passa a ser dono da tela** — que é literalmente o pedido de fidelidade. E os slots que já estão prometidos (`bottomNavigationBar`, FAB) entram **sem reabrir esta decisão**. As **duas** razões que decidem estão logo abaixo da tabela, mais a nota do teclado | Os três consumidores mudam de forma; o `/preview` mexe no `RefreshIndicator` e no `Positioned` do banner; `sdui_view.dart` passa a importar `material.dart` |
| **(b) Sem `Scaffold`** — `Column(children: [SduiAppBar(...), Expanded(body)])` | **Nada.** A auditoria procurou e não achou benefício: "manter o renderer fora do `material.dart`" **não existe** — `packages/sdui_flutter/lib` já importa `material.dart` em **15 arquivos** (`src/builders/button.dart`, `card.dart`, `checkbox.dart`, `divider.dart`, `dropdown.dart`, `radio.dart`, `slider.dart`, `switch.dart`, `text_field.dart`, os 5 de `builders/image/` e `parsing/material_icons.dart`), e a própria (b) desenha uma `AppBar` do Material | **Não escapa do problema do scroll** (o `Expanded` também exige altura limitada) e cobra **três wrappers** — recuo do topo (`MediaQuery.removePadding`), observer de rolagem (`ScrollNotificationObserver`) e recuo do teclado (`Padding(bottom: viewInsets.bottom)`). Baratos um a um; o custo real é que **cada app cliente futuro tem de lembrar dos três** |
| **(c) O host monta** — o renderer exporta `SduiAppBar.fromSpec(spec)` e cada consumidor pluga no `Scaffold` dele | Explícito; o app cliente que já tem `Scaffold` continua dono dele | Três lugares hoje — e **todo app cliente futuro** — precisam lembrar de plugar. É a classe de bug da **invariante I1 do item 41** (o `imageUrlResolver` opcional que hoje viaja por 7 hops no editor e 2 no `/preview`, e cuja ausência é silenciosa — ver Riscos herdados): esquecer não dá erro, dá barra faltando |

**Recomendação: (a) — mantida, com a justificativa reescrita duas vezes.**
Fidelidade quer dizer que o spec descreve a tela, não o miolo da tela.

> **Duas rodadas de correção, e é importante que as duas fiquem registradas.**
>
> **O discovery original** acusava a (b) de ser "uma barra de mentira: sem
> elevação, sem back automático, **sem `AnnotatedRegion`**". Duas das três
> acusações são falsas: a `AppBar` embrulha **a si mesma** num
> `AnnotatedRegion<SystemUiOverlayStyle>` (`app_bar.dart:1229`) e o botão de
> voltar vem de `ModalRoute.of(context)?.impliesAppBarDismissal`
> (`app_bar.dart:1013`) — as duas coisas sem `Scaffold` nenhum.
>
> **A primeira correção da auditoria também não se sustentou**, e é retratada
> aqui: eu havia posto **altura**, **elevação ao rolar** e **recuo do topo** como
> as razões de (a). Verificando de novo (Flutter 3.44.9):
> - **Altura — não discrimina, retirada.** A `AppBar` já se auto-dimensiona a
>   `toolbarHeight` sozinha, pelo `_ToolbarContainerLayout.getSize`
>   (`app_bar.dart:50-63`, `getSize` em `:62`, usado em `:1157`), e soma o recuo
>   do topo pelo `SafeArea(bottom: false)` de `:1191`. Numa `Column` a altura
>   infinita deixa o `Align(topCenter)` (`:1194`) fazer shrink-wrap, dando
>   `padding.top + toolbarHeight`. Dentro do `Scaffold` a conta é a mesma, só que
>   como **teto**: `ConstrainedBox(maxHeight: AppBar.preferredHeightFor(...) +
>   topPadding)` (`scaffold.dart:3049-3056`). **Mesma altura renderizada nos dois
>   casos.** (O `ConstrainedBox(maxHeight: toolbarHeight)` de `app_bar.dart:1170`
>   que eu tinha citado só existe quando há `bottom != null`, isto é, com `TabBar`.)
> - **Elevação ao rolar — real, mas barata.** O `scrolledUnder` precisa do
>   `ScrollNotificationObserver` (`app_bar.dart:836`), que o `Scaffold` provê
>   (`scaffold.dart:3235`) — mas ele é **exportado por
>   `package:flutter/widgets.dart`** (`widgets.dart:130`), a biblioteca que
>   `sdui_view.dart:1` já importa. É **um wrapper**.
> - **Recuo do topo — real, e é um `MediaQuery.removePadding`.** Também um wrapper.
>
> **Terceira correção, no ciclo 3 — e esta derruba a razão que eu tinha posto em
> primeiro lugar.** Eu havia escrito que o teclado era "a perda que wrapper nenhum
> resolve", com um universal negativo **sem ponteiro**: *"o encolhimento é
> exclusivo do `_ScaffoldLayout` — nenhum outro widget do framework consome
> `viewInsets.bottom` para redimensionar"*. **Falso.** O `CupertinoPageScaffold`
> reflui pelo teclado com um `MediaQuery` + `Padding` puros, sem layout próprio
> (`cupertino/page_scaffold.dart:192-203`: zera `viewInsets.bottom` e devolve o
> mesmo valor como `EdgeInsets.only(bottom:)`), e o `CupertinoTabScaffold` faz
> igual (`cupertino/tab_scaffold.dart:314-318`, via `removeViewInsets` +
> `contentPadding`). O mecanismo **é um wrapper**, do mesmo formato dos outros
> dois. Com a rolagem já migrada para dentro do `SduiView`,
> (b) + `Padding(bottom: viewInsets.bottom)` reproduz o comportamento.
>
> Dois wrappers viraram três, e três wrappers baratos **também** não decidem uma
> arquitetura. **As duas razões que decidem são estas:**

**1. O resto do chrome já está prometido, e é tudo slot do `Scaffold`.** O
próprio "Fora de escopo" deste documento diz que `bottomNavigationBar` e FAB
virão, e que "a resposta será a mesma quando forem pedidos". Os dois são slots do
`Scaffold`. Escolher (b) agora é **refazer esta decisão na primeira barra
inferior** — e aí com dado já publicado no formato errado, que é o caro.

**2. O renderer já assume um `Scaffold` hospedeiro, em dois lugares.** O
`onAction` do app de demonstração chama `ScaffoldMessenger.of`
(`rendered_content_view.dart:29`), e o do canvas também
(`preview_surface.dart:113`). A opção (b) deixaria essa suposição implícita e não
verificada — exatamente o modo de falha da **invariante I1**: não dá erro, dá
`SnackBar` que não aparece.

**O teclado desce a coadjuvante, e vira nota de contrato do SDK.** Continua sendo
comportamento que alguém precisa entregar — o catálogo tem `textField`
(`packages/sdui_core/lib/src/catalog/widget_catalog.dart:488`), `dropdown`
(`:1030`) e `slider` (`:1073`), e o `Scaffold` o entrega de graça com
`resizeToAvoidBottomInset` nascendo ligado (`scaffold.dart:2779-2780`). Na (a) vem
junto; na (b) é o **terceiro** item da lista que todo app cliente tem de acertar
sozinho. É argumento de ergonomia de SDK, não de impossibilidade — e o documento
não pode vendê-lo como impossibilidade, senão o primeiro tech-lead de app cliente
que abrir o Cupertino derruba o argumento e leva a A2 junto.

**⚠️ Sub-pergunta embutida, e é de produto:** se o `SduiView.content` monta o
`Scaffold`, **o app cliente perde o direito de ter chrome próprio na tela do
conteúdo.** Está certo para o app de demonstração (ele existe para provar
fidelidade), mas é decisão de contrato do `driva_client` (item 25, fatia 2) — e
o arquivo onde ela aterrissa **já existe como stub**:
`packages/sdui_flutter/lib/src/driva_content.dart:10-14`, que hoje lança
`UnimplementedError` mandando usar `SduiView.content(spec)`. Note que a fatia 2
do item 25 é **a mesma** que vai levar a remoção da casca (**A14**): as duas
decisões caem no mesmo lugar e devem ser tomadas juntas.
Recomendação: sim para o v1 — o `DrivaContent` traz o próprio `Scaffold` e isso
vira documentação explícita do SDK; um `useHostScaffold: true` entra depois **se**
um cliente real pedir. Não inventar o botão de escape antes de existir quem
aperte.

### A3 — Quais props a appBar expõe no v1?

Todas as candidatas abaixo já têm editor pronto (§5): o custo é o descriptor + o
renderer lendo a prop.

| Prop | Custo | Nota |
| --- | --- | --- |
| `enabled` (bool) | Barata | **Obrigatória** — é o que expressa "esta página não tem barra", e o que dá a retrocompatibilidade do §6. `defaultValue: false` |
| `title` (string) | Barata | Único campo onde `isBindable: true` faria sentido — ver **A10** |
| `backgroundColor` | Barata | Reuso direto de `FieldKind.color` |
| `foregroundColor` | Barata | Cobre título + ícones |
| `centerTitle` (bool) | Barata | ⚠️ o default do Flutter é **dependente de plataforma**, e a regra exata (`app_bar.dart:805-817`) é mais estrita do que "iOS sim, Android não": android/fuchsia/linux/windows → `false`; **iOS/macOS → `actions == null \|\| actions!.length < 2`**. Como o v1 não tem `actions` (**A4**), no iOS o default seria `true` e no Android `false` — divergência garantida. O descriptor precisa fixar `defaultValue: false` **explícito**. Argumento **reforçado** pela auditoria |
| `elevation` (double) | Barata de fazer, **de baixo valor** | ⚠️ **Justificativa corrigida.** O discovery dizia que "em M3, `elevation` sozinha quase não muda nada" — falso: ela alimenta o `Material.elevation` (`app_bar.dart:1233`) e o `surfaceTintColor` cai explicitamente em `colorScheme.surfaceTint` (`app_bar.dart:1236-1243`), então **muda o tint do fundo**. O que **não** aparece é a sombra (`_AppBarDefaultsM3.shadowColor => Colors.transparent`, `app_bar.dart:2542`), e em rolagem ela é **substituída** por `scrolledUnderElevation` (`app_bar.dart:951-955`). Ou seja: entrega um efeito sutil que o usuário vai confundir com "mexi na cor de fundo". Recomendação: **cortar do v1** — agora pelo motivo certo |
| `showBackButton` / leading | Barata como bool, **semanticamente arriscada** | No demo app a rota de conteúdo é raiz: **não há o que popar**. Precisão da auditoria: a `AppBar` decide isso por `ModalRoute.of(context)?.impliesAppBarDismissal` (`app_bar.dart:1013`), que conta rota abaixo **ou** `LocalHistoryEntry` (`widgets/routes.dart:2256-2258`) — não é `Navigator.canPop`. Uma prop booleana forçaria um botão que o Flutter esconderia sozinho, ou vice-versa. O modelo honesto é `leadingIcon` (`FieldKind.iconName`, editor já existe) **+ ação** — mesma dependência do `actions`. Recomendação: **cortar do v1** |
| `actions` | **Problemática** | Dois bloqueios, ver §5 e **A4** |

**Recomendação: v1 = `enabled`, `title`, `backgroundColor`, `foregroundColor`,
`centerTitle`.** Cinco props, descriptor novo + `AppBar` no renderer, **zero
widget novo no Inspector**. `elevation` e `showBackButton` ficam de fora não por
serem caras, mas por entregarem pouco ou mentirem.

### A4 — `actions` entra no v1 ou espera o item 28?

**Recomendação: fora do v1**, registrado como dependência do item 28 — pelos dois
bloqueios do §5 (não há kind de lista; não há onde a appBar pendurar evento, já
que não é um `SduiNode`). Um ícone que não faz nada é decoração, e decoração com
cara de botão é pior que ausência — a mesma falha silenciosa que o item 39 matou
na imagem.

### A5 — O que acontece com os conteúdos já publicados?

**Ausência de `appBar` = sem barra**, sem migração, sem mudança visual em nada
que está no ar. O mecanismo recomendado é o `enabled` com `defaultValue: false`
(§6), que preserva o padrão do 8f e não apaga props ao desligar.

**Precisa de confirmação explícita** porque tem um contraponto real: o app de
demonstração **tinha** uma barra até hoje de manhã e agora não tem. Se a
expectativa do dev for "o conteúdo que eu já publiquei volta a ter barra", a
resposta não é default no renderer — é ele **adicionar a appBar no editor e
republicar**, que é justamente o fluxo que esta feature entrega.

Alternativa rejeitada: default com barra e `title` = `name` do conteúdo — mudaria
a aparência de conteúdo já no ar sem ninguém pedir, que é a definição de
regressão.

### A6 — `appBar` × `safeArea.top`: quem ganha?

**Mecanicamente não há conflito** — confirmado pela auditoria no Flutter 3.44.9,
com duas precisões que o `plan.md` precisa:

- `scaffold.dart:3030` monta o body com
  `removeTopPadding: widget.appBar != null`, e o `removePadding` zera
  `padding.top` (`scaffold.dart:2909,2917`). Havendo appBar, o
  `MediaQuery.padding.top` que chega ao body é **zero** — o `SduiSafeArea` interno
  vira **no-op no topo**, com `top: true` ou `top: false`. Não quebra, não duplica
  recuo.
- `app_bar.dart:1191` embrulha a própria AppBar num `SafeArea(bottom: false)`
  — **mas só quando `primary: true`** (o default). Se algum dia o descriptor
  expuser `primary`, esta conclusão muda.
- ⚠️ **A zeragem tem uma exceção que a opção (c) abaixo ativa:** com
  `extendBodyBehindAppBar: true` (default `false`, `scaffold.dart:1710`) o
  `_BodyBuilder` **restaura** `top = max(padding.top, appBarHeight + bannerHeight)`
  (`scaffold.dart:973-978`), e `contentTop` vai a `0` (`scaffold.dart:1043`). Ou
  seja: a opção (c) não é neutra em recuo — ela devolve o padding ao body.

**O problema é de significado.** O conteúdo real testado tem `top: false` — o
usuário escolheu **desenhar sob a barra do sistema**. Ligar uma appBar torna essa
escolha **inerte, sem nenhum aviso**: o toggle continua no Inspector, continua
clicável, e não faz mais nada.

| Opção | Trade-off |
| --- | --- |
| **(a) Independentes, sem aviso** | Zero código; o Inspector fica com um controle que não faz nada. Reintroduz a classe de bug do próprio item 43 |
| **(b) O Inspector avisa** — "Respeitar o topo" ganha `helpText`/estado desabilitado quando a barra está ligada | Barato, honesto, não mexe no dado do usuário. Resolve menos |
| **(c) Derivar `extendBodyBehindAppBar` de `safeArea.top`** — `top: false` ⇒ `extendBodyBehindAppBar: true` + appBar transparente  | Preserva a intenção do usuário e é uma linha no renderer — mas a linha **não é neutra**: com `extendBodyBehindAppBar: true` o body recupera `top = max(padding.top, appBarHeight + bannerHeight)` (`scaffold.dart:973-978`), então o `SduiSafeArea` volta a ter efeito no topo. E **troca um controle inerte por outro**: com `top: false`, o `backgroundColor` da appBar passa a não ter efeito, e o dev não tem como descobrir por quê |
| **(d) Prop explícita `extendBehindAppBar` na appBar** | Honesta e capaz: quem quer a barra transparente sobre o herói pede isso | Uma prop a mais no v1, e um conceito a mais para explicar |

**Recomendação: (b) no v1, com (d) registrada como o caminho de crescimento.**
Não recomendo a (c), por um motivo de produto: o dev que já tinha
`top: false` (herói sangrando sob o status bar) e **agora adiciona uma appBar**
quase certamente quer uma barra normal — o `top: false` é vestigial. Derivar
transparência dali o surpreende e esconde a causa. Se ele quiser o efeito, que
peça por ele.

⚠️ **Item obrigatório do E2E, independente da opção escolhida:** as quatro
combinações de `appBar.enabled` × `safeArea.top` têm de produzir estado
**visualmente distinto** em aparelho físico contra homologação.

### A7 — Fundir com o item 43, e em que forma?

| Opção | Trade-off |
| --- | --- |
| **(a) Dois itens separados**, appBar primeiro | Entrega antes o que dói agora. Mas: dois E2E em aparelho físico (a parte cara, e só o humano faz); dois passes no Inspector e no mock; e o 43 modelaria contraste contra o fundo da página quando a appBar já é o que está atrás da barra do sistema |
| **(b) Um item, uma fase só** | Um E2E, um passe. Fase grande demais para um PR; contraria "1 fase = 1 PR" |
| **(c) Um item (43), em fases, um E2E no fim** — chrome de página de pé primeiro, barra do sistema como fase/PR própria logo em seguida | Um E2E físico só; Inspector e mock recebem um passe coordenado; o contraste é modelado contra o que estará de fato atrás da barra. A appBar entra em `develop` na primeira fase, mas o item só **fecha** depois da fase do 43 |

**Recomendação: (c).**

### A8 — A appBar aparece no mock do editor e no `/preview`?

**Recomendação: nos três lugares, e isso é o requisito, não um detalhe** — a
feature inteira existe para que os três mostrem a mesma coisa. Pelo §4, o mock e
o app de demonstração herdam praticamente de graça; o `/preview` tem o ajuste dos
`Positioned` e do `minHeight`.

**Caso de borda a decidir junto:** os três curto-circuitos de `root == null`
(§3). **Uma página com barra configurada e sem nenhum widget mostra a barra, ou
mostra o estado-vazio?**
**Recomendação: mostra a barra, com o estado-vazio abaixo dela** — senão o dev
configura a barra e não a vê até adicionar um widget qualquer, e o editor volta a
mentir.

### A9 — Forma do campo em `ContentSpec`: plano ou aninhado?

Esta é a pendência que o item 43 já tinha registrado, agora com uma peça a mais
na mesa.

| Opção | Trade-off |
| --- | --- |
| **(a) Campos planos** — `ContentSpec.safeArea`, `.appBar`, `.systemBars`, irmãos | Segue o que já existe; zero migração; cada um com seu descriptor e sua semântica de default | `ContentSpec` cresce um campo por peça de chrome |
| **(b) Aninhado** — `ContentSpec.chrome = {safeArea, appBar, systemBars}` | Um lugar só; abre espaço para `bottomBar`/FAB no futuro | **Migra o `safeArea` de todo conteúdo já salvo**, ou obriga o schema a ler dois formatos para sempre |
| **(c) Um mapa só** — `pageChromeDescriptor` juntando tudo, separado por `group` | Um `InspectorPropList` só, uma busca só, zero widget novo | Mistura "recuo do conteúdo" com "barra de topo" no mesmo mapa do JSON; envenena o schema para o 43 |

**Recomendação: (a).** O ganho da (b) é organização; o custo é migração de dado
em produção logo depois de o item 24 ter acabado de estabilizar a publicação.
Não vale.

> **Nota técnica que decorre da (a), para o `plan.md` resolver — confirmada pela
> auditoria, com ponteiro:** a busca (`SearchField`, `_query` em
> `inspector_prop_list.dart:42,81-83,106`) e o scroll (`ListView`, `:120`) moram
> **dentro** do `InspectorPropList`. Hoje o `InspectorPanel` tem dois pontos de
> chamada **alternativos** — o ramo do nó (`inspector_panel.dart:55`) e o ramo da
> Página (`:91`) — então nunca há dois na tela ao mesmo tempo. Empilhar dois no
> ramo da Página daria **duas buscas e dois scrolls**. A saída natural é extrair a
> busca e o scroll para o `InspectorPanel`, com os descriptors separados. É
> decisão de implementação, não de produto — mas a consequência visível (uma busca
> só no painel da Página) é.
>
> **Barato de graça:** o colapso por seção já existe e já é repassado
> (`inspector_area.dart:14-16,43` → `inspector_panel.dart:21,36,60,96`), então as
> duas seções colapsáveis que o PRD promete no caminho feliz **não custam
> mecanismo novo**.

### A10 — O `title` aceita binding `{{prop}}`?

Nenhuma prop do `safeAreaDescriptor` é bindável. Mas `title` é texto, e texto é o
candidato natural do item 29 — e o `prop_binding_dialog.dart` já existe.

**Recomendação: `isBindable: false` no v1.** Aceitar `{{...}}` num campo que o
renderer não resolve produz uma página que mostra `{{titulo}}` literal no
aparelho — falha invisível no editor, visível só no cliente. Reabrir no item 29,
que é quem traz a resolução.

### A11 — O rodapé de debug (data do spec + `etag`) morreu junto. Faz falta?

O `content_meta_bar.dart` apagado era também **ferramenta de diagnóstico**: era
por ele que se via qual versão do spec o aparelho tinha em mãos. A remoção estava
certa (não vem do spec, logo não pode estar na tela do conteúdo), mas levou a
ferramenta junto.

**Recomendação:** não volta para a UI do conteúdo em hipótese nenhuma. Se fizer
falta, vira **log** ou uma tela de debug própria do app de demonstração, fora do
que o renderer desenha. **Pergunta ao dev:** fez falta ao conferir o APK, ou o
que ele precisava já está no `/preview`?

### A12 — Em que ordem o item 43 entra em relação ao E2E do item 41? _(aberta pela auditoria)_

O discovery registrou isto como risco, não como pergunta — mas é decisão, e ela
trava a primeira fase. Os arquivos **não** colidem (ver Riscos herdados); o que
colide é a **rodada de E2E** e o **golden do canvas**.

| Opção | Trade-off |
| --- | --- |
| **(a) O 43 espera a F8 do 41 ser atestada** | O E2E do 41 fotografa um editor estável; zero retrabalho de golden. Custa esperar as F5/F6/F7 mergearem e o humano rodar o roteiro |
| **(b) O 43 anda em paralelo, e o 41 refotografa** | Não bloqueia. Mas paga uma segunda rodada de prints do 41 — e é o humano quem tira, que é o recurso caro |
| **(c) O 43 anda até a fase do kernel, e para** | O kernel (descriptor + `ContentSpec` + schema) **não toca UI nenhuma** e não mexe em golden nem em altura. Destrava trabalho real sem tocar no alvo do QA |

**Recomendação: (c) agora, (a) para o resto.** A fase do kernel é genuinamente
0-dep — é o único pedaço desta feature que não move nada debaixo do E2E do 41.

### R1 — O golden do canvas é regravado uma vez só _(restrição para o `plan.md`, **não** decisão do humano)_

A D32 do item 41 (`docs/17-ergonomia-editor/plan.md:1248`) já estabeleceu a
regra: **golden regravado por duas causas = dois commits**. A fase do editor deste
item muda a altura do canvas (a barra passa a ocupar espaço), e a F9 do 41 regrava
goldens por outra causa. Sem ordem declarada, os dois trabalhos se sobrescrevem e
o discriminador da D32 (`git show --stat`) deixa de discriminar.

**Não há escolha a fazer aqui** — a regra já existe e só precisa ser aplicada.
O `plan.md` declara que o golden do canvas é regravado **uma vez**, na fase do
editor deste item, em commit próprio, e que a F9 do 41 rebaseia em cima. Fica
como restrição do plano, fora da mesa do humano.

### A14 — A casca do app de demonstração: quem remove, e quando? — ✅ **DECIDIDA (humano, 2026-08-17): opção (a)**

> **Decisão do humano, 2026-08-17 — opção (a).** O item 43 remove o `appBar:` e o
> `bottomNavigationBar:` **da tela de conteúdo** do app de demonstração. O
> `Scaffold` externo fica. O resto da casca continua com o item 25.
>
> ⚠️ **Esta decisão reverte parcialmente a alocação feita pelo tech-manager na
> manhã de 2026-08-17**, que punha a remoção inteira na fatia 2 do item 25. **A
> tela de conteúdo saiu de lá e é deste item.** Quem ler o item 25 não deve
> esperar encontrá-la: a fatia 2 continua dona do `content_meta_bar.dart` como
> arquivo, da tela de catálogo e do que mais houver na branch parada.

A casca estava em `develop` (`content_page.dart:34-48` +
`content_meta_bar.dart`), com a remoção parada em
`parked/demo-app-internet-e-casca`. O registro do impasse fica abaixo, porque é
ele que explica por que a decisão foi necessária.

Sem a remoção, o app de demonstração continua desenhando `Scaffold` + `AppBar`
próprios — e a fase do renderer deste item entrega um **segundo** `Scaffold` e uma
**segunda** `AppBar` dentro dele. O resultado no aparelho é duas barras
empilhadas: exatamente o sintoma que o PRD lista em "Erros monitorados"
(*"`AppBar` duplicada na árvore"*), promovido de risco a certeza.

| Opção | Trade-off |
| --- | --- |
| **(a) O item 43 remove a casca da tela de conteúdo** (só `content_page.dart`; `catalog_page.dart` e o resto do app ficam) | Destrava a promessa nº 4 do PRD e o E2E em aparelho. Custa contrariar a alocação da fatia 2 do item 25 — mas só no recorte mínimo: a tela do conteúdo, que é a que o renderer passa a possuir |
| **(b) O item 43 espera a fatia 2 do item 25** | Respeita a decisão do tech-manager. Mas o E2E em aparelho físico — a parte cara, que só o humano faz — **não pode ser executado**, porque a barra dupla mascara o que se quer medir. Na prática adia o item inteiro |
| **(c) O item 43 entrega, e o E2E roda com a casca** | Não roda: o §"De onde veio" existe porque a casca **mente**. Medir fidelidade contra um app que desenha chrome próprio é o defeito original |

**Decidido: (a).** A recomendação do PM/tech-lead foi seguida.

#### A fronteira da F0 — o que entra e o que não entra

Escrita aqui porque sem ela a F0 cresce sozinha na hora de implementar: é uma
fase de poucas linhas, e tudo em volta dela é tentador.

**Entra — e só isto:**

- em `content_page.dart:34-48`, saem o `appBar:` e o `bottomNavigationBar:`; o
  widget vira `Scaffold(body: ContentBody())`;
- o `import` de `content_meta_bar.dart` sai do `content_page.dart`, porque deixa
  de ser usado ali.

**Não entra — é do item 25, fatia 2:**

- **apagar o arquivo `content_meta_bar.dart`.** Ele fica no repo, órfão, até o
  item 25. Deletá-lo é mudança de outro item e alarga o diff da F0 sem
  necessidade — o que a fidelidade exige é que ele saia **da tela**, não do disco;
- a **tela de catálogo** (`catalog_page.dart:37`) e a `AppBar` dela — é chrome
  legítimo de uma tela que não é a do conteúdo;
- **qualquer outra coisa da branch `parked/demo-app-internet-e-casca`** (a parte
  de "internet" do nome, inclusive) — nada dela é encostado por este item;
- o `Scaffold` externo, que **fica**, pelo motivo abaixo.

⚠️ **O `Scaffold` externo não sai — nem na F0, nem depois.**
`content_body.dart:12-18` despacha três estados e só o `ContentLoaded` (`:15`)
passa pelo renderer; `ContentLoading` (`:14`) e `ContentError` (`:16`) são
**irmãos** dele, fora da subárvore do `SduiView`. Um `Scaffold` que nasça dentro
do `SduiView.content` não os alcança — ficariam sem superfície de fundo. A branch
parada já chegou a essa conclusão sozinha (mantém `Scaffold(body: ContentBody())`).
O aninhamento resultante é inofensivo, como o §3 já registra.

---

## Fora de escopo (declarado, para não voltar como surpresa)

- **`bottomNavigationBar` e FAB.** O argumento de "é slot do `Scaffold`" vale
  igual, e a resposta será a mesma quando forem pedidos. Não entram agora: cada
  um traz de volta a discussão de `actions`/eventos (**A4**).
- **`actions` na appBar** — **A4**, depende do item 28.
- **Binding no `title`** — **A10**, depende do item 29.
- **`elevation` e `showBackButton`** — **A3**, cortados do v1 por baixo valor e
  por risco semântico, não por custo.
- **Diferença iOS × Android** no desenho da barra do sistema — o item 43 já tem
  decisão do humano: "para o objetivo (prever contraste) isso não é relevante; um
  desenho só serve os dois". **Não reabrir.**
- **`SliverAppBar` / barra que encolhe ao rolar.** Outro widget, outro modelo.

---

## Riscos herdados

> **Auditados em 2026-08-17.** O item 41 vive em **`docs/17-ergonomia-editor/`**,
> não em `docs/41-*` (`roadmap.md:122`) — a pasta que o discovery procurava não
> existe.

- **Invariante I1 do item 41** (o `imageUrlResolver` opcional cuja ausência é
  silenciosa) vale igual aqui: se a **A2** fechar na opção (c), a appBar herda
  exatamente esse modo de falha. É o principal argumento contra aquela opção.
  **Correção de número:** a I1 está em `docs/17-ergonomia-editor/specs.md:371-378`
  e fala em **oito arquivos**, não "6 widgets" (o `roadmap.md:129` é que encurtou).
  Hoje a cadeia **cresceu**. Cadeia do editor, 7 hops, todos sob
  `apps/driva_editor/lib/modules/editor_module/presentation/`:
  `editor/editor_page.dart:153` → `editor/page/editor_workspace.dart:57` →
  `editor/page/center_area.dart:45` → `editor/page/canvas_area.dart:54` →
  `editor/widgets/canvas_panel.dart:84` →
  `editor/widgets/canvas/canvas_panel_body.dart:86` →
  `editor/widgets/canvas/preview_surface.dart:111`. Cadeia do preview, 2 hops:
  `preview/preview_page.dart:76` → `preview/widgets/preview_content.dart:51`.
  (Atenção aos dois `canvas_panel*`: moram em pastas diferentes.) O modo de falha
  está **confirmado e piorando** — o que fortalece o argumento.
- **Colisão de nome — corrigida.** O `app_shell/` do editor **não tem `AppBar`
  nenhuma** (§7). O que colide é o tipo `AppBarAction`/`AppBarActionKind`
  (`core/widgets/app_shell/app_bar_action.dart:3,9`), além do `AppBar` do Material.
- **O E2E do item 41 está pendente, e a colisão não é de arquivo — é de rodada.**
  Estado real (`docs/17-ergonomia-editor/plan.md:40-56`): **F3 mergeada** (PR #153,
  `[x]`, e foi ela que entregou a status bar do mock); **F5 (#155), F6 (#159) e F7
  (#160) com PR aberto** (`[-]`); **F8 (E2E) e F9 (bateria) não iniciadas**.
  **Nenhuma fase pendente do 41 toca `preview_content.dart` nem
  `preview_surface.dart`** — as listas de arquivos da F5 (`plan.md:1989-1998`) e da
  F7 (`plan.md:2067-2074`) não os citam, e F8/F9 não mexem em código de produção.
  O risco real é outro, e é caro: a **F8 do 41 é um E2E de UI do editor inteiro em
  homologação**, e a fase do renderer deste item **muda a altura do canvas e do
  `/preview`**. Instrumentar o E2E do 41, mexer na altura e só então pedir os
  prints ao humano invalida a rodada. Some-se a colisão de **golden**: a D32 do 41
  (`plan.md:1248`, golden regravado por duas causas = dois commits) e a F9
  regravam goldens do canvas, e a fase do renderer daqui os regrava de novo.
  **A ordem tem de ser declarada no `plan.md`, não deduzida.**
- **"Chrome da página" (43) e "status bar do mock" (41 F3) não são o mesmo
  objeto** — e isso é bom. A do 41 é **simulação do aparelho desenhada pelo
  editor**, nunca sai no spec, overlay que de propósito **não pinta fundo**
  (`device_status_bar.dart:9-10`, `device_frame.dart:118-125`). A do 43 é **dado
  do spec desenhado pelo renderer**. Elas se encontram num ponto só — o overlay
  transparente deixa a cor da appBar aparecer por baixo — e é exatamente esse
  ponto que torna a previsão de contraste possível no mock. **A F3 do 41 é
  pré-requisito satisfeito, não concorrente.**
- **Precedência sugerida — atualizada.** O item 46 **já tem `plan.md`**
  (`docs/46-projectid-na-rota-do-editor/plan.md:15-17`): F1 implementada e com
  gates de QA/CISO passados, **faltando só abrir o PR**; F2 (E2E) e F3 (bateria)
  abertas. Ou seja, ele não espera mais o tech-lead — espera merge. O chrome de
  página entra depois, no lugar do 43 no Marco 1b.

---

## Decisões do humano

_A preencher. Nenhuma fase começa antes._

### As três que vão à mesa — com o custo de cada caminho

Estas mudam o recorte, a ordem ou o alcance da feature. **A A14 já foi decidida —
era ela que destravava as outras duas.**

#### ✅ Decidida

| # | Pergunta | Decisão do humano | Quando | Consequência registrada |
| --- | --- | --- | --- | --- |
| **A14** | Quem remove a casca do app de demonstração? | **(a)** o item 43 remove o `appBar:` e o `bottomNavigationBar:` **só da tela de conteúdo**; o `Scaffold` externo fica | **2026-08-17** | **Reverte parcialmente a alocação do tech-manager da manhã de 2026-08-17:** a tela de conteúdo sai da fatia 2 do item 25 e passa a ser deste item. O resto da casca (`content_meta_bar.dart` como arquivo, tela de catálogo, restante da branch parada) **continua** com o item 25. Vira a **F0**, com a fronteira escrita em §A14 |

#### Pendentes

| # | Pergunta | Caminho | O que custa | Recomendação |
| --- | --- | --- | --- | --- |
| **A12** | Em que ordem o 43 entra em relação ao E2E do item 41? Nenhuma fase pendente do 41 toca os mesmos arquivos, mas a F8 dele fotografa o editor inteiro e as nossas fases mudam a altura do canvas e do `/preview` | **(a)** esperar a F8 do 41 ser atestada | Espera as F5/F6/F7 mergearem e o humano rodar o roteiro do 41. Bloqueia trabalho que não precisa esperar | ✅ **(c)** — o kernel é o único pedaço que não move nada debaixo do QA |
| | | **(b)** andar em paralelo | Paga **uma segunda rodada de prints do 41** — e quem tira os prints é você | |
| | | **(c)** só o kernel anda agora; o resto espera | Nada. O kernel (descriptor + `ContentSpec` + schema) não toca UI, golden nem altura | |
| **A2** | Quem monta o `Scaffold` — o renderer ou o host? Decide o que o `SduiView.content` devolve, e portanto o contrato do SDK | **(a)** o `SduiView.content` devolve o `Scaffold` | Os três consumidores mudam de forma; o `/preview` mexe no `RefreshIndicator` e no `Positioned` do banner; `sdui_view.dart` importa `material.dart`. **O app cliente perde o direito a chrome próprio na tela do conteúdo** (mas mantém o `Scaffold` externo — ver a A14) | ✅ **(a)** — os slots já prometidos (`bottomNavigationBar`, FAB) entram sem reabrir a decisão, e dois consumidores já assumem `Scaffold` hospedeiro |
| | | **(b)** `Column` + `SduiAppBar`, sem `Scaffold` | Três wrappers que **cada app cliente futuro** tem de lembrar (recuo do topo, observer de rolagem, recuo do teclado) — e **refaz esta decisão na primeira barra inferior**, aí com dado já publicado | |
| | | **(c)** o host monta e pluga `SduiAppBar.fromSpec` | Três lugares hoje **e todo app cliente futuro** precisam lembrar de plugar; esquecer não dá erro, dá barra faltando (**invariante I1**) | |

### As demais — refinam o conteúdo das fases, não o recorte

| # | Pergunta | Recomendação do PM | Decisão |
| --- | --- | --- | --- |
| A1 | appBar é chrome ou nó do catálogo? | (a) chrome da página | — |
| A3 | Props do v1 | `enabled`, `title`, `backgroundColor`, `foregroundColor`, `centerTitle` | — |
| A4 | `actions` no v1? | não — depende do item 28 | — |
| A5 | Conteúdo já publicado sem `appBar` | ausência = sem barra, via `enabled` com default `false` | — |
| A6 | `appBar` × `safeArea.top` | (b) o Inspector avisa; (d) fica para depois | — |
| A7 | Fundir com o item 43? | (c) um item, em fases, um E2E | — |
| A8 | Mock e `/preview` mostram a barra? | sim, os três; página vazia com appBar mostra a barra | — |
| A9 | Forma do campo em `ContentSpec` | (a) campos planos | — |
| A10 | `title` bindável? | não no v1 — item 29 | — |
| A11 | O rodapé de debug faz falta? | não volta para a UI do conteúdo | — |

> **A2, A12 e A14 estão na tabela de cima** — as que mudam recorte, ordem ou
> alcance. A **A14 já está decidida**; a A2 e a A12 seguem pendentes, com o custo
> de cada caminho lado a lado.
>
> **Não está em tabela nenhuma, de propósito:** a **R1** (golden do canvas
> regravado uma vez só) é restrição do `plan.md`, não escolha — a regra já existe
> na D32 do item 41. Pergunta sem alternativa não ocupa a mesa do humano.
