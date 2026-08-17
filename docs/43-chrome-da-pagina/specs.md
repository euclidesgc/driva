# Specs — Chrome da página: barra de topo (appBar) e barra do sistema

**Item:** 43 (reescopado — absorve o pedido novo de 2026-08-17)
**Discovery:** 2026-08-17, PM
**Origem:** uso real — APK release do `apps/driva_demo_app` contra homologação, em Android físico
**Status:** discovery aberto — **nenhuma fase começa antes de as ambiguidades fecharem**

> **Procedência do levantamento técnico.** Um `tech-lead` foi acionado para o
> discovery de código, mas **o relatório dele não retornou** dentro desta rodada.
> Todo o levantamento abaixo foi feito **diretamente pelo PM**, lendo os arquivos
> citados — cada caminho e cada número de linha deste documento foi conferido no
> repo (e, no caso do Flutter, em `~/.puro/envs/3.38.6/`). O que **não** foi
> feito, e um tech-lead faria: varredura pelo grafo do `code-review-graph` atrás
> de dependentes que este documento possa ter deixado passar, e a revisão da
> viabilidade das fases. **Antes de abrir o `plan.md`, o tech-lead deve validar o
> §3 (os três consumidores) e a A2** — é ali que mora o risco de escopo.

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

**A casca já foi removida nesta sessão** (fora do escopo desta feature, como
correção imediata do que estava mentindo):
`apps/driva_demo_app/lib/modules/published_module/presentation/content/page/content_page.dart`
virou `Scaffold(body: ContentBody())`, e o
`.../content/view/content_meta_bar.dart` foi apagado.

A remoção **fechou a mentira e abriu a lacuna**: agora o conteúdo ocupa a tela
inteira, e o spec **não tem como pedir uma barra de topo** nem para quem quer
uma. O conteúdo que o dev testou tem `safeArea: {"top": false, "enabled": true}`
— foi construído de propósito para desenhar sob a barra de status, o que torna a
lacuna visível: sem appBar no spec, quem quisesse uma barra teria que desenhá-la
à mão com um `container` + `text`, sem elevação ao rolar, sem botão de voltar,
sem coordenação com a área segura e sem integração com a barra do sistema.

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
| Editor | `.../editor/page/inspector_area.dart:40` (ramo sem seleção, `onUpdateSafeAreaProps`), `.../editor/cubit/editor_cubit.dart` (`updateSafeAreaProps`, com `coalesceKey` para o undo agrupar), `.../editor/page/inspector_vm.dart`, `.../editor/widgets/widget_tree/page_tree_row.dart` (a linha "Página · área segura") | `InspectorPropList` deixou de depender de `SduiNode` — recebe `ownerKey` + `properties` + `descriptor` + `onUpdateProps`, então **serve nó e página com o mesmo código** |

**Backend: zero trabalho.** `backend/src/contents/contents.service.ts` só compara
`spec['specVersion']`; `safeArea` nunca é citado — o JSONB passa reto. Vale igual
para `appBar`.

**Consequência de custo:** a máquina de editar chrome de página **já existe e é
genérica**.

### 2. O que o `SduiView` monta hoje

`packages/sdui_flutter/lib/src/sdui_view.dart` — 71 linhas, o arquivo inteiro é
o contrato:

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

| # | Onde | Como embrulha |
| --- | --- | --- |
| 1 | `apps/driva_demo_app/.../content/view/rendered_content_view.dart:19` | dentro do `Scaffold(body:)` do app; **sem scroll próprio** |
| 2 | `apps/driva_editor/.../editor/widgets/canvas/preview_surface.dart:103-108` | `GestureDetector` > **`SingleChildScrollView`** > `SduiView.content` |
| 3 | `apps/driva_editor/.../preview/widgets/preview_content.dart:40-52` | `RefreshIndicator` > `LayoutBuilder` > **`SingleChildScrollView`** > `ConstrainedBox(minHeight:)` > `SduiView.content` |

**O custo não é `Scaffold` aninhado** — isso o Flutter tolera. **É o scroll.** Em
dois dos três consumidores a rolagem fica **fora** do `SduiView`, o que entrega
altura infinita para dentro dele. Tanto um `Scaffold` quanto um
`Column`+`Expanded` estouram nessa condição.

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
- **Device mock do canvas — herda de graça, e com sinergia.**
  `.../canvas/device_frame.dart` já injeta `device.safeAreaPadding` num
  `MediaQuery`, então o `Scaffold` do renderer consumiria o recuo igual ao
  aparelho. E `device_status_bar.dart` **já foi escrito para não pintar fundo**
  ("desenha só os ícones sobre o que já está atrás… (item 43)") — os ícones do
  sistema aparecem corretamente sobre a cor da appBar, sem mudança nenhuma.
