# variance_report.md — Item 39 (`docs/16-image-url-e-props/`)

Registro dos desvios em relação ao `plan.md` desta pasta, no formato **como estava / por que
mudou / o que mudou**. Regra do CLAUDE.md: desvio do plano só entra com aprovação do humano e
registro aqui.

Numeração: `VR-16-NN`, na ordem em que os desvios acontecem.

| # | Fase | Desvio | Origem | Estado |
| --- | --- | --- | --- | --- |
| VR-16-01 | F2 | `app.set('trust proxy', 1)` em `backend/src/main.ts` | Gate CISO | **Aplicado** |
| VR-16-02 | F3 | O ponto de injeção do resolver: **8** arquivos do editor, não 1 | Regra do CLAUDE.md cobrada por 5 testes | **Aplicado** |
| VR-16-03 | E2E | As 3 asserções vermelhas da rodada 01 tinham **duas** causas: regressão da F4 (já corrigida) e cegueira do driver | Investigação pós-rodada | **Aplicado** |

> **Nota de numeração — reserva desfeita.** A **D16** do `plan.md` havia reservado o rótulo
> `VR-16-02` para uma hipótese que nunca se concretizou (o teste do contrato da D12 descendo
> para a F1, que depende de aprovação do humano). A reserva foi removida do plano e o número
> ficou com o desvio que de fato aconteceu. **Regra:** número de desvio se atribui **quando o
> desvio acontece**, nunca antecipado — reservar deixa buracos que ninguém sabe explicar
> depois. Se aquela hipótese virar realidade, pega o próximo número livre.

---

## VR-16-01 — `trust proxy` no `main.ts`, fora da lista de arquivos da F2

**Fase:** F2 (proxy de mídia). **Origem:** ressalva do gate CISO, não do plano.
**Data:** 2026-08-15. **Estado:** aplicado; F2 liberada **com ressalvas**.

### Como estava

O plano listava, para a F2, apenas `backend/src/media/` e o registro em `app.module.ts`. O
**controle 7** (§5›F2) pedia rate limit "por **IP**; por **chave** quando houver identidade",
apoiado no precedente já existente no repo (`ThrottlerModule` em `projects.module.ts:11`,
`@UseGuards(ThrottlerGuard)` em `projects.controller.ts:48,70`).

O plano tratava esse precedente como **pronto para reusar**. `backend/src/main.ts` não
aparecia em lugar nenhum da F2.

### Por que mudou

O `ThrottlerGuard` usa **`req.ip`** como chave do balde. Em homologação e produção o container
roda **atrás do Traefik**, e sem `trust proxy` o Express enxerga apenas a conexão TCP que vem
do proxy reverso: **`req.ip` é o IP interno do Traefik, igual para todos os chamadores**.

O efeito é que o rate limit deixa de ser por cliente e vira um **balde único global**. Com o
`MEDIA_PROXY_THROTTLE` de 30 req/min, **um atacante sozinho esgota a cota e todos os usuários
legítimos do editor tomam `429` pelo resto da janela** — o controle 7 não só falha em conter
abuso, como se transforma em vetor de negação de serviço contra os próprios usuários.

**O gap é pré-existente e sistêmico, não introduzido pelo proxy.** Ele atinge igualmente o
`projects.controller.ts`, cujo throttle de upload está no ar desde o item 9d com a mesma falha
silenciosa. O gate CISO do proxy foi apenas **o primeiro lugar onde alguém olhou** — o que é
o próprio propósito do gate.

Corrigir só dentro de `media.controller.ts` era impossível: a resolução de `req.ip` é
configuração da aplicação Express, não do controller.

### O que mudou

Em `backend/src/main.ts`:

- `NestFactory.create(AppModule)` → `NestFactory.create<NestExpressApplication>(AppModule)`,
  para expor o `app.set` tipado;
- **`app.set('trust proxy', 1)`**, com o porquê comentado no código (é decisão de segurança
  que a linha não mostra sozinha).

**Por que `1` e não `true`:** `1` confia **apenas no hop imediato** — o Traefik. `true`
confiaria numa cadeia arbitrária de `X-Forwarded-For`, que qualquer chamador pode forjar; o
atacante escolheria um IP diferente a cada requisição e o rate limit ficaria **pior do que sem
`trust proxy` nenhum**. A escolha do valor é parte do controle, não detalhe.

### Efeito colateral, deliberado e benéfico

