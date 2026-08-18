# PRD — Chrome da página: barra de topo (appBar) e barra do sistema

**Item:** 43 (reescopado)
**Specs:** [`specs.md`](specs.md)
**Autor:** PM · **2026-08-17**

> **Procedência: auditada pelo `tech-lead` em 2026-08-17.** As afirmações técnicas
> foram conferidas contra o código e o SDK; as correções estão neste arquivo e no
> `specs.md`, com ponteiro. O recorte de fases abaixo foi revisado e **mudou**:
> ganhou uma fase de remoção da casca (**F0**) e uma ordem declarada em relação ao
> item 41.

> ⚠️ **Este PRD é provisório até as ambiguidades do `specs.md` serem decididas
> pelo dev.** A **A14 já foi decidida (2026-08-17)** — era a bloqueante, e o
> resultado está incorporado aqui (F0 firme, promessa nº 4 firme). Seguem abertas
> a **A2**, a **A12** e as onze originais. Ele está escrito **assumindo as
> recomendações do PM**,
> para que o dev veja o produto que elas produzem e possa vetar com o desenho na
> frente. Recomendação vetada = seção reescrita antes de o `tech-lead` abrir o
> `plan.md`.

---

## Problema

O construtor e o aparelho não mostram a mesma coisa, e o driva não tem como
fazer com que mostrem.

O dev abriu um conteúdo publicado real num Android físico e viu uma barra de topo
com título e botão de recarregar que **ele nunca montou** — era casca do app de
demonstração, e **ela ainda está lá**: `content_page.dart:34-48` em `develop`
segue montando `Scaffold(appBar: AppBar(...), body: ContentBody(),
bottomNavigationBar: ContentMetaBar())`. (A versão anterior deste PRD dizia que a
casca "foi removida no mesmo dia" — não foi; a remoção está parada em
`parked/demo-app-internet-e-casca` e estava alocada à fatia 2 do item 25. Pela
**A14**, decidida pelo humano em 2026-08-17, **a tela de conteúdo passou a ser
deste item** e sai na F0.)

O buraco que a casca esconde é o mesmo: **o spec não sabe dizer "esta página tem
uma barra de topo"**.

Hoje quem quiser uma barra tem duas saídas, e as duas são ruins:

1. **Desenhar à mão** um `container` + `text` no topo da árvore — sem elevação ao
   rolar, sem botão de voltar, sem altura padrão de plataforma, sem coordenação
   com a área segura e sem influência sobre a cor dos ícones do sistema.
2. **Deixar o app cliente desenhar** — que é exatamente o que acabou de ser
   removido por mentir: o editor não tem como saber o que o app vai pôr ali.

E há uma consequência de segunda ordem, que é o que amarra este item ao 43
original: **quando existe uma appBar, é a cor de fundo dela — não a da página —
que decide se o relógio e a bateria do usuário somem** (`AppBar` resolve o
`SystemUiOverlayStyle` a partir do próprio `backgroundColor`, verificado no
Flutter 3.44.9 — a versão do projeto, `.puro.json` + `ci.yml:41`; **não** a 3.38.6
do `default` do puro). Entregar o estilo da barra do sistema antes da appBar seria
modelar contraste contra a superfície errada.

---

## Resultado esperado

**Uma página montada no construtor aparece igual no aparelho — incluindo o topo.**

Em concreto, ao fim deste item:

1. O dev liga uma barra de topo no Inspector da Página, dá título e cores, e vê a
   barra **no mock do canvas, no `/preview` e no app instalado** — os três iguais.
2. Nenhum conteúdo publicado hoje muda de aparência. Ausência de `appBar` é
   ausência de barra, sem migração.
3. O dev consegue **prever no editor** se os ícones da barra do sistema vão sumir
   contra o fundo que estará atrás deles — que é a promessa do item 43 original,
   agora modelada contra a superfície certa.
4. A **tela de conteúdo** do app de demonstração não desenha **nada** que não
   venha do spec. Ela volta a ser um instrumento de medida confiável. Entregue
   pela **F0** — a **A14 foi decidida em 2026-08-17** e a remoção da casca dessa
   tela é deste item.

**O que este item não é:** não é o `Scaffold` inteiro virando editável
(`bottomNavigationBar` e FAB ficam de fora), não é appBar com botões que fazem
coisa (isso é o item 28), e não é barra que encolhe ao rolar.