- **`/preview` — tem trabalho próprio, pequeno mas real.** O banner de falha e a
  pílula "último salvo" são `Positioned(top: AppSpacing.s16)` num `Stack`:
  passariam a ficar **atrás da appBar**. E o `ConstrainedBox(minHeight: constraints.maxHeight)`
  precisa descontar a altura da barra.

### 5. O que o catálogo já sabe editar — e o que não sabe

`packages/sdui_core/lib/src/catalog/field_kind.dart`:

```
string · doubleNum · intNum · dimension · boolean · color ·
enumeration · edgeInsets · alignment · iconName
```

Cor no spec é **string `#RRGGBB` ou `#AARRGGBB`**, parseada por `parseColor`
(`packages/sdui_flutter/lib/src/parsing/parsers.dart:9`), e editada pelo
`.../prop_field/color_editor.dart` (pacote `flex_color_picker` + 8 swatches +
campo hex). O item 44 acabou de consertar o título vazando do modal: **o seletor
de cor está saudável, é reuso puro.**

**Logo, todas as props candidatas do v1 são de tipos que o Inspector já desenha
— custo de editor: zero widget novo.**

**A exceção é `actions`**, e ela tem **dois** bloqueios, não um:

1. **Não existe kind de lista.** Os 10 `FieldKind` são escalares ou objeto fixo;
   todo o Inspector é `chave → valor` num mapa plano agrupado por `field.group`.
   Um editor de array-de-objetos é widget novo do zero.
2. **O editor não sabe autorar evento nenhum.** `grep -rn "events" apps/driva_editor/lib`
   → **zero ocorrências**. `SduiAction` existe no kernel e o renderer despacha
   via `onAction`, mas a autoria é o **item 28**. E há um detalhe estrutural:
   o plano do 28 põe as ações em **`SduiNode.events`** — e a appBar como chrome
   **não é um `SduiNode`**, logo não tem onde pendurar evento sem inventar um
   formato paralelo que o 28 teria que unificar depois.

### 6. A retrocompatibilidade tem um jeito certo e um jeito que quebra tudo

`content_schema.dart` faz `?? const {}` e `content_spec.dart` tem
`this.safeArea = const {}`. Para o `safeArea` isso está certo: **mapa vazio
significa "tudo no padrão"**, e o padrão do descriptor é `enabled: true`.
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
`statusBarIconBrightness` ou `AnnotatedRegion` no kernel e no renderer. A única
`AppBar` do repo é a **do próprio editor** (item 16c, o shell de duas faixas com
breadcrumb, `core/widgets/app_shell/`) — chrome do editor, sem relação com o
spec. **Colisão de nome a vigiar** ao nomear o widget do renderer.

---

## A decisão de fundo: appBar é chrome, não nó do catálogo

O pedido do dev sugere "um componente de appbar no catálogo". **A recomendação é
não fazer assim**, e a razão não é preferência de estilo — é o que a `AppBar` é
no Flutter.

`AppBar` não é um widget composável: é o **slot `appBar:` do `Scaffold`**. É o
`Scaffold` que a posiciona, reserva a altura dela, coordena com o `body`, dá o
botão de voltar automático (`Navigator.canPop`) e faz a elevação reagir à
rolagem.

Como nó do catálogo, ela seria arrastável para qualquer lugar. Nada impediria:

- uma appBar **dentro de uma `Row`**, espremida ao lado de um botão;
- **duas** appBars na mesma página;
- uma appBar **no meio** da árvore, com conteúdo acima dela;
- uma appBar como **raiz** (o item 8c permite qualquer widget como raiz).

Cada um desses casos é um documento válido pelo schema e sem sentido na tela. A
alternativa seria escrever regra de posição só para ela — que é exatamente o que
o `diagnoseTree` já faz, de forma custosa, para `expanded`/`spacer`, os dois nós
que só valem dentro de um flex. **Repetir esse padrão de exceção é o custo real
da opção "catálogo".**

O repo já resolveu essa mesma classe de problema uma vez, no item 8f, e a
solução tem nome e lugar: **chrome da página**. Ver **A1**.

---

## A fusão com o item 43 (recomendada)

O item 43 do roadmap — **"Estilo da barra do sistema como chrome da página"**,
pedido do humano em 2026-08-16, `[ ]` não iniciado, **sem plano de gaveta** em
`docs/plans/` e sem pasta em `docs/` — promete a mesma coisa, na mesma camada:

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
3. **Acoplamento técnico duro, verificado no Flutter 3.38.6.** `AppBar` já
   embrulha a si mesma num `AnnotatedRegion<SystemUiOverlayStyle>`
   (`app_bar.dart:1226`), resolvendo o estilo por
   `widget.systemOverlayStyle ?? AppBarTheme.systemOverlayStyle ?? defaults ?? _systemOverlayStyleForBrightness(backgroundColor)`.
   Ou seja: **havendo appBar, é a cor de fundo dela que decide se o relógio
   some** — não a cor de fundo da página. Implementar o 43 sem saber se existe
   appBar modela o contraste contra a coisa errada, e a regra se reescreve na
   semana seguinte.

