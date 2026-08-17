# PRD — Chrome da página: barra de topo (appBar) e barra do sistema

**Item:** 43 (reescopado)
**Specs:** [`specs.md`](specs.md)
**Autor:** PM · **2026-08-17**

> **Procedência:** o levantamento técnico foi feito diretamente pelo PM (ver a
> nota de abertura do `specs.md`) — o `tech-lead` acionado para o discovery de
> código **não retornou** nesta rodada. Caminhos e números de linha foram
> conferidos no repo, mas a **viabilidade das fases abaixo ainda não passou pelo
> tech-lead**: o recorte de 5 fases é proposta do PM, não plano validado.

> ⚠️ **Este PRD é provisório até as onze ambiguidades do `specs.md` serem
> decididas pelo dev.** Ele está escrito **assumindo as recomendações do PM**,
> para que o dev veja o produto que elas produzem e possa vetar com o desenho na
> frente. Recomendação vetada = seção reescrita antes de o `tech-lead` abrir o
> `plan.md`.

---

## Problema

O construtor e o aparelho não mostram a mesma coisa, e o driva não tem como
fazer com que mostrem.

O dev abriu um conteúdo publicado real num Android físico e viu uma barra de topo
com título e botão de recarregar que **ele nunca montou** — era casca do app de
demonstração. A casca foi removida no mesmo dia, o que corrigiu a mentira e
expôs o buraco: **o spec não sabe dizer "esta página tem uma barra de topo"**.

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
Flutter 3.38.6). Entregar o estilo da barra do sistema antes da appBar seria
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
4. O app de demonstração não desenha **nada** que não venha do spec. Ele volta a
   ser um instrumento de medida confiável.

**O que este item não é:** não é o `Scaffold` inteiro virando editável
(`bottomNavigationBar` e FAB ficam de fora), não é appBar com botões que fazem
coisa (isso é o item 28), e não é barra que encolhe ao rolar.

---

## Recorte — quatro fases

A ordem é de dependência. **1 fase = 1 PR.**

| Fase | O que entrega | Depende de |
| --- | --- | --- |
| **F1 — Kernel: o chrome cresce** | `appBarDescriptor` fora do `widgetCatalog` + `ContentSpec.appBar` + validação no schema | — |
| **F2 — Renderer: o `SduiView` vira a página** | `SduiView.content` devolve `Scaffold(appBar:, body:)` com `bodyWrapper`; os três consumidores migram a rolagem para dentro | F1 |
| **F3 — Editor: o Inspector da Página ganha a barra** | Seção "Barra de topo" no ramo sem seleção, `updateAppBarProps` no cubit, linha da árvore atualizada, mock desenhando | F1 (pode andar em paralelo com F2 se as chaves estiverem congeladas) |
| **F4 — Barra do sistema (o item 43 original)** | `systemBars` como terceiro chrome + `AnnotatedRegion`, com o contraste resolvido contra a appBar quando ela existe | F2, F3 |
| **F5 — E2E em aparelho físico + bateria automatizada** | Roteiro atestado pelo dev humano; testes **por último** | F4 |

**Por que a F4 não vem antes:** ver o Problema. E por que ela não vai para o fim
da fila do produto: é a metade que o humano já tinha pedido em 2026-08-16, e sai
como PR próprio logo que o modelo de chrome estiver de pé.

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
| Página **sem nenhum widget** (`root == null`) com a barra ligada | **Mostra a barra**, com o estado-vazio abaixo dela | Três curto-circuitos hoje devolvem vazio antes de olhar o chrome (`sdui_view.dart:58`, `rendered_content_view.dart:16`, `preview_surface.dart:105`). Sem corrigi-los, o dev configura a barra e não a vê |
| `appBar.enabled: true` + `safeArea.top: true` | A barra consome o recuo do topo; o `SafeArea` do body vira no-op no topo (comportamento do `Scaffold`) | Verificado: `scaffold.dart:2992` remove o padding do topo do body quando há appBar |
| `appBar.enabled: true` + `safeArea.top: false` | **Idem** — e o Inspector **avisa** que "Respeitar o topo" não tem efeito com a barra ligada | O toggle continua clicável e inerte; controle inerte sem explicação é a falha silenciosa que o projeto proíbe. (Decisão **A6**, em aberto) |
| Título mais comprido que a barra | Elipse, como qualquer `AppBar` | Não inventar comportamento; herdar o do Flutter |
| `backgroundColor` com alfa (`#AARRGGBB`) | Aceito — `parseColor` já suporta | Mas o E2E precisa provar o que fica atrás |
| Cor de fundo da barra vs. ícones do sistema | Resolvido na **F4**; até lá, herda o comportamento padrão da `AppBar` (que já deriva do `backgroundColor`) | É a razão de a F4 vir depois da F2, não antes |
| JSON com `appBar` que não é objeto | `SpecValidationError('appBar: esperado um objeto')`, no mesmo molde do `safeArea` | Mesma validação, mesma mensagem |
| JSON com chave desconhecida dentro de `appBar` | Preservada e ignorada pelo renderer | É o comportamento atual do `safeArea` — o schema não valida chaves internas |
| App cliente que já tem `Scaffold` próprio | No v1, **o `SduiView.content` é dono da tela**; o app remove o dele | Decisão **A2**, em aberto. Documentado explicitamente no SDK |
| `/preview`: banner de falha e pílula "último salvo" | Precisam ficar **abaixo** da barra, não atrás dela | Hoje são `Positioned(top: AppSpacing.s16)` num `Stack` |

---

## Critérios de aceite por fase

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
  overflow, com o conteúdo mais alto que a tela.
- Página com `root == null` e barra ligada **desenha a barra**.
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
  preveni-lo (nota herdada da D29 do item 41).

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
| `AppBar` duplicada na árvore | Algum consumidor manteve o `Scaffold` próprio depois da F2 |

---

## Riscos

**R1 — A rolagem migrando para dentro do `SduiView` é o custo real, e ele está
em três lugares.** Não é a `AppBar` que dá trabalho; é que hoje dois consumidores
embrulham o renderer num `SingleChildScrollView`, e altura infinita estoura
qualquer `Scaffold`/`Expanded`. **Mitigação:** o `bodyWrapper` proposto no `specs.md` §3 cobre os três casos sem ramificar, e a F2 tem aceite de overflow
próprio.

**R2 — O `/preview` está com E2E pendente** (item 41 F8/F9, não atestados). Mexer
no `preview_content.dart` agora move o alvo debaixo do QA. **Mitigação:** o
tech-lead confere a ordem antes de abrir a F2; se o F8 do item 41 estiver perto,
ele vai primeiro.

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

### Do humano (herdadas do item 43, 2026-08-16 — não reabrir)

- **iOS e Android não precisam de desenhos diferentes** da barra do sistema no
  mock: para o objetivo (prever contraste), a diferença não é relevante.

### Registradas por mim (PM), abertas a veto

Todas as onze recomendações estão na tabela final do
[`specs.md`](specs.md#decisões-do-humano). As três que mais mudam o produto se
forem vetadas:

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