---

## Recorte — seis fases

A ordem é de dependência. **1 fase = 1 PR.** _(Revisto pela auditoria: eram cinco
fases sob o título "quatro"; entrou a **F0** e as dependências externas ficaram
explícitas.)_

| Fase | O que entrega | Depende de |
| --- | --- | --- |
| **F0 — O app de demonstração para de mentir** | Remove `appBar:` e `bottomNavigationBar:` da **tela de conteúdo** do demo app (`content_page.dart:34-48`); **o `Scaffold` externo fica** | — (**A14 decidida em 2026-08-17**; fronteira do que entra e do que não entra em `specs.md` › A14) |
| **F1 — Kernel: o chrome cresce** | `appBarDescriptor` fora do `widgetCatalog` + `ContentSpec.appBar` + validação no schema | — (**a única fase 0-dep de verdade** — não toca UI, golden nem altura) |
| **F2 — Renderer: o `SduiView` vira a página** | `SduiView.content` devolve `Scaffold(appBar:, body:)` com `bodyWrapper`; os três consumidores migram a rolagem para dentro | F1, F0; **e a F8 do item 41** (**A12**) |
| **F3 — Editor: o Inspector da Página ganha a barra** | Seção "Barra de topo" no ramo sem seleção, `updateAppBarProps` no cubit, linha da árvore atualizada, mock desenhando | F1 (pode andar em paralelo com F2 se as chaves estiverem congeladas). Regrava o golden do canvas **uma vez**, em commit próprio (**A13**) |
| **F4 — Barra do sistema (o item 43 original)** | `systemBars` como terceiro chrome + `AnnotatedRegion`, com o contraste resolvido contra a appBar quando ela existe | F2, F3 |
| **F5 — E2E em aparelho físico + bateria automatizada** | Roteiro atestado pelo dev humano; testes **por último** | F4 |

**Por que a F4 não vem antes:** ver o Problema. E por que ela não vai para o fim
da fila do produto: é a metade que o humano já tinha pedido em 2026-08-16, e sai
como PR próprio logo que o modelo de chrome estiver de pé.

**Por que a F0 existe.** Sem ela, a F2 entrega um `Scaffold` + `AppBar` **dentro**
do `Scaffold` + `AppBar` que o demo app já monta: duas barras empilhadas no
aparelho. O item "AppBar duplicada na árvore" da tabela de Erros monitorados
deixaria de ser sinal de defeito e viraria o comportamento esperado — e o E2E em
aparelho, que é a parte cara, não teria o que medir.

---

## Caminho feliz

1. O dev abre um conteúdo no editor e **clica fora de qualquer widget** (ou na
   linha "Página" no topo da árvore).
2. O Inspector mostra **"Página"**, com o nome e o slug do conteúdo no subtítulo,
   e duas seções colapsáveis: **Barra de topo** e **Área segura**.
3. Ele liga **"Usar barra de topo"**. O mock desenha a barra na hora, abaixo da
   status bar simulada do aparelho, com a altura real de uma `AppBar`, e o
   conteúdo desce.
4. Ele digita o **título**, escolhe a **cor de fundo** e a **cor do texto** no
   seletor de cor de sempre, e marca **centralizar título**. Cada tecla e cada
   cor aparece no mock, sem recarregar.
5. O JSON ao lado passa a mostrar o bloco `appBar`.
6. Ele salva, abre o `/preview` no celular pelo QR e **vê a mesma barra**.
7. Ele publica, abre o app instalado e **vê a mesma barra** — mesma cor, mesmo
   título, mesma altura, mesma posição.
8. Ele desliga "Usar barra de topo". A barra some dos três lugares; **o título e
   as cores continuam preenchidos** no Inspector, prontos para religar.

---

## Exceções e casos de borda