**Recomendação: um item só (43, reescopado), em fases, com um E2E físico no fim
— e o estilo da barra do sistema saindo como fase/PR própria logo depois do
modelo de chrome estar de pé, não no fim da fila.** Ver **A7**.

**Numeração: 43, não um 48 novo.** A convenção do repo é numerar a pasta pelo
item de roadmap (`docs/24-…` = item 24, `docs/46-…` = item 46). O 43 já está no
roadmap **no lugar de precedência certo** (Marco 1b, logo depois do 8f, entre os
chromes de página), já tem decisão do humano registrada, e criar um 48 obrigaria
a matar o 43 e perder esse rastro.

---

## Ambiguidades abertas

Nenhuma fase começa antes de fecharem. Cada uma traz as opções, o que cada uma
custa, e a recomendação do PM — que é recomendação, não decisão.

### A1 — Onde a appBar mora: chrome da página ou widget do catálogo?

| Opção | O que ganha | O que custa |
| --- | --- | --- |
| **(a) Chrome da página** — `ContentSpec.appBar`, editado no Inspector quando nada está selecionado | Coerente com o 8f e com o 43; impossível ter duas, ou uma dentro de uma `Row`; integra com o `Scaffold` de verdade | Não aparece na paleta — o dev precisa descobrir que se edita clicando fora de tudo (mitigado: a linha "Página · área segura" da árvore já é esse ponto de entrada e passa a listar o que a página tem) |
| **(b) Descriptor no catálogo** — `type: "appBar"` arrastável | Descoberta imediata: está na paleta, como todo o resto | Precisa de regra de posição só para ela (o custo do `expanded`/`spacer`); ou o renderer a iça até o `Scaffold` (magia), ou desenha uma barra falsa e perde elevação, botão de voltar, `AnnotatedRegion` e coordenação de área segura |
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
| **(a) O `SduiView.content` devolve um `Scaffold`** (com `appBar:` nulo quando não há), + `bodyWrapper` opcional para os hosts | `AppBar` de verdade: elevação ao rolar, altura reservada corretamente, botão de voltar automático e **o `AnnotatedRegion` de graça** (que é metade do item 43). O spec passa a ser dono da tela — que é literalmente o pedido de fidelidade | Os três consumidores mudam de forma; o `/preview` mexe no `RefreshIndicator` e nos `Positioned`; `sdui_view.dart` passa a importar `material.dart` |
| **(b) Sem `Scaffold`** — `Column(children: [SduiAppBar(...), Expanded(body)])` | Nada, na prática | **Não escapa do problema do scroll** (o `Expanded` também exige altura limitada), e ainda obriga `MediaQuery.removePadding(removeTop: true)` na mão. É uma barra de mentira: sem elevação, sem back automático, **sem `AnnotatedRegion`** — reintroduz dentro do renderer o "desenha à mão com container + text" que a feature existe para eliminar |
| **(c) O host monta** — o renderer exporta `SduiAppBar.fromSpec(spec)` e cada consumidor pluga no `Scaffold` dele | Explícito; o app cliente que já tem `Scaffold` continua dono dele | Três lugares hoje — e **todo app cliente futuro** — precisam lembrar de plugar. É a classe de bug da **invariante I1 do item 41** (o `imageUrlResolver` que viajou por 6 widgets e cuja ausência era silenciosa): esquecer não dá erro, dá barra faltando |

**Recomendação: (a).** Fidelidade quer dizer que o spec descreve a tela, não o
miolo da tela. As opções (b) e (c) entregam uma barra que *parece* certa no mock
e erra no aparelho — que é o defeito que originou o pedido.

**⚠️ Sub-pergunta embutida, e é de produto:** se o `SduiView.content` monta o
`Scaffold`, **o app cliente perde o direito de ter chrome próprio na tela do
conteúdo.** Está certo para o app de demonstração (ele existe para provar
fidelidade), mas é decisão de contrato do `driva_client` (item 25, fatia 2).
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
| `centerTitle` (bool) | Barata | ⚠️ o default do Flutter é **dependente de plataforma** (true no iOS, false no Android). O descriptor precisa fixar `defaultValue: false` **explícito**, senão mock e aparelho divergem — que é o bug que esta feature existe para matar |
| `elevation` (double) | Barata de fazer, **de baixo valor** | Em Material 3, `elevation` sozinha quase não muda nada sem `scrolledUnderElevation`/`surfaceTintColor`. Recomendação: **cortar do v1** |
| `showBackButton` / leading | Barata como bool, **semanticamente arriscada** | No demo app a rota de conteúdo é raiz: **não há o que popar**, e o botão vira enfeite morto ou some sozinho. O modelo honesto é `leadingIcon` (`FieldKind.iconName`, editor já existe) **+ ação** — o que joga para a mesma dependência do `actions`. Recomendação: **cortar do v1** |
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

