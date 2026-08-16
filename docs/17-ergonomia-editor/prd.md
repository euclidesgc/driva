# PRD — Ergonomia do editor: espaço de tela, grupos e modo preview

> **Rodada 01: aprovada.** As respostas **A1–A10** chegaram e viraram **D1–D4** e
> **D20** no `plan.md`. O recorte abaixo (fatias 1 e 2, F1–F4) é contrato.
>
> **Rodada 02 (itens 5.3 e 1.2 do `feedback_rodada_01.md`): decidida em
> 2026-08-16**, com **H1–H5** no `specs.md`. Tem seção própria no fim deste
> documento. As propostas **P7–P10** são do PM e têm veto fácil antes de a fase
> abrir — o resto é contrato.

- **Item no roadmap:** **não existe ainda.** Uma varredura em `docs/` por QR
  code, tela cheia e colapso de painel do editor devolve zero — isto é escopo
  genuinamente novo e precisa entrar com número próprio (proposta: **41**), no
  Marco 4, junto de 23 e 38.
- **Specs:** [`specs.md`](specs.md) — inclui as ambiguidades abertas e as
  invariantes técnicas.
- **Origem:** pedido do dev humano, 2026-08-15.

---

## Problema

O editor foi crescendo por dentro — 24 primitivos na paleta, um Inspector que
ganhou seções, estados e binding (item 9b), uma árvore com drag-and-drop
(item 8e), marcação de problema no nó (item 38) — e **a área onde se vê o
resultado não cresceu junto**. As três colunas são larguras fixas (280 / sobra /
320) com o canvas ficando com o resto; quanto menor a janela, menor o canvas, e
o mock de celular tem 393 pontos de largura que não encolhem.

O chrome fixo é **280 + 320 + 12 = 612 px**; o centro fica com `viewport − 612`,
sempre. Quatro consequências, todas mensuráveis:

1. **O canvas é o primeiro a apertar** e não há como dar espaço a ele: a 1024 o
   mock de celular já aparece cortado, e o preset **Tablet não cabe nem numa
   janela de 1440**.
2. **Não existe "ajustar à janela".** O zoom é manual (0.4–1.5) e o dev precisa
   descobrir sozinho que tem de mexer nele quando a janela muda.
3. **O que se ganha, se perde.** O splitter existe e o Inspector já colapsa, mas
   **nada é lembrado**: voltar à tela devolve 280/320 e reabre todas as seções.
4. **O editor estoura.** Os breadcrumbs têm ellipsis sem `Flexible` — a elipse
   nunca dispara e o `Row` transborda **já a 1280** com nome longo; a faixa 1
   estoura abaixo de ~700 px; abaixo de 612 px o workspace inteiro estoura.

E, por fora: **para ver o conteúdo no aparelho de verdade, hoje não há caminho
nenhum.**

## Objetivo

Devolver o **espaço de tela** ao construtor e dar ao dev um jeito de **ver o
conteúdo no tamanho real**, sem antecipar nada dos itens 24 (publicação), 26
(auth), 28 (eventos) ou 30 (breakpoints do spec).

**Resultado esperado, em uma frase:** o dev consegue dedicar a tela inteira ao
canvas quando quer, achar um widget na paleta sem rolar, e olhar o conteúdo em
tamanho real — tudo sem sair do editor e sem perder o ajuste no refresh.

---

## Recorte proposto — o que entra numa primeira fatia

O critério: **valor rápido, zero dependência de roadmap, zero backend.** As três
frentes baratas primeiro; a cara isolada e condicionada à resposta de **A6**.

### Fatia 1 — Ergonomia do editor (**3 fases, zero backend, zero CISO**)

A ordem inverteu depois do discovery técnico: **a responsividade vem primeiro**,
porque o que está quebrado hoje não é o colapso — é o editor estourando e o mock
não se ajustando.

| # | Entrega | Fase |
| --- | --- | --- |
| 1 | Matar os overflows duros: `Flexible` nos crumbs, overflow menu na faixa 1, piso mínimo para o centro no split view, largura inicial dos painéis por `LayoutBuilder` | F1 |
| 2 | **"Ajustar à janela" (fit) do mock** — o maior retorno isolado do pedido | F1 |
| 3 | Colapsar/expandir os dois painéis laterais, com controle sempre visível | F2 |
| 4 | Colapso e **largura arrastada** lembrados entre sessões | F2 |
| 5 | Grupos da paleta colapsáveis, um a um (+ memória do estado, ver **A5**) | F3 |
| 6 | Modo tela cheia (a essa altura, meia fase) | F3 |
| 7 | Bateria automatizada, **depois** do E2E atestado | F4 |