| Situação | Comportamento esperado | Por quê |
| --- | --- | --- |
| Conteúdo publicado antes desta feature (sem `appBar` no JSON) | **Nenhuma barra, nenhuma mudança visual** | `enabled` cai no `defaultValue: false` do descriptor. Retrocompatibilidade é requisito, não efeito colateral |
| Página **sem nenhum widget** (`root == null`) com a barra ligada | **Mostra a barra**, com o estado-vazio abaixo dela | Três curto-circuitos hoje devolvem vazio antes de olhar o chrome (`sdui_view.dart:58`, `rendered_content_view.dart:16-18`, `preview_surface.dart:102,105-106`). Sem corrigi-los, o dev configura a barra e não a vê |
| `appBar.enabled: true` + `safeArea.top: true` | A barra consome o recuo do topo; o `SafeArea` do body vira no-op no topo (comportamento do `Scaffold`) | Verificado (Flutter 3.44.9): `scaffold.dart:3030` remove o padding do topo do body quando há appBar |
| `appBar.enabled: true` + `safeArea.top: false` | **Idem** — e o Inspector **avisa** que "Respeitar o topo" não tem efeito com a barra ligada | O toggle continua clicável e inerte; controle inerte sem explicação é a falha silenciosa que o projeto proíbe. (Decisão **A6**, em aberto) |
| Título mais comprido que a barra | Elipse, como qualquer `AppBar` | Não inventar comportamento; herdar o do Flutter |
| `backgroundColor` com alfa (`#AARRGGBB`) | Aceito — `parseColor` já suporta | Mas o E2E precisa provar o que fica atrás |
| Cor de fundo da barra vs. ícones do sistema | Resolvido na **F4**; até lá, herda o comportamento padrão da `AppBar` (que já deriva do `backgroundColor`) | É a razão de a F4 vir depois da F2, não antes |
| JSON com `appBar` que não é objeto | `SpecValidationError('appBar: esperado um objeto')`, no mesmo molde do `safeArea` | Mesma validação, mesma mensagem |
| JSON com chave desconhecida dentro de `appBar` | Preservada e ignorada pelo renderer | É o comportamento atual do `safeArea` — o schema não valida chaves internas |
| App cliente que já tem `Scaffold` próprio | No v1, **o `SduiView.content` é dono da tela do conteúdo**; o app remove o `appBar:`/`bottomNavigationBar:` dele, **não o `Scaffold`** | Decisão **A2**, em aberto. O `Scaffold` do host segue servindo os estados que não passam pelo renderer (carregamento, erro) — ver o aceite da F0. Documentado explicitamente no SDK |
| `/preview`: **banner de falha** | Precisa ficar **abaixo** da barra, não atrás dela | É `Positioned(top: AppSpacing.s16)` num `Stack` (`preview_content.dart:59-71`) |
| `/preview`: **pílula "último salvo"** | **Nada a fazer** — não colide | Corrigido pela auditoria: ela está no **rodapé** (`preview_content.dart:72-79`, `Positioned(bottom:)`), não no topo como o PRD dizia |
| App de demonstração com conteúdo mais alto que a tela | Passa a **rolar** | Hoje não rola: `rendered_content_view.dart:19` fica dentro de `Scaffold(body:)` sem scroll nenhum. Defeito não catalogado que a F2 conserta de carona — vira aceite, senão ninguém prova |

---

## Critérios de aceite por fase

### F0 — O app de demonstração para de mentir

- `content_page.dart` não monta mais `appBar:` nem `bottomNavigationBar:` na tela
  de conteúdo. **O `Scaffold` externo FICA** — vira `Scaffold(body: ContentBody())`,
  exatamente como a branch parada já fez, e **a F2 não o remove**.
- **Por que ele fica** (e isto é aceite, não observação): `content_body.dart:12-18`
  despacha três estados, e só **um** deles passa pelo renderer — `ContentLoading`
  (`:14`) e `ContentError` (`:16`) são irmãos do `RenderedContentView` (`:15`),
  **fora** da subárvore do `SduiView`. Um `Scaffold` que nasça dentro do
  `SduiView.content` **não os alcança**: ficariam sem superfície de fundo e sem
  `Scaffold` registrado para o `ScaffoldMessenger.of` de
  `rendered_content_view.dart:29`. O `Scaffold` aninhado que resulta disso é
  inofensivo — o próprio `specs.md` §3 já registra que o Flutter tolera.
- **Aceite explícito do estado de erro:** com a rede cortada, a tela de erro
  (`content_error_view.dart`, com `FilledButton` e `Theme.of`) aparece **sobre
  fundo de superfície**, não sobre preto. É a linha que impede o DoD de atestar
  "uma barra, não duas" num app cujo estado de erro perdeu o fundo.