**Mecanicamente não há conflito** (verificado no Flutter 3.38.6):
`scaffold.dart:2992` monta o body com `removeTopPadding: widget.appBar != null`,
e `app_bar.dart:1188` embrulha a própria AppBar num `SafeArea(bottom: false)`.
Havendo appBar, o `MediaQuery.padding.top` que chega ao body é **zero** — o
`SduiSafeArea` interno vira **no-op no topo**, com `top: true` ou `top: false`.
Não quebra, não duplica recuo.

**O problema é de significado.** O conteúdo real testado tem `top: false` — o
usuário escolheu **desenhar sob a barra do sistema**. Ligar uma appBar torna essa
escolha **inerte, sem nenhum aviso**: o toggle continua no Inspector, continua
clicável, e não faz mais nada.

| Opção | Trade-off |
| --- | --- |
| **(a) Independentes, sem aviso** | Zero código; o Inspector fica com um controle que não faz nada. Reintroduz a classe de bug do próprio item 43 |
| **(b) O Inspector avisa** — "Respeitar o topo" ganha `helpText`/estado desabilitado quando a barra está ligada | Barato, honesto, não mexe no dado do usuário. Resolve menos |
| **(c) Derivar `extendBodyBehindAppBar` de `safeArea.top`** — `top: false` ⇒ `extendBodyBehindAppBar: true` + appBar transparente  | Preserva a intenção do usuário e é uma linha no renderer. Mas **troca um controle inerte por outro**: com `top: false`, o `backgroundColor` da appBar passa a não ter efeito, e o dev não tem como descobrir por quê |
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

> **Nota técnica que decorre da (a), para o `plan.md` resolver:** dois
> `InspectorPropList` empilhados dão **duas buscas e dois scrolls** no painel.
> A saída natural é extrair a busca e o scroll para o `InspectorPanel`, com
> os descriptors permanecendo separados. É decisão de implementação, não de
> produto — mas a consequência visível (uma busca só no painel da Página) é.

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

- **Invariante I1 do item 41** (o `imageUrlResolver` que viaja por 6 widgets e
  cuja ausência é silenciosa) vale igual aqui: se a **A2** fechar na opção (c), a
  appBar herda exatamente esse modo de falha. É o principal argumento contra
  aquela opção.
- **Colisão de nome com a `AppBar` do editor** (item 16c,
  `core/widgets/app_shell/`). O widget do renderer não pode se chamar `AppBar`.
- **O `/preview` está com E2E pendente** (item 41 F8/F9, ainda não atestados).
  Mexer no `preview_content.dart` antes daquele E2E fechar move o alvo debaixo do
  QA. **Verificar a ordem com o tech-lead antes de abrir a primeira fase.**
- **Precedência sugerida:** o item 46 está com discovery fechado
  esperando só o `plan.md` (1 PR) — destravar ele primeiro; o chrome de página
  entra depois, no lugar do 43 no Marco 1b.

---

## Decisões do humano

_A preencher. Nenhuma fase começa antes._

| # | Pergunta | Recomendação do PM | Decisão |
| --- | --- | --- | --- |
| A1 | appBar é chrome ou nó do catálogo? | (a) chrome da página | — |
| A2 | Quem monta o `Scaffold`? | (a) o `SduiView.content`, com `bodyWrapper` | — |
| A3 | Props do v1 | `enabled`, `title`, `backgroundColor`, `foregroundColor`, `centerTitle` | — |
| A4 | `actions` no v1? | não — depende do item 28 | — |
| A5 | Conteúdo já publicado sem `appBar` | ausência = sem barra, via `enabled` com default `false` | — |
| A6 | `appBar` × `safeArea.top` | (b) o Inspector avisa; (d) fica para depois | — |
| A7 | Fundir com o item 43? | (c) um item, em fases, um E2E | — |
| A8 | Mock e `/preview` mostram a barra? | sim, os três; página vazia com appBar mostra a barra | — |
| A9 | Forma do campo em `ContentSpec` | (a) campos planos | — |
| A10 | `title` bindável? | não no v1 — item 29 | — |
| A11 | O rodapé de debug faz falta? | não volta para a UI do conteúdo | — |