### Fatia 2 — Ver no aparelho (**decisão do humano, separada**)

Fica fora da fatia 1 **de propósito**: é a única parte com decisão de produto
aberta, e na leitura (a) ela deixa de ser 0-dep.

**Recomendação do PM, endossando o tech-lead: a leitura (d)** — rota
`/preview/:projectId/:id` no próprio editor. **1 fase contra 4, entregando
quase a mesma coisa.** A (a) só se paga quando o item 24 existir; antes disso
ela distribui rascunho por link, que é exatamente o desvio `VR-13-01` já
registrado — e ainda por cima quebra no dia em que o 24 entrar.

### Fora de escopo (declarado)

- Variação do spec por breakpoint — **item 30**, problema diferente com nome
  parecido.
- **Rotação (paisagem) do mock** — a moldura posiciona botões por fração da
  altura e o recorte da câmera assume o topo. Fase própria, se ele quiser.
- **Tokens de breakpoint completos e comportamento por faixa de largura** — só
  se **A1** pedir; o discovery técnico recomenda adiar.
- **"Dobrar seções" do painel JSON** — é o item **8b**, primo do pedido 3, mas
  não se junta agora.
- Layout do editor para tela de celular — se **A1** responder "celular", vira
  item próprio, não cabe aqui.
- Preview **interativo** (tocar botão e a ação acontecer) — depende do item 28.
- Autenticação da rota de preview — dívida do item 26, registrada no risco R3.
- Qualquer mudança em `sdui_core` ou no formato do JSON. **Este item não toca o
  kernel.**
- Backend. **A fatia 1 não tem nenhuma mudança de API.**

---

## Caminho feliz (fatia 1)

1. O dev abre um conteúdo numa janela qualquer. **O mock se ajusta sozinho à
   janela** e o editor restaura **o layout que ele deixou** — as larguras que
   arrastou, os painéis que colapsou, os grupos que fechou.
2. Ele está mexendo em propriedades: colapsa a paleta com um clique. O canvas
   ocupa o espaço liberado na hora; o mock continua centrado.
3. Precisa de um widget: reabre a paleta pelo mesmo controle, colapsa os grupos
   que não usa e vê `Listas` inteiro sem rolar.
4. Quer olhar o resultado: entra no modo tela cheia. Painéis, breadcrumb e
   rodapé sumem; sobra o mock, maior. `Esc` devolve tudo exatamente como estava.
5. Reduz a janela do navegador para metade da tela. O editor **não estoura**, o
   breadcrumb trunca em vez de transbordar, o mock reajusta, e tudo volta ao
   normal ao alargar.
6. Troca para o preset **Tablet** — que hoje não cabe nem numa janela de 1440 —
   e ele aparece inteiro, ajustado.

## Exceções e casos de borda

| Situação | Comportamento esperado |
| --- | --- |
| Os **dois** painéis colapsados ao mesmo tempo | Permitido — é justamente o "quase tela cheia". Os dois controles continuam visíveis |
| Paleta colapsada e o dev quer arrastar um widget | Não há de onde arrastar. O controle de reabrir precisa estar **sempre visível** — é o que **A3** decide (some de vez × faixa fina de ícones) |
| Busca ativa na paleta com grupos colapsados | Com filtro, os grupos com resultado **abrem**; ao limpar a busca, voltam ao estado que o dev tinha deixado. Sem isso, buscar parece "não achou nada" |
| Um nó é selecionado com o Inspector colapsado | Proposta: **reabre o Inspector** — selecionar é o gesto de "quero ver as propriedades". Alternativa: respeitar o colapso e só destacar. **Decisão P1, aberta a veto** |
| Erro/aviso de diagnóstico com o rodapé escondido no modo tela cheia | O rodapé de problemas **não some** no modo tela cheia se houver erro; some quando "Nenhum problema". Erro escondido é o sintoma que o item 38 acabou de corrigir |
| Modo tela cheia + atalhos do item 23 (`Ctrl+Z`, `Ctrl+G`…) | Continuam funcionando. O modo tela cheia é layout, não muda o mapa de teclas |
| Janela abaixo de 612 px (o chrome fixo de hoje) | Degradação decidida, nunca `RenderFlex overflow` — a régua é "não existe estado da janela em que o editor mostre faixa listrada de overflow" |
| Nome de projeto/conteúdo longo no breadcrumb | Trunca com elipse. Hoje **estoura a 1280**, porque a ellipsis existe mas falta `Flexible` |
| Preset Tablet numa janela comum | Cabe, ajustado pelo fit. Hoje não cabe **nem a 1440** |
| Fit ligado e o dev mexe no zoom manual | O manual vence e desliga o fit até ele pedir "ajustar" de novo. Fit que resiste a comando vira briga |
| Se a fatia 2 entrar: preview aberto no celular com edição não salva | Mostra o **último salvo** — não existe autosave. A tela de preview precisa dizer isso, ou o dev conclui que está quebrado |
| Colapso restaurado num aparelho com janela menor que a largura salva | A largura salva é **reclampada** aos limites atuais (min 200 / max 480 e o que couber), não aplicada cega |
| Preferência local corrompida ou ausente | Cai no padrão (280/320, tudo expandido) em silêncio. Layout salvo não é dado do usuário — nunca deve bloquear a abertura do editor |