- A tela de **catálogo** do demo app (`catalog_page.dart:37`) **continua com a
  `AppBar` dela** — não é a tela do conteúdo, e não está no escopo.
- `flutter analyze` verde; o app sobe e abre um conteúdo publicado.
- **A fronteira é estreita e está escrita** (`specs.md` › A14): **não** entra
  apagar o arquivo `content_meta_bar.dart` (fica órfão no repo até o item 25),
  **não** entra a tela de catálogo, **não** entra mais nada da branch parada.
- **Registro obrigatório em `variance_report.md`:** esta fase mexe em arquivo que
  estava alocado à fatia 2 do item 25, e a **A14 (humano, 2026-08-17)** moveu a
  tela de conteúdo para cá. Registrar como estava, por que mudou e o que mudou.

### F1 — Kernel

- `appBarDescriptor` existe **fora** do `widgetCatalog`; `parseNode` continua
  recusando `type: "appBar"`.
- `ContentSpec.appBar` entra no construtor, `copyWith`, `toJson` (**omitido
  quando vazio**) e na igualdade.
- Um spec **sem** `appBar` faz round-trip `toJson` → `parseContentSpec` sem
  ganhar a chave.
- `appBar` não-objeto devolve `Left(SpecValidationError)`.
- `appBarDescriptor.defaultValueOf('enabled')` é **`false`**;
  `defaultValueOf('centerTitle')` é **`false` explícito** (não o default
  dependente de plataforma do Flutter).

### F2 — Renderer

- `SduiView.content(spec)` com `appBar.enabled: false` (ou ausente) produz árvore
  **sem `AppBar`**.
- Com `enabled: true`, produz uma `AppBar` com título, cores e centralização
  vindos das props, e defaults do descriptor quando a chave falta.
- Os três consumidores rolam o conteúdo **por dentro** do `SduiView`, sem
  overflow, com o conteúdo mais alto que a tela — **inclusive o app de
  demonstração, que hoje não rola de jeito nenhum**.
- Página com `root == null` e barra ligada **desenha a barra**.
- Com a barra ligada, o `SduiSafeArea` interno vira **no-op no topo** (o
  `Scaffold` já zera o `padding.top` do body, `scaffold.dart:3030`) — e o
  aceite prova que **não há recuo duplicado** nem sumido.
- A barra tem a **altura da `AppBar` de verdade**, não uma altura escolhida por
  nós: o teste compara com `AppBar.preferredHeightFor`/`kToolbarHeight` mais o
  recuo de área segura, não com um número mágico.
- `flutter analyze` verde no workspace.

### F3 — Editor

- Sem nó selecionado, o Inspector mostra "Página" com as seções **Barra de topo**
  e **Área segura**, **uma busca só** no painel.
- Editar qualquer prop reflete no mock **sem recarregar**, com rebuild escopado
  (nada de reconstruir o workspace inteiro por tecla).
- `Ctrl+Z` desfaz uma sequência de digitação no título como **uma** entrada
  (coalescing por chave, como o `safeArea` já faz).
- A linha da árvore deixa de dizer só "área segura" e passa a refletir o que a
  página tem.
- Desligar a barra **preserva** título e cores no JSON.

### F4 — Barra do sistema

- O estilo dos ícones do sistema vira dado do spec, no molde de chrome de página.
- Havendo appBar, o contraste é resolvido **contra a cor da appBar**; não havendo,
  contra o fundo da página.
- O mock mostra o resultado — inclusive quando o resultado é "os ícones somem".
  Um mock que sempre desenha ícones legíveis **mascara** o defeito em vez de
  preveni-lo (nota herdada da D29 do item 41,
  `docs/17-ergonomia-editor/plan.md:1105`, entregue na F3/PR #153: a status bar do
  mock é overlay, ocupa exatamente `safeAreaTop` e **não pinta fundo** —
  `device_status_bar.dart:9-10`, `device_frame.dart:118-125`).

### F5 — DoD

- [ ] **E2E em aparelho físico, atestado pelo dev humano**, contra homologação
      (não `localhost` — lição do item 9g), com prints em
      `docs/43-chrome-da-pagina/evidencias/rodada_01/`.
- [ ] O roteiro prova as **quatro combinações** de `appBar.enabled` ×
      `safeArea.top` como estados **visualmente distintos**.
