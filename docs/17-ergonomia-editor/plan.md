# Plano — Navegar funciona no celular, editar funciona no desktop, e o conteúdo cabe nos dois

_Item **41** do roadmap (Marco 4 — Ergonomia do construtor). **Não existe plano de
gaveta**: escopo novo, nascido do pedido do dev humano em 2026-08-15. A matéria-prima é
[`specs.md`](specs.md) + [`prd.md`](prd.md) desta pasta, **mais a evidência de campo de
2026-08-16** (§2.0). Onde este plano divergir do PRD, **este manda**, e o motivo está na
§8._

> **Nota histórica (2026-08-18).** As menções a `/contents/:id/edit` neste documento descrevem a rota do editor à época. Desde o item **46** a rota é `/projects/:projectId/contents/:id/edit` — ver `docs/46-projectid-na-rota-do-editor/`.

> **Regra do "pronto":** `flutter analyze` verde + testes existentes passando. Nunca opinião.
> **Toca backend?** Não — nenhuma linha, em nenhuma fase. **Toca `sdui_core`?** Não.
> **Gate CISO?** Não é obrigatório em nenhuma fase (§4›D3 explica por que a rota de
> preview não abre superfície nova). **0-dep de roadmap:** sim — não antecipa nem
> depende dos itens 24, 26, 28 ou 30.
> **Alvos:** `apps/driva_editor/` — módulos `contents_module`, `projects_module`,
> `editor_module` e `core/`. Nada em `packages/`, nada em `backend/`.

---

## Estado

**Sete fases em `develop`: F1 (#137), F1b (#136), F2 (#135), F4 (#138) e a leva da 4ª
revisão — F4b (#141), F2c (#142) e F2b (#143), mergeadas como stack. A próxima é a F3,
com a status bar do mock dentro (5.1) e a D32 valendo: golden regravado por duas causas =
dois commits.**

**2026-08-16 — plano revisado duas vezes no mesmo dia; duas evidências de campo.** A F2
(rota de preview) **mergeou no PR #135 e está no ar em hml**. A F1 está em execução. A
segunda foto — o **editor** no celular, com o canvas desaparecido — abriu a **F1b**.

As quatro ambiguidades caras do `specs.md` seguem fechadas (A6, A1, A3, A7 — D1 a D4), e
o humano tomou **uma quinta decisão em 2026-08-16**: *"navegar no celular funciona;
editar, não"* (D20). Ela **reabre parcialmente a A1** — de propósito, e com limite
declarado (§4›D20).

**Pré-condição dura, herdada da invariante I6 do `specs.md`: RESOLVIDA em 2026-08-16.** As
fases que tocam arquivos dos itens 38 e 39 (**F3** e **F5**) estavam presas ao E2E daqueles
itens — **o dev humano atestou os dois hoje**, e a F3 está liberada. O que era "F3
bloqueada" agora é só ordem de PR.

| Fase | O que entrega | Dono | PR | Estado |
| --- | --- | --- | --- | --- |
| F1 | **Navegar no celular funciona** — projeto, categorias, lista, busca, diálogos | especialista-apresentacao | **#137** | `[x]` |
| **F1b** | **O editor degrada com dignidade** — abaixo de `compact`, portão com dois caminhos | especialista-apresentacao | **#136** | `[x]` |
| F2 | Rota `/preview/:projectId/:id` — o conteúdo no celular | especialista-apresentacao + especialista-infra | **#135** | `[x]` |
| **F2b** | **Puxar para atualizar no `/preview`** — o gesto no lugar do botão (4.1) | especialista-apresentacao | **#143** | `[x]` |
| **F2c** | **O `/preview` abre sem barra de endereços** — PWA com alvo instalável próprio (4.3) | especialista-infra | **#142** | `[x]` |
| F3 | Piso do editor: overflows do shell + "ajustar à janela" **+ a status bar do mock (5.1)** | especialista-apresentacao | **#153** | `[x]` |
| F4 | Grupos da paleta colapsáveis | especialista-apresentacao | **#138** | `[x]` |
| **F4b** | **O colapso da paleta sobrevive à troca de aba** (1.1) | especialista-apresentacao | **#141** | `[x]` |
| F5 | Painel do editor colapsa numa faixa fina de ícones | especialista-apresentacao | **#155** | `[-]` |
| F6 | O layout do editor é lembrado entre sessões | especialista-dominio + especialista-dados + especialista-apresentacao | **#159** | `[-]` |
| F7 | Modo tela cheia | especialista-apresentacao + especialista-infra | **#160** | `[-]` |
| F8 | E2E manual em homologação, executado e **atestado pelo humano** | qa instrumenta · dev humano atesta | — | `[ ]` |
| F9 | Bateria automatizada + docs vivas | qa | — | `[ ]` |

Legenda: `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída e revisada pelo QA.

**O que mudou na 1ª revisão** (evidência da lista de conteúdos): entrou a **F1**
(navegação em celular), o antigo piso do editor virou **F3**, e as fases seguintes
deslocaram uma casa. **D5** e **D20** nasceram ou foram reescritas; a **D22** corrigiu um
aceite do próprio DoD que era **improvável em homologação** (§4›D22, §8›8).

**O que mudou na 2ª revisão** (evidência do editor): entrou a **F1b**, com as decisões
**D23** (o portão é substituição, não adaptação) e **D24** (de onde o portão tira o
`projectId`). A **cerca 2 da D5** foi desambiguada — ela tinha virado contraditória no
instante em que a F1b nasceu (§4›D5).

**O que mudou na 3ª revisão** (rodada 4 do QA): a **D27** separa os dois limiares da tela
de conteúdos (600 = "é telefone?", 795 = "este cabeçalho cabe?") e devolve a gaveta ao
600 — a tarefa 6 tinha uma frase ambígua minha, e a implementação moveu a gaveta junto com
o cabeçalho. O **caso 7** entrou na §11.0 com forma inédita: aceite que **não errou,
envelheceu**. O §10 devolveu a geometria à máquina e ficou com o humano só o que exige
hardware.

**O que mudou na 4ª revisão (2026-08-17) — o feedback do uso real.** O
[`feedback_rodada_01.md`](feedback_rodada_01.md) trouxe doze pontos em cinco frentes. O dev
humano liberou **quatro** para andar sem discovery, e eles entram assim:

| Frente | Como entra | Por quê assim |
| --- | --- | --- |
| **1.1** — o colapso da paleta morre ao trocar de aba | **F4b**, fase própria | Defeito, barato, 0-dep. A decisão de **onde** o estado passa a morar é a **D28**, e ela não é a óbvia |
| **5.1** — o mock não desenha a status bar | **dentro da F3**, mesmo PR | **Decisão do dev humano**: as duas mexem no mock (F3 no ajuste, 5.1 no chrome desenhado) e agrupar economiza uma rodada de E2E. O preço é um golden com **duas causas** — pago pela **D32** |
| **4.1** — pull-to-refresh no preview | **F2b**, fase própria | Muda o `PreviewCubit`, não só a tela (D30) |
| **4.3** — PWA sem barra de endereços | **F2c**, fase própria | É `web/` e `index.html`, não Dart; e a promessa tem fronteira de plataforma (D31) |

**Fora desta revisão, e de propósito:** **4.2** (a barra de navegação — o dev ainda não
confirmou se é a barra de gestos do Android ou chrome nosso), **5.3** e **1.2** (em
discovery), **2.1/2.2** (encaixam na F5/F6, ainda não decididas) e **3** (travar proporção,
discovery próprio). Nenhuma delas virou tarefa aqui. O **R14** desta revisão, porém,
**alimenta o discovery do 4.2** com uma hipótese medível.

**Por que `F2b`, `F2c` e `F4b` e não `F10`, `F11`, `F12`.** Mesma razão que criou a F1b: a
**F8 é o E2E** e a **F9 é a bateria** — as duas são terminais por construção, e pendurar
fases novas depois delas diria que há trabalho depois do fechamento, o que é falso.
Suficixar no ponto de inserção mantém a adjacência semântica (a F4b continua a F4; a F2b e
a F2c continuam a F2) e **não renumera nada que já foi referido por número em PR**.

> ⚠️ **Este `plan.md` não está em branch nenhum.** A versão viva (D20–D27, tarefas 6–11)
> está **não commitada** na árvore principal; o worktree da F1 carrega uma versão anterior.
> **Não copie este arquivo para o worktree** — o coordenador o leva no PR. Quem editar o
> plano edita **este** caminho.

**Por que a F1b não renumera as fases.** A **F2 já mergeou como PR #135** e é referida
pelo número em histórico de PR e em conversa; a F1 está em execução. Renumerar pela
segunda vez no mesmo dia reescreveria a história de trabalho em voo por ganho cosmético.
A fase nova entra como **F1b**, e a irregularidade no nome é o preço — barato — de os
números anteriores continuarem querendo dizer a mesma coisa que queriam ontem.

---

## 1. Objetivo e recorte

São **dois problemas com o mesmo nome** — "o editor não é responsivo" — e naturezas
opostas. Tratá-los como um só foi o erro que a evidência de campo desfez.

| | **Navegação** (F1) | **Editor** (F1b, F3, F5, F7) |
| --- | --- | --- |
| Telas | home de projetos, detalhe do projeto, categorias, lista de conteúdos, diálogos | workspace, canvas, paleta, inspector |
| Largura que dói | **360–412** (celular na mão) | **360–412** (o canvas some) **e** 1024–1440 (janela de laptop) |
| Sintoma | **tela inutilizável**: texto uma letra por linha, campo cortado, painel comendo 66% | **no celular, o canvas não existe**; no laptop, tela apertada: mock cortado, breadcrumb estourando |
| Natureza da correção | **comportamento por faixa de largura** — a barra lateral vira outra coisa | **substituição** por faixa (F1b: o construtor sai de cena) + mecânica no desktop (`Flexible`, piso, escala) |
| Meta | **funcionar de verdade no celular** | **funcionar bem no desktop e sair com dignidade abaixo disso** |
| Evidência | **foto do aparelho** (§2.0) | **foto do aparelho** (§2.0) + medição no código (§2.3, §2.4) |

**O editor tem duas metas, e elas não se contradizem.** Abaixo de `compact` ele **não
adapta o layout** — ele **cede o lugar** a uma tela que explica e oferece dois caminhos
(F1b, §4›D23). Acima, ele é desktop e é otimizado como desktop. A promessa "editar no
celular, não" continua literal; o que a F1b muda é que "não" passa a ser uma **frase**, em
vez de uma tela quebrada.

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

> **A foto não foi arquivada a tempo e o estado não é mais reproduzível (D33).** O "antes"
> passou a ser a tabela sintoma → causa do `evidencias/rodada_00/README.md`, com arquivo e
> linha de cada defeito. O "depois" está em `evidencias/rodada_01/`.

**Isso reordena o item.** O `specs.md` do PM afirma que o problema é do editor, e essa
leitura estava certa sobre o *que* dói no editor — mas **a tela mais visitada quebra
muito pior**, e num nível diferente: o editor a 1024 fica apertado; a lista de conteúdos
a 412 fica **inutilizável**.

**Segunda foto, mesmo dia, mesmo aparelho, tema claro — o EDITOR.** E é um defeito
**diferente** do primeiro, não a mesma coisa noutra tela:

- **O canvas desaparece por completo.** O painel de Widgets ocupa ~75% da largura; o
  Inspector fica à direita com **todos** os rótulos truncados (`Págin…`, `Usar área
  se…`, `Respeitar o…`, `Respeitar a…`). **O mock do dispositivo não aparece em lugar
  nenhum.**
- Faixa 1 (Salvar / undo / redo) e breadcrumb presentes e legíveis; rodapé "Nenhum
  problema" visível.

Não é "apertado", como o editor a 1024. É **o editor sem a peça que justifica ele
existir**. A mecânica está na §2.2 — e **não** é o `SizedBox` hardcoded da lista.

**Terceira foto: a tela de conteúdos em tema claro, com o mesmo defeito da primeira.**
Isso fecha uma hipótese antes que alguém a persiga: **as causas são de layout, não de
tema.** Nenhuma correção deste item mexe em `EditorColors` nem nas paletas.

> **As três se perderam antes de serem arquivadas (D33).** O `README.md` da
> `evidencias/rodada_00/` registra as três com a causa de cada sintoma no código — e é essa
> causa, não a foto, que os itens 28 e 35-A do DoD passaram a exigir.

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

**Causa B′ — a mesma `Row` do cabeçalho estoura de 600 a 794, com a gaveta já fora de
cena.** Medido pelo QA em 2026-08-16: a **600** faltam `195 px`; a **794**, `0,66 px`; a
**795** já cabe. Ou seja, a gaveta resolve **abaixo** de 600, mas a faixa `600–794` fica
descoberta — a barra lateral volta e o cabeçalho ainda não cabe.

> **A correção não é mais um breakpoint.** A tentação é levar o empilhamento do cabeçalho
> a disparar em 795 e enfiar esse número no `AppBreakpoints`. **Não.** 795 não é uma faixa
> do app: é a largura em que **aquele cabeçalho específico** para de caber, medida no
> conteúdo dele — exatamente como o `topBarActionsFitWidth` da F3 (D5›corolário). O
> cabeçalho ganha o **próprio `LayoutBuilder`** e um token `AppSizes.
> contentPanelHeaderFitWidth`; abaixo disso, empilha. **`AppBreakpoints` continua com dois
> números**, e o vocabulário não é corrompido por um terceiro que não é faixa de nada.
>
> Efeito colateral bom: com o empilhamento governado pelo próprio conteúdo, ele passa a
> funcionar **também** abaixo de 600, e a Causa B deixa de depender de duas regras
> separadas.

**Causa D — o modo "Lista" estoura muito pior, a um toque de distância.** Medido: **610 px
de estouro a 360** com nome de conteúdo longo. O `ViewModeToggle` fica no mesmo cabeçalho,
então o dev chega lá com um toque. Não é caso de borda: é o outro dos dois modos de
exibição da tela, e a `ContentRow` precisa do mesmo tratamento que o cartão — nome em
`Flexible` com `maxLines` e `ellipsis`.

**Causa C′ — o `ContentFormDialog` estoura 216 px, e estoura até a 1440.**
`DropdownButtonFormField` de categoria com nome longo, dentro de um dialog fixo em 380:
falta `isExpanded: true`. **Não é defeito de celular** — é largura-independente, quebra em
qualquer tela. **Pré-existente**, não é regressão da F1. Fica aqui mesmo assim: é o
**mesmo arquivo** que a Causa C abre, é uma propriedade, e o passo 5 do E2E desta fase
abre justamente esse diálogo — deixá-lo de fora seria mergear uma fase cujo próprio
roteiro a reprova.

**Causa E — a Grade nunca esteve limpa, e a verificação anterior errou por método.**
A tarefa 5 da F1 concluiu "Grade adapta, nada a fazer". **Medido depois, está errado:**

| Tela | 370 | 375 | 380 |
| --- | --- | --- | --- |
| Estouro do tile | **7,0 px** | **4,5** | **2,0** |

**375 é iPhone SE e iPhone 8.** É onde o
`SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300)` passa de **1 para 2
colunas** e o tile despenca para ~153 px. **Alargar a tela piora o defeito** — e é por
isso que a verificação passou: ela olhou 360 e 412, e o buraco está entre os dois. Ver
**D25›segundo achado**: a varredura precisa dos **pontos de transição**, não só das bordas.

**Causa F — a Lista ainda estoura de 394 a 460**, mesmo depois da primeira correção:

| Tela | 394 | 412 | 430 | 460 |
| --- | --- | --- | --- | --- |
| Estouro | **19 px** | **14** | **9,6** | **2,1** |

Pega **Pixel (412)** e **Pro Max (430)** — dois dos aparelhos mais comuns. O aceite `6-B`
**ainda não está cumprido**.

**Causa G — o `SlugBadge` some em silêncio de 320 a ~392.** Precisa de ~39 px de chrome
interno e recebe menos; abaixo disso **não trunca, desaparece** — sem faixa e sem erro
(o mecanismo está na **D25**). É a causa que nenhuma ferramenta do projeto detectava.

> **O número não fecha, e a divergência é o achado.** O plano mediu **39**
> (`s10×2 + ícone 14 + s5`); a primeira implementação entregou **`_minWidth = 28`**,
> privado. **Não decido aqui qual é o certo — decido que o número pare de ser digitado.**
> `minimumWidth` vira **público e derivado dos tokens do próprio `build`** do widget; o
> valor que a expressão produzir é a verdade, nos dois lugares, e o plano **para de
> carregar o literal** (DoD 10d, 10e).
>
> **Por que a derivação não fechava sozinha:** o `14` do ícone **não é token**.
> `AppIconSizes` só tem `s18`. Ou seja, a divergência 28 × 39 não é erro de conta — é
> **sintoma de chrome não tokenizado** (Gate 4). Derivar o mínimo **força** a
> tokenização, e é por isso que "derivado" é requisito e não preferência: um mínimo
> derivado de tokens não pode divergir do widget; um mínimo digitado diverge no primeiro
> `s10` que alguém trocar por `s8`.

**O que de fato se comporta bem** (não mexer): a contagem de colunas do delegate, que
adapta sozinha. **O que quebra é o conteúdo do tile depois que ele estreita** — que era a
hipótese original da tarefa 5, e continua sendo a certa; o que faltou foi medir na largura
em que o tile é mais estreito, que **não** é a tela mais estreita.

### 2.2 O editor no celular: o canvas não encolhe — ele **desaparece**

Aqui o `ResizableSplitView` **é** o culpado — ao contrário da §2.1, onde não era. Mas o
mecanismo é o mesmo da Causa B, com um desfecho pior.

`ResizableSplitView.build` monta:

```
SizedBox(280 · esquerda) · ResizeHandle(6) · Expanded(centro) · ResizeHandle(6) · SizedBox(320 · direita)
```

Os filhos **não-flexíveis** somam `280 + 6 + 6 + 320 = 612`, e são medidos primeiro. A 412
px de tela, a sobra para o `Expanded` é `412 − 612 = −200` → **clampada a zero**.

**O `CenterArea` — que carrega a aba Mock E a aba JSON — é construído com largura zero.**
Não é "pequeno": é **inexistente**. É por isso que na foto não há canvas em lugar nenhum, e
por isso que o defeito não se parece com o do editor a 1024 (lá o mock aparece cortado;
aqui não aparece).

A conta de onde cada peça fica, a 412 px:

| Filho | Ocupa | Visível na tela |
| --- | --- | --- |
| Paleta | `[0, 280]` | inteira — **68% da tela** (a 360 px: **78%**, que é o "~75%" da foto) |
| Handle | `[280, 286]` | sim |
| **Centro (canvas + JSON)** | `[286, 286]` | **largura zero — nada** |
| Handle | `[286, 292]` | sim |
| Inspector | `[292, 612]` | **só até 412 — 120 dos 320 px** |

> **O detalhe que evita um conserto errado:** os rótulos truncados do Inspector
> (`Págin…`, `Usar área se…`) **não são um bug do Inspector**. Ele é medido corretamente
> a 320 px e desenha os rótulos para 320; o que acontece é que **200 px dele ficam fora
> da tela**, cortados pelo overflow da `Row`. A 320 px os mesmos rótulos cabem. **Não
> mexa no Inspector** — é a diferença entre este caso e o da §2.1›Causa B, onde o filho
> faminto era um `Text` que ainda pintava, e pintava na vertical.

**Por que a D14 não resolve isto.** A rolagem horizontal da D14 (F3) faria o canvas ficar
*alcançável por arrasto lateral* — o que é degradação aceitável numa janela de desktop
estreita, e é resposta errada para um celular: pedir que o dev role para achar o
construtor não conserta o fato de o construtor não caber. **Por isso a F1b existe, e por
isso ela é substituição, não ajuste** (§4›D23). A D14 continua valendo na faixa entre o
limiar `compact` e o piso do split view (§6›Interação D14 × D23).

### 2.3 O chrome fixo do editor come o centro, sempre

`ResizableSplitView` monta `SizedBox(280) · handle(6) · Expanded(centro) · handle(6) ·
SizedBox(320)`. **612 px de chrome fixo**, em qualquer tela. O centro fica com
`viewport − 612`, e o widget não tem `LayoutBuilder`: não sabe o tamanho da janela.

### 2.4 O mock não cabe, e o zoom é manual

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

### 2.5 Três overflows do editor que já estão no ar

1. **Breadcrumb (faixa 2).** `AppShellBreadcrumbBar` monta uma `Row` **sem nenhum filho
   flexível**, e o `CrumbLabel` pede `overflow: TextOverflow.ellipsis` num `Text` de
   largura ilimitada — a elipse **nunca dispara**.
2. **Faixa 1.** `AppShellTopBar` monta `wordmark · Spacer · 4 ações · status · tema`. O
   `Spacer` é o único elemento flexível.
3. **Workspace.** Abaixo de 612 px o `Row` do split view estoura. Medido pelo QA a
   **601: `A RenderFlex overflowed by 11 pixels on the right`** — e o `CenterArea`
   clampado a zero (§2.2).
4. **`canvas_toolbar.dart` — descoberto pelo QA em 2026-08-16, medindo a F1b.** A **1024**
   a toolbar do canvas estoura **103 px**. É defeito **pré-existente**, anterior a este
   item, e ninguém tinha medido: a toolbar monta `SegmentedButton` de 3 presets + `Spacer`
   + dimensões + 3 controles de zoom, tudo sem filho flexível além do `Spacer`. A F3 já
   ia mexer nesse arquivo (botão de ajustar) — **agora mexe sabendo o número.**

**A soma disto é a faixa 600–~1280, defeituosa e conhecida.** Nenhum aceite deste plano
pede print dela antes da F3 (§5›F1b›7-E). A F3 é a dona.

### 2.6 Nada do layout do editor é lembrado

O arraste do splitter existe, mas o estado é `State` local: **some no refresh e a cada
navegação**. O Inspector colapsa seções desde o item 9b (`PropSection`, com
`initiallyExpanded`), mas **reabre tudo** a cada troca de nó e a cada refresh. Hoje a
**única** chave persistida no app é `preferences.theme_mode`.

### 2.7 Não há caminho nenhum para o aparelho

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

1. **[ajustada em 2026-08-17]** O editor nunca **usa** o enum do kernel:

   ```
   grep -rn "SduiBreakpoint" apps/driva_editor/lib | grep -vE ':[0-9]+:\s*///?'
   → zero
   ```

   **Por que o segundo `grep` entrou.** A redação anterior era literal (`= zero`, sem
   filtro) e produzia um absurdo: **a cerca proibia _nomear_ aquilo que ela proíbe
   _importar_**. O único lugar do repositório onde o leitor precisa da palavra exata é
   justamente o doc do `app_breakpoints.dart`, que existe para explicar **por que aquele
   enum não entra** — e ele era obrigado a dizer "o enum de faixa do spec SDUI". Frase
   vaga envelhece pior que nome próprio: daqui a seis meses ninguém sabe a qual símbolo
   ela se referia, e a decisão vira folclore.

   **A cerca mede _uso_, não _menção_.** Comentário (`//` e `///`) é prosa e fica de fora.

   **Ponto cego conhecido, aceito:** comentário de fim de linha (`final x = 1; //
   SduiBreakpoint`) não é filtrado e dispararia falso positivo. Se acontecer, mova o
   comentário para a linha de cima — é correção trivial, e vale mais que um regex frágil
   tentando tokenizar Dart com `grep`.

2. **[desambiguada em 2026-08-16, quando a F1b nasceu]** A redação anterior era *"nenhum
   arquivo de `editor_module` consulta `AppBreakpoints`"*, e ela **virou contraditória no
   instante em que a D23 apareceu**: o portão da F1b precisa do limiar, e ele mora no
   `editor_module`. Deixá-la assim seria pior do que não ter cerca — uma cerca que o
   próximo PR viola legitimamente é uma cerca que todo PR seguinte viola por costume.

   **A cerca nunca protegeu a palavra `AppBreakpoints`. Ela protege esta frase:** *o
   construtor não muda de layout por faixa de largura.* O portão não muda o layout do
   construtor — ele **substitui** o construtor (D23). Uma porta, e atrás da porta o
   construtor é cego a faixa.

   A cerca passa a ser **dois greps**, os dois de máquina:

   ```
   # (a) o limiar entra no módulo por UMA porta, e só por ela
   grep -rl "AppBreakpoints" apps/driva_editor/lib/modules/editor_module
   → exatamente: .../editor_module/presentation/editor/page/editor_viewport_gate.dart

   # (b) a UI do construtor nunca vê faixa nenhuma
   grep -rn "AppBreakpoints" \
     apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/
   → zero
   ```

   O grep **(b)** é o que carrega a intenção: canvas, paleta, inspector e árvore vivem
   sob `presentation/editor/widgets/`. Se o limiar nunca chega lá, o construtor **não tem
   como** adaptar-se por faixa — que é exatamente o que a D20 prometeu. O grep **(a)** é o
   que impede a porta de virar corredor.

   **Resolução do conflito `add/add` em `app_breakpoints.dart` (F1 × F1b) — decidida
   aqui para não ser julgada no merge.** Os dois worktrees criam o arquivo. A **API é
   idêntica** (`compact = 600`, `medium = 1024`, `isCompact`) e o `theme.dart` é byte a
   byte igual: o merge é limpo em tudo, **menos no doc-comment**.

   O doc da **F1** termina com *"e `editor_module` não consulta este arquivo (D1: o editor
   mira desktop)"* — frase **que a F1b torna falsa**. Se o merge aceitar a versão da F1 em
   silêncio, o repositório passa a documentar o **contrário** da cerca 2a.

   **Vence a versão da F1b**, e o doc carrega esta verdade, não a anterior:

   > O `editor_module` consulta este arquivo em **exatamente um** lugar —
   > `editor_viewport_gate.dart` —, e é substituição, não adaptação: abaixo de `compact` o
   > construtor não é construído. A UI do construtor
   > (`presentation/editor/widgets/`) nunca vê faixa nenhuma.

   Quem resolver o conflito **não escolhe**: aplica isto. A frase da F1 não é "a versão
   antiga" — é uma afirmação que deixou de ser verdadeira entre um PR e outro, e ficou
   registrada por acaso de cronologia.

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

