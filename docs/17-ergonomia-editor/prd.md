# PRD — Ergonomia do editor: espaço de tela, grupos e modo preview

> ⚠️ **NÃO APROVADO.** Este PRD é a **proposta de recorte** do PM, escrita para
> ser discutida. Ele depende das respostas **A1–A10** do `specs.md`; enquanto
> elas não chegarem, o que está aqui é hipótese de trabalho, não contrato. O
> contrato do "pronto" só existe depois do "sim" do humano, e o texto abaixo
> muda conforme as respostas.

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