- [ ] O roteiro prova que um conteúdo **publicado antes desta feature** aparece
      **inalterado** no aparelho.
- [ ] O roteiro prova o mesmo conteúdo lado a lado nos três lugares: **mock,
      `/preview` e app instalado**.
- [ ] O roteiro prova o caso de contraste do item 43: fundo escuro + ícones
      escuros = relógio ilegível, e a correção pelo spec.
- [ ] O roteiro prova que o app instalado mostra **uma** barra, não duas — o
      print do aparelho é a única evidência de que a F0 pegou.
- [ ] O roteiro prova que conteúdo **mais alto que a tela rola no aparelho**
      (defeito que hoje existe e a F2 conserta).
- [ ] Bateria automatizada escrita **depois** do E2E atestado (cap. 22).
- [ ] `flutter analyze` verde + suíte completa passando.
- [ ] `CHANGELOG` na seção `Unreleased`, no mesmo PR de cada mudança.
- [ ] `docs/roadmap.md` com o item 43 marcado `[x]`.

---

## Testes que cada fase vai pedir

| Fase | Testes |
| --- | --- |
| F1 | `sdui_core`: `appBar_descriptor_test.dart` (defaults, `isBindable: false`, `enabled` default `false`); `content_schema_test.dart` (ausente → `{}`; não-objeto → `Left`; round-trip sem ganhar a chave); `content_spec_test.dart` (`copyWith`, igualdade, `toJson` omitindo vazio) |
| F2 | `sdui_flutter`: widget test — `enabled: false` ⇒ `find.byType(AppBar)` conta **zero**; `enabled: true` ⇒ título/cores/centralização corretos; `root == null` + barra ⇒ barra presente; conteúdo alto rola sem overflow |
| F3 | `driva_editor`: `inspector_panel_test.dart` (seção Barra de topo aparece sem seleção; desligar preserva props); `editor_cubit_test.dart` (`updateAppBarProps` com merge, remoção por `null` e coalescing do undo); golden do mock com a barra ligada |
| F4 | `sdui_flutter`: o `AnnotatedRegion` resolvido contra a appBar quando ela existe, contra a página quando não; `driva_editor`: golden do mock nos dois casos |
| F5 | Suíte completa + os goldens regravados (o canvas muda de altura ao ganhar a barra) |

---

## Analytics (a instrumentar)

| Evento | Quando | Por que importa |
| --- | --- | --- |
| `page_appbar_toggled` | Liga/desliga a barra de topo (com o estado destino) | Diz se a barra é adotada de verdade ou se o pedido era outro |
| `page_appbar_prop_edited` | Edita uma prop da barra (com a chave) | Mostra **quais** props importam — entrada direta para decidir se `elevation`/`showBackButton`/`actions` valem a próxima fatia |
| `page_chrome_section_opened` | Abre a seção Barra de topo / Área segura no Inspector | Confirma que o ponto de entrada "clicar fora de tudo" é encontrável, que é o risco conhecido da decisão **A1** |
| `spec_published_with_appbar` | Publicação de conteúdo com `appBar.enabled: true` | Mede adoção no que chega ao app, não só no editor |

---

## Erros monitorados

| Sinal | O que investigar |
| --- | --- |
| `RenderFlex`/`BoxConstraints` overflow no `/preview` ou no canvas | A migração da rolagem para dentro do `SduiView` (F2) furou em algum consumidor — é o risco central da feature |
| `SpecValidationError('appBar: ...')` em conteúdo já salvo | Alguém gravou `appBar` fora do formato; não pode derrubar a tela, tem que virar recado |
| Conteúdo publicado antes da feature renderizando **com** barra | Regressão de retrocompatibilidade — o `enabled` default vazou para `true` |
| `AppBar` duplicada na árvore | Algum consumidor manteve o **`appBar:` próprio** depois da F0/F2 — **não** é o `Scaffold` externo, que fica de propósito (um `Scaffold` sem `appBar:` não contribui barra nenhuma). Se a F0 não entrou, este sinal é certeza, não alerta — ver **A14** |

---

## Riscos

**R1 — A rolagem migrando para dentro do `SduiView` é o custo real, e ele está
em três lugares.** Não é a `AppBar` que dá trabalho; é que hoje dois consumidores
embrulham o renderer num `SingleChildScrollView`, e altura infinita estoura
qualquer `Scaffold`/`Expanded`. **Mitigação:** o `bodyWrapper` proposto no `specs.md` §3 cobre os três casos sem ramificar, e a F2 tem aceite de overflow
próprio.