A correção é de escopo da aplicação, então **conserta junto o throttle do
`projects.controller.ts`**. É desvio de escopo assumido: separar em outro PR deixaria um
buraco de segurança conhecido no ar, e o conserto é a mesma linha.

### Aprovação

- **Gate CISO:** F2 liberada **com ressalvas**; esta é a ressalva, e foi aplicada.
- **Registro:** este documento, mais o `CHANGELOG` `Unreleased` do mesmo PR.

### O que fica em aberto

O plano descreve o rate limit como controle **por IP e por chave**. Com o `trust proxy`, o
por-IP passa a funcionar de fato. O **por-chave** continua não existindo — não há identidade
no caminho do editor (não há auth; item 26 aberto), exatamente como a **D10** e o **R9** já
registram. **Isto não é desvio**; é o limite conhecido, e segue registrado no plano.

---

## VR-16-02 — O ponto de injeção do resolver: 8 arquivos do editor, não 1

**Fase:** F3 (renderer ganha o resolver; o editor injeta). **Origem:** a regra do CLAUDE.md,
cobrada por 5 testes que quebraram. **Data:** 2026-08-15. **Estado:** aplicado; F3 com CISO
liberado e código aprovado pelo QA, que confirmou o desvio como **procedente**.

### Como estava

A **D11** decidiu que o proxy é chrome do editor e entra por injeção. A §5›F3 traduziu isso em
**um** arquivo:

> **`apps/driva_editor/lib/…`** — o resolver do editor, montado de `AppConfig.apiBaseUrl`,
> injetado onde o canvas monta o `SduiView.content` (`.../canvas/preview_surface.dart`).

E a §3.1 reforçava, sobre o `showDiagnostics`: _"`preview_surface.dart:104` liga
`showDiagnostics: true` — o **único** ponto do repo que o liga. **É aqui que o editor injeta o
resolver da F3.** Um ponto, um arquivo."_

### Por que mudou

A primeira versão seguiu o plano ao pé da letra e chamou **`getIt<AppConfig>()` dentro do
`PreviewSurface`**. **Cinco testes quebraram na hora.**

`preview_surface.dart` é **widget-folha, não página**. A regra do CLAUDE.md é literal:

> página `StatelessWidget` com `static Widget pageBuilder` — **o único lugar que toca o
> get_it**.

Os testes que quebraram montavam o `PreviewSurface` isoladamente, sem container de DI
registrado — exatamente o que a regra existe para preservar: **widget-folha testável sem
bootstrap da aplicação**. **A quebra foi a regra cobrando, não acidente** — e é a razão de o
desvio ser procedente em vez de negociável.

**O erro do plano foi de precisão, e vale nomear:** ele identificou corretamente o ponto de
**consumo** (onde o resolver é usado: `SduiView.content`, no `preview_surface.dart`) e foi
**omisso quanto ao ponto de construção** (onde ele é montado a partir do `AppConfig`, que só
pode ser a página). Consumo e construção não são o mesmo lugar quando há regra de DI no meio —
e o plano escreveu "um ponto, um arquivo" como se fossem.

### O que mudou

O resolver é construído em `EditorPage.pageBuilder` (o único lugar autorizado a tocar o
get_it) e **enfiado por construtor** até o canvas. **8 arquivos:**

| # | Arquivo | Papel |
| --- | --- | --- |
| 1 | `core/network/media_proxy_image_url_resolver.dart` | **novo** — a função que reescreve para `/v1/media/proxy?url=` |
| 2 | `core/network/network.dart` | barrel, exporta o resolver |
| 3 | `…/editor/editor_page.dart` | **constrói** o resolver no `pageBuilder`, com a guarda da D19 |
| 4 | `…/editor/page/editor_workspace.dart` | repasse |
| 5 | `…/editor/page/center_area.dart` | repasse |
| 6 | `…/editor/page/canvas_area.dart` | repasse |
| 7 | `…/editor/widgets/canvas_panel.dart` | repasse |
| 8 | `…/editor/widgets/canvas/preview_surface.dart` | **consome** — passa ao `SduiView.content` |

Nenhum dos 5 intermediários usa o valor: só o declaram e repassam.

### Ressalva do QA — **5 níveis de threading é o teto**

O QA aprovou com esta ressalva, e ela é o registro mais útil deste desvio: **cinco níveis de
repasse por construtor é o limite aceitável.** Um sexto vira sinal de que o padrão se esgotou.