---

## Critérios de aceite por fase

_Régua de máquina em todas: **`flutter analyze` verde + testes existentes
passando.** Nunca opinião._

### F1 — Piso de responsividade + "ajustar à janela"

Os defeitos objetivos que esta fase mata, todos já no ar hoje:

- **Breadcrumbs da faixa 2 estouram a 1280** com nome longo — têm ellipsis mas
  **não têm `Flexible`**, então a elipse nunca dispara. Passa a truncar.
- **Faixa 1 estoura abaixo de ~700 px** (4 ações + status + tema no editor).
  Ganha overflow menu.
- **O centro não tem piso.** `280 + 320 + 12 = 612 px` de chrome fixo; abaixo
  disso, `RenderFlex overflow`. Passa a ter mínimo, e a largura inicial dos
  painéis a vir de `LayoutBuilder` em vez de constante.
- **O preset Tablet (820) não cabe nem numa janela de 1440** — precisa de ~863
  de centro e tem 828. Com o fit, passa a caber por ajuste.
- **Não existe "ajustar à janela".** O zoom é manual (0.4–1.5) e o dev precisa
  descobrir sozinho que tem de mexer nele. Entra o fit.

Régua: **não existe largura de janela em que o editor mostre a faixa listrada de
overflow.** Se **A1** responder (i), a fase acaba aqui e os tokens de breakpoint
ficam para depois.

- **Invariante I1:** o `imageUrlResolver` continua chegando ao
  `preview_surface.dart` depois de qualquer mudança na cadeia do centro.
- **Sem tocar `sdui_core`.** Nenhuma linha deste item entra no kernel.

### F2 — Colapso dos painéis + memória do layout

- Cada painel lateral colapsa e expande, com o controle **sempre alcançável**
  (`Semantics`/tooltip — cor não pode ser o único sinal).
- Colapso e larguras persistem e são **reclampados** na restauração.
  `shared_preferences` já é dependência e o `preferences_module` tem a pilha
  pronta; a única decisão de plano é se o layout do editor mora lá (o módulo
  passaria a saber do editor) ou num repositório próprio do `editor_module`.
- **Gate de rebuild (item 3b):** o estado mora **dentro do
  `ResizableSplitView`**, junto das larguras que ele já governa. Os painéis
  chegam como campos `Widget` já construídos, então o `setState` do split view
  **não reconstrói painel nenhum** — custa só o `Row`. **Não entra no
  `EditorCubit`** (invariante **I2**): todo `emit` é o caminho quente que o item
  3b domou, e o item 30 já reservou assento lá (`editingBreakpoint`). Se o
  gatilho vier do AppBar ou de atalho, entra um `EditorLayoutController`
  (`ValueNotifier`) escopado no módulo.
- **Gate 1:** nada de `Widget _buildX(...)`. Cada peça nova é widget próprio.
- **Gate 4:** larguras, durações da animação de colapso e a espessura da faixa
  saem de `core/theme/` — nenhum número cru na tela.

### F3a — Grupos da paleta colapsáveis

- Os quatro grupos (`WidgetCategories.inPaletteOrder`, do kernel) colapsam
  individualmente; a ordem continua vindo do kernel, não da UI.
- O cabeçalho de categoria sai de dentro do `build` do
  `WidgetPalettePanel` e vira widget dedicado (Gates 1 e 3). Se virar um
  `CollapsibleSection` reutilizável, desenhá-lo sabendo que o item **8b**
  ("dobrar seções" no painel JSON) é o terceiro cliente — **sem** juntar os
  itens agora (invariante **I5**).
- **Não promover** nada do Inspector para `core/widgets/` nesta fase — os itens
  38 e 39 acabaram de mexer ali (invariante **I4**).
- Busca ativa expande os grupos com resultado e **restaura** o estado ao limpar.
- Widget novo no catálogo continua aparecendo **sem tocar no editor** — a regra
  do catálogo não pode ser quebrada pelo colapso.
- **Não usar `ExpansionTile`** (decisão do discovery técnico).
- Se **A5** confirmar que o incômodo é a memória, o estado colapsado do
  **Inspector** também passa a ser lembrado — hoje ele reabre expandido a cada
  troca de tipo de nó e a cada refresh.