A conta da §2.4 hoje mora espalhada no `build` da `DeviceFrame`. Se o ajuste refizer a
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

> ⚠️ **Necessária, mas insuficiente — ver D25.** As três camadas acima foram construídas
> sobre **um único sinal**: o report de overflow do `RenderFlex`. A D22 perguntou *onde*
> esse sinal é visível. Não perguntou *se ele é emitido*. Existe uma classe de defeito —
> o widget que **colapsa a zero e some** — em que **as três camadas ficam cegas ao mesmo
> tempo**. A D25 corrige a régua.

### D23 — **[nova, humano, 2026-08-16]** Abaixo de `compact`, o editor **cede o lugar** — não se adapta

Diante da segunda foto (§2.0, §2.2), o humano decidiu: o editor **não** vira mobile —
arrastar widget em 412 px é outro produto, e "editar no celular, não" continua de pé. Mas
ele **degrada com dignidade**: abaixo do limiar `compact`, mostra uma tela que explica que
o construtor pede janela maior, com **dois caminhos**:

- **"Ver conteúdo"** → a rota `/preview/:projectId/:id` (F2, já no ar).
- **"Voltar aos conteúdos"** → o detalhe do projeto.

**A palavra que sustenta a decisão é _substituição_, não _adaptação_.** É ela que
mantém a D20 literalmente verdadeira e a cerca da D5 coerente:

| | Adaptação (o que **não** fazemos) | Substituição (o que fazemos) |
| --- | --- | --- |
| O que acontece com o construtor | ele se reorganiza para caber | ele **não é construído** |
| Onde o limiar é consultado | espalhado pelos widgets do construtor | **um arquivo**, antes do construtor existir |
| O que a D20 vira | "editar no celular, mais ou menos" | "editar no celular, não — e aqui está o que dá para fazer" |

**Onde o portão mora:** `EditorViewportGate`, consultado **no topo do
`EditorPage.build`**, antes do `BlocBuilder`. Abaixo do limiar, **nada** do editor é
construído — nem o workspace, nem o spinner de carregamento, nem a árvore de widgets do
construtor. Isso não é otimização: é a afirmação arquitetural em código. Um portão
colocado *dentro* do `EditorWorkspace` seria adaptação disfarçada de substituição.

**O aviso só é um caminho porque a F2 chegou antes — e isso foi sorte, não previsão.** A
F2 foi antecipada na 1ª revisão por um motivo diferente (de-risking de hardware: era a
única fase cujo E2E exige aparelho físico e homologação real, §8›3). O efeito colateral é
que, quando a segunda foto chegou, **já existia para onde mandar o usuário**. Sem a rota
`/preview`, esta tela seria uma porta fechada com um texto educado. Fica registrado como
**consequência**, não como acerto de planejamento — plano que se atribui sorte depois vira
plano em que ninguém confia.

### D24 — **[nova]** O portão tira o `projectId` da mesma fonte que o editor já usa

Os dois botões precisam do `projectId`, e a rota do editor (`/contents/:id/edit`) **não o
carrega**. A tentação é inventar mecanismo novo. Não há necessidade: o
`EditorLoadFailure` do `editor_page.dart` **já resolve exatamente isto hoje**, com
`context.read<EditorCubit>().projectId` — valor que veio do `ProjectScope` no
`pageBuilder`. O portão usa a mesma fonte, e o `BlocProvider` está em escopo porque é
montado no `pageBuilder`, acima do `build`.

**A limitação herdada, escrita para não ser confundida com regressão da F1b:** um **deep
link do editor aberto frio** (alguém compartilha `/contents/:id/edit` e o aparelho nunca
passou pela tela do projeto) cai no `DEFAULT_PROJECT_ID` do build, e os dois botões
apontariam para o projeto errado. **Isso já é verdade hoje**, no botão "Voltar para o
projeto" da tela de falha — a F1b não cria o problema, herda. É a família da D18 e do item
26, e está fora (§12). **Limitação fechada pelo item 46 em 2026-08-18:** a rota virou
`/projects/:projectId/contents/:id/edit` e o deep link frio já chega com o projeto certo.

O caminho real — lista → tocar num conteúdo → portão — tem o `ProjectScope` quente, e é
**esse** o caminho que o aceite percorre (item 35-C do DoD). Um aceite que testasse o deep
link frio estaria medindo o item 26, não esta fase.

### D25 — **[nova, 2026-08-16]** "Sem faixa amarela" **não é** critério de ausência de overflow. A régua é **geometria medida**

Achado do QA na rodada 2 da F1, e ele **derruba a premissa da D22**, escrita no dia
anterior.

**O mecanismo — sem ele a regra vira superstição.** `RenderFlex.paint`, no Flutter:

```dart
if (!_hasOverflow) { defaultPaint(context, offset); return; }
if (size.isEmpty) { return; }            // ←  a saída antecipada
assert(() { paintOverflowIndicator(...); return true; }());
```

A **mensagem** de overflow (`A RenderFlex overflowed by N pixels`) é emitida por
`paintOverflowIndicator`, que é chamado **de dentro do `paint`**. Um `RenderFlex` que
colapsa para tamanho zero cai no `return` da segunda linha: **não pinta a faixa e não
emite o erro.**

**A consequência é pior do que "a D22 tinha um furo": as três camadas da D22 ficam cegas
ao mesmo tempo**, porque as três se apoiavam no mesmo sinal:

| Camada da D22 | O que ela via | Neste defeito |
| --- | --- | --- |
| Sintoma (release) | nada cortado na borda | **cego** — não há nada cortado; há algo **ausente** |
| Indicador (debug local) | a faixa listrada | **cego** — o `paint` retorna antes de desenhá-la |
| Máquina (`FlutterError.onError`) | o erro de overflow | **cego** — o erro nunca é emitido |

A D22 perguntou **onde** o sinal é visível. Não perguntou **se ele é emitido**. Era a
pergunta certa pela metade.

**O caso medido.** O `SlugBadge` precisa de **39 px** só de chrome interno
(`padding 20 + ícone 14 + vão 5`). Abaixo disso ele **não trunca: ele some** — e em
silêncio. Largura renderizada:

| Tela | 320 | 360 | 375 | 412 | 480 | 700 |
| --- | --- | --- | --- | --- | --- | --- |
| Badge | **3,9 px** | **13,9** | **17,6** | **26,9** | 43,9 | 91 (intrínseco) |

**De 320 a ~392 o badge está na árvore, ocupa espaço e não mostra nada.** A faixa inteira
vinha sendo dada como limpa.

> **Por que isto é pior que overflow, e não apenas diferente:** overflow é feio e chama
> atenção. **Um widget que some não deixa buraco — deixa a tela parecendo correta.** Passa
> na revisão visual, passa na faixa listrada, passa no `FlutterError`. É o defeito perfeito:
> invisível para todas as ferramentas que temos, inclusive para o olho.

**A régua nova: o widget cabe no seu mínimo?** Em três níveis, e o do meio é o que pega:

1. **O widget declara o mínimo.** Todo widget com chrome interno fixo (padding + ícone +
   vão) expõe o próprio `minimumWidth`, derivado dos tokens — não um número solto no teste.
2. **O teste mede a geometria renderizada.** `tester.getSize(find.byType(X)).width >=
   X.minimumWidth`, nas larguras de borda. **É esta a camada que enxerga.**
3. **O E2E observa presença, não ausência de banner.** O aceite é "**o elemento aparece no
   print**", nunca "não apareceu faixa".

**Escopo, para a regra não virar infinita.** Precisam declarar mínimo e ser medidos os
widgets com **chrome interno fixo que podem ser espremidos**: badges, chips, pílulas,
botões com ícone + texto, linhas com ícone + rótulo. **Não** todo widget da árvore.

**Segundo achado de método, no mesmo pacote: o pior caso não é a tela mais estreita.**
A Grade prova. `SliverGridDelegateWithMaxCrossAxisExtent(300)` vira de 1 para 2 colunas
por volta de 375, e o tile **encolhe para ~153 px ao a tela alargar**:

| Tela | 370 | 375 | 380 |
| --- | --- | --- | --- |
| Estouro do tile | **7,0 px** | **4,5** | **2,0** |

**375 é iPhone SE e iPhone 8.** Alargar de 370 para 375 **piora** o defeito — o número não
é monotônico na largura. Uma varredura que testasse só 360 e 412 passaria por cima dele,
que é exatamente o que aconteceu quando a Grade foi dada como limpa (§2.1).

**Regra derivada:** a varredura de larguras inclui **os pontos de transição** (onde uma
grade muda de contagem de colunas, onde um `Wrap` muda de linha), não só o mínimo e o
máximo. Ponto de transição se **calcula** a partir do delegate, não se adivinha.

### D26 — **[nova, 2026-08-16]** `AppBreakpoints` só contém faixa que alguém consulta

`AppBreakpoints.expanded = 1024` **nasceu morto**: ninguém o lê. A F3 tampouco vai lê-lo —
o trabalho dela é mecânico (`Flexible` nos crumbs, piso do split view, escala calculada) e
o único limiar que ela cria é o `topBarActionsFitWidth`, que **não é faixa** (D5›corolário).

**Decisão: `expanded` sai do código.** O número 1024 continua registrado **aqui, na D5**,
onde não apodrece e não vira dead code — e o item 30, quando precisar dele, o lê daqui com
a cerca da D5 valendo (mesmos números, sem importar o enum do kernel).

**O princípio é o mesmo que manteve o 795 fora**, e vale enunciá-lo uma vez para os dois
casos: **`AppBreakpoints` não é um catálogo de números redondos.** Entra faixa que governa
comportamento e que alguém consulta. `795` ficou de fora por não ser faixa; `1024` sai por
não ter consumidor. Constante sem leitor é documentação disfarçada de código — e
documentação disfarçada de código é a que ninguém atualiza.

### D27 — **[nova, 2026-08-17]** São **dois** limiares na tela de conteúdos, e cada um responde a uma pergunta diferente

O QA achou que a tela ficou com dois números vivos: **600** governando só a data
(`content_row_body.dart:39`) e **795** governando gaveta **e** cabeçalho
(`project_detail_page.dart:116`). Dois limiares sem explicação viram mistério em duas
semanas, então esta decisão os separa e diz o que cada um significa.

**Primeiro, o que aconteceu.** A tarefa 6 da F1 dizia que o cabeçalho ganha limiar próprio
e *"substitui o gatilho `compact` da tarefa 3"* — **tarefa 3 era o cabeçalho; tarefa 2 era
a gaveta.** A implementação leu a frase de forma mais larga e moveu **a gaveta também**
para 795. **A ambiguidade é minha**, e o aceite 6 pegou o desvio — que é o sistema
funcionando, não o aceite falhando.

**Decisão: a gaveta volta para `AppBreakpoints.compact` (600); o cabeçalho fica com
`AppSizes.contentPanelWideHeaderFitWidth` (795).** Não por simetria com o texto antigo —
porque são perguntas distintas, e fundi-las apaga a distinção que a D5 existe para
proteger:

| | `AppBreakpoints.compact` = **600** | `AppSizes.*FitWidth` = **795** |
| --- | --- | --- |
| A pergunta que responde | **"isto é um telefone?"** | **"este widget cabe?"** |
| Natureza | decisão de **produto**, por faixa | **geometria**, medida no próprio conteúdo |
| Governa | o que a tela **escolhe mostrar**: barra lateral vira gaveta (D21), `UpdatedAt` some (`content_row_body.dart`) | como um widget **se arranja**: o cabeçalho empilha |
| De onde vem o número | Material 3, alinhado ao item 30 (D5) | medição: a 794 faltam 0,66 px |
| Quem mais pode consultar | qualquer tela de navegação | **só** o widget que o mediu |