**R2 — O E2E do item 41 está pendente, e o conflito não é de arquivo.**
_(Reescrito pela auditoria.)_ O item 41 vive em `docs/17-ergonomia-editor/`. Sua
**F3 já mergeou** (PR #153) e foi ela quem entregou a status bar do mock; **F5
(#155), F6 (#159) e F7 (#160) têm PR aberto**; **F8 (E2E) e F9 (bateria) não
começaram** (`plan.md:40-56`). **Nenhuma fase pendente do 41 toca
`preview_content.dart` nem `preview_surface.dart`** — logo não há colisão de
merge. O que colide é a **rodada**: a F8 do 41 é um E2E de UI do editor inteiro
em homologação, e a nossa F2/F3 muda a altura do canvas e do `/preview`. Mexer
nisso entre a instrumentação do QA e os prints do humano invalida a rodada — e a
D32 do 41 (golden por duas causas = dois commits) deixa de discriminar.
**Mitigação:** a F1 (kernel) anda agora, porque não toca UI; a F2 espera a F8 do
41 ser atestada (**A12**), e o golden do canvas é regravado uma vez só, na F3,
em commit próprio (**A13**).

**R6 — A casca do demo app não foi removida, e a remoção pertencia a outro item.**
_(Da auditoria; **fechado pela A14 em 2026-08-17**.)_ Era o risco que podia adiar
o item inteiro: sem a F0, o E2E em aparelho físico não mede fidelidade, mede
barra dupla. **Resolvido:** o humano moveu a tela de conteúdo para este item, e
ela vira a F0. **Risco residual:** a F0 crescer na implementação e encostar no que
continua sendo do item 25 — mitigado pela fronteira escrita em `specs.md` › A14 e
pelo registro no `variance_report.md`.

**R3 — O ponto de entrada "clicar fora de tudo" é pouco descobrível.** É o preço
conhecido da decisão **A1**. **Mitigação:** a linha da árvore vira o atalho
explícito, e o analytics `page_chrome_section_opened` diz se pegou.

**R4 — Prometer meia barra.** Uma appBar sem `actions` e sem botão de voltar pode
ser lida como incompleta. **Mitigação:** está declarado no Fora de escopo e
amarrado ao item 28 — e a alternativa (ícone que não faz nada) é pior.

**R5 — Escopo da F4 herdar a indefinição do 43 original.** A pendência "um
`systemBars` próprio ou campos dentro do `safeArea`" agora tem resposta pela
**A9** (campos planos, irmãos). Se a A9 for vetada, a F4 reabre.

---

## Decisões travadas

### Do humano (não reabrir)

- **iOS e Android não precisam de desenhos diferentes** da barra do sistema no
  mock: para o objetivo (prever contraste), a diferença não é relevante.
  _(2026-08-16, herdada do item 43 original.)_
- **A14 — a remoção da casca da tela de conteúdo do app de demonstração é deste
  item.** Sai o `appBar:` e o `bottomNavigationBar:`; o `Scaffold` externo fica.
  O resto da casca segue com o item 25. _(2026-08-17.)_ **Reverte parcialmente a
  alocação do tech-manager da mesma manhã** — registrar no `variance_report.md`
  quando a F0 for implementada.

### Registradas por mim (PM), abertas a veto

As recomendações ainda pendentes estão na tabela do
[`specs.md`](specs.md#decisões-do-humano). As que mais mudam o produto se forem
vetadas:
- **A2 — o `SduiView.content` passa a ser dono da tela.** Veto aqui muda a
  arquitetura da F2 inteira e enfraquece a promessa de fidelidade.
- **A3 — cinco props no v1.** Veto para mais props é barato; veto para `actions`
  puxa o item 28 para dentro.
- **A7 — item único com o 43.** Veto aqui separa em dois itens e custa um segundo
  E2E em aparelho físico.

### Premissas herdadas (não reabertas aqui)

- Chrome de página fica **fora do `widgetCatalog`** — precedente do item 8f.
- Paleta, Inspector e defaults derivam 100% de descriptor; nada hardcoded no
  editor.
- O editor **não executa** ação nenhuma — quem executa é o app cliente.