- Se nascer um `AppBreakpoints` em `core/theme/`, os limiares são os do item 30
  (600 / 1024), **sem importar o enum do kernel** (invariante **I3**).

### F3b — Modo tela cheia (meia fase, depois da F2)

- Um controle e um atalho entram no modo; `Esc` sai e **devolve o layout
  anterior intacto**. A infra de `Shortcuts` do item 23 já está pronta.
- As faixas do `AppShell` somem **por um sinal no controller do AppShell**, que
  as páginas já alimentam — o shell continua sem ler cubit (regra do item 16c).
- O rodapé de problemas **permanece** se houver erro ou aviso.
- Não é rota nova — é estado de layout. Se **A6** escolher a leitura (d), a rota
  nasce lá e reaproveita esta mesma tela sem chrome.

### F4 — Bateria automatizada

Depois do E2E manual atestado (regra do cap. 22). No mínimo: persistência e
reclamp do layout; colapso não reconstruindo os painéis (o gate do item 3b);
busca com grupo colapsado; `Esc` restaurando o layout; o fit acertando a escala
para cada preset; e teste de regressão de overflow nas larguras de borda —
**612, 700, 1024, 1280 e 1440**, que são exatamente onde os defeitos vivem.

### DoD — o que a prova precisa mostrar

- **Estado visualmente distinto em print**, na **homologação real**, não em
  localhost: colapsado, expandido e — se houver persistência — reaberto após
  refresh. "Os painéis colapsam" não se prova com log.
- Os overflows: print de cada largura de borda **antes e depois**.
- Se a fatia 2 entrar na leitura (d): **foto de celular real**. Máquina nenhuma
  cobre isso.

---

## Analytics (a instrumentar)

| Evento | Quando | Por que importa |
| --- | --- | --- |
| `editor_panel_toggled` | Colapsa/expande painel (com qual painel e para qual estado) | Diz se o colapso é usado de verdade ou se o problema era outro (largura, zoom) |
| `editor_palette_group_toggled` | Colapsa/expande grupo (categoria) | Mostra quais categorias estorvam — entrada para a ordem da paleta e para o item 9 |
| `editor_fullscreen_entered` / `_exited` | Entra/sai do modo tela cheia (com a duração da sessão em tela cheia) | Se a permanência for longa, o pedido real era um modo de visualização, não colapso |
| `editor_layout_restored` | Abertura do editor com layout salvo (ou padrão) | Confirma que a memória do layout está pegando |
| `editor_viewport_width_bucket` | Abertura do editor, largura em faixas | **Responde A1 com dado em vez de suposição** — em que larguras o editor é realmente usado |

## Erros monitorados

| Sinal | O que investigar |
| --- | --- |
| `RenderFlex overflow` no workspace | O piso de responsividade furou; o `AppBlocObserver`/`FlutterError.onError` do `bootstrap.dart` já captura |
| Falha ao ler/gravar a preferência de layout | Não pode bloquear a abertura; cai no padrão e registra |
| Largura restaurada fora dos limites | Bug de reclamp; sintoma seria painel maior que a janela |

---

## Riscos