**A saída, quando chegar:** um `InheritedWidget` escopado montado no `EditorPage.build` —
o mesmo padrão do `Theme`, em que o widget-folha lê do contexto em vez de a página empurrar
por seis construtores. Isso mantém a regra do get_it intacta (quem constrói continua sendo a
página) e elimina os intermediários que só carregam o valor.

**Não é para agora.** É para o próximo que precisar passar **qualquer coisa** por esse caminho
— e é ele quem paga a refatoração, não esta fase. Registrado aqui porque o custo é invisível
até alguém tentar o sexto.

### Aprovação

- **Gate CISO:** liberado.
- **QA:** código aprovado; desvio confirmado como **procedente**, com a ressalva dos 5 níveis.
- **Registro:** este documento; a §5›F3 do `plan.md` foi corrigida para os 8 arquivos.

---

## VR-16-03 — As 3 asserções vermelhas da rodada 01 tinham duas causas, não uma

**Fase:** E2E (rodada 01). **Origem:** investigação pedida depois de a rodada fechar 26 PASS / 3 FAIL.
**Data:** 2026-08-19. **Estado:** aplicado; nenhum arquivo de `lib/` foi tocado nesta investigação.

As três falhas registradas em `evidencias/rodada_01/README.md:9` (o placar, `26 PASS / 3 FAIL`, está em `:7`) — `(D15/DoD 23) o campo mostra
"Ajustado para o mínimo (1)"`, `(D15/DoD 23) o campo mostra errorText de valor inválido` e
`(D15/DoD 23) os dois sinais se distinguem` — **não** tinham causa comum. Corrigir só a primeira
teria devolvido a rodada 02 vermelha, pelo segundo motivo, sem ninguém entender por quê.

### Causa 1 — a F4 desfez o sinal que a F1 tinha acabado de criar (produto; já corrigida)

A **F1** fez o campo numérico parar de clampar calado: `packages/sdui_core/lib/src/catalog/widget_catalog.dart:330`
e `:340` subiram `image.width`/`image.height` de `min: 0` para `min: 1`, e o `NumberEditor` passou a
avisar quando ajustava o valor.