**Por que a gaveta não deve seguir o 795.** 795 não é largura de telefone — é janela de
desktop pequena ou tablet deitado. A 700 com barra lateral o painel de conteúdos ainda
recebe 427 px, que é uma tela de duas colunas perfeitamente usável **desde que o cabeçalho
empilhe** — e ele empilha, pelo próprio limiar. Mandar a gaveta para 795 tira a barra
lateral de larguras em que ela cabe bem, e estica a decisão do humano (D20/D21: *"em faixa
`compact`"*, isto é, celular) para um território que ele não decidiu.

**O teste para saber em qual dos dois um número novo entra:** *se eu trocar a fonte ou o
ícone deste widget, o número muda?* Se muda, é `AppSizes` e pertence ao widget. Se não
muda, é faixa, e aí a pergunta seguinte é se **o produto** decidiu algo para aquela faixa.

### D28 — **[nova, 2026-08-17]** O colapso da paleta sobe para o `State` do `LeftPanel`. **`AutomaticKeepAliveClientMixin` está fora — e o motivo não é o que parecia**

O defeito (1.1) está medido: `_collapsedCategories` é um `Set<String>` no
`_WidgetPalettePanelState` (`widget_palette_panel.dart:19`), e o `WidgetPalettePanel` é o
**primeiro filho do `TabBarView`** de `left_panel.dart:30`. `TabBarView` só constrói a
página corrente: ir à Árvore desmonta a paleta e mata o set.

Duas saídas, e a diferença entre elas **não** é a que se supôs no levantamento.

**A hipótese que fui verificar: keepAlive ligaria a serialização da árvore no caminho
quente.** A aba Árvore é o **segundo** filho do mesmo `TabBarView`, e ela carrega um
`BlocSelector` (`left_panel.dart:33-39`) cuja `selector` chama `_structureKey(root)` — um
percurso recursivo que escreve a árvore inteira num `StringBuffer` **a cada `emit` do
`EditorCubit`**. Hoje esse custo só existe enquanto a aba Árvore está visível, porque fora
dela o `BlocSelector` **não está montado**. É o caminho que a **D8** protege.

**A hipótese está certa no mecanismo e errada na magnitude.** Medido — não estimado —
replicando `_structureKey` byte a byte e rodando no **Dart VM (JIT)**, 20.000 repetições
após aquecimento:

| Nós na página | Tamanho da chave | Custo por `emit` | Fração de um frame de 60 fps (16.667 µs) |
| --- | --- | --- | --- |
| 40 | 754 B | **9,4 µs** | 0,06 % |
| 120 | 2,2 KB | **28,0 µs** | 0,17 % |
| 400 | 7,5 KB | **88,0 µs** | 0,53 % |
| 1200 | 22,4 KB | **275 µs** | 1,6 % |

A comparação de strings que o `BlocSelector` faz depois custa **0,01 µs** — irrelevante.
_Ressalva honesta do método: é VM JIT nativa, não `dart2js` no Chrome. Vale como **ordem
de grandeza**, e a ordem de grandeza é: para uma página realista (dezenas de nós), manter a
árvore montada custaria **microssegundos e ~2 KB de lixo por tecla digitada**. É
desperdício, não é catástrofe._

**Então o desempate não é desempenho — e dizer isso é o ponto.** Um plano que
justificasse a decisão com "seria lento" estaria fazendo exatamente o que a **D25** proíbe:
afirmar sem medir. Medi. Não é lento. **A decisão se sustenta em duas razões estruturais,
e as duas são verificáveis:**

1. **keepAlive não sobrevive ao colapso da F5.** A F5 troca o painel esquerdo por uma faixa
   fina de ícones — o subtree inteiro sai da árvore, `State` e mixin junto. O dev
   reabriria o painel e encontraria **os quatro grupos abertos de novo**: a mesma queixa
   do 1.1, uma fase depois, agora com uma correção instalada que parece cobri-la. Consertar
   agora de um jeito que quebra na F5 é pior do que não consertar, porque a segunda vez
   não é lida como defeito novo.
2. **Estado em folha é estado que a F6 não alcança.** A F6 persiste **quatro** clientes, e
   os grupos da paleta são um deles. Enquanto o set morar no `State` do painel, a F6 tem
   de subi-lo de qualquer forma — ou seja, o trabalho da F4b é trabalho da F6 antecipado,
   não trabalho jogado fora. Com keepAlive, é jogado fora.

**A cerca que a decisão instala** (é grep, não print): `grep -rn
"AutomaticKeepAliveClientMixin\|wantKeepAlive" apps/driva_editor/lib` = **zero**. Hoje já
é zero; a cerca existe para que continue sendo, porque a linha que ligaria o custo da
tabela acima é **uma linha** e ninguém a associaria ao `EditorCubit`.

**Onde exatamente o estado passa a morar, e por que não mais acima.** No `State` de um
`LeftPanel` que vira `StatefulWidget`, como um `ValueNotifier<Set<String>>` passado ao
`WidgetPalettePanel` pelo construtor. **Não** mais acima, e a razão é a **R5**:
`EditorWorkspace.build` roda a **cada `emit`** (é o braço `EditorReady()` do `switch` em
`editor_page.dart:96`), e o que impede isso de reconstruir o painel esquerdo é o
`const LeftPanel()` de `editor_workspace.dart:35` — instância idêntica, Flutter
curto-circuita. Descer o notifier de cima **mata esse `const`** e passa a reconstruir
`TabBar` + `TabBarView` + paleta a cada tecla digitada no Inspector. O `const` do
`LeftPanel` é infraestrutura de desempenho, não estilo.

Corolários:

- O notifier **sempre recebe um `Set` novo** (`notifier.value = {...atual}` com a mudança).
  `ValueNotifier` compara por `==`, e `Set` não tem igualdade de valor: mutar o mesmo
  conjunto no lugar **não notifica**, e o sintoma seria "o chevron não vira".
- O `ValueListenableBuilder` envolve **só a lista de grupos**, não o `build` do
  `LeftPanel` — mesma disciplina da D8›R5, um andar abaixo.
- **A busca (`_query`) fica onde está, e isso é decisão, não esquecimento.** Filtro é
  efêmero: voltar da Árvore para uma paleta ainda filtrada, sem lembrar por quê, é pior do
  que voltar para uma paleta limpa. Grupos são **hábito**; busca é **momento**. Quem
  implementar não deve subir os dois "por simetria".
- **A F5 move este notifier e a aba corrente juntos** para o `EditorLayoutController`, numa
  mudança só — ela já precisa expor a aba corrente (§5›F5, aceite 26).

### D29 — **[nova, 2026-08-17]** A status bar do mock é **overlay** e ocupa **exatamente** `safeAreaTop` — desenhar não pode mover o conteúdo

O pedido (5.1) é pedagógico e o argumento do dev é o melhor da rodada: o
`DevicePreset.safeAreaPadding` **já** injeta o recuo no `MediaQuery`
(`device_frame.dart:92-100`), o `SafeArea` do conteúdo **já** o respeita, e o resultado é
uma **faixa vazia sem causa visível**. Falta desenhar quem ocupa o espaço.

**A armadilha, e ela é de uma linha.** A leitura natural — "põe uma barra no topo" — é
`Column(children: [StatusBar(), Expanded(child: conteúdo)])`. Isso **conta o recuo duas
vezes**: o `MediaQuery.padding` já reservou `safeAreaTop`, e a `Column` reserva de novo. O
conteúdo desce o dobro, e o sintoma é "o `SafeArea` ficou exagerado" — que ninguém liga à
causa.

**Decisão: a status bar entra na mesma camada do `CameraCutout`** (`device_frame.dart:104-108`
— `Positioned.fill` + `IgnorePointer`, dentro do `ClipRRect` da tela), com altura fixada em
`device.safeAreaTop`. Ela **pinta sobre** o espaço já reservado; não participa do layout do
conteúdo. Simétrico embaixo: o indicador de home ocupa `device.safeAreaBottom`, que é o que
torna aquele recuo visível também.

Corolários:

- **O relógio é fixo, não `DateTime.now()`.** Um relógio vivo torna o golden do
  `canvas_panel` não-determinístico e ele quebraria a cada minuto. Rótulo em token, valor
  `9:41`. _Se o humano preferir hora real, o preço é tirar o relógio do recorte do golden —
  veto barato, mas é veto, não ajuste._
- **Um desenho só para os três presets.** O objetivo é explicar o `SafeArea`, não emular
  iOS e Android fielmente. O `notch` (`pill` × `punchHole`) continua governando **só** o
  recorte da câmera, que segue por cima.
- **Gate 4 sem exceção:** cor, altura, tamanho de ícone e o rótulo do relógio vão para
  `core/theme/device_mock_colors.dart` (que já existe) e `app_sizes.dart` — nada cru no
  widget.
- **Isto não tem relação com o 4.2.** Aquele é a barra do **aparelho real** na rota
  `/preview`, e está pendente de confirmação do dev. Este é chrome desenhado dentro do
  mock, no editor.

> ⚠️ **Refinamento de 2026-08-16 — a barra é transparente, e o Gate 4 vale só para os
> ícones.** O dev pediu a status bar com um objetivo que esta decisão não entregava:
> **prever contraste**. *"Imagina se eu coloco um background preto? todos textos sumiriam e
> eu só perceberia em HML."* Uma barra pintada com fundo de token fica **sempre legível no
> mock — inclusive quando no aparelho ela sumiria**: ela não previria o problema, o
> mascararia. A barra passa a **não pintar fundo**; desenha sobre o fundo real da página, e
> só os ícones e o relógio consomem token.
>
> **E o dev está enganado sobre o `SafeArea`, o que precisa estar escrito aqui porque a
> conclusão errada é natural:** o `safeArea` do 8f governa o **recuo**, não a cor dos ícones
> do sistema. Quem governa é o `SystemUiOverlayStyle` (`statusBarIconBrightness` no Android,
> `statusBarBrightness` no iOS), e ele tem **zero ocorrências** no kernel, no renderer e no
> editor. Nenhuma combinação das props existentes de `safeArea` resolve o caso do fundo
> preto. Isso virou o **item 43 do roadmap** — e é dele que a cor dos ícones desta barra
> passará a vir. Até lá, a barra do mock desenha os ícones no token, e o que ela prova é
> **onde** a barra fica, não **como** ela ficará.

### D30 — **[nova, 2026-08-17]** O gesto substitui o **botão**, não a **frase** — e recarregar não pode custar o que está na tela

O pedido (4.1) é *"um botão pra atualizar que incomoda; talvez um simples pushtorefresh
resolva"*. Duas coisas não podem sair junto com o botão.

**Primeira: a frase da D4.** A D4 é decisão travada do humano — *"o preview mostra o último
salvo, e diz isso na tela"*. Ela obriga a **dizer**, não a **ter um botão**. O carimbo
continua visível e permanente; o que sai é a metade `· toque para atualizar`, que era a
afordância. _Achado colateral, e o dev precisa saber: o **aceite 12 da F2** exige "Último
salvo" legível na foto, e o código mergeado escreve `Verificado às HH:MM` — a frase que o
aceite pedia **nunca existiu**. É um caso 7 da §11.0 do outro lado do espelho: o aceite não
envelheceu, ele passou sem ser conferido. A F2b acerta a cópia como parte da fase._

**Segunda: o conteúdo que está na tela.** `PreviewCubit.load()`
(`preview_cubit.dart:20`) emite `PreviewLoading()` antes de buscar, e o `switch` da
`preview_page.dart:61-70` troca a tela por um `CircularProgressIndicator` centralizado.
Ligado a um `RefreshIndicator`, isso dá: o dev puxa, o conteúdo **some**, aparece um spinner
de tela cheia por cima do spinner do gesto, e o conteúdo volta. É pior do que o botão.

**Decisão:** nasce um `Future<void> refresh()` ao lado do `load()`. `load()` é a carga
fria e continua passando por `PreviewLoading`. `refresh()` **não emite `Loading`** —
mantém o `PreviewReady` corrente na tela e devolve o `Future` que o
`RefreshIndicator.onRefresh` aguarda.

**E o erro no `refresh()` não derruba o conteúdo.** Sem rede, `load()` levaria a tela para
`PreviewFailure` — o gesto "atualizar" viraria "perder o que eu estava vendo", que é a pior
troca possível num celular. No `refresh()`, a falha **reemite o `PreviewReady` anterior** e
sinaliza o erro à parte, **sem** mexer no carimbo. Isso dá três estados **visualmente
distintos**, que é o que a §11.0 cobra:

| O que aconteceu | Conteúdo | Carimbo | Sinal de erro |
| --- | --- | --- | --- |
| Buscou e havia mudança | **muda** | **muda** | — |
| Buscou e não havia mudança | igual | **muda** | — |
| Falhou | igual | **não muda** | **aparece** |

**O carimbo é o único sinal do caso do meio**, e é por isso que ele não pode sair da tela:
sem ele, "puxei e nada aconteceu" e "puxei e falhou" são o mesmo print.

### D31 — **[nova, 2026-08-17]** O `/preview` é um **segundo alvo instalável**, com `scope` próprio — e a promessa "o link abre limpo" é **Android**

O pedido (4.3) é abrir o preview sem barra de endereços. O caminho é PWA, e a pergunta que
o plano precisa fechar é: `start_url` própria, ou um alvo instalável separado?

**São a mesma pergunta, e a resposta vem do `scope`, não do `start_url`.** Um documento tem
**um** manifest. O `web/manifest.json` de hoje é o template intocado do Flutter
(`name: "driva_editor"`, `start_url: "."`, `description: "A new Flutter project."`) e o
`index.html` o referencia numa linha estática (`index.html:33`). Instalar a partir de
`/preview/...` com esse manifest instala **o editor**.

**Por que o `scope` decide.** Num app instalado no Android, um link **dentro do `scope`**
aberto de qualquer outro aplicativo abre **no app instalado**, sem barra de endereços — que
é literalmente o gesto do dev ("mando a URL para o meu celular e toco"). Se o `scope` fosse
`/`, o app capturaria **todos** os links do editor, inclusive os de trabalho no desktop.
Com `scope: "/preview"`, só as URLs de preview são capturadas.

**Decisão: um segundo manifest** (`web/preview_manifest.json`) com `scope: "/preview"`,
`display: "standalone"`, `id` próprio e nome próprio, **selecionado no parse do documento**
por um script inline no `index.html` que troca o `href` do `<link rel="manifest">` quando
`location.pathname` começa com `/preview`. O SPA serve o mesmo `index.html` para todas as
rotas, e o navegador lê o manifest no parse — antes de o Flutter subir. Sem Dart, sem
acoplamento com o `go_router`, sem backend.

**O ponto fraco é o `start_url`, e ele é declarado, não escondido.** A URL de preview tem
`:projectId/:id`; `start_url` é estática. Fica `"/preview"`, e a rota `/preview` **sem
parâmetros** ganha uma tela curta — "abra um conteúdo pelo editor para pré-visualizar
aqui", com um caminho para a lista de projetos. Tocar no ícone da tela inicial não é o
caminho principal (o caminho principal é o link), mas **não pode dar em 404**, que é o que
aconteceria se `start_url` apontasse para uma rota que exige ids. _A alternativa — lembrar
o último preview aberto no aparelho — exige persistência e vira uma pilha de repositório
por conforto. Fica registrada na §12, não aqui._

**A fronteira de plataforma, e ela precisa estar no aceite:** **iOS não captura links.** No
Safari, um link sempre abre no Safari, mesmo com o app na tela inicial. No iPhone o dev tem
`display: standalone` **ao abrir pelo ícone**, e barra de endereços **ao abrir pelo link**.
No Android tem os dois limpos. Um aceite que não nomeie a plataforma passa no aparelho
errado e mente.

> ⚠️ **Corrigido em 2026-08-16, depois do primeiro teste de campo.** A troca do `href` por
> script **perdia a corrida**: o Chrome começa a processar o `<link rel="manifest">` no
> instante em que o parser o insere, e quem instalava a partir do `/preview` recebia o alvo
> do **editor** (`scope: "/"`) — o oposto exato do que esta decisão desenhou. O link passou
> a ser **criado** pelo script, sem href errado no documento em momento nenhum.
>
> **E o aceite desta decisão era cego para o defeito.** "Abriu sem barra de endereços" é
> verdade **também** com o app errado instalado, porque `scope: "/"` cobre `/preview`
> igualmente — o print do cenário quebrado é idêntico ao do cenário correto. O aceite passa
> a ser o **nome embaixo do ícone**: `Preview` (certo) contra `driva` (o `short_name` do
> editor). É mais um caso da §11.0, e o de forma mais cara: um aceite que **não pode
> falhar** não é aceite.

### D32 — **[nova, 2026-08-16]** Golden regravado por **duas** causas = **dois commits**, e o discriminador é `git show --stat`

A F3 e a 5.1 entram no mesmo PR por decisão do humano (economizar uma rodada de E2E). O
preço é concreto: `goldens/canvas_device_mock.png` é **um único golden**
(`canvas_panel_golden_test.dart:89`, um caso só) e as duas frentes o alteram — a F3 porque
muda a escala do mock, a 5.1 porque desenha uma faixa que antes era vazia.

**Por que isso quebra a régua do item 39.** Aquela régua pede **citar o diff visual** na
regravação. Com duas causas num diff só, a citação vira "mudou por causa da F3 e da 5.1" —
e aí, se a escala regredir, o revisor atribui o diff à status bar e **passa**. É o padrão
da §11.0 na forma mais pura: o aceite deixa de discriminar.

**Decisão: a regravação é feita em dois commits, nesta ordem, e cada um cita a sua causa.**

| Commit | O que o diff contém | Citação exigida | Como o revisor confere |
| --- | --- | --- | --- |
| **A — ajuste** | os arquivos do fit (`fit_scale.dart`, `canvas_panel.dart`, `device_preset.dart`, `resizable_split_view.dart`) **+** o golden | a mudança de **geometria**: o preset e a janela, a escala antes e depois, e o que encolheu | `git show --stat` do commit **não** contém `device_frame.dart` nem tokens da status bar |
| **B — status bar** | `device_frame.dart`, o widget novo da barra, tokens **+** o golden | a mudança da **faixa do topo**: o que passou a ser desenhado ali | `git show --stat` do commit **não** contém nenhum arquivo do fit |

**O discriminador é de máquina, não de olho.** Ninguém precisa comparar PNG: `git show
--stat` de cada commit prova que a causa citada é a única causa possível daquele diff.
**Regravar as duas num commit só reprova, mesmo com as duas causas citadas** — e reprova
porque o revisor perde a capacidade de atribuir, não porque a descrição ficou pobre.

**Consequência na ordem das tarefas da F3:** o fit inteiro entra **antes** da status bar. A
tarefa da 5.1 não pode ser feita primeiro nem em paralelo com a do fit, sob pena de os dois
diffs se misturarem no golden.

---

### D33 — **[nova, 2026-08-16]** A `rodada_00` não terá fotos, e a causa no código substitui o "antes"

As fotos de campo que motivaram este item nunca foram arquivadas: chegaram por mensagem, e
quando o dev foi salvá-las a F1 e a F1b **já estavam mergeadas e no ar**. O estado que elas
mostram não é mais reproduzível em homologação.

**O que se perde, exatamente:** os itens 28 e 35-A pediam um **par** de fotos, e o par era a
prova de melhora — um "depois" sozinho não mostra que algo mudou.

**Decisão: o par é substituído pela causa no código, e o `evidencias/rodada_00/README.md`
passa a ser a evidência do "antes".** Ele já traz a tabela sintoma → causa com arquivo e
linha (`project_detail_page.dart:113` para o painel a 66% da largura,
`content_panel_view.dart:140` para o `Expanded` resolvendo a zero). Os itens 28 e 35-A
perdem a cláusula de pareamento e passam a apontar para a `rodada_01`.

**Por que isto não é rebaixar a régua.** A foto prova **que** quebrou; a linha prova **por
quê**. Um aceite ancorado em `Expanded` a largura zero é conferível por qualquer um a
qualquer momento — a foto, não: ela envelhece junto com o build que a produziu. O que a
D25 proíbe é aceite que não discrimina, e "o título ocupa uma linha horizontal" discrimina
sozinho, sem precisar do contraste.

**A regra que fica para as próximas rodadas:** evidência de campo é arquivada **no mesmo dia
em que chega**, antes de qualquer PR que a torne irreproduzível. Uma foto no aplicativo de
mensagens não é evidência arquivada.

### D34 — **[nova, humano, 2026-08-16]** A pílula se apaga sozinha — e o que a traz de volta é o **sucesso**, não o gesto

A F2b subiu e o dev viu a pílula no Chrome do desktop: *"não pedi pra remover isso?"*. O
pedido 4.1 era o **botão**, e a D30 tinha guardado a **frase** de propósito — ela é o único
sinal do caso do meio (puxou, buscou, não havia mudança). O incômodo, porém, é real: a
frase fica permanente sobre um preview que existe para ser olhado.

**Decisão do humano:** a pílula aparece, fica legível por `AppDurations.transientNotice` e
desvanece. Volta a cada busca **bem-sucedida**.

**O que faz a decisão ser segura é ela reagir a `fetchedAt`, não ao gesto.** O timer
reinicia no `didUpdateWidget` quando o carimbo muda — e pela D30 o carimbo **não** muda
quando o `refresh()` falha. A falha, portanto, não traz a pílula de volta: quem puxa sem
rede vê o banner de erro e **nenhuma** pílula, e quem puxa com sucesso vê a pílula com a
hora nova. Os dois prints continuam diferentes, que é o que a D30 protegia. Se o gatilho
fosse "puxou", os dois voltariam a ser o mesmo print e a D30 estaria desfeita.

**Consequência que veio junto, e não é opcional.** Com o botão fora (D30) e a pílula
transitória, no **Chrome do desktop** não sobrava nada: o `MaterialScrollBehavior` não põe
o mouse em `dragDevices`, então o `RefreshIndicator` **nunca** responde a arraste de mouse
— o gesto que substituiu o botão não existe no PC, e a única saída era recarregar a página.
Nasce a `PreviewScrollBehavior`, que soma `PointerDeviceKind.mouse` aos `dragDevices` só na
árvore do preview. _Não é escopo novo: é o que faz a promessa da F2b valer no aparelho em
que o dev estava quando reclamou._

**A pílula também deixa de interceptar ponteiro** (`IgnorePointer`). Ela é rótulo desde a
D30, e um `Material` opaco no rodapé do `Stack` engolia o arraste que começasse ali —
justamente a borda de onde se puxa numa tela pequena.

### D35 — **[nova, humano, 2026-08-16]** A top bar degrada em **três peças**, e a ação primária não vai para o menu

Foto do aparelho, na tela de projetos: a top bar mostra `Driva Builder`, `Arquivados (2)` e
o botão `+ Novo projeto` **cortado ao meio**, com o indicador de status e o botão de tema
fora da tela. `app_shell_top_bar.dart:32` é uma `Row` crua — wordmark, `Spacer`, ações,
status, tema — sem `LayoutBuilder`, sem `Flexible` e sem menu. Abaixo da soma das larguras
ela corta, e **sem faixa listrada** (D25): o sintoma é o corte, não um aviso.

A tarefa 1 da F3 já previa "as ações colapsam num menu". A foto acrescentou o que a decisão
original não tinha: **`Novo projeto` é a ação primária da tela**, e mandá-la para um kebab
põe a única ação criadora da tela a dois toques, no aparelho em que criar já é mais caro.

**Decisão do humano — três peças, nesta ordem de sacrifício:**

| Peça | Em faixa larga | Em faixa estreita |
| --- | --- | --- |
| `AppWordmark` | `Driva Builder` | **`Driva`** — a marca continua legível e devolve ~90 px |
| Ação `filled` (primária) | ícone + rótulo | **só o ícone**, ainda em destaque e a **um** toque |
| Demais ações | ícone + rótulo | **menu de overflow** |

**Por que não o FAB**, que seria o padrão Material no celular: a top bar não controla a
página. Projetar uma ação do shell para dentro do `Scaffold` da página — ou fazer cada
página declarar o seu FAB — é refatoração de arquitetura, não ajuste de layout, e não cabe
numa fase cujo objeto é matar overflow. _Fica registrado na §12 como possibilidade, não
como dívida._

**O que o aceite tem de provar**, e a D25 vale aqui: nada de "não vi faixa listrada". A
régua é **geometria medida** — a soma das larguras dos filhos da `Row` cabe na viewport, e
**toda ação declarada continua alcançável** (visível ou dentro do menu). Uma ação que
desaparece sem entrar no menu é o mesmo defeito com outra roupa.

---

## 5. Fases

### F1 — Navegar no celular funciona · **[0-dep; ∥ com F2, F3, F4]** · **[sub-agente: especialista-apresentacao]**

É a D20. **Escopo ampliado em 2026-08-16** com as causas **B′** (lacuna 600–794) e **D**
(modo "Lista", 610 px de estouro a 360) — que o QA achou medindo a própria tela que esta
fase conserta. Ficaram aqui, e não na F1b, porque são **a mesma tela e o mesmo movimento**
(o `272` virando faixa, o cabeçalho aprendendo a refluir); mandá-las para outra fase seria
partir um conserto ao meio.

Cobre as causas da §2.1 **na mesma fase**, porque corrigir só a Causa A
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
6. **[paralela: não — dep. 3]** **Causa B′:** **só o cabeçalho** ganha `LayoutBuilder`
   próprio e `AppSizes.contentPanelWideHeaderFitWidth` (795), e passa a empilhar **por não
   caber**, não por faixa. Fecha a lacuna 600–794.
   **⚠️ O gatilho substituído é o da tarefa 3 (o cabeçalho) — a gaveta da tarefa 2 continua
   em `AppBreakpoints.compact` (600).** A redação anterior desta tarefa dizia só
   "substitui o gatilho `compact` da tarefa 3" e foi lida como valendo para a página
   inteira; a gaveta acabou movida para 795. **São dois limiares de propósito, e a D27 diz
   o que cada um significa.** `AppBreakpoints` não ganha número novo.
7. **[paralela: sim]** **Causa D:** `ContentRow` (modo "Lista") — nome em `Flexible` com
   `maxLines: 1` + `ellipsis`, mesmo tratamento do cartão.
8. **[paralela: sim]** **Causa C′:** `isExpanded: true` no `DropdownButtonFormField` de
   categoria do `ContentFormDialog`. Uma propriedade; 216 px de estouro, **inclusive a
   1440**.
9. **[paralela: sim]** **Causa E:** o conteúdo do tile da Grade na transição de 1→2
   colunas (~375). **Medir o ponto de transição a partir do delegate**, não chutar
   larguras (D25).
10. **[paralela: sim]** **Causa F:** fechar a faixa 394–460 do modo Lista, que a primeira
    correção não pegou.
11. **[paralela: não — atravessa 9 e 10]** **Causa G / D25:** `SlugBadge` (e os demais
    widgets de chrome interno fixo) expõem `minimumWidth` derivado dos tokens, e a
    geometria renderizada passa a ser **medida**, não inferida da ausência de faixa.
    _Esta tarefa é a que muda a régua; as outras consertam casos._

**Aceite (validável — escrito como o print que o prova):**

1. **A foto refeita.** Mesmo aparelho, mesmo projeto: **"Todos os conteúdos" aparece em UMA
   linha horizontal**, com reticências se não couber. _**Atendido** por
   `evidencias/rodada_01/01_conteudos_android.jpg` (tema claro). O aceite não pede mais o
   par: o "antes" é a causa no código, não a foto (D33)._
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
6. **Os dois limiares, cada um no seu lugar (D27) — três larguras, não duas:**
   - **599** → **gaveta** (`AppBreakpoints.compact`), cabeçalho empilhado;
   - **601** → **barra lateral de volta**, cabeçalho **ainda empilhado** (795 não foi
     alcançado);
   - **795** → barra lateral **e** cabeçalho em linha única.

   _Três prints. É a terna que prova que os limiares são **dois e independentes**: se um
   número só governasse tudo, o print de 601 seria idêntico ao de 599 (foi o desvio que a
   rodada 4 pegou) ou ao de 795. A segunda metade de cada linha — o estado do cabeçalho —
   é o que separa este aceite de um que passaria com a tela estourada._
6-A. **A lacuna 600–794 fechada (Causa B′):** prints a **600**, **700** e **794** —
   nas três, o cabeçalho **empilhado**, título em uma linha, busca legível, **nada
   cortado na borda direita**. _Hoje faltam 195 px a 600 e 0,66 px a 794. O print a 794 é
   o que prova que o limite superior foi encontrado, e não chutado._
6-B. **O modo "Lista" (Causa D):** no `APARELHO`, tocar no `ViewModeToggle` e trocar para
   Lista, com um conteúdo de **nome longo**. **Esperado:** o nome trunca com reticências,
   nada cortado. _Hoje: 610 px de estouro a 360 — o pior número da tela, a um toque do
   caminho feliz. Se o E2E só percorrer o modo Grade, não prova nada sobre metade da
   tela._
6-C. **`AppBreakpoints` só tem faixa com consumidor (D26)** — prova de máquina: o
   arquivo define **o limiar `compact` e nada mais**; `expanded = 1024` **saiu** por não
   ter leitor, e `795` nunca entrou por não ser faixa. _Duas tentações opostas, um
   princípio só._
6-D. **A Grade cabe na transição de colunas (Causa E):** prints a **370, 375 e 380** —
   nos três, o conteúdo do tile **inteiro**. _375 é iPhone SE e iPhone 8. Um aceite que só
   olhasse 360 e 412 passaria: o pior caso está entre eles, porque alargar a tela
   **encolhe** o tile (D25)._
6-E. **A Lista cabe de 394 a 460 (Causa F):** prints a **394, 412 e 430**, nome longo
   truncando. _Pixel e Pro Max. A primeira correção do modo Lista não pegou esta faixa._
6-F. **O `SlugBadge` aparece, não some (Causa G / D25):** prints a **320, 360 e 375** com
   o **badge legível**. _Aceite **positivo**: "o badge aparece". Não use "não houve faixa"
   — neste defeito não há faixa nem quando ele existe (§11.0›caso 6)._
6-G. **O diálogo de conteúdo cabe com categoria de nome longo (Causa C′):** print a
   **1440** e no aparelho, com o dropdown mostrando o nome **sem estourar**. _216 px de
   estouro hoje, e **em qualquer largura** — não é defeito de celular._
7. **O construtor não foi afetado** — prova de máquina, os dois greps da D5›cerca 2
   (DoD 10 e 10b).

**O que este aceite NÃO prova:** que o editor funciona no celular. Não funciona, e é
decisão (D20). O aceite 7 é o que impede que alguém "aproveite a viagem". **O que
acontece quando o dev toca num conteúdo a partir desta lista é a F1b — e a F1 não fecha
sem ela** (§5›F1b, DoD 12).

---

### F1b — O editor degrada com dignidade · **[dep. F1 (conceitual) e F2 (mergeada)]** · **[sub-agente: especialista-apresentacao]**

É a D23. Fase curta e autocontida: um widget, um portão, zero mudança no construtor.

**Por que fase própria, e não dentro da F1.** As duas leituras têm razão, e a resposta
pega as duas:

- **A favor de ficar dentro:** conceitualmente é parte de "navegar no celular funciona".
  Consertar a lista para o dev **achar** um conteúdo e deixá-lo cair num beco ao **abrir**
  é entregar meia verdade.
- **A favor de ficar fora:** a F1 está **em execução**, em `contents_module`; esta fase
  vive em `editor_module` e não compartilha um arquivo com ela. Ampliar escopo no meio da
  execução é exatamente como o item 39 se atrapalhou. E esta fase carregava uma pergunta
  de arquitetura em aberto — a contradição da cerca da D5 — que precisava ser resolvida
  **antes** de alguém codar; resolvê-la dentro de uma fase em voo daria alvo móvel ao
  especialista.

**A síntese: dois PRs, um aceite.** Elas mergeiam separadas, mas **a F1 não é dada por
concluída até a F1b mergear** — o passeio de E2E do Bloco A termina no portão, e o item 12
do DoD exige os dois PRs. Protege-se o especialista em voo **sem** declarar pronta uma
promessa pela metade.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `.../editor_module/presentation/editor/page/editor_viewport_gate.dart` | **novo** — a **única** porta do limiar no módulo (D5›cerca 2a); decide entre portão e construtor |
| `.../editor_module/presentation/editor/page/small_viewport_notice.dart` | **novo** — a tela: explicação + os dois botões |
| `.../editor/editor_page.dart` | o `build` passa pelo portão **antes** do `BlocBuilder` (D23) |

**Tarefas:**

1. **[paralela: não]** **[x]** `EditorViewportGate` + `SmallViewportNotice`, com os dois
   botões ligados a `EditorRoutes.previewNamed` e `ContentsRoutes.projectDetailNamed`,
   ambos com o `projectId` vindo de `context.read<EditorCubit>().projectId` (D24).
2. **[paralela: não — dep. 1]** **[x]** Plugar no `EditorPage.build`, acima do
   `BlocBuilder`.

**Não faz parte desta fase, e é bom que não faça:** nenhuma linha em `canvas_panel.dart`,
`resizable_split_view.dart`, na paleta ou no Inspector. **Em particular, não se toca nos
rótulos do Inspector** — eles não têm defeito (§2.2, o alerta em destaque).

**Aceite (validável — escrito como o print que o prova):**

**7-A.** **A foto refeita do editor.** Mesmo aparelho da §2.0, mesmo conteúdo: aparece a
tela de aviso, **com os dois botões visíveis e legíveis**. _**Atendido** por
`evidencias/rodada_01/02_editor_portao_android.jpg`. Reprova se aparecer qualquer pedaço do
construtor — paleta, inspector ou faixa de canvas._

**7-B.** **"Ver conteúdo" leva ao preview do conteúdo que estava aberto.** Tocar no botão
→ foto da tela seguinte mostrando **o conteúdo renderizado**, e a URL do aparelho sendo
`…/preview/<projectId>/<id>` **com o mesmo `<id>` do conteúdo que foi tocado na lista**.
_Não basta "vai para alguma tela de preview": o par de fotos tem que mostrar o mesmo
conteúdo. É o que separa um botão que funciona de um botão que existe._

**7-C.** **O caminho inteiro, de ponta a ponta, num aparelho só:** lista de conteúdos
(F1) → tocar num conteúdo → portão (7-A) → "Ver conteúdo" → preview (7-B). _É o passeio
que prova que a F1 não termina em beco, e é o caminho em que o `ProjectScope` está quente
(D24)._

**7-D.** **"Voltar aos conteúdos" volta para o projeto certo** — foto da lista, com o
nome do projeto no breadcrumb.

**7-E.** **[corrigido em 2026-08-16 — a versão anterior era impassável]** Janela de
desktop a **599** → portão; a **1280** → construtor inteiro, **com o mock visível**.
_Dois prints. Prova que o portão sai de cena acima do limiar e que o construtor volta
intacto._

> **A versão anterior pedia o par 599 / 601, e reprovava por construção.** O QA mediu a
> 601: o portão faz a coisa certa (sai), o `EditorWorkspace` entra, e o
> `ResizableSplitView` estoura — `A RenderFlex overflowed by 11 pixels on the right`. É a
> aritmética da §2.2 aplicada a 601: `601 − 612 = −11` → `CenterArea` clampado a **zero**.
> **A 601 o canvas não é visível: ele tem largura zero, o mesmo defeito da foto, 189 px
> mais tarde.**
>
> **Isso não é regressão da F1b** — é a faixa que a §6 entrega de propósito à F3/D14. Mas
> o print que o aceite pedia **não existia até a F3 mergear**, e quem tentasse produzi-lo
> concluiria que o portão quebrou o editor.
>
> **Faixa 600–~1280: defeituosa de propósito, dona é a F3.** Além do estouro do split view
> (600→612), o QA mediu **103 px de estouro no `canvas_toolbar.dart` a 1024** — defeito
> **pré-existente**, anterior a este item (§2.5). **Print tirado nessa faixa não é prova
> contra a F1b**, e nenhum aceite desta fase o pede. O 1280 foi escolhido por ser uma
> largura em que o editor comprovadamente funciona **hoje**, antes de qualquer fase deste
> plano — que é a única coisa que o 7-E precisa medir.
>
> **Por que eu errei, e por que este erro é diferente dos outros quatro:** o número 601
> veio da **fronteira do portão**, não de onde o canvas passa a caber. São dois limiares
> distintos, e eu os tratei como um. Ver §11.0›caso 5.

**7-F.** **O construtor continua cego a faixa** — prova de máquina, os dois greps da
D5›cerca 2: `(a)` devolve **só** `editor_viewport_gate.dart`; `(b)` devolve **zero**.

**O que este aceite NÃO prova:** que um deep link do editor aberto frio no celular leva ao
projeto certo. Não leva, **já não levava antes desta fase**, e é a família da D18 / item 26
(§12, D24).

---

### F2 — Rota `/preview/:projectId/:id` — o conteúdo no celular · **[MERGEADA — PR #135, no ar em hml]** · **[especialista-apresentacao + especialista-infra]**

Não afetada por nenhuma das duas evidências de campo. **Entregue.** A F1b depende dela: é
o destino do botão "Ver conteúdo" (D23).

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

### F2b — Puxar para atualizar no `/preview` · **[0-dep; ∥ com tudo]** · **[sub-agente: especialista-apresentacao]**

É a frente **4.1** do feedback, governada pela **D30**. Fase pequena, mas **não é só trocar
um `InkWell` por um `RefreshIndicator`**: o `PreviewCubit` de hoje só sabe recarregar
passando por `PreviewLoading`, e o gesto exige um caminho que não apague a tela.

**O cuidado que o dev levantou, resolvido nos três casos.** `RefreshIndicator` precisa de
um `Scrollable`, e o conteúdo SDUI pode ter scroll próprio ou nenhum. Medido no código:

| Caso | O que existe hoje | O que a fase faz | O gesto puxa? |
| --- | --- | --- | --- |
| **Conteúdo curto** (não enche a tela) | `PreviewContent` já envolve o `SduiView` num `SingleChildScrollView` (`preview_content.dart:31`), com física padrão → **extensão zero, não puxa** | `physics: AlwaysScrollableScrollPhysics` + `ConstrainedBox(minHeight: viewport)` sob `LayoutBuilder` | **sim** — é a física, não a altura, que destrava |
| **Conteúdo mais alto que a tela** | rola normalmente | nada muda | **só no topo**; no meio da rolagem o gesto **rola** |
| **Conteúdo com `listView`/`gridView` no próprio spec** | o catálogo tem os dois, e os builders usam `shrinkWrap: true` por padrão (`sdui_flutter/lib/src/builders/list_view.dart:13`, `grid_view.dart:15`) → extensão interna zero | nada — o `notificationPredicate` padrão do `RefreshIndicator` já aceita **só `depth == 0`**, e o scrollable interno chega com `depth ≥ 1` | **sim**, pelo externo |

**A dívida que este levantamento expôs, e que a fase NÃO conserta:** um spec com
`shrinkWrap: false` num `listView` de raiz dá **altura ilimitada** dentro do
`SingleChildScrollView` e quebra o preview. Isso **já é verdade hoje**, desde a F2 — a F2b
herda, não cria. Registrada no **R15**.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `.../preview/cubit/preview_cubit.dart` | **`Future<void> refresh()`** ao lado do `load()`: sem `PreviewLoading`, e falha reemite o `PreviewReady` anterior (D30) |
| `.../preview/cubit/preview_state.dart` | o `PreviewReady` ganha como sinalizar a falha do refresh **sem** trocar de estado — campo, não subestado novo: trocar de estado apagaria o conteúdo, que é o que a D30 proíbe |
| `.../preview/widgets/preview_content.dart` | `RefreshIndicator` em volta do `SingleChildScrollView`; física `AlwaysScrollable`; `LayoutBuilder` + `ConstrainedBox` |
| `.../preview/widgets/last_saved_pill.dart` | perde a afordância e o `InkWell`; a cópia passa a dizer **"Último salvo"** (D30, e é o aceite 12 da F2 que nunca foi cumprido) |
| `.../preview/widgets/preview_refresh_failure_banner.dart` | **novo** (Gate 1) — o sinal de falha que não derruba o conteúdo |
| `core/theme/app_durations.dart` | se o banner tiver tempo de vida, o número é token |

**Tarefas:**

1. **[paralela: não — primeiro]** `refresh()` no cubit + o campo de falha no `PreviewReady`
   (D30). _Entra primeiro porque a tela não tem como ser escrita contra um cubit que ainda
   apaga o conteúdo._
2. **[paralela: sim]** `RefreshIndicator` + física + `ConstrainedBox` no `PreviewContent`.
3. **[paralela: sim]** A pílula perde a afordância e ganha a cópia certa.
4. **[paralela: não — dep. 1 e 2]** O banner de falha, ligado ao campo do estado.

**Aceite (validável — escrito como o print que o prova):**

12-A. **Conteúdo curto (o caso que o dev levantou):** um conteúdo de **um `text`**, que não
    enche a tela. Puxar de cima **mostra o indicador**. _Foto durante o gesto, com o
    indicador visível. Reprova se o gesto não pegar — é exatamente o que acontece hoje com
    a física padrão, e é o modo de falha silenciosa desta fase._
12-B. **Conteúdo mais alto que a tela — o par que discrimina:** (a) no **topo**, puxar →
    indicador; (b) **rolado até o meio**, puxar → **a tela rola**, sem indicador. _Dois
    prints. Se forem iguais, o `RefreshIndicator` sequestrou a rolagem, e o conteúdo longo
    ficou inalcançável._
12-C. **O gesto de fato buscou, e o carimbo é a única prova disso:** puxar **sem mudar nada
    no desktop** → o conteúdo é o mesmo e o **horário do carimbo muda**. _É o caso do meio
    da tabela da D30. Sem esta linha, "puxei e nada aconteceu" e "puxei e falhou" são o
    mesmo print._
12-D. **A falha é visualmente distinta (D30):** aparelho em **modo avião**, puxar.
    **Esperado:** o conteúdo **continua na tela**, o banner de falha aparece, e o carimbo
    **não muda**. _Trio com o 12-C: os três estados da tabela da D30, três prints
    diferentes. Reprova se o conteúdo sumir, se a tela virar erro, ou se o carimbo avançar
    com a rede caída — carimbo que avança sem ter buscado é a mentira que este aceite existe
    para pegar._
12-E. **A D4 continua de pé, e agora a frase está certa:** o par do aceite 11 da F2 refeito
    com o gesto — editar sem salvar → puxar → **não muda**; salvar → puxar → **muda** — e a
    pílula, nas duas fotos, diz **"Último salvo"**. _O aceite 12 da F2 exigia essa palavra e
    o código mergeado nunca a escreveu (D30). Aqui ela é conferida na foto, não no código._

**O que este aceite NÃO prova:** que o preview aguenta um spec com `listView` de
`shrinkWrap: false` (R15) — e não prova de propósito: essa quebra é anterior à fase.

---

### F2c — O `/preview` abre sem barra de endereços · **[0-dep; ∥ com tudo]** · **[sub-agente: especialista-infra]**

É a frente **4.3**, governada pela **D31**. Quase nada de Dart: é `web/` e uma rota nova
que existe só para o `start_url` não dar em 404.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `apps/driva_editor/web/manifest.json` | sai o template (`"driva_editor"`, `"A new Flutter project."`); entram nome, descrição e `id` do **editor**, com `scope: "/"` |
| `apps/driva_editor/web/preview_manifest.json` | **novo** — `scope: "/preview"`, `start_url: "/preview"`, `display: "standalone"`, `id` próprio, nome próprio, os mesmos ícones |
| `apps/driva_editor/web/index.html` | script inline que troca o `href` do `<link rel="manifest">` (linha 33) quando `location.pathname` começa com `/preview`; `<meta name="apple-mobile-web-app-capable">` na forma legada, ao lado da moderna que já existe (linha 24) |
| `.../editor_routes.dart` | `previewHome = '/preview'` + `previewHomeRoute`, irmã da rota de preview no root (`app_router.dart:19`) |
| `.../preview/preview_home_page.dart` | **nova** — a tela curta do `start_url`: o que é, e um caminho para a lista de projetos |

**Decisões locais:** o `id` dos dois manifests é **explícito** — sem ele o navegador deriva
a identidade do `start_url` e os dois alvos podem colidir na atualização. O script inline
roda **no parse**, antes do `flutter_bootstrap.js` (`index.html:36`), porque é aí que o
navegador lê o manifest. Nada de Dart tocando `document`: a rota não precisa saber que
existe manifest.

**Tarefas:**

1. **[paralela: sim]** Os dois manifests + o script de troca no `index.html`.
2. **[paralela: sim]** A rota `/preview` sem parâmetros + a página curta.
3. **[paralela: não — por último]** Verificação de instalabilidade no **aparelho físico**,
   nos dois sistemas (tarefa de verificação, não de código — vira o aceite abaixo).

**Aceite (validável — escrito como o print que o prova):**

12-F. **Android, o caminho que o dev pediu:** com o preview instalado pela tela inicial,
    **tocar num link `https://hml…/preview/<projectId>/<id>`** vindo de outro aplicativo.
    **Esperado:** abre **sem barra de endereços**. _Foto do aparelho. Reprova se abrir no
    navegador com a barra — e é aí que se descobre que o `scope` ficou errado._
12-G. **O ícone da tela inicial não dá em beco:** abrir pelo ícone (que vai para o
    `start_url`, sem ids). **Esperado:** a tela curta, com o caminho para os projetos.
    _Reprova com 404, tela branca, ou o editor inteiro._
12-H. **A fronteira de plataforma está declarada, e a foto prova qual é (D31):** o **mesmo
    link** no iPhone. **Esperado:** abre **com** barra de endereços (Safari não captura
    links), e abrir **pelo ícone** dá standalone. _Duas fotos de iOS, distintas entre si.
    Este aceite **não reprova o iOS** — ele reprova o **plano** se as duas fotos do iPhone
    forem iguais, porque aí a limitação que a D31 declarou não é a limitação real._
12-I. **O editor não foi capturado junto:** com o preview instalado, abrir um link do
    **editor** (`https://hml…/contents/...`) no mesmo aparelho. **Esperado:** abre no
    navegador, normal. _Reprova se abrir dentro do app de preview — seria `scope` grande
    demais, e o sintoma é o dev perdendo a barra de endereços onde ele precisa dela._

**O que este aceite NÃO prova:** que o conteúdo respeita a área segura do aparelho real
quando roda em standalone (**R14**) — e essa observação **alimenta o discovery do 4.2**,
que segue pendente.

---

### F3 — Piso do editor: overflows do shell, "ajustar à janela" **e a status bar do mock** · **[MERGEADA — PR #153]** · **[sub-agente: especialista-apresentacao]**

É a D1, verbatim, **mais a frente 5.1** do feedback. As duas metades da D1 entram no mesmo
PR porque foi assim que o humano definiu o piso do editor, e porque nenhuma vale sozinha
como "o editor parou de brigar comigo".

**A 5.1 entra aqui por decisão do dev humano**, não por afinidade técnica: as duas mexem no
mock do device — a D1 no ajuste e na escala, a 5.1 no chrome desenhado — e agrupá-las
economiza uma rodada de E2E. **O preço é o golden com duas causas, e ele é pago pela D32**:
dois commits, um por causa, com `git show --stat` como discriminador. A ordem das tarefas
abaixo não é preferência — é o que a D32 exige.

**Precede a F5 e a F7, e não é só por ser o maior retorno isolado.** É **pré-requisito
para elas serem prováveis num print**: com o zoom fixo no `Transform.scale`, colapsar a
paleta libera 280 px que viram **fundo cinza** — o mock não cresce um pixel. A F5 sem a F3
entrega um par de prints em que nada de relevante muda.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `core/theme/app_sizes.dart` | **já existe** (a F1 o criou, com 5 constantes) — **estender**, não criar: `canvasToolbarHeight`, `topBarHeight`, `breadcrumbBarHeight`, `minCenterWidth`, `panelRailWidth` (F5), `topBarActionsFitWidth` e **`workspaceMinimumWidth`** (público e **derivado**, D25›1 — é dele que o aceite 17-A tira as larguras) |
| `core/theme/device_mock_colors.dart` | **já existe** — ganha os tokens da status bar do mock (Gate 4, D29) |
| `.../editor/widgets/canvas/device_status_bar.dart` | **novo** (Gate 1, D29) — relógio, sinal, wifi e bateria; altura = `device.safeAreaTop` |
| `.../editor/widgets/canvas/device_home_indicator.dart` | **novo** (Gate 1, D29) — altura = `device.safeAreaBottom` |
| `core/widgets/app_shell/app_shell_breadcrumb_bar.dart` | `Flexible` em cada `CrumbLabel` — a elipse passa a disparar |
| `core/widgets/app_shell/app_shell_top_bar.dart` | `LayoutBuilder`; abaixo de `topBarActionsFitWidth` as ações **secundárias** colapsam num menu e a primária vira ícone (D35) |
| `core/widgets/app_shell/app_shell_actions_overflow_menu.dart` | **novo** (Gate 1) |
| `core/widgets/branding/app_wordmark.dart` | forma curta em faixa estreita (D35) |
| `core/widgets/layout/resizable_split_view.dart` | `LayoutBuilder`, piso do centro, reclamp, rolagem horizontal (D14) |
| `.../editor/device_preset.dart` | `Size get frameSize` (D10) |
| `.../editor/widgets/canvas/device_frame.dart` | consome `frameSize` (D10); e a status bar entra na **mesma camada do `CameraCutout`** (hoje `Positioned.fill` + `IgnorePointer`, linhas 104-108), **não** numa `Column` — D29 |
| `.../editor/widgets/canvas/fit_scale.dart` | **novo** — `double fitScaleFor({required Size frame, required Size viewport})`, pura e testável |
| `.../editor/widgets/canvas_panel.dart` | `LayoutBuilder` em volta da `Column` (D9) |
| `.../editor/widgets/canvas/canvas_toolbar.dart` | botão "Ajustar à janela" + percentual efetivo; tokeniza `height: 44` e `iconSize: 18` |
| `.../editor/page/canvas_area.dart` | o `BlocSelector` carrega `fitToWindow` |
| `.../editor/cubit/editor_state.dart` · `editor_cubit.dart` | `fitToWindow` (default `true`, P5); `toggleFitToWindow()`; `changeZoom` desliga o fit |

**Tarefas:**

1. **[paralela: sim]** Overflow do shell: `Flexible` nos crumbs + menu na faixa 1 +
   `AppSizes` + a degradação em três peças da **D35** (wordmark curto, primária em ícone,
   secundárias no menu). **Tem foto:** `evidencias/rodada_02/` — a barra cortando o "Novo
   projeto" ao meio no aparelho.
2. **[paralela: sim]** Piso do centro no `ResizableSplitView` (D14).
3. **[paralela: sim]** `DevicePreset.frameSize` + `DeviceFrame` consumindo (D10).
4. **[paralela: não — dep. 3]** `fitScaleFor` + `LayoutBuilder` no `CanvasPanel` +
   `fitToWindow` + botão e percentual na toolbar.
5. **[paralela: não — dep. 1-4, e é o COMMIT A da D32]** Regravar
   `goldens/canvas_device_mock.png` (é **um** arquivo, não um glob:
   `canvas_panel_golden_test.dart:89` tem um caso só). A citação nomeia **só a geometria**:
   preset, janela, escala antes e depois. _O `git show --stat` deste commit **não pode
   conter** `device_frame.dart` nem token de status bar._
6. **[paralela: não — só depois da 5]** A **status bar do mock (5.1)**:
   `DeviceStatusBar` + `DeviceHomeIndicator` + tokens, entrando na camada do `CameraCutout`
   (D29). _Não pode começar antes da tarefa 5 estar commitada, senão os dois diffs se
   misturam no golden._
7. **[paralela: não — por último, e é o COMMIT B da D32]** Regravar
   `goldens/canvas_device_mock.png` de novo. A citação nomeia **só a faixa do topo e a de
   baixo**. _O `git show --stat` deste commit **não pode conter** nenhum arquivo do fit._

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
    aberto**, mostrando **"Publish", "Desfazer" e "Refazer"** dentro — e **"Salvar" como
    ícone `filled` fora do menu**, a um toque (D35: a ação primária nunca entra no menu).
    _O `⋮` visível não basta: um menu que abre vazio passaria no aceite e reprovaria na
    prática. **[Correção editorial, 2026-08-16 — QA da F3]:** a redação anterior dizia
    "Salvar" dentro do menu, contradizendo a D35 (mesma seção, mesmo dia). A D35 é a
    decisão nomeada e travada; este texto só corrige o aceite para bater com ela — não é
    mudança de decisão._
17-A. **A faixa 600–1280 deixa de ser terra de ninguém** — é a F3 que a herda (§2.5›4,
    §5›F1b›7-E). **O que se prova é uma invariante, não três números:** *acima de
    `AppBreakpoints.compact` o canvas nunca tem largura zero* — ou porque sobra espaço, ou
    porque, abaixo do piso do workspace, a **D14** lhe garante `AppSizes.minCenterWidth`
    dentro da rolagem horizontal. **Três prints, e cada largura vem de onde o mecanismo
    muda:**
    - **(a) 600** — a fronteira do portão da F1b, o primeiro pixel em que há construtor.
      Abaixo do piso: **rolagem horizontal da D14 visível** e o canvas em
      `minCenterWidth`, **não-zero**, com o mock aparecendo.
    - **(b) `AppSizes.workspaceMinimumWidth`** — o piso, **lido do token no momento do
      print**, não digitado aqui. É a largura em que a rolagem some. _Hoje ele vale ~732;
      **a descrição do PR registra o valor que ele tinha na rodada**._
    - **(c) 1024** — canvas folgado, e a **toolbar do canvas sem nada cortado** (hoje ela
      estoura **103 px a 1024**, medido).

    > **Por que este aceite é escrito assim, e é a §11.0›caso 7 aplicada antes do dano.** A
    > versão anterior dizia "prints a **612**, 700 e 1024". Os três eram literais, e o 612
    > vinha de uma conta que assume **dois** painéis laterais. O **5.3** (trocar Árvore ↔
    > Propriedades de lado) está em discovery e, se o dev escolher três painéis laterais, o
    > piso sobe de ~732 para ~938 — e o aceite antigo viraria **inalcançável sem ninguém
    > perceber**, porque o texto não denuncia de onde o 612 veio. Ancorando (b) no token e
    > (a) na fronteira `compact`, **o 5.3 move os prints junto com o piso e a invariante
    > continua verdadeira**: subir o piso só muda qual dos dois mecanismos responde em cada
    > largura. Ver **R13**.
18. **Workspace a 560:** a rolagem horizontal da D14 aparece e **nenhum conteúdo some na
    borda direita**. _Camada do sintoma, D22 — a faixa listrada é o passo 19 do roteiro,
    em build de debug._
19. **Invariante I1 sobreviveu ao `canvas_panel.dart`:** a `image` sem ACAO do item 39
    **continua carregando** no mock, e a aba Network mostra `…/v1/media/proxy?url=…`.
    _Print, não grep._

**Aceite da 5.1 — a status bar do mock:**

19-A. **A faixa deixou de ser vazia:** print do preset **Smartphone** com relógio, sinal,
    wifi e bateria desenhados **dentro** da moldura, no topo, e o recorte da câmera
    continuando por cima. _Aceite positivo: o elemento **aparece**._
19-B. **Desenhar não moveu o conteúdo (D29) — o par que pega a armadilha:** o mesmo
    conteúdo, antes (commit A da D32) e depois (commit B), com o **topo do conteúdo no
    mesmo y**. _É esta linha que separa "pintei sobre o espaço reservado" de "empurrei o
    conteúdo para baixo". Se o conteúdo desceu, o recuo está sendo contado duas vezes — o
    defeito de uma linha que a D29 existe para evitar, e que passaria como "ficou mais
    espaçado"._
19-C. **O `SafeArea` ganhou causa visível — e é o que o dev pediu:** par de prints com o
    **mesmo conteúdo**, uma vez com a área segura respeitada e uma vez sem. **Esperado:**
    sem, o conteúdo passa **por baixo do relógio**; com, ele começa **abaixo** da faixa.
    _Os dois prints têm de ser visualmente distintos. **É o aceite da promessa da frente
    5.1**, não do caminho feliz: se os dois forem iguais, a status bar virou enfeite e não
    explica nada — que é exatamente o estado de hoje, só que com pixels bonitos._
19-D. **Os três presets, sem colisão:** print de **Smartphone (pill)**, **Android
    (punchHole)** e **Tablet**. **Esperado:** em nenhum deles o relógio ou os ícones ficam
    **por baixo** do recorte da câmera, e a barra tem a altura do `safeAreaTop` **daquele**
    preset. _O Smartphone é o mais estreito (393) e o Tablet não tem recorte — testar só um
    passa e não prova nada._

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

### F4b — O colapso da paleta sobrevive à troca de aba · **[0-dep; ∥ com tudo]** · **[sub-agente: especialista-apresentacao]**

É a frente **1.1** do feedback, governada pela **D28**. **Defeito, não funcionalidade
ausente** — a F4 registrou "a persistência é a F6", e aquilo era sobre **sessões**; perder o
colapso ao ir na Árvore e voltar é perda **dentro da mesma sessão**, e o dev lê como coisa
quebrada.

**A camada que esta fase entrega, e a que ela não entrega.** Sobreviver à **troca de aba**:
aqui. Sobreviver à **sessão** (`shared_preferences`): continua sendo a **F6**, que absorve
o notifier desta fase junto com a aba corrente da F5 (D28). Esta fase **não** grava nada em
disco.

**Arquivos:**

| Arquivo | Papel |
| --- | --- |
| `.../editor/page/left_panel.dart` | vira `StatefulWidget` **de construtor `const`**; o `State` cria e descarta o `ValueNotifier<Set<String>>` (D28) |
| `.../editor/widgets/widget_palette_panel.dart` | `_collapsedCategories` sai do `State` (linha 19) e passa a vir pelo construtor; `_toggleCategory` (26-30) troca `setState` por **`Set` novo** no notifier; `ValueListenableBuilder` envolve **só a lista de grupos** |

**Decisões locais:** `const LeftPanel()` em `editor_workspace.dart:35` **continua `const`**
— é o que impede o painel esquerdo de reconstruir a cada `emit` do `EditorCubit` (D28›R5), e
por isso o notifier nasce **dentro** do `LeftPanel`, não é descido de cima. A busca
(`_query`) **fica onde está**: filtro é momento, colapso é hábito (D28). **Nada de
`AutomaticKeepAliveClientMixin`** — a razão está medida na D28, e não é a que parecia.

**Tarefas:** 1. **[paralela: não — única]** `LeftPanel` stateful + notifier + o painel
recebendo pelo construtor. _Uma tarefa só, dois arquivos: é uma fase de PR de relance._

**Aceite (validável — escrito como o print que o prova):**

23-A. **O trio que prova, e um par não provaria:** (1) aba **Widgets** com **3 dos 4 grupos
    fechados**; (2) aba **Árvore**, com a árvore desenhada; (3) de volta em **Widgets**, os
    **mesmos 3 fechados**. _O print (2) existe para que (1) e (3) não possam ser a mesma
    foto tirada duas vezes. Hoje o print (3) mostra os quatro abertos._
23-B. **A busca continua efêmera, e isso é decisão (D28):** digitar `col` → ir para
    **Árvore** → voltar. **Esperado:** o campo de busca **vazio** e os 3 grupos fechados de
    volta. _Reprova nas duas pontas: se a busca sobreviver (o dev volta para uma paleta
    filtrada sem lembrar por quê) **ou** se os grupos voltarem abertos._
23-C. **A cerca da D28 — prova de máquina, não print:** `grep -rn
    "AutomaticKeepAliveClientMixin\|wantKeepAlive" apps/driva_editor/lib` = **zero**, e
    `grep -n "const LeftPanel()" apps/driva_editor/lib/modules/editor_module/presentation/editor/page/editor_workspace.dart`
    = **uma** ocorrência. _A primeira metade guarda o caminho quente da D8; a segunda guarda
    o escopo de rebuild. Nenhuma das duas tem print — não invente um._

**O que este aceite NÃO prova:** que o colapso sobrevive ao **fechamento do painel** (F5) ou
à **sessão** (F6). Não sobrevive, e não deve fingir que sim — as duas linhas são das fases
seguintes, que herdam este notifier em vez de reescrevê-lo.

---

### F5 — Painel do editor colapsa numa faixa fina de ícones · **[PR #155, aberto]** · **[sub-agente: especialista-apresentacao]**

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
4. **[paralela: não — dep. 1 e 3; só se a F4b tiver mergeado]** **Mudar o notifier dos
   grupos da paleta e a aba corrente do `State` do `LeftPanel` para o
   `EditorLayoutController`, na mesma mudança** (D28). _Sem isto, colapsar o painel
   descarta o `State` do `LeftPanel` e o dev reencontra os quatro grupos abertos ao
   reabrir — a queixa 1.1 de volta, uma fase depois, com a correção já instalada e
   parecendo cobri-la._

**Aceite (validável — escrito como o print que o prova):**

24. **Paleta colapsada:** a faixa fina com os ícones **Widgets** e **Árvore** visíveis, **e
    o percentual do canvas subiu** em relação ao print anterior. _O percentual é a metade
    que prova que o espaço foi para o mock e não para o fundo._
25. **Os dois painéis colapsados:** duas faixas, mock no maior tamanho, **os dois
    controles de reabrir visíveis**.
26. **A faixa é atalho, não só interruptor (D2):** com a paleta colapsada, clicar no ícone
    **Árvore** reabre o painel **na aba Árvore**.
26-A. **O colapso da F4b sobreviveu ao colapso do painel:** fechar 3 grupos → **colapsar a
    paleta na faixa fina** → reabrir. **Esperado:** os **mesmos 3 fechados**. _É a tarefa 4
    desta fase provada em foto. Reprova com os quatro abertos — e reprovar aqui é a única
    forma de descobrir que a tarefa 4 foi esquecida, porque nada mais na F5 a exercita._
27. **A borda que a A3 decidiu:** o print do item 24 mostra o controle de reabrir **dentro
    da faixa**. _Reprova se o único caminho de volta for atalho ou menu escondido._

**O que este aceite NÃO prova:** que os painéis não reconstroem no toggle (D8). Não há
print para isso — é teste de widget na F9.

---

### F6 — O layout do editor é lembrado entre sessões · **[PR #159, aberto]** · **[sub-agente: especialista-dominio + especialista-dados + especialista-apresentacao]**

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

### F7 — Modo tela cheia · **[PR #160, aberto]** · **[sub-agente: especialista-apresentacao + especialista-infra]**

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
34. **A borda P2 — metade provável hoje:** entrar em tela cheia **com um erro de
    diagnóstico no rodapé** → o rodapé **continua visível**. _Esconder erro num modo novo
    reintroduziria o sintoma que o item 38 corrigiu._ **[Correção editorial, F7, 2026-08-16
    — QA]:** a segunda metade do aceite original ("sem erro → some") é **inatingível hoje**
    — `EditorStatusBar` sempre renderiza quando `EditorReady` (mostra "Nenhum problema" em
    vez de sumir), gap **pré-existente** à F7 (não regressão: `status_bar_area.dart` não foi
    tocado nesta fase). O `prd.md:136` já dizia que deveria sumir; ninguém implementou.
    **Decisão pendente do humano**, registrada em `variance_report.md` VR-17-05 e no
    `roadmap.md`: reescrever a regra do rodapé (item próprio) ou aceitar o texto como está.
    Enquanto não decidir, a F8 não instrumenta esse par de prints.
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
| **`EditorViewportGate`** (F1b) | a 360 e 412: **o `EditorWorkspace` não é construído** (`find.byType(EditorWorkspace)` → `findsNothing`) e o aviso aparece com os dois botões; a 601: o inverso. **É o teste que trava o retorno do canvas de largura zero.** _Aqui 601 é a largura **certa**: este teste mede o contrato do **portão** (sair acima de 600), não a visibilidade do canvas. Que o canvas ainda não apareça a 601 é defeito da F3, e é por isso que o aceite visual usa 1280 (§11.0›caso 5)._ |
| **Rotas dos botões do portão** | "Ver conteúdo" navega para `previewNamed` com o `projectId` **e** o `contentId` corretos; "Voltar aos conteúdos" para `projectDetailNamed` |
| **Regressão de overflow** | widget test com `tester.view.physicalSize` em **360, 412, 560, 599, 600, 601, 612, 700, 794, 795, 1024, 1280, 1440**, capturando `FlutterError.onError` — **zero** overflow, **nas duas telas** (projeto e editor) **e nos dois modos de exibição** (Grade e Lista). _Roda em debug: é a única camada que enxerga o indicador (D22). `editor_perf_test.dart` já tem o helper `enlarge(tester)` como precedente. As larguras 601, 794 e 795 estão na lista porque foram **medidas**, não estimadas — são as bordas exatas dos defeitos que o QA achou._ |
| **Geometria (D25) — a rede que não existe hoje** | para cada widget de chrome interno fixo (`SlugBadge` à frente): `tester.getSize(...).width >= X.minimumWidth` nas **11 larguras de borda**. **Árvore nova a cada largura** — ver a nota abaixo, que quase enganou o QA |
| **Golden em faixa compacta** | **os goldens existentes estão todos a 1200×900 com `isCompact: false` — só existe o layout largo.** Entram goldens a **375** e **412**: gaveta fechada, **gaveta aberta**, cabeçalho empilhado, modo **Lista** com nome longo |
| **Ponto de transição como _função_, não constante** | a largura em que o delegate vira de _n_ para _n+1_ colunas é **calculada e testada** (`chrome + n×316 + 1`), não escrita à mão. _Constante mentiria no dia em que o `maxCrossAxisExtent` ou o `crossAxisSpacing` mudassem — e ninguém saberia_ |
| Os quatro diálogos | **320, 360, 375, 412 e 1440**, com categoria de **45 caracteres** (Causa C′). _O 1440 está na lista porque este defeito **não é de celular**_ |
| `DialogContentWidth` | clampa contra o `MediaQuery` — largura pedida nunca excede a tela |
| `ContentPanelHeader` | empilha por `contentPanelWideHeaderFitWidth` (795), **não** por faixa (D27) |
| `ContentRowBody` | esconde `UpdatedAt` em `compact` (600) — o outro consumidor de `AppBreakpoints` (D27) |
| `ProjectDetailPage` | gaveta por `AppBreakpoints.compact` (600), **não** por 795 (D27) — o teste que trava o desvio da rodada 4 |

> ⚠️ **Árvore nova por largura, e não é detalhe de estilo.** Reusar a mesma árvore entre
> larguras **suprime o segundo relato do mesmo `RenderFlex`** — o framework não reporta
> duas vezes o mesmo overflow do mesmo objeto. O QA quase foi enganado por isso: a
> varredura passava porque o **relato** sumia, não porque o defeito sumisse. É a **mesma
> família do caso 6** (§11.0): ausência de sinal lida como ausência de defeito. Cada
> largura monta a árvore do zero.
| Diálogos | a 360: largura do diálogo ≤ largura da tela; e `ContentFormDialog` com categoria de nome longo **a 1440** (Causa C′) |
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
 F2 (rota de preview) ── MERGEADA (#135) ───┐
   ├─ F2b (pull-to-refresh) ─────────────┐  │  destino do botão "Ver conteúdo"
   └─ F2c (PWA standalone) ──────────────┤  │
 ┌─ F1 (navegação no celular) ─ F1b (portão do editor) ◄┘
 │        └─────── um aceite só ───────┘     │                    │
 │                                           │                    ├─ F8 (E2E) ─ F9 (bateria)
 ├─ F4 (grupos) ─ F4b (sobrevive à aba) ─────┼──┐                 │
 │                                           │  ├─ F6 (memória) ──┤
 └─ F3 (piso do editor + status bar) ─┬─ F5 (colapso) ────────────┘
                                      └─ F7 (tela cheia) ─────────┘
```

| PR | Fase | Pode começar quando |
| --- | --- | --- |
| — | F2 | **mergeada, #135** |
| 1 | **F1** | **em execução** |
| **1b** | **F1b** | **Já** — `editor_module`, zero arquivo em comum com a F1 em voo; a F2 (seu destino) já está no ar |
| 2 | F4 | **mergeada, #138** |
| **2b** | **F4b** | **Já** — dois arquivos, nenhum em voo |
| **2c** | **F2b** | **Já** — só `preview/` |
| **2d** | **F2c** | **Já** — `web/` + uma rota nova |
| 3 | F3 | **Já** — o E2E dos itens 38 e 39 foi **atestado em 2026-08-16**; a pré-condição I6 caiu |
| 4 | F5 | Depois dos PRs 3 **e 2b** (a tarefa 4 da F5 move o notifier da F4b) |
| 5 | F7 | Depois do PR 4 |
| 6 | F6 | Depois dos PRs 2b e 4 |
| — | F8 | Depois de todos em homologação |
| 7 | F9 | Depois do atestado humano da F8 |

**Seis frentes podem correr em paralelo hoje: F1, F1b, F4b, F2b, F2c e F3.** Nenhuma
compartilha arquivo com outra — verificado, não presumido:

- **F1** fica em `contents_module`, `projects_module` e `core/theme/app_breakpoints.dart`.
- **F1b** fica em `editor_module/presentation/editor/page/` (dois arquivos novos +
  `editor_page.dart`).
- **F4** (entregue) ficou em `widget_palette/`.
- **F4b** fica em `page/left_panel.dart` + `widgets/widget_palette_panel.dart`.
- **F2b** fica em `presentation/preview/` (cubit, `preview_content.dart`,
  `last_saved_pill.dart`, um widget novo).
- **F2c** fica em `web/` + `editor_routes.dart` + uma página nova em `preview/`.
- **F3** fica em `core/theme/`, `core/widgets/app_shell/`, `core/widgets/layout/` e
  `editor/widgets/canvas*`.
- **F2** (entregue) ficou em `preview/`, `editor_page.dart`, `editor_routes.dart`,
  `app_router.dart`, `core/network/` e `canvas_toolbar.dart`.

**Atrito 1 — `editor_page.dart`.** Tocado pela F2 (mergeada) e pela F1b (o portão no topo
do `build`). Como a F2 já está em `develop`, a F1b nasce em cima dela: **sem conflito, se
a branch da F1b sair de `develop` atualizada**.

**Atrito 2 — `canvas_toolbar.dart`.** Tocado pela F2 (botão do preview, já lá), pela F3
(botão de ajustar) e pela F7 (botão de tela cheia). **O PR 3 rebase antes de mergear.**

**Atrito 3 — `left_panel.dart`.** Tocado pela **F4b** (vira `StatefulWidget` e passa a
possuir o notifier dos grupos) e pela **F5** (expõe a aba corrente, e a tarefa 4 leva o
notifier para o `EditorLayoutController`). **Não é conflito de merge, é ordem:** o PR 2b
entra antes do 4, e o 4 **move** o que o 2b criou em vez de reescrever. Invertida a ordem,
a F5 nasce sem o notifier e a F4b depois teria de instalá-lo num painel que já colapsa —
duas mudanças no mesmo lugar, com a queixa 1.1 viva no meio.

**Atrito 4 — `goldens/canvas_device_mock.png`.** Só a F3 o toca, e o toca **duas vezes**,
de propósito (D32). Nenhuma outra fase pode regravá-lo no mesmo ciclo: um terceiro commit
sobre o mesmo arquivo destrói a atribuição que a D32 construiu.

**Interação D14 × D23 — a faixa em que cada uma manda.** As duas tratam de janela
estreita, e é preciso dizer onde uma acaba:

| Largura | Quem responde | O que acontece |
| --- | --- | --- |
| < 600 (`compact`) | **D23 (F1b)** | o construtor não é construído; aparece o portão |
| 600 até o piso do split view | **D14 (F3)** | rolagem horizontal — degradação decidida, nada some |
| acima do piso | layout normal | o ajuste da F3 cuida do mock |

**A F1b não torna a D14 obsoleta**, e a D14 não cobre o celular. Quem implementar a F3 não
deve concluir, ao ver o portão, que o piso do `ResizableSplitView` ficou sem cliente.

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

**R12 — A F1 está sem rede, e não é figura de linguagem.** O QA confirmou: **nenhum**
teste referencia `ProjectDetailPage`, `ContentRowBody`, `SlugBadge`, `AppSizes`,
`AppBreakpoints`, `DrawerToggleButton`, `CategoryTreePanel` ou `ContentPanelHeader`.
Consequências medidas: **tirar o `Flexible` do badge não quebra nada; mudar o 795 para
qualquer valor não quebra nada.** Os 4 goldens estão a 1200×900 com `isCompact: false` —
**nenhum cobre a gaveta**. Ou seja, tudo o que a F1 conserta pode ser desfeito no próximo
PR sem um sinal vermelho.

Isso **não** antecipa a bateria (a regra do cap. 22 continua: testes depois do E2E
atestado). O que ele muda é o **conteúdo** da F9, que passa a ter três alvos obrigatórios
— geometria (D25), golden em faixa compacta, e pontos de transição —, e o **peso** do item
43 do DoD: enquanto a F9 não entrar, cada PR posterior é revisão manual sem rede, e quem
revisar precisa saber disso.

**R10 — O portão da F1b virar corredor.** Um limiar dentro do `editor_module` é
precedente: o próximo que quiser "só um ajustezinho por largura" no construtor vai apontar
para ele. Mitigado pelos **dois greps** da D5›cerca 2 — o (a) mantém uma porta só, o (b)
mantém a UI do construtor cega a faixa. **Se algum PR precisar afrouxar qualquer um dos
dois, é desvio e vai para o `variance_report.md` com aprovação do humano** — não é ajuste
de plano.

**R11 — "Consertar" os rótulos do Inspector.** A foto mostra `Págin…`, `Usar área se…`, e
o impulso natural é mexer no Inspector. **Não há defeito lá** (§2.2): ele é medido a 320
px e desenha certo; 200 px dele estão fora da tela. Um PR que mexa em
`inspector_prop_list.dart` ou nos rótulos por causa desta foto está consertando o sintoma
errado — e ainda por cima em arquivos que os itens 38 e 39 acabaram de tocar (I4).

**R9 — A F1 crescer além de um PR de relance.** Ela cobre três causas e cinco tarefas. Se
a tarefa 5 (verificação da home e do cartão) revelar quebra estrutural no `ContentCard`,
**o tech-lead parte a F1 em duas no momento do PR** — projeto/categorias/busca numa, cartão
e home noutra — e registra em `variance_report.md`. Está previsto, não é desvio.

**R13 — O 5.3 sobe o piso do workspace, e o 17-A precisa sobreviver a isso.** Trocar Árvore
↔ Propriedades de lado (frente 5.3, em discovery) pode virar **três** painéis laterais em
vez de dois, e o piso do workspace sairia de ~732 para ~938 px. Um aceite ancorado em
números literais (`612`, `700`) viraria **inalcançável sem ninguém perceber** — §11.0›caso
7 na forma pura. Mitigado por construção: o **17-A** ancora a largura do meio em
`AppSizes.workspaceMinimumWidth` **lido no momento do print**, e a invariante que ele prova
(*acima de `compact` o canvas nunca tem largura zero*) é indiferente ao valor do piso — subir
o piso só troca qual mecanismo responde, o espaço que sobra ou a rolagem da D14. **O que
sobra de dever para o 5.3:** registrar o novo valor do piso na descrição do PR, e rodar o
terceiro teste de bolso da §11.0 (`grep` por `workspaceMinimumWidth` nos aceites) antes de
fechar. _Isto é dependência declarada, não bloqueio: a F3 **não** espera o 5.3._

**R14 — O preview em standalone pode não ter área segura, e ninguém vai ligar as duas
coisas.** A F3 desenha a status bar **no mock** e torna o `SafeArea` visível ali (D29). No
aparelho real, sob a **F2c**, o preview roda em `display: standalone` — e se o `viewport`
que o engine do Flutter injeta não trouxer `viewport-fit=cover`, o `MediaQuery.padding` do
aparelho vem **zero** e o `SafeArea` do conteúdo previsto não faz nada. O resultado seria o
pior dos dois mundos: o mock ensinando um comportamento que o aparelho não reproduz.
**Não vira tarefa aqui** — vira **observação medida no E2E** (passo 17-c) e **entrada para o
discovery do 4.2**, que segue pendente: *"a barra de navegação aparece"* pode ser exatamente
isto, e não chrome nosso.

**R15 — `shrinkWrap: false` num `listView` de raiz quebra o preview, e é anterior à F2b.**
`PreviewContent` envolve o `SduiView` num `SingleChildScrollView` desde a F2
(`preview_content.dart:31`); os builders do renderer usam `shrinkWrap: true` **por padrão**
(`list_view.dart:13`, `grid_view.dart:15`), o que salva o caso comum. Um spec que ponha
`shrinkWrap: false` dá altura ilimitada e quebra. **A F2b herda, não cria**, e o aceite dela
declara isso em vez de fingir cobertura. _Dono natural: o item que revisar o catálogo de
scrollables — não este._

---

## 8. Divergências em relação ao recorte do PRD

| # | O PRD dizia | Este plano faz | Por quê |
| --- | --- | --- | --- |
| 1 | 4 fases: overflows+fit · colapso+persistência · paleta+tela cheia · bateria, mais o preview separado | **12 fases** | Ver as linhas abaixo. As três últimas (F2b, F2c, F4b) e a ampliação da F3 nasceram do **uso real** (`feedback_rodada_01.md`), depois de o PRD estar fechado — não são divergência de recorte, são matéria-prima que o PRD não tinha |
| 2 | **O problema é do editor** | **São dois problemas**, e a navegação quebra pior | Evidência de campo de 2026-08-16 (§2.0). A tela mais visitada renderiza texto **uma letra por linha** a 412 px. O `specs.md` não tinha essa informação |
| 3 | Preview como "fatia 2", depois de tudo | **F2, em execução desde cedo** | É a única fase cujo E2E exige **hardware físico e homologação real**; descobrir tarde que o aparelho não abre a rota é o pior lugar para descobrir. E é 0-dep de verdade |
| 4 | Colapso **e** persistência na mesma fase | **F5 e F6 separadas** | A pilha serve **quatro** clientes. Escrita antes de os quatro existirem, seria escrita duas vezes. E colapso sem memória já é fatia vertical utilizável |
| 5 | Tela cheia junto dos grupos da paleta | **F7, própria** | Muda a **API pública do `AppShell`** (`core/widgets/`), preocupação de revisão diferente de mexer na paleta |
| 6 | Preset Tablet precisa de **~863 px** de centro | **~952 px** | O PRD contou só o `bezel`. A `DeviceFrame` soma `bezel * 0.55` de cada lado (botões laterais) e o `CanvasPanel` envolve num padding de 32. §2.3 |
| 7 | "Tokens de breakpoint, só se A1 pedir; o discovery recomenda adiar" | **`AppBreakpoints` nasce na F1** | A D20 deu um cliente: a barra lateral de 272 px não se conserta com `Flexible` — a 412 px ela tem de deixar de ser barra lateral. Isso é faixa, e faixa quer nome (D5) |
| 8 | **"Nunca `RenderFlex overflow`"; "a régua é não existir estado em que o editor mostre faixa listrada"; prova em homologação** | **A faixa listrada não é aceite de homologação** (D22) | `flutter build web --release`: o indicador é pintado dentro de um `assert` e **não existe em release**. O aceite anterior teria passado provando nada — a mesma armadilha do item 39 |
| 9 | "A1 excluiu comportamento por faixa de largura" | **Reaberto, só para a navegação** | D20, decisão do humano de 2026-08-16, com fronteira cobrada por grep (D5›cerca 2) |
| 10 | Analytics em 5 eventos | **Fora** (§12) | Não existe pipeline de analytics no editor hoje |
| 11 | **"O editor não precisa abrir em celular"** — e nada foi dito sobre o que ele *mostra* lá | **F1b: abaixo de `compact` o editor cede o lugar a um portão com dois caminhos** | 2ª evidência de campo: no aparelho o **canvas não existe** (`Expanded` → 0, §2.2). "Não precisa abrir" descrevia a ambição; não dizia o que fazer com quem abre. A D23 responde sem tornar o editor mobile |
| 12 | Preset Tablet: a conta do centro está em **§2.3** | **§2.4** | A §2 ganhou uma subseção (§2.2, o canvas sumindo) e as seguintes deslocaram uma casa |

---

## 9. O que ainda precisa do humano

**As cinco decisões caras estão fechadas** (A6 → D3, A1 → D1, A3 → D2, A7 → D4, e a de
2026-08-16 → D20). Sobraram duas questões pequenas; **nenhuma bloqueia a F1**:

**Q1 — `qr_flutter`: RESOLVIDA.** Entrou no PR #135 (`qr_flutter: ^4.1.0`). É a **única
dependência nova** de toda a feature, e o item 59 do DoD cobra que o PR a documente.
_Nada a decidir._

**Q2 — O colapso das seções do Inspector é lembrado por rótulo de grupo (global) ou por
tipo de nó?** Este plano adota **global por rótulo** (P3: layout é hábito de trabalho, não
atributo do documento) — é o que faz o Inspector parar de reabrir tudo a cada troca de nó,
que é o incômodo concreto. **Veto fácil na revisão da F6.**

**Q3 — [nova, 2026-08-17] O relógio do mock é `9:41` fixo.** Hora real quebraria o golden a
cada minuto (D29). Se o humano quiser hora real, o preço é recortar a faixa do topo do
golden — o que enfraquece justamente o que o **36-B** prova. **Veto barato na revisão do
PR 3, mas é veto, não ajuste.**

**Q4 — [nova, 2026-08-17] A pílula do preview perde o `· toque para atualizar` e mantém o
carimbo.** A **D4** é decisão travada dele e obriga a **dizer** que é o último salvo, não a
ter um botão (D30). **Se ele quiser o botão de volta ao lado do gesto, é veto na revisão do
PR 2c** — mas então o 52-C precisa de outro sinal, porque o carimbo deixa de ser a única
prova de que o gesto buscou.

**Q5 — [nova, 2026-08-17] O `start_url` do preview vai para uma tela curta**, não para o
último conteúdo aberto (D31). Lembrar exigiria persistência por conforto (§12). **Veto na
revisão do PR 2d.**

---

## 10. Roteiro de E2E manual

**Em homologação** (`https://hml.driva.duckdns.org`), **nunca em localhost** — lição
permanente do item 9g. **Exceção única e declarada: o passo 19** (D22). O que está marcado
**[olho]** ou **[mãos]** é do humano.

> **A divisão do trabalho, decidida na rodada 4:** **[máquina]** cobre tudo que é
> **geometria** — largura, presença, tamanho renderizado, ponto de transição. **[olho]** e
> **[mãos]** cobrem o que exige julgamento ou hardware: legibilidade, gesto, teclado do
> sistema, e a comparação com as fotos de campo. **Não peça print para provar largura** —
> é a atenção mais cara do time gasta no que a máquina faz melhor, e ainda por cima
> procurando o sinal errado (D25).

> ⚠️ **Defeito conhecido deste roteiro, achado em 2026-08-17 — leia antes de seguir as
> tags.** As referências `(DoD NN)` dos passos **1 a 18** foram escritas contra uma
> numeração anterior da §11.4 e **estão deslocadas** (o passo 1 diz `DoD 24, 25`, que hoje
> são linhas da §11.3). É o **caso 7 da §11.0** aplicado ao próprio roteiro: o texto não
> errou, envelheceu, e nada nele denuncia isso. **Enquanto não forem varridas, a autoridade
> é a §11.4 e os aceites por fase da §5** — as tags são pista, não índice. As tags dos
> passos **12a a 12c, 14a a 14c e 18a a 18i** foram escritas já contra a numeração atual e
> estão corretas. _Varrer as antigas é tarefa do QA no fechamento (§11.5›63)._

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
| `CT_CURTO` | Um conteúdo com **um `text` só**, que não enche a tela do celular | passo 18a |
| `CT_LONGO_VERTICAL` | Um conteúdo **mais alto que a tela** do celular | passo 18b |
| `ANDROID` | Um Android físico, com o preview **instalado pela tela inicial** | passos 18e a 18g, 18i |
| `IPHONE` | Um iPhone físico, mesmo preparo | passo 18h |

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
6a. **[mãos]** Ainda no `APARELHO`, tocar no `ViewModeToggle` e trocar para **Lista**, com
   um conteúdo de **nome longo**. **Esperado:** o nome trunca com reticências, nada
   cortado. _610 px de estouro hoje — o pior número da tela, a um toque do caminho feliz._
   _(DoD 34-B)_
7. **[olho]** Janela de desktop a **599** e a **601**. **Esperado:** 599 → gaveta; 601 →
   **barra lateral de volta E o cabeçalho empilhado, nada cortado**. _Dois prints. A
   segunda metade é o que separa este aceite de um que passaria com a tela estourada._
   _(DoD 30, 34)_
7-bis. **[máquina]** Os três limiares da D27, em janela real: **599 → gaveta**;
   **601 → barra lateral, cabeçalho empilhado**; **795 → barra lateral e cabeçalho em
   linha**. _É a terna que prova que os limiares são dois e independentes._ _(DoD 34)_
7-ter. **[máquina]** **Varredura de geometria (D25) — medida, não fotografada.**
   As 11 larguras de borda, **com árvore nova em cada uma**, verificando **presença e
   tamanho**: `SlugBadge` acima do próprio `minimumWidth` (320–375 é onde ele some hoje);
   tile da Grade no ponto de transição **calculado** (~370/375/380); modo Lista truncando
   (394/412/430); os quatro diálogos, inclusive a **1440** com categoria de 45 caracteres.
   _(DoD 34-A, 34-D, 34-E, 34-F, 34-G)_

   > **Por que isto saiu do humano.** A versão anterior deste roteiro mandava o dev olhar
   > **nove a dezenove larguras de janela** e procurar faixa amarela. Errado duas vezes:
   > **largura é geometria, e geometria se mede** — pedir print para provar largura é
   > gastar a atenção mais cara do time no que a máquina faz melhor; e **procurar faixa é
   > procurar o sinal errado** nestes defeitos (D25). O humano continua sendo insubstituível
   > no que segue — e **só** no que segue.

**Bloco A3 — o que só o hardware prova.** Levantado pelo QA como exclusivo de aparelho
físico: nenhum destes o CDP reproduz, e nenhum é sobre largura.

7-h1. **[mãos]** **A foto de campo em aparelho físico**, mesma tela, mesmo conteúdo.
   _**Atendido** pela `rodada_01` (itens 28, 29, 31, 33 e 35-A). Emulador não serve: o item
   22 do DoD exige aparelho, e a régua da §11.0 vale para pixel de aparelho, não de
   `--screenshot`._
7-h2. **[mãos]** **Gaveta com toque real** — abrir tocando no botão, fechar selecionando
   uma categoria, e **abrir pelo _edge swipe_** da borda esquerda. _O edge swipe do
   `Drawer` é gesto de plataforma; o CDP não o reproduz, e é como metade dos usuários de
   Android abre gaveta._
7-h3. **[mãos]** **Teclado virtual sobre o campo de busca:** tocar na busca e digitar com
   o teclado do sistema aberto. **Esperado:** o campo continua visível e o resultado
   também. _O teclado virtual muda o `viewInsets` de um jeito que nenhum teste de widget
   e nenhum navegador de desktop reproduz — e é onde uma tela "que cabia" deixa de caber._

**Bloco A2 — o editor degrada com dignidade (F1b) · o passeio termina aqui, não no
Bloco A**

7a. **[mãos]** No `APARELHO`, **na lista do passo 4**, tocar num conteúdo. **Esperado:** a
tela de aviso, **com os dois botões visíveis**. _Reprova se aparecer qualquer pedaço do
construtor — paleta, inspector ou faixa de canvas._ _(DoD 35-A)_
7b. **[mãos]** Tocar em **"Ver conteúdo"**. **Esperado:** o conteúdo renderizado, e a URL
do aparelho com **o mesmo `<id>` do conteúdo tocado no passo 7a**. _Foto das duas telas;
"foi para alguma tela de preview" não basta._ _(DoD 35-B)_
7c. **[mãos]** Voltar e tocar em **"Voltar aos conteúdos"**. **Esperado:** a lista, com o
nome do projeto certo no breadcrumb. _(DoD 35-D)_
7d. **[olho]** Janela de desktop a **599** e a **1280**, agora **no editor**. **Esperado:**
599 → portão; 1280 → construtor inteiro, **com o mock visível**. _**Não teste a 601.** Ali
o canvas tem largura zero por um estouro do `ResizableSplitView` que pertence à F3 — o
resultado seria um print que parece regressão da F1b e não é (§5›F1b›7-E)._ _(DoD 35-E)_

> **Os passos 1 a 7d são um passeio só, no mesmo aparelho, sem voltar ao desktop no meio.**
> É ele que prova que a F1 não termina em beco — e é por isso que a F1 não fecha sem a
> F1b (§5›F1b). Um E2E que parasse no passo 7 atestaria "achei o conteúdo" e deixaria
> "abri o conteúdo" sem resposta. _(DoD 35-C)_

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
12a. **[olho]** **A status bar do mock (5.1)**, nos **três presets**. **Esperado:** relógio,
    sinal, wifi e bateria desenhados no topo, dentro da moldura; o recorte da câmera por
    cima, **sem sobrepor** relógio nem ícones; embaixo, o indicador de home. _(DoD 36-A,
    36-D)_
12b. **[olho]** **O par que prova o `SafeArea` — é o pedido da 5.1, e o caminho feliz não o
    prova.** Mesmo conteúdo, uma foto com a área segura respeitada e outra sem.
    **Esperado:** sem, o conteúdo passa **por baixo do relógio**; com, começa **abaixo** da
    faixa. _Duas fotos visualmente distintas. Iguais = a status bar virou enfeite._
    _(DoD 36-C)_
12c. **[máquina]** **A disciplina da D32, conferida no histórico, não na imagem:**
    `git log --stat` do PR 3 mostra **dois** commits tocando
    `goldens/canvas_device_mock.png`; o primeiro **sem** `device_frame.dart`, o segundo
    **sem** os arquivos do fit. _Não se confere PNG a olho: confere-se a atribuição._ E os
    dois goldens, sobrepostos, têm o **topo do conteúdo no mesmo y** — é o par do 36-B.
    _(DoD 5, 36-B)_

**Bloco C — painéis, paleta, memória e tela cheia (F4, F4b, F5 a F7)**

13. **[olho]** Colapsar a paleta; depois o Inspector. **Esperado:** faixas finas com os
    ícones, **o percentual do canvas sobe**, os dois controles de reabrir visíveis. Com a
    paleta colapsada, clicar em **Árvore** reabre **na aba Árvore**. _(DoD 37, 38, 39)_
14. **[olho]** Fechar os 4 grupos da paleta; digitar `col`; limpar. **Esperado:** fechados
    sem rolagem → `Layout` abre com `Column` visível → **volta a fechar**. _Três prints; o
    terceiro é o que prova._ _(DoD 40, 41)_
14a. **[olho]** **A troca de aba (F4b)** — trio: 3 grupos fechados → aba **Árvore**, com a
    árvore desenhada → de volta em **Widgets**. **Esperado:** os **mesmos 3 fechados**. _O
    print do meio existe para o primeiro e o terceiro não poderem ser a mesma foto._
    _(DoD 45-A)_
14b. **[olho]** Digitar `col`, ir para **Árvore**, voltar. **Esperado:** campo de busca
    **vazio** e os 3 grupos fechados. _Busca é momento, colapso é hábito (D28) — este passo
    reprova nas duas pontas._ _(DoD 45-B)_
14c. **[olho]** Fechar 3 grupos → **colapsar a paleta na faixa fina** (F5) → reabrir.
    **Esperado:** os mesmos 3 fechados. _É a única coisa que exercita a tarefa 4 da F5._
    _(DoD 45-C)_
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
18. **[mãos]** Editar `CT_IMG` no desktop **sem salvar** → **puxar de cima** no aparelho.
    **Esperado:** **nada muda**. Depois **Salvar** → puxar. **Esperado:** muda. E a pílula
    diz **"Último salvo"** — na foto, não no código. _Depois da F2b o gesto substitui o
    toque na pílula; a pílula continua na tela e deixa de ser botão (D30)._ _(DoD 53, 54)_

**Bloco D2 — o gesto e o app instalado (F2b, F2c) · aparelho físico obrigatório**

18a. **[mãos]** `CT_CURTO` (um `text` só, que não enche a tela): **puxar de cima**.
    **Esperado:** o indicador aparece. _É o caso que a física padrão **não** atende, e o
    modo de falha silenciosa desta fase: sem `AlwaysScrollableScrollPhysics` o gesto
    simplesmente não pega, sem erro nenhum._ _(DoD 52-A)_
18b. **[mãos]** `CT_LONGO_VERTICAL` (mais alto que a tela) — **par**: (a) no topo, puxar →
    indicador; (b) rolado até o meio, puxar → **a tela rola**, sem indicador. _Prints
    iguais = o `RefreshIndicator` sequestrou a rolagem e o fim do conteúdo ficou
    inalcançável._ _(DoD 52-B)_
18c. **[mãos]** Puxar **sem ter mudado nada no desktop**. **Esperado:** conteúdo igual, e o
    **horário do carimbo muda**. _(DoD 52-C)_
18d. **[mãos]** **Modo avião**, puxar. **Esperado:** o conteúdo **continua na tela**, o
    banner de falha aparece, e o carimbo **não muda**. _Trio com o 18c: os três estados da
    D30 em três prints distintos. Carimbo que avança com a rede caída reprova — é o gesto
    mentindo que buscou._ _(DoD 52-D)_
18e. **[mãos]** **Android:** instalar o preview pela tela inicial; depois **tocar num link
    `/preview/<projectId>/<id>`** vindo de outro aplicativo. **Esperado:** abre **sem barra
    de endereços**. _É o pedido literal da frente 4.3._ _(DoD 50-A)_
18f. **[mãos]** Ainda no Android: abrir pelo **ícone** da tela inicial. **Esperado:** a tela
    curta do `start_url`, com caminho para os projetos — **não** 404, não o editor.
    _(DoD 50-B)_
18g. **[mãos]** Ainda no Android: abrir um link do **editor** (`/contents/...`).
    **Esperado:** abre no navegador, com barra. _Reprova se abrir dentro do app de preview:
    `scope` grande demais (D31)._ _(DoD 50-C)_
18h. **[mãos]** **iPhone, o mesmo link** — **par**: pelo link → **com** barra de endereços;
    pelo ícone → standalone. _Este passo **não reprova o iOS**; ele reprova a **D31** se as
    duas fotos forem iguais, porque aí a fronteira de plataforma declarada não é a real._
    _(DoD 50-D)_
18i. **[olho]** Na foto do 18e (standalone, aparelho com recorte): **o conteúdo respeita a
    área segura do aparelho?** _**Observação, não aceite** — é o R14, e a resposta alimenta
    o discovery da frente 4.2, que segue pendente. Anotar sim/não com foto; não reprova a
    rodada._

**Bloco E — a camada do indicador (D22), e a única exceção ao "nunca localhost"**

19. **[máquina]** **Em build de debug local** (`flutter run -d chrome --target
    apps/driva_editor/lib/main_dev.dart --dart-define-from-file=apps/driva_editor/config/dev.json`),
    repetir as larguras de borda: **320, 360, 370, 375, 380, 394, 412, 430, 460, 560, 599,
    600, 612, 700, 794, 795, 1024, 1280, 1440**, na tela de projeto **e** no editor.
    **Esperado: nenhuma faixa listrada em nenhuma delas.** _Este passo roda em localhost
    **porque o indicador de overflow só existe em debug** (D22). Ele **não substitui** os
    passos 1 a 12: aqueles provam que o usuário não vê o defeito; este prova que o defeito
    não está apenas escondido._

    > ⚠️ **Este passo vale menos do que parecia, e é preciso saber quanto.** Ele **não
    > detecta** widget que colapsa a zero e some: `RenderFlex.paint` retorna em
    > `size.isEmpty` **antes** de desenhar a faixa (D25). Foi assim que a faixa 320–392
    > passou por limpa com o `SlugBadge` invisível. **Quem cobre essa classe é o passo
    > 7-ter (presença observada) e o DoD 10d (geometria medida).** O passo 19 continua
    > útil para overflow *clássico* — o que corta e transborda —, e **só para isso**.

---

## 11. Definition of Done

**O item 41 só está pronto quando todas as linhas abaixo estiverem marcadas.** Cada linha
diz **como se prova** — nada aqui se atesta por opinião.

### 11.0 Como um aceite mente — cinco casos, uma forma só

Não é regra abstrata: são **cinco aceites reais**, três do item 39 e dois deste plano,
todos escritos por alguém competente, todos falsos. Ler isto antes de escrever qualquer
linha nova de aceite.

| # | Aceite | Escrito a partir do **mecanismo** | O **estado observável** que faltava | Como mentiu |
| --- | --- | --- | --- | --- |
| 1 | `Ctrl+Shift+W` (item 39) | "o atalho está no mapa de `Shortcuts`" | "o modo entra" | Chrome come a combinação: o mapa estava certo e o app nunca recebia a tecla |
| 2 | `loadingBuilder` (item 39) | "o builder foi passado" | "o spinner aparece" | presente na API, nunca renderizado no caminho real |
| 3 | `width: 0` (item 39) | "a prop chega no widget" | "a imagem ocupa espaço na tela" | valor legítimo na API, invisível na tela |
| 4 | Faixa listrada em release (este plano, D22) | "não há `RenderFlex overflow`" | "nada está cortado na borda" | o indicador é pintado dentro de `assert` — **em release não existe**, e o aceite passava sempre |
| 5 | **601 px (este plano, F1b›7-E)** | "o portão dispara a 600, logo a 601 há construtor" | "o canvas aparece" | a 601 o `CenterArea` tem **largura zero**: o portão sai, e o defeito da foto volta |
| 6 | **"Sem faixa amarela" (este plano, D22 → D25)** | "o `RenderFlex` não reportou overflow" | "**o elemento aparece na tela**" | `RenderFlex.paint` retorna em `size.isEmpty` **antes** de pintar o indicador: widget que colapsa a zero **some sem faixa e sem erro**. Derrubou as **três** camadas da D22 de uma vez |
| 7 | **"a 601 há barra lateral" (este plano, F1›6 → D27)** | — _o aceite estava certo quando foi escrito_ | — _e continuou parecendo certo depois de deixar de ser_ | **forma nova**: uma decisão posterior moveu o limiar de 600 para 795 e **ninguém varreu os aceites que citavam 600**. O texto não errou; ele **envelheceu** |

**A forma comum:** o aceite descreve o que o **código faz**, não o que a **tela mostra**.
Todo aceite deste plano é escrito como *o print que o provaria* por causa desses cinco.

**O que o caso 5 ensina e os outros quatro não ensinam.** O número `601` não foi
inventado: veio da **fronteira do mecanismo** (o portão dispara em 600). Mas a fronteira
do mecanismo e a fronteira do estado observável **são grandezas diferentes** — o canvas só
volta a ter largura acima de 612, e quanto acima é a **F3** que decide. Daí duas regras:

- **O número do aceite vem de onde o estado observável muda, não de onde o mecanismo
  dispara.** Quando os dois coincidem, é coincidência — verifique, não presuma.
- **Um aceite não pode depender de uma fase futura para ser verdadeiro.** Se o observável
  só aparece depois que outra fase mergear, o aceite **pertence àquela fase**. O 7-E pedia
  um print que a F1b não tinha como produzir; pior, quem tentasse produzi-lo concluiria
  que a F1b quebrou o editor. Aceite assim não só falha: **acusa o inocente.**

**O que o caso 6 ensina, e é o mais caro dos seis:** ele **quebrou a correção do caso 4**.
A D22 nasceu para consertar o caso 4 e montou três camadas — todas sobre o mesmo sinal.
Quando o sinal não é emitido, as três caem juntas. Daí a terceira regra:

- **Aceite negativo ("não apareceu X") é frágil por natureza.** Ele confunde *ausência de
  defeito* com *ausência de sinal*, e as duas coisas se parecem exatamente. Sempre que
  possível, o aceite é **positivo e medido**: "o elemento aparece", "a largura renderizada
  é ≥ o mínimo", "o percentual mudou". Quando um aceite negativo for inevitável, escreva
  **por que o sinal seria emitido** se o defeito existisse — e se não souber responder, o
  aceite não vale.

**O caso 7 é o único de forma diferente, e por isso a defesa é outra.** Os seis primeiros
nasceram errados: escolheram o sinal errado no momento em que foram escritos, e uma
releitura atenta os pegaria. **O sétimo nasceu certo.** O aceite "a 601 há barra lateral"
era verdade quando foi escrito; deixou de ser quando a Causa B′ moveu o limiar de 600 para
795 — e **continuou parecendo verdade**, porque nada no texto denuncia que o número virou
órfão. Releitura atenta não pega: só pega quem souber que o limiar mudou.

- **Aceite que cita um número é acoplado à decisão que fixou aquele número.** Trocar o
  limiar é uma **edição em dois lugares**, sempre: o código e os aceites que o mencionam.
  Vale para larguras, durações, chaves de preferência, nomes de rota — qualquer constante
  que apareça num aceite.
- **É por isso que o caso 7 refina o caso 5.** O 5 dizia: o número vem de onde o
  observável muda, não de onde o mecanismo dispara. O 7 acrescenta: **e quando o mecanismo
  se muda de casa, o número que você escreveu fica para trás.**

**Teste de bolso, antes de escrever qualquer aceite:** _consigo tirar esse print hoje, com
o que está mergeado, e ele fica diferente se a fase falhar?_ Se a resposta a qualquer
metade for "não", o aceite ainda está descrevendo o mecanismo.

**Segundo teste de bolso, do caso 6:** _se o defeito existisse, o que exatamente
produziria o sinal que eu estou esperando?_ Se a resposta for "o framework reporta", vá
ler **onde** ele reporta.

**Terceiro teste de bolso, do caso 7 — este é para quem _muda_ algo, não para quem
escreve o aceite:** _que aceites mencionam o número que eu acabei de mudar?_ Faça o
`grep` no `plan.md` **antes** de fechar a tarefa. É a única defesa contra um aceite que
não errou — envelheceu.

### 11.1 Cancela de máquina

| # | Item | Como se prova |
| --- | --- | --- |
| 1 | `flutter analyze` verde no workspace | saída do comando, zero issues, no PR |
| 2 | Suíte existente passando (`flutter test -r compact`) em `sdui_core`, `sdui_flutter` e `driva_editor` | saída no PR |
| 3 | **Zero linha em `packages/`** | `git diff --stat origin/develop -- packages/` = vazio, em **todos** os PRs |
| 4 | **Zero linha em `backend/`** | `git diff --stat origin/develop -- backend/` = vazio |
| 5 | **`goldens/canvas_device_mock.png` regravado em DOIS commits no PR 3, um por causa (D32)** | `git log --stat` do PR: o commit do fit **não** contém `device_frame.dart` nem tokens de status bar; o commit da status bar **não** contém arquivo do fit. Cada um cita a sua causa. **Um commit só com as duas causas reprova, mesmo com as duas citadas** — o revisor perde a capacidade de atribuir o diff |
| 6 | **Gate 1** — nenhuma função/método novo que retorna `Widget` fora do permitido | leitura do diff; nenhum `Widget _buildX(` novo |
| 7 | **Gate 4** — nenhum tamanho, duração ou cor cru nos arquivos tocados | `grep` nos arquivos do diff: só tokens |
| 8 | **Gate de rebuild (D8)** — colapsar **não** reconstrói `LeftPanel`, `CenterArea` nem `InspectorArea` | teste de widget com contador de builds (F9). **É de máquina: não existe print que prove isto, e nenhum foi inventado** |
| 9 | **O editor não _usa_ o breakpoint do kernel** (D5›cerca 1) | `grep -rn "SduiBreakpoint" apps/driva_editor/lib \| grep -vE ':[0-9]+:\s*///?'` = **zero**. _A cerca mede uso, não menção: o doc do `app_breakpoints.dart` precisa nomear o enum para explicar por que ele não entra_ |
| 10 | **O limiar entra no `editor_module` por UMA porta** (D5›cerca 2a) | `grep -rl "AppBreakpoints" apps/driva_editor/lib/modules/editor_module` = **exatamente** `.../presentation/editor/page/editor_viewport_gate.dart` |
| 10b | **A UI do construtor é cega a faixa** (D5›cerca 2b, D20, D23) | `grep -rn "AppBreakpoints" apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/` = **zero**. _É este que carrega a promessa "o construtor não se adapta por faixa"; afrouxá-lo é desvio, não ajuste (R10)_ |
| 10c | **`AppBreakpoints` não tem constante sem leitor** (D26) | para cada constante do arquivo, existe pelo menos um consumidor fora dele. `expanded`/1024 **saiu**; o número segue registrado na D5 |
| 10d | **Geometria medida, não ausência de faixa** (D25) | todo widget de chrome interno fixo tocado por este item expõe `minimumWidth` **público** e **derivado dos tokens do próprio `build`** — nunca um literal —, e há teste `tester.getSize(...).width >= X.minimumWidth` nas larguras de borda **e nos pontos de transição**. _Sem isto, a régua de overflow do plano inteiro é cega à classe do `SlugBadge`_ |
| 10e | **O mínimo é derivável, e a derivação fecha** (D25) | `minimumWidth` é uma **expressão de tokens**, e cada termo dela é token — não número solto. _Este item existe porque a primeira implementação entregou `_minWidth = 28` privado, contra os **39** que o plano mediu (`s10×2 + ícone 14 + s5`): **um dos dois está errado e ninguém consegue dizer qual sem derivar**. Ver a nota da Causa G_ |
| 10f | **A cerca da D28** — o caminho quente da D8 não foi ligado, e o escopo de rebuild do painel esquerdo não regrediu | `grep -rn "AutomaticKeepAliveClientMixin\|wantKeepAlive" apps/driva_editor/lib` = **zero**; `const LeftPanel()` continua em `editor_workspace.dart`. _Medido na D28: manter a aba Árvore montada custa 9–28 µs e ~2 KB de lixo **por tecla** numa página de 40–120 nós. Não é catástrofe — é desperdício sem guarda, e a linha que o liga é uma só_ |
| 10g | **O piso do workspace é público e derivado** (D25›1, e é dele que o 17-A tira as larguras) | `AppSizes.workspaceMinimumWidth` existe, é **expressão de tokens** (não literal), e a descrição do PR 3 **registra o valor** que ele tinha na rodada. _Sem o registro, o R13 volta: o 5.3 muda o piso e ninguém sabe contra que número os prints foram tirados_ |
| 11 | CI verde em todos os PRs — a mesma régua do humano | checks do GitHub |

### 11.2 Aceite por fase

| # | Item | Como se prova |
| --- | --- | --- |
| 12 | Os **14 critérios da F1** (1 a 7, com `6-A` a `6-G`) atestados **e os 6 da F1b** (`7-A` a `7-F`) | `revisar-fase` do QA nos PRs 1 **e** 1b. **A F1 não fecha sem a F1b** (§5›F1b): "navegar no celular funciona" é falso enquanto tocar num conteúdo der num beco |
| 13 | Os **5 critérios da F2** atestados | `revisar-fase` do QA — **PR #135, mergeado** |
| 13b | Os **5 critérios da F2b** (`12-A` a `12-E`) atestados | `revisar-fase` do QA no PR 2c |
| 13c | Os **4 critérios da F2c** (`12-F` a `12-I`) atestados | `revisar-fase` do QA no PR 2d |
| 14 | Os **12 critérios da F3** atestados — os 8 da D1 (incluindo o `17-A`) **e os 4 da 5.1** (`19-A` a `19-D`) | `revisar-fase` do QA no PR 3 |
| 15 | Os **4 critérios da F4** atestados | `revisar-fase` do QA no PR 2 |
| 15b | Os **3 critérios da F4b** (`23-A` a `23-C`) atestados | `revisar-fase` do QA no PR 2b |
| 16 | Os **5 critérios da F5** atestados, incluindo o `26-A` (o colapso da F4b sobrevive ao colapso do painel) | `revisar-fase` do QA no PR 4 |
| 17 | Os **4 critérios da F6** atestados | `revisar-fase` do QA no PR 6 |
| 18 | Os **4 critérios da F7** atestados | `revisar-fase` do QA no PR 5 |
| 19 | Nenhum desvio das decisões **D1–D32** sem `variance_report.md` aprovado **pelo humano** | desvios numerados `VR-17-NN`, com "como estava / por que mudou / o que mudou" |

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
| 25 | **O defeito de campo está documentado com causa rastreável** em `evidencias/rodada_00/README.md` — tabela sintoma → causa, cada linha apontando arquivo e linha do código que a produz | o README existe e nenhum sintoma fica sem causa nomeada no código. _As fotos do "antes" **não** foram arquivadas antes de a F1/F1b mergearem, e o estado não é mais reproduzível em homologação. A causa no código substitui a comparação visual — e é evidência mais forte, porque uma foto mostra **que** quebrou e a linha mostra **por quê** (D33)_ |
| 25-A | **As fotos de campo do "depois"** arquivadas em `evidencias/rodada_01/` — projetos (`00_…`), conteúdos (`01_…`) e o portão do editor (`02_…`) | os arquivos existem, com o `README.md` da pasta dizendo qual aceite cada um prova |
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
| 28 | O título não desce letra por letra | foto do aparelho: **uma linha horizontal**, com reticências se não couber — `rodada_01/01_conteudos_android.jpg` | qualquer texto vertical. _**Atendido** (rodada 01): "Todos os conteúdos" em uma linha, e a busca com o hint inteiro — `Buscar por nome, slug ou ID...`, não `Busc…`_ |
| 29 | As categorias não comem a tela | foto sem barra lateral + foto da gaveta aberta | a barra lateral aparecer em `compact` |
| 30 | A gaveta fecha ao selecionar | par: toque em "Divulgar" → gaveta fechada **e** lista filtrada | a gaveta ficar aberta sobre a lista |
| 31 | A busca é usável no celular | foto do campo com hint legível e texto digitado | `Busc…` |
| 32 | Criar conteúdo cabe (Causa C) | diálogo com os dois botões visíveis, sem rolagem horizontal | qualquer botão fora da tela |
| 33 | A home de projetos funciona no celular | foto com cartões legíveis | conteúdo de cartão cortado |
| 34 | **Os dois limiares são dois, e independentes** (D27) | **terna**: 599 → gaveta · 601 → **barra lateral, cabeçalho ainda empilhado** · 795 → barra lateral **e** cabeçalho em linha | o print de 601 for igual ao de 599 (um limiar só governando tudo — **o desvio que a rodada 4 pegou**) ou igual ao de 795. _Um par de larguras não distingue os casos; por isso são três_ |
| **34-A** | A lacuna **600–794** foi fechada (Causa B′) | prints a **600**, **700** e **794**: cabeçalho empilhado, nada cortado | qualquer uma das três cortar. _Hoje: 195 px faltando a 600; 0,66 a 794_ |
| **34-B** | O modo **"Lista"** também funciona (Causa D) | foto do aparelho no modo Lista, nome longo truncando com reticências | o nome cortar ou empurrar a linha. _610 px de estouro a 360 hoje, a **um toque** do modo Grade — E2E que só percorre Grade não cobre metade da tela_ |
| **34-C** | O vocabulário de faixa não foi corrompido (D26) | `app_breakpoints.dart` define **só o limiar `compact`**; toda constante tem leitor | um número sem consumidor ficar, **ou** um número que não é faixa entrar. _795 saiu por não ser faixa; 1024 saiu por não ter leitor_ |
| **34-D** | A Grade cabe **na transição de colunas** (Causa E) | prints a **370, 375, 380**: conteúdo do tile inteiro | qualquer um cortar. _375 é iPhone SE/8. Testar só 360 e 412 **passa** e não prova nada: alargar a tela encolhe o tile_ |
| **34-E** | A Lista cabe em **394–460** (Causa F) | prints a **394, 412, 430**: nome truncando com reticências | qualquer um estourar. _Pixel e Pro Max_ |
| **34-F** | **O `SlugBadge` aparece** (Causa G / D25) | prints a **320, 360, 375** com o badge **legível**, mais o teste de geometria (DoD 10d) | o badge sumir ou ficar ilegível. _**Aceite positivo de propósito.** "Não houve faixa amarela" **não serve aqui**: neste defeito não há faixa nem quando ele existe (§11.0›caso 6)_ |
| **34-G** | O diálogo cabe com categoria de nome longo (Causa C′) | print a **1440** e no aparelho: dropdown sem estouro | estourar em qualquer largura. _216 px hoje, e **não é defeito de celular**_ |
| 35 | **O construtor não foi "aproveitado" pela faixa** (D20, D23) | prova de máquina, DoD 10 e 10b | o limiar aparecer em mais de um arquivo do módulo, **ou** em qualquer arquivo sob `presentation/editor/widgets/` |
| **35-A** | **O editor no celular não é mais uma tela quebrada** (D23) | foto do aparelho: tela de aviso **com os dois botões** — `rodada_01/02_editor_portao_android.jpg` | aparecer **qualquer** pedaço do construtor: paleta, inspector, faixa de canvas. _**Atendido** (rodada 01): o aviso, "Ver conteúdo" e "Voltar aos conteúdos", e nenhum pedaço do construtor na tela_ |
| **35-B** | **"Ver conteúdo" leva ao conteúdo que estava aberto** | par de fotos: portão → preview, com **o mesmo `<id>` na URL** do conteúdo tocado | ir para "alguma" tela de preview, ou para outro conteúdo. _Um botão que existe não é um botão que funciona_ |
| **35-C** | **A navegação no celular não termina em beco** | o passeio inteiro num aparelho só: lista → tocar → portão → preview (§10›Bloco A2) | qualquer etapa exigir voltar ao desktop. _É o item que amarra F1 e F1b_ |
| **35-D** | **"Voltar aos conteúdos" volta ao projeto certo** | foto da lista com o nome do projeto no breadcrumb | outro projeto, ou 404 |
| **35-E** | **O portão sai de cena acima do limiar, e o construtor volta intacto** | par: janela a **599** → portão; a **1280** → construtor **com o mock visível** | os dois estados forem iguais, **ou** o construtor a 1280 vir diferente de antes da F1b. _**Não** use 601: a 601 o canvas tem largura zero por um defeito que é da F3 (§5›F1b›7-E). Print nessa faixa não é prova contra a F1b_ |
| 36 | O mock cabe na janela | Tablet a 1024×720, **quatro quinas visíveis**, barra **abaixo de 40%** | a moldura sair da área, **ou** a barra travar em 40% — a escala passou pelo clamp (D9) |
| **36-A** | **A faixa do topo do mock deixou de ser vazia** (5.1) | Smartphone com relógio, sinal, wifi e bateria **desenhados** dentro da moldura | a faixa continuar vazia. _Aceite **positivo**: o elemento aparece_ |
| **36-B** | **Desenhar não empurrou o conteúdo** (D29) | par antes/depois (commits A e B da D32) com o **topo do conteúdo no mesmo y** | o conteúdo descer. _É o recuo contado duas vezes — defeito de uma linha, que passa como "ficou mais espaçado"_ |
| **36-C** | **O `SafeArea` ganhou causa visível — a promessa da 5.1, não o caminho feliz** | par com o **mesmo conteúdo**: sem área segura, ele passa **por baixo do relógio**; com, começa **abaixo** da faixa | os dois prints forem iguais. _Aí a status bar virou enfeite e não explica nada — que é o estado de hoje, só que com pixels bonitos_ |
| **36-D** | **Os três presets, sem colisão** | Smartphone (pill), Android (punchHole) e Tablet: relógio e ícones **fora** do recorte da câmera, altura = `safeAreaTop` daquele preset | qualquer sobreposição. _393 px é o mais estreito; um preset só passa e não prova_ |
| 37 | O ajuste é reativo | dois prints, 1440 → ~900, sem tocar em nada: percentuais diferentes | percentuais iguais |
| 38 | Manual vence o ajuste (P5) | toggle **selecionado** × **não-selecionado**, percentuais diferentes | os dois estados forem visualmente iguais |
| 39 | O breadcrumb trunca | `CT_LONGO` a 1280, uma linha com reticências | duas linhas, ou texto cortado na borda |
| 40 | A faixa 1 não engole ação | print **com o menu de overflow aberto**, mostrando "Salvar" e "Publish" | só o `⋮` aparecer: um menu vazio passaria e reprovaria na prática |
| 41 | O workspace estreito degrada em vez de sumir | a 560: rolagem horizontal, **nada sumindo na borda direita** | conteúdo cortado sem rolagem |
| 42 | **Não há overflow escondido** (D22) | passo 19, **em debug local**: nenhuma faixa listrada em 360, 412, 560, 599, 600, 612, 700, 1024, 1280, 1440 | qualquer faixa. _E se este item for "provado" com print de homologação, **reprova por construção**: lá a faixa não existe_ |
| 43 | Painel do editor colapsado continua alcançável (D2) | faixa fina com o controle de reabrir **dentro dela** | o único caminho de volta for atalho ou menu escondido |
| 44 | Colapsar dá espaço **ao mock** | par com o **percentual do canvas subindo** | o percentual não mudar — o espaço virou fundo cinza |
| 45 | Buscar com grupos fechados acha | trio: fechados → `col` abre `Layout` → limpar **fecha de novo** | o terceiro print não voltar ao estado do primeiro |
| **45-A** | **O colapso sobrevive à troca de aba** (1.1 / D28) | trio: 3 fechados → aba **Árvore com a árvore desenhada** → volta com **os mesmos 3 fechados** | o terceiro print vier com os quatro abertos. _O print do meio existe para o primeiro e o terceiro não poderem ser a mesma foto tirada duas vezes_ |
| **45-B** | **A busca continua efêmera, e isso é decisão** (D28) | `col` → Árvore → voltar: campo **vazio** e os 3 grupos fechados | qualquer das duas pontas: busca sobrevivendo (paleta filtrada sem motivo à vista) **ou** grupos reabrindo |
| **45-C** | **O colapso sobrevive ao colapso do painel** (F5›tarefa 4) | 3 fechados → colapsar a paleta na faixa fina → reabrir: os mesmos 3 | os quatro abertos. _É a **única** coisa que exercita a tarefa 4 da F5; sem esta linha, esquecê-la não produz sinal nenhum e a queixa 1.1 volta uma fase depois_ |
| 46 | O layout sobrevive ao **refresh** | antes/depois de `F5` | qualquer diferença |
| 47 | O layout sobrevive à **navegação** | antes/depois de sair pelo breadcrumb e voltar | qualquer diferença. _É o incômodo relatado; o refresh sozinho não cobre_ |
| 48 | Largura salva é reclampada (D13) | 480 salvo, janela em 1024, após recarregar | painel maior que a janela |
| 49 | Preferência corrompida **não bloqueia** (D12) | lixo em `flutter.editor.layout` + reload → editor abre em 280/320 | tela branca, erro, ou carregando eterno |
| 50 | O preview abre **frio** no aparelho (D18) | foto de celular que **nunca abriu o editor**, URL visível | 404, ou só funcionar depois de passar pela tela do projeto |
| **50-A** | **O link abre sem barra de endereços** (4.3 / D31) | **Android**, preview instalado: tocar num link `/preview/<projectId>/<id>` vindo de outro app → **sem barra** | abrir no navegador com a barra. _É o pedido literal da frente 4.3, e é onde se descobre que o `scope` ficou errado_ |
| **50-B** | **O ícone da tela inicial não dá em beco** | abrir pelo ícone (`start_url`, sem ids) → a tela curta, com caminho para os projetos | 404, tela branca, ou o editor inteiro |
| **50-C** | **O `scope` não capturou o editor junto** | link do **editor** (`/contents/...`) no mesmo aparelho → abre no navegador, normal | abrir dentro do app de preview. _`scope` grande demais: o dev perderia a barra de endereços justamente onde precisa dela_ |
| **50-D** | **A fronteira de plataforma declarada é a real** (D31) | **iPhone**, par: pelo **link** → **com** barra; pelo **ícone** → standalone | as duas fotos do iPhone forem **iguais**. _Não reprova o iOS — reprova a **D31**, porque aí a limitação que o plano declarou não é a que existe_ |
| 51 | O preview **não perde o resolver** (D6 / I1) | na mesma foto, a `image` sem ACAO **carregada** | caixa "falhou" — é a regressão exata do item 39 |
| 52 | O preview mostra o **último salvo** (D4) | par: editar sem salvar → **puxar** → **não muda**; salvar → puxar → **muda**; e a pílula diz **"Último salvo"** nas duas fotos | o primeiro par mudar, **ou** a pílula não dizer "Último salvo". _O aceite 12 da F2 exigia essa palavra e o código mergeado escreve `Verificado às` — passou sem ser conferido (D30)_ |
| **52-A** | **Conteúdo curto puxa** (4.1) | um conteúdo de **um `text`**, que não enche a tela: puxar → **indicador visível** | o gesto não pegar. _É o modo de falha silenciosa desta fase: com a física padrão o `SingleChildScrollView` tem extensão zero e o gesto **simplesmente não existe**, sem erro nenhum_ |
| **52-B** | **Conteúdo longo rola e puxa, e não os dois ao mesmo tempo** | par: no **topo**, puxar → indicador; **rolado até o meio**, puxar → **rola**, sem indicador | os dois prints forem iguais. _`RefreshIndicator` sequestrando a rolagem deixa o fim do conteúdo inalcançável_ |
| **52-C** | **O gesto de fato buscou** (D30) | puxar sem mudar nada: conteúdo igual, **horário do carimbo muda** | o carimbo não mudar. _É o caso do meio da tabela da D30: sem o carimbo, "puxei e nada mudou" e "puxei e falhou" são o mesmo print_ |
| **52-D** | **A falha é visualmente distinta e não custa o conteúdo** (D30) | **modo avião**, puxar: conteúdo **na tela**, banner de falha **aparece**, carimbo **não muda** | o conteúdo sumir, a tela virar erro, **ou** o carimbo avançar com a rede caída. _Carimbo que avança sem ter buscado é o gesto mentindo, e é indistinguível de sucesso_ |
| 53 | Tela cheia tem saída visível | print do modo ligado **com o controle de sair** | nenhum controle visível |
| 54 | Tela cheia **não esconde erro** (P2) | par: com erro → rodapé fica; sem erro → some | o rodapé sumir com erro. _Reintroduziria o sintoma que o item 38 corrigiu_ |
| 55 | O atalho, se houver, **chega ao app** (D16) | print do modo ligado logo após teclar, **no Chrome real** | o navegador capturar. _Lição do `Ctrl+Shift+W`: o `SingleActivator` no mapa não prova nada_ |

**Os itens 28, 34-F, 35-A, 35-C, 36-C, 42, 51, 52-D e 54 são a cancela.** O **36-C** entrou
porque é a única linha que separa "desenhei uma status bar" de "o `SafeArea` passou a ter
causa visível" — que é a **promessa** da frente 5.1; sem ele, 5.1 entrega pixels e não
entrega o argumento pedagógico que a justificou. O **52-D** entrou porque um gesto que
carimba a hora sem ter buscado é **indistinguível de sucesso** no celular, e num aparelho
offline o dev não tem console para descobrir. O **34-F** entrou porque um
widget que some é o único defeito desta lista que **passa em todas as outras verificações**
— e um item que a régua antiga não enxergava é exatamente o que uma cancela existe para
pegar. Se o texto ainda desce letra por
letra, se o editor no celular ainda é uma tela sem canvas, se abrir um conteúdo ainda dá
num beco, se há overflow escondido atrás do release, se a imagem voltou a falhar em
silêncio, ou se a tela cheia esconde erro — nada mais no DoD importa.

### 11.5 Fechamento

| # | Item | Como se prova |
| --- | --- | --- |
| 56 | **Bateria automatizada (F9) escrita DEPOIS do E2E atestado**, nunca antes | o PR 7 é posterior em data ao atestado do item 24 |
| 57 | Gate do CISO onde o agente for acionado | registro do agente `ciso`. _Nenhuma fase o exige por construção (D3), mas o registro de "não se aplica, e por quê" fica_ |
| 58 | `CHANGELOG` `Unreleased` atualizado **no mesmo PR** de cada mudança | o diff do PR contém o CHANGELOG |
| 59 | Se a Q1 for aprovada, `qr_flutter` documentado como dependência nova na descrição do PR 2 | o PR cita a dependência e o porquê |
| 60 | Docs vivas: `final_report.md` ao fechar; `variance_report.md` no primeiro desvio (`VR-17-01`) | os arquivos existem |
| 61 | `docs/roadmap.md` — o item **41** entra no Marco 4 e vira `[x]`; o débito do R3 entra na tabela de débitos vivos | as linhas marcadas |
| 62 | `docs/plans/README.md` atualizado com a doc viva do 41 | o índice |
| 63 | **As tags `(DoD NN)` dos passos 1 a 18 da §10 varridas contra a §11.4** | cada tag aponta para a linha que descreve aquele passo. _Existe porque elas estão deslocadas hoje (aviso no topo da §10): o roteiro é o mapa que o humano segue com o aparelho na mão, e um mapa com legenda trocada gasta a atenção mais cara do time_ |

---

## 12. Fora de escopo — evoluções registradas

- **Editar SDUI no celular** — arrastar widget num telefone é outro modelo de interação e
  outro produto. **D20 decidiu explicitamente que o editor mira desktop**, e a **D23**
  decidiu o que ele mostra abaixo disso: um portão com dois caminhos, não uma versão
  reduzida do construtor. A resposta para "ver no celular" é a rota `/preview` (F2).
- **Deep link do editor aberto frio no celular** (`/contents/:id/edit` compartilhado, sem
  passar pela tela do projeto) — o `ProjectScope` cai no `DEFAULT_PROJECT_ID` do build e os
  botões do portão apontariam para o projeto errado. **Isso já é verdade hoje**, no botão
  "Voltar para o projeto" da tela de falha: a F1b herda, não cria (D24). Família da D18 e
  do **item 26**. **Débito quitado pelo item 46 em 2026-08-18** — a rota passou a carregar
  o projeto.
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
- **O ícone do preview lembrar o último conteúdo aberto** — `start_url` é estática e a URL
  de preview tem `:projectId/:id`; lembrar exigiria persistência e uma pilha de repositório
  por conforto. A **D31** fecha na tela curta. Quando houver razão, o dono natural é a
  mesma pilha da F6.
- **Fazer o link de preview abrir limpo no iPhone** — Safari não captura links para app
  instalado, e isso é do sistema, não do manifest (D31). O que existe hoje é abrir pelo
  ícone. Nada a fazer no nosso lado.
- **Relógio real (em vez de `9:41`) no mock** — custa tirar a faixa do topo do recorte do
  golden, senão ele quebra a cada minuto (D29). Veto barato do humano, mas é veto.
- **As frentes do `feedback_rodada_01.md` que ficaram de fora desta revisão** — **4.2** (a
  barra de navegação; pendente de o dev confirmar se é a barra de gestos do Android ou
  chrome nosso, e o **R14** dá a hipótese medível), **5.3** (árvore como alvo de arraste;
  discovery obrigatório, e é o que destrava o **1.2**), **1.2** (a paleta sumir de vez;
  reabre a A3 e depende do 5.3), **2.1/2.2** (persistência e colapso total do Inspector;
  encaixam na F5/F6) e **3** (travar proporção; discovery próprio pelas três perguntas da
  §3 do feedback). **Nenhuma virou tarefa** — e o **17-A** foi escrito para que a decisão do
  5.3 não o mate por acidente (R13).