**R1 — "Responsividade em geral" não tem critério de pronto.** Sem a resposta de
**A1**/**A2**, F4 vira poço sem fundo. Mitigação: o piso é um **número**, e o
teste de aceite é objetivo (nenhum overflow entre o piso e a tela cheia).

**R2 — Colapso pode não ser o que resolve.** O splitter já existe e o Inspector
já colapsa; o que **não** existe é memória de nada disso, nem o fit. Há uma
chance real de o incômodo do dev ser "não é lembrado" e "o mock não se ajusta",
e não "falta colapsar". Por isso a F1 vem primeiro e **A5** foi reformulada.

**R3 — Preview por URL cria uma porta sem tranca.** Não piora o estado atual (o
editor inteiro já é aberto), mas vira dívida a ser fechada no item 26, e precisa
entrar na tabela de débitos vivos do roadmap **quando** for construída.

**R4 — Construir o preview sobre a rota pública é construir sobre areia.** O
PRD do item 24 já decidiu: `/v1/public` passa a servir **só publicado**, com
`404` sem publicação e **sem backfill**. Um preview de rascunho por ali morre no
dia do 24.

**R5 — Conflito de merge com trabalho em voo.** Os itens 38 e 39 acabaram de
mexer em canvas, árvore e Inspector e estão **em homologação aguardando
atestação**; o item 24 planeja tocar `core/widgets/app_shell/` (dois chips de
status). Esta feature mexe exatamente nessas áreas. Mitigação: não começar antes
do E2E do 38/39 atestado, e F3/F4 (que tocam o shell) irem **depois** ou serem
coordenadas com o 24.

**R6 — Desfazer o item 3b sem perceber.** Estado de layout no lugar errado
reconstrói o workspace a cada clique. É gate explícito na F1, não observação.

**R7 — Perder o `imageUrlResolver` numa tela nova.** A F3 do item 39 o injeta
por repasse através de seis widgets do editor; qualquer tela ou rota nova que
renderize o spec precisa carregá-lo adiante. Esquecer faz a imagem de host sem
CORS voltar a falhar em silêncio — a regressão exata do item 39. Ver a
invariante **I1** do `specs.md`.

**R8 — Entrar antes de fechar 38 e 39.** Nenhum dos dois tem `final_report.md`,
o roadmap ainda os marca incompletos apesar de estarem em `develop`, e as
baterias (F7 do 38, F5 do 39) não existem. Esta feature mexe nos mesmos
arquivos. Ver **I6**.

---

## Decisões travadas

### Do humano

_Nenhuma ainda._ Este PRD está aguardando **A1–A10**.

### Registradas por mim (PM), abertas a veto

- **P1. Selecionar um nó reabre o Inspector colapsado.** Selecionar é o gesto de
  "quero ver as propriedades"; manter fechado transforma a seleção em nada
  visível. Veto fácil se ele preferir respeitar o colapso.
- **P2. O rodapé de problemas não some no modo tela cheia quando há erro.** O
  item 38 acabou de tornar o problema visível no nó e no rodapé; esconder isso
  num modo novo seria reintroduzir o sintoma corrigido.
- **P3. Colapso e largura são preferência do usuário, globais — não por
  conteúdo.** Layout é hábito de trabalho, não atributo do documento.
- **P4. O modo tela cheia é estado de layout, não rota.** Nasce sem URL própria;
  se **A6** pedir a leitura (d), a rota nasce lá e reaproveita a mesma tela.
- **P5. O fit é o padrão ao abrir, e o zoom manual o desliga.** Abrir já
  ajustado é o que conserta a percepção; um fit que resiste a comando manual
  vira briga com o usuário.
- **P6. Se a fatia 2 entrar, a tela de preview diz que mostra o último salvo.**
  Sem autosave, é a primeira coisa que frustra — e uma linha de copy resolve.

### Premissas herdadas (não reabertas aqui)

- A ordem e o agrupamento da paleta vêm do **kernel**
  (`WidgetCategories.inPaletteOrder`), não do editor.
- A persistência local é a do item 3 (`preferences_module`,
  `shared_preferences`) — não nasce infraestrutura nova.
- O E2E precisa exercitar a UI real em homologação (regra permanente desde o
  item 9g), e a bateria automatizada vem por último (cap. 22).

---

# Rodada 02 — a árvore como alvo de arraste (5.3) e o colapso total (1.2)

> Decidida em 2026-08-16. Base: **H1–H5** e **P7–P10** no
> [`specs.md`](specs.md) §"Rodada 02". Origem: `feedback_rodada_01.md` §5.3 e §1.2.

## Resultado esperado

O dev monta uma página **vendo a paleta e a árvore ao mesmo tempo** e coloca cada
widget **no lugar exato** que quis, sem tentativa e erro: soltando **sobre** um
nó ele envolve aquele nó; soltando **entre** dois nós ele insere um irmão
naquela posição. Quando o gesto não pode dar certo, ele **vê a recusa durante o
arraste**, não depois.

## O que **não** muda — e por que isso é resultado, não omissão

- **A A3/D2 fica de pé.** Painel colapsado vira **faixa fina de ícones com o
  controle de expandir sempre visível** — a referência que ele mandou
  (`referencias/chrome_sidebar_colapsada.png`) é exatamente isso. O item **1.2
  é absorvido pela F5**; não vira fase nem item novo.
- **Nada de segunda origem do gesto de criar.** Sem flyout de paleta, sem
  clique-para-adicionar, sem `Ctrl+K`. A paleta não some, então a origem
  continua sendo ela.
- **Os botões "Envolver em Column/Row" da F2 do item 38 ficam.** O 5.3 é adição.
- **Continuam 3 colunas.** O piso do workspace não sobe e o **aceite 17-A da F3
  sobrevive intacto**.

## Recorte — cinco etapas

| # | Etapa | Depende de | Por que nesta ordem |
| --- | --- | --- | --- |
| **E0** | Rede de teste da estrutura atual | — | `ResizableSplitView`, `LeftPanel`, `CenterArea` e `InspectorArea` têm **zero testes**; depois da inversão não há com o que comparar |
| **E1** | Troca de colunas: Árvore → direita, Propriedades → aba esquerda | E0, **e a F3 mergeada** | F3 e E1 regravam o **mesmo** golden; sequenciar é o que mantém uma causa por regravação |
| **E2** | Kernel: `wrapNode` aceita `SlotKind.single` + `wrapNodeWith` no cubit | — (∥ com E1) | Camadas diferentes, não se tocam |
| **E3** | O gesto: três semânticas de zona, affordance no hover, recusa visível, autoscroll | E1 + E2 | O gesto precisa das colunas trocadas e do kernel que não mente |
| **E4** | F5 ajustada: faixa fina, `PanelRail` esquerdo com **um** botão | E1 | Só depois da troca é que o botão "Árvore" sai do painel esquerdo |

**P10 justifica a F3 antes da E1**: as duas tocam `goldens/canvas_device_mock.png`,
e duas causas de regravação no mesmo arquivo é onde a régua do item 39 deixa de
discriminar.

## Caminho feliz

1. O dev abre o editor. Painel esquerdo: abas **Widgets** \| **Propriedades**.
   Painel direito: **Árvore**. As duas visíveis, sem trocar de aba.
2. Ele arrasta **Column** da paleta e para **sobre o corpo** de um `container`
   que já tem conteúdo. O nó destaca-se inteiro e o rótulo diz **"Envolver
   container em Column"**.
3. Ele solta. O `container` passa a ser **filho** da Column nova; a árvore mostra
   o `container` recuado um nível. O rodapé registra a operação. **Um** passo de
   desfazer volta tudo.
4. Ele arrasta **Text** da paleta e para **na fresta** entre dois filhos de uma
   Column. Aparece a **linha de inserção** naquela posição.
5. Ele solta. O `text` entra **como irmão**, no índice da fresta.
6. Ele arrasta um nó **já existente** da árvore e repete os dois gestos: as
   mesmas duas semânticas valem para mover.
7. Ele colapsa a paleta. Ela vira **faixa fina** com o botão de expandir no topo;
   o canvas cresce e o percentual do mock sobe.

## Exceções e casos de borda

| Caso | Comportamento |
| --- | --- |
| Alvo é `SlotKind.none` (`text`, `image`, `button`) | Corpo = **envolver**. Nunca "inserir dentro" — não há slot |
| Alvo é `single` **vazio** (`container` sem `child`) | Corpo = **inserir como filho**. É o único caminho para encher um container vazio |
| Alvo é `single` **ocupado** | Corpo = **envolver**. O slot está cheio |
| Alvo é `multi` (cheio **ou vazio**) | Corpo = **envolver**. As frestas já cobrem toda posição, inclusive o índice 0 do vazio (`widget_tree_panel.dart:105`, laço com `<=`) |
| Widget arrastado é `SlotKind.none` | A affordance de envolver **não aparece**. Um `text` não pode envolver nada |
| Arrastar um nó para dentro de si mesmo | **Recusa visível** (`DropRefusal.cycle`), com estado distinto durante o gesto |
| Alvo sumiu no meio do gesto | **Recusa visível** (`DropRefusal.unknownTarget`) |
| Envolver a **raiz** | Funciona e **troca a raiz** (`tree_ops.dart:136`). A árvore mostra o wrapper novo no topo |
| Nó alvo abaixo da dobra da árvore | A árvore **rola sozinha** durante o arraste (**R-d**). Sem isso, alvo inalcançável |
| Página vazia (sem `root`) | Inalterado: a faixa "Solte um widget aqui para começar" segue sendo o alvo, e o primeiro widget vira a raiz |
| Preferência de layout corrompida | Cai no padrão **em silêncio** (D12). Vale para o formato novo |

## Critérios de aceite por etapa

Escritos como **o print que os prova**, seguindo a §11.0 e a **D25** do
`plan.md`: aceite positivo e medido, nunca "não apareceu X".

### E0 — Rede de teste

- `flutter test` cobre `ResizableSplitView` (larguras iniciais, clamp, arraste do
  divisor), `LeftPanel` (as duas abas montam), `CenterArea` e `InspectorArea`,
  **na estrutura de hoje**, e passa **antes** de qualquer linha da E1.
- _Régua:_ inverter as colunas com a rede no lugar precisa **falhar** os testes
  que descrevem a ordem. Se a suíte passar depois da inversão, a rede não cobriu
  o que precisava.

### E1 — Troca de colunas

1. **Print único, editor aberto a 1440:** a **paleta à esquerda** e a **árvore à
   direita**, ambas com conteúdo visível, **no mesmo print**. _É a premissa
   inteira do 5.3; se as duas não couberem num print, a etapa falhou._
2. **A aba trocou:** o painel esquerdo mostra **Widgets \| Propriedades**;
   selecionar um nó no canvas e a aba **Propriedades** mostra os campos daquele
   nó.
3. **R-a, a largura por slot:** arrastar a paleta para ~460, dar **F5**. O print
   depois mostra a **paleta** em ~460 e a **árvore** na largura dela — não a
   árvore com 460. _Reprova se as larguras trocarem de dono._
4. **O piso não subiu:** print a **612**, **700** e **1024** com o canvas de
   largura **não-zero** e a toolbar sem corte. _É o 17-A da F3, reexecutado após
   a troca para provar que ela não o quebrou._

### E2 — Kernel

5. `wrapNode` com wrapper `SlotKind.single` devolve árvore com o alvo em `child`
   (teste em `packages/sdui_core/test/ops/tree_ops_test.dart`).
6. `wrapNode` com wrapper `SlotKind.none` continua devolvendo `null` — e o
   **chamador do editor nunca o invoca**, porque a affordance não aparece.
7. Envolver a raiz troca a raiz, e o `parsePageSpec` do resultado passa.

### E3 — O gesto (a etapa que precisa dos quatro estados distintos)

8. **Os quatro estados, em quatro prints visivelmente diferentes**, com o mesmo
   widget sendo arrastado:
   - **(i) envolver** — corpo de um `container` **com** conteúdo: nó inteiro
     destacado + rótulo "Envolver container em Column";
   - **(ii) inserir irmão** — fresta entre dois nós: **linha de inserção** na
     posição, sem destaque do nó;
   - **(iii) inserir filho** — corpo de um `container` **vazio**: destaque
     **interno** ao nó + rótulo "Inserir dentro de container";
   - **(iv) recusado** — arrastar um nó para dentro de si mesmo: estado de
     recusa com **cor + ícone + cursor** (cor nunca sozinha).
   _Um print de "o widget apareceu na árvore" **não** serve: os três primeiros
   desfechos produzem "um nó novo na árvore". A prova é o estado **durante** o
   arraste e a **forma** da árvore depois._
9. **A árvore depois, três prints distintos:** (i) o `container` **recuado um
   nível** sob a Column nova; (ii) o `text` **no mesmo nível**, no índice da
   fresta; (iii) o `text` **dentro** do container antes vazio.
10. **Desfazer é um passo:** `Ctrl+Z` depois do envolver devolve a árvore ao
    print anterior. _Um envolver que custa dois desfazeres é bug de composição._
11. **Mover nó existente vale o mesmo:** repetir 8-(i) e 8-(ii) arrastando um nó
    **da própria árvore**, não da paleta. _H3 — as duas origens._
12. **A affordance não mente (P8):** arrastar um **`container`** sobre um `text`
    mostra "Envolver text em container", e **soltar funciona** — print da árvore
    com o `text` dentro do `container`. _Antes da E2 isto era `null` silencioso._
13. **A affordance não aparece onde não pode:** arrastar um **`text`** sobre
    qualquer nó **não** oferece envolver — o print mostra só as zonas de
    inserção. _Aceite negativo, e por isso vem com o mecanismo declarado: a
    affordance é derivada de `descriptorFor(type).slot != SlotKind.none`, então
    se ela aparecesse, apareceria por essa via._
14. **Autoscroll (R-d):** com uma página de ~40 nós, arrastar até a borda
    inferior da árvore **rola a lista** e permite soltar num nó que estava fora
    da tela. _Par de prints: antes (alvo fora) e depois (alvo visível, destacado)._
15. **A recusa é visível durante o gesto**, não só depois: print **com o ponteiro
    ainda pressionado** no estado de recusa.

### E4 — F5 ajustada

16. **Paleta colapsada:** faixa fina com o botão de **expandir** visível **e o
    percentual do canvas maior** que no print anterior. _O percentual é a metade
    que prova que o espaço foi para o mock, não para o fundo._
17. **Um botão, não dois:** a faixa esquerda mostra **só** o controle de
    expandir. _O aceite 26 original da F5 ("clicar no ícone Árvore reabre na aba
    Árvore") **foi reescrito**: a Árvore não mora mais ali._
18. **Os dois painéis colapsados:** duas faixas, mock no maior tamanho, **os dois
    controles de voltar visíveis**.

## Testes que cada etapa vai pedir

| Etapa | Unit | Widget | Golden |
| --- | --- | --- | --- |
| **E0** | — | `ResizableSplitView`, `LeftPanel`, `CenterArea`, `InspectorArea` na forma atual | — |
| **E1** | — | ordem das colunas; aba `Propriedades` reage à seleção; largura por painel (R-a) | **regravar** `canvas_device_mock.png` (causa: troca de colunas); corrigir `editor_perf_test.dart` (`find.text('Árvore')` deixa de ser rótulo de aba) |
| **E2** | `wrapNode` com `single`, com `none`, na raiz, e id duplicado | — | — |
| **E3** | a regra da P7 como função pura sobre `SlotKind` (tabela inteira) | as quatro zonas emitindo o callback certo; **substituir** `'soltar sobre uma linha manda o alvo, não o índice'` pela semântica nova | — |
| **E4** | — | faixa fina com um botão; painéis não reconstroem no toggle (D8) | — |

**A bateria vem por último**, depois do E2E atestado (cap. 22). A **E0 é
exceção declarada**: é rede de refatoração, não bateria da feature — sem ela a
inversão de colunas passa na suíte inteira sem ser vista.

## Analytics (acréscimo)

| Evento | Quando | Por que importa |
| --- | --- | --- |
| `editor_tree_drop` | Drop concluído na árvore, com `semantics` (`wrap` \| `sibling` \| `child`), `origin` (`palette` \| `tree`) e `targetSlotKind` | Diz **qual das três** o dev usa de verdade. Se `wrap` for residual, a troca de contrato não valeu |
| `editor_tree_drop_refused` | Drop recusado, com o motivo (`cycle` \| `unknownTarget` \| `wrapperIsNone`) | Recusa frequente é sintoma de affordance confusa, não de usuário errado |
| `editor_drop_undone` | `Ctrl+Z` **até 5 s** depois de um drop, com a `semantics` daquele drop | **É a métrica de mira.** Desfazer imediato quer dizer "não era isso que eu queria" — o sinal mais honesto de que as três zonas em 40 px não estão dando conta |
| `editor_wrap_via_button` | Uso do "Envolver em Column/Row" da F2 do item 38 | Compara a ergonomia antiga com a nova; se o botão continuar ganhando, o gesto não resolveu |

## Erros monitorados (acréscimo)

| Sinal | O que investigar |
| --- | --- |
| `wrapNode` devolvendo `null` num caminho de UI | **Não deveria acontecer** depois da E2 — a affordance só aparece para wrapper `multi`/`single`. Se acontecer, a UI e o kernel divergiram |
| Spec que falha `parsePageSpec` após um drop | A árvore ficou inválida; **nenhuma operação desta entrega pode produzir isso** — o nó inválido residente é fase posterior (H7), e até ela existir um spec inválido é defeito, não estado previsto |
| Pico de `editor_drop_undone` | O menu ofereceu um destino que o usuário não queria — entrada para revisar a cópia das quatro opções |
| Preferência de layout no formato antigo | Esperado uma vez após a E1; cai no padrão em silêncio (D12) e não pode aparecer de novo |

## Riscos desta rodada

**R-a a R-f** estão no `specs.md` §"Riscos herdados" e cada um precisa de tarefa
no `plan.md`. Os dois que mudam decisão:

**R-c — a árvore permanente liga o caminho quente que a D8 protege.** Hoje o
`TabBarView` desmonta a Árvore fora de foco. Como painel permanente, o
`BlocSelector` com `_structureKey` — que **serializa a árvore inteira em string a
cada `emit`** — passa a rodar sempre. **Mitigação exigida na E1:** trocar a chave
de rebuild por algo que não serialize (contagem + ids de estrutura, ou
comparação estrutural barata), e cobrir com o teste de rebuild da D8. Sem isso, a
E1 entrega ergonomia e paga com o desempenho que o item 3b conquistou.

**R-f — dois goldens, duas causas.** A F3 e a E1 regravam
`goldens/canvas_device_mock.png`. **A ordem é F3 → E1**, e a descrição de cada PR
**nomeia a sua causa** no diff visual. Regravação sem citação reprova (régua do
item 39).

## Decisões desta rodada

**Do humano:** **H1** (o incômodo é ver as duas ao mesmo tempo), **H2**
(semântica por zona, sem tecla), **H3** (as duas origens de arraste), **H4**
(colapsar é só ganhar espaço — mantém a A3/D2), **H5** (Árvore à direita,
Propriedades como aba).

**Do PM:** **P8** (`wrapNode` para `single`; affordance escondida só para `none`)
e **P10** (ordem de entrega, com F3 antes da E1) — **ambas aprovadas**. A **P7**
(regra do corpo do nó) ficou **vazia** com o menu da H6, e a **P9** (nó inválido
fora de escopo) foi **recusada** pela H7.

**Assumidas pelo TM, pendentes de confirmação:** **P11** (fresta e menu convivem)
e **P12** (opção impossível aparece desabilitada com o motivo, em vez de
habilitada-e-erro-depois).