A **F4** (`9af0cbb`, 2026-08-15 22:29) migrou esses dois campos de `FieldKind.doubleNum` para
`FieldKind.dimension` (as duas trocas aparecem no diff do arquivo acima). Com isso
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/typed_prop_editor.dart:58`
passou a despachar `image.width` para o **`DimensionEditor`**, que clampava **sem sinalizar** — o
`NumberEditor` continuou avisando, mas `image.width` deixou de passar por ele.

Duas fases do mesmo item, uma desfazendo a outra, **ambas aprovadas em revisão**. Quem pegou foi o
E2E: os prints `evidencias/rodada_01/23a_largura_zero.png` e `23b_largura_abc.png` são a mesma tela,
com a borda laranja de foco e mensagem nenhuma.

**Já está corrigido.** `624970b` criou
`apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field/numeric_clamp.dart`
(`:3` a mensagem de valor inválido, `:21-27` o `clampMessageFor` que separa mínimo de máximo) e ligou
os dois editores nele — `dimension_editor.dart:208-209` e `number_editor.dart:118-119` levam
`errorText`/`helperText` ao campo.

### A evidência da rodada 01 é de ANTES da correção

- `9af0cbb` — 2026-08-15 22:29:13 -0300 — F4 introduz a regressão
- `624970b` — 2026-08-16 **00:26:02** -0300 — a correção
- `f4daf0c` — 2026-08-16 **00:29:09** -0300 — a pasta `evidencias/rodada_01/` é comitada

**Três minutos.** Os 3 FAIL registram um estado que já não existia quando o arquivo entrou no
repositório. O `README.md` da rodada 01 **não foi reescrito** — evidência de execução passada não se
edita; quem fecha o item é a rodada 02.

### Causa 2 — o driver não conseguia ler o sinal, mesmo depois de corrigido

`docs/16-image-url-e-props/e2e_drive.mjs`, no `semanticLabels()`, lia só
`getAttribute('aria-label')`.

> Os ponteiros de engine abaixo são do **SDK do Flutter 3.44.9**, não deste repositório, e a
> numeração de linha muda entre versões — o que não muda é o mecanismo. Para reconferir noutra
> versão, procure por `LabelRepresentation` e `GenericRole`. O engine do Flutter Web só usa esse atributo quando o nó **tem filhos**
(`AriaLabelRepresentation`, em
`flutter/engine/src/flutter/lib/web_ui/lib/src/engine/semantics/label_and_value.dart:123`).

Nó-**folha** com rótulo — todo `Text`, e portanto o `helperText`/`errorText` do `InputDecorator` — cai
no `GenericRole`
(`.../lib/web_ui/lib/src/engine/semantics/semantics.dart:1057`), que escolhe
`LabelRepresentation.sizedSpan` (`:1065`) e **remove o atributo `role`** (`:1101`). A
`SizedSpanRepresentation` escreve o rótulo como **texto de um `<span>`** dentro do `flt-semantics`
(`label_and_value.dart:275`) — nunca como `aria-label`. O DOM esperado está no teste do próprio
engine: `.../lib/web_ui/test/engine/semantics/semantics_test.dart:717`, `<sem><span>Hello</span></sem>`.

**As três asserções vermelhas eram as únicas do roteiro que dependiam de leitura semântica.** As
outras 26 são de rede (domínio `Network` do CDP), de spec (API) ou de pixel — e passaram todas. Ler o
atributo errado era invisível enquanto nenhuma outra asserção o exercitava.

Corrigido: o texto próprio passa a sair também dos filhos **diretos** (nó de texto ou `<span>`).
Simulado contra um DOM aninhado com essa estrutura, o leitor antigo devolve só `["Largura"]` e o novo,
`["Largura", "Ajustado para o mínimo (1)"]`.

### Dois achados do supervisor, no mesmo arquivo

**A asserção de distinção não distinguia.** `check('(D15/DoD 23) os dois sinais se distinguem')` era a
**conjunção literal** das duas asserções positivas anteriores — não tinha como reprovar sozinha, e
nunca afirmou que o estado `0` **não** traz "Valor inválido" nem que o estado `abc` **não** traz
"Ajustado para o mínimo". Com as duas mensagens aparecendo nos dois estados, as três asserções
passariam com a tela errada. Hoje isso é impossível porque
`.../prop_field/number_text_field.dart:32` suprime o `helperText` quando há `errorText` — mas o E2E
não provava o que o nome dele diz, e foi um E2E que não provava o que dizia que deixou este item
parado. A asserção passou a ser só as **negativas**.

**O comentário do filtro dava uma razão falsa.** Ele afirmava que `textContent` cru faria "todo rótulo
casar com todo nó" e a asserção "passaria sem provar nada". Não procede: as três asserções rodam
regex sobre um `join(' | ')` da página inteira, onde a duplicação nos ancestrais não muda resultado
nenhum. O filtro continua certo — a razão escrita é que estava errada, e pela regra de comentários do
`CLAUDE.md` um **porquê** incorreto é pior que nenhum. Reescrito com a razão verdadeira: manter a
lista como **um rótulo por nó**.

### A lição de fundo — a suíte não tinha uma linha sobre essas mensagens

Nenhum teste em `apps/driva_editor/test/` mencionava "Ajustado para o mínimo" ou "Valor inválido"
antes desta investigação. **Foi isso que permitiu duas fases do mesmo item se desfazerem uma à outra
com revisão aprovada nas duas** — não havia nada na cancela de máquina que percebesse o sinal sumindo,
e o único instrumento que percebeu foi o E2E, três dias depois.

A rede agora existe: `.../prop_field/dimension_editor_test.dart:127` (grupo "sinal do ajuste e do
erro", 4 casos, incluindo a árvore acessível em `:170`) e a dupla equivalente no `NumberEditor`, em
`.../prop_field/prop_field_editors_test.dart`. Os 4 casos do `DimensionEditor` **falham** contra a
versão pré-`624970b` do editor e passam contra a atual — verificado restaurando `9af0cbb:dimension_editor.dart`
e reproduzido de forma independente pelo supervisor, com o mesmo resultado (4 vermelhos, nenhum outro).

O teste da árvore acessível não duplica o de texto: em opacidade zero o `FadeTransition` do
`InputDecorator` tira o nó da árvore semântica, então "está na tela" e "é anunciável" são condições
diferentes — e a segunda é a que o leitor de tela e o driver do E2E leem.

### Aprovação

- **Nada de `lib/` mudou:** a causa 1 já estava corrigida em `develop`; esta investigação acrescentou
  teste e corrigiu o instrumento.
- **Pendente:** a **rodada 02** contra homologação, com a `develop` atual implantada. É o que falta
  para o atestado humano do DoD 23.
