# Plano — Widget `image`: a URL aparece, e o editor de propriedades cresce

_Item **39** do roadmap (Marco 2, item 9 track contínuo). Base: `docs/plans/39-image-url-e-props/plan.md` —
plano de gaveta, matéria-prima deste. Onde os dois divergirem, **este manda**, e o
motivo está na §8._

> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**.
> **⚠️ Este item TOCA O BACKEND.** O humano escolheu o **proxy de mídia** em vez do
> `WebHtmlElementStrategy.fallback` (D2, 2026-08-15) — o plano de gaveta e a primeira
> versão deste plano diziam "não toca backend"; **não dizem mais**. Há uma fase de backend
> com **gate CISO obrigatório**.
> **0-dep.** Nasce de relato do dev humano no uso real (2026-08-15).
> Sai **antes do item 24**, por decisão do humano — logo depois do item 38.
> Alvos: `packages/sdui_flutter`, `packages/sdui_core`,
> `apps/driva_editor/lib/modules/editor_module/` **e `backend/src/`**.

## Estado

**Plano fechado em 2026-08-15** — as quatro perguntas foram respondidas pelo humano (§9) e
viraram decisões travadas (§4). Nada bloqueia a execução.

**Rodada 1 da F1 reprovada pelo QA (2026-08-15).** Três bloqueios; o de plano era o **B1** —
o aceite 3 exigia um estado "carregando" que o `loadingBuilder` **não produz no Flutter
Web**. Não foi enfraquecido: o mecanismo virou **`frameBuilder`** (**D12**), o aceite 3 foi
reescrito com como se verifica, e dois aceites mal redigidos (7 e 8) foram corrigidos.

**Rodada 2 — código aprovado pelo QA; o plano é que devia à fase (2026-08-15).** Quatro
ajustes, todos já refletidos aqui: **D13** registra o `showDiagnostics` que o CISO exigiu na
F1 e que o plano desconhecia (a §3.1 dizia haver **um** hook quando já havia **dois** — quem
pegasse a F3 o reinventaria); **D14** faz o Gate 4 do CI varrer o `sdui_flutter`, porque a D7
tornou falsa a isenção antiga; **D15** reescreve o aceite do `width: 0` para medir o fim do
silêncio, não a visibilidade de 1px; **D16** registra o intervalo sem teste automático do
contrato da D12. A lista de arquivos da §5›F1 foi completada.

**F2 — código aprovado e gate CISO liberado _com ressalvas_ (2026-08-15); ainda `[-]`** porque
o QA achou furos na **prova** (três mutações sobreviveram à matriz) e eles estão sendo
fechados. A ressalva do CISO era o `trust proxy` e já foi aplicada: **`VR-16-01`** em
`variance_report.md` desta pasta. Três
ajustes de documento entraram junto: **D17** registra que a matriz de segurança é a **exceção
documentada** à regra "testes por último" e nasce na F2 (o bullet duplicado saiu da F5);
**D18** registra que a suíte roda contra **servidor local efêmero** — ela prova o guarda,
**não** que a URL do relato carrega; e a lista de arquivos da F2 foi completada.

**Leitura obrigatória para quem escrever aceite daqui em diante: §8, item 13.** Três aceites
seguidos passaram no papel e eram falsos na tela — é padrão, não acidente.

| Fase | O que entrega | Dono | PR | Estado |
| --- | --- | --- | --- | --- |
| F1 | Os três estados ficam distintos + tokens + clamp | especialista-infra | 1 (`bugfix/*`) | `[-]` |
| F2 | **Backend: proxy de mídia + gate CISO** | especialista-infra + **ciso** | 2 (`feature/*`) | `[-]` |
| F3 | Renderer ganha o resolver; o editor injeta o proxy | especialista-infra | 3 (`feature/*`) | `[ ]` |
| F4 | Catálogo: `image` abrangente (Incremento 4 do item 9) | especialista-dominio + especialista-infra | 4 (`feature/*`) | `[ ]` |
| F5 | Bateria automatizada (por último) | qa | 5 | `[ ]` |

`[ ]` não iniciada · `[-]` em andamento · `[x]` concluída e revisada pelo QA

**O relato do dev só fica integralmente resolvido no PR 3.** A F1 faz a falha **parar de ser
silenciosa** (que é o defeito); a F2+F3 fazem a URL do caso B **carregar**. Dizer que o PR 1
"resolve o relato" seria mentira — ver §6.

## 1. Objetivo e recorte

Relato do dev humano, no uso real:

> _"O componente de imagem precisa melhorar os editores de propriedades e uma vez que eu
> informei a url de uma imagem na propriedade ela deveria ser exibida, atualmente não está
> exibindo."_

São **duas coisas de natureza diferente**, e o plano as separa porque uma é defeito e a
outra é catálogo:

1. **Defeito (F1–F3).** A imagem não aparece **e o editor não diz por quê**. A falha é pixel
   a pixel idêntica ao estado "sem URL" — o usuário não distingue "errei a URL", "o host
   bloqueou", "ainda está carregando" e "não preenchi". A F1 sai como `bugfix/*`; a causa
   estrutural (CORS no Flutter Web) exige o proxy da F2 e a injeção da F3.
2. **Incremento de catálogo (F4).** O `image` tem **4** propriedades; o `container` tem
   **12**. É o **"Incremento 4: `image` abrangente"** do item 9, já listado como sub-bullet
   em `docs/roadmap.md:72`.

**Entra no backend** (novidade desta rodada): um endpoint `GET /v1/media/proxy?url=` que
busca a imagem no servidor e a devolve com `Access-Control-Allow-Origin` para a origem do
editor. **É superfície de SSRF e por isso é fase própria, com gate CISO** (D2).

**Fica fora:** upload de imagem pelo editor (item 27, storage); a **rota pública** do proxy
para apps cliente que rodem em Flutter Web (D11); `image` a partir de asset local; blurhash;
`Image.memory`/base64; `svg`; `avatar`/`aspectRatio`. Registro completo na §12.

## 2. Causa confirmada

Conferida contra o código de hoje — os `file:line` abaixo são os **atuais**.

**As duas suspeitas óbvias estão mortas.** A prop **chega** e o builder **lê**:

- Descriptor: `PropField(key: 'src', kind: FieldKind.string, label: 'URL da imagem', isRequired: true)`
  — `packages/sdui_core/lib/src/catalog/widget_catalog.dart:310` (bloco `'image'`).
- Builder: `final src = (p['src'] ?? '').toString();` —
  `packages/sdui_flutter/lib/src/builders/image.dart:10`. Mesma chave, mesmo tipo.
  Registrado em `default_registry.dart:36`.
- O campo de texto comita **a cada tecla**, sem `onSubmitted` nem debounce. Clicar fora
  **não perde** o valor.
- O canvas usa o renderer real e nada o cobre: as decorações de `SelectableNodeSurface` são
  todas **foreground** sobre um `Stack(fit: StackFit.passthrough)`.

### 2.1 O defeito real — `packages/sdui_flutter/lib/src/builders/image.dart`

```dart
if (src.isEmpty) {                                        // :14
  return SizedBox(width: width ?? 80, height: height ?? 80,
    child: const ColoredBox(color: Color(0x22000000)));   // :15-19
}
return Image.network(src, width: width, height: height, fit: boxFitFrom(p['fit']),
  errorBuilder: (_, _, _) => SizedBox(width: width ?? 80, height: height ?? 80,
    child: const ColoredBox(color: Color(0x22000000))),   // :26-30
);
```

**O `errorBuilder` (`:26-30`) desenha exatamente o mesmo quadrado cinza do caso "sem `src`"
(`:15-19`)** — mesmo `Color(0x22000000)`, mesmo tamanho, mesma ausência de texto. E não há
estado de carregamento nenhum — nem `frameBuilder` (o mecanismo certo, D12) nem
`loadingBuilder`. Do ponto de vista do usuário, "falhou", "está carregando" e "não preenchi"
são **o mesmo pixel**. Ele digita a URL, o quadrado cinza continua lá, e a conclusão
inevitável é "não está exibindo".

**Este é o defeito, e ele existe independentemente de CORS.** É a F1.

### 2.2 Por que a falha acontece — CORS no Flutter Web

`buildImage` não passa `webHtmlElementStrategy`, então vale o default
`WebHtmlElementStrategy.never` (`flutter/lib/src/widgets/image.dart:455`, SDK **3.38.6**).
Na implementação web isso cai em `loadViaDecode()`
(`flutter/lib/src/painting/_network_image_web.dart:128`), que busca os **bytes** — sujeito à
política de mesma origem. Um `<img>` do HTML não seria.

**Matriz de casos, verificada empiricamente em 2026-08-15:**

| Caso | Resposta do host | `Image.network` web **hoje** | Depois da F1 | Depois da F2+F3 (proxy) |
| --- | --- | --- | --- | --- |
| **A — host com ACAO** (`picsum.photos`, `images.unsplash.com`, `upload.wikimedia.org`) | `access-control-allow-origin: *` | **carrega** | carrega, igual | carrega **via proxy** |
| **B — host sem ACAO** (`www.google.com/images/branding/googlelogo/...png`) | `200`, `cross-origin-resource-policy: cross-origin`, **sem ACAO** | **NÃO carrega, em silêncio** | não carrega, mas **diz "falhou" e por quê** | **carrega** |
| **C — URL inexistente** (`https://exemplo.invalido/x.png`) | erro de DNS/404 | falha em silêncio | estado **"falhou"** com motivo | estado "falhou" (o proxy devolve erro tipado) |
| **D — campo vazio** | — | quadrado cinza | estado **"vazio"**, distinto de C | igual |

Ou seja: **URL de CDN de banco de imagens funciona; uma URL copiada com "copiar endereço da
imagem" de um site qualquer, não** — e falha calada.

**Por que o proxy resolve.** A imagem passa a ser servida **pelo nosso backend**, e é o nosso
backend que decide o `Access-Control-Allow-Origin`. O mecanismo já existe no repo:
`backend/src/main.ts:50` chama `app.enableCors({ origin: [...corsOrigins, localhost] })`,
alimentado por `CORS_ORIGINS`. Um endpoint sob `/v1/` herda isso — a resposta sai com a
origem do editor autorizada, e o `Image.network` carrega pelo **caminho de bytes**, que é o
caminho normal do Flutter.

**Ganho colateral que decide o DoD:** com o proxy a imagem continua sendo **imagem de
verdade** — widget Flutter, composável, **capturável por screenshot e por golden**. O
`WebHtmlElementStrategy.fallback` a transformava em platform view, que **não é capturável**
(`flutter/lib/src/widgets/image.dart:417`) — quebrando justamente o print que provaria a
correção. **O proxy resolve o DoD que o fallback tornaria impossível.** É o argumento que
fecha a D2 junto com o de segurança.

### 2.3 Segunda causa silenciosa, independente — `width: 0` some com a imagem

O editor `doubleNum` comita a cada tecla e **não aplica `field.min`**:

```dart
void _onTextChanged(String text) {                          // number_editor.dart:55
  if (text.trim().isEmpty) { widget.onChanged(null); return; }
  final parsed = _parse(text);
  if (parsed != null) widget.onChanged(parsed);             // :61 — sem clamp
}
```

O `min: 0` de `widget_catalog.dart:329` (largura) e `:336` (altura) **só alimenta o
`Slider`** — que nem aparece, porque `hasRange => min != null && max != null`
(`prop_field.dart:55`) e o `image` não define `max`; `number_editor.dart:78` devolve o campo
puro. Digitar `0` produz `Image.network(width: 0)` — e o placeholder também, porque
`width ?? 80` vira `0`.

**A assimetria é a dívida.** O `DimensionEditor` **clampa**:

```dart
final min = widget.field.min?.toDouble() ?? 0;   // dimension_editor.dart:73
final clamped = number < min ? min : number;     // :74
```

**⚠️ Clampar contra `field.min` não resolve o `0`**, porque o `min` do `image` **é `0`**. O
clamp é necessário e insuficiente — ver D6.

### 2.4 O que não deu para determinar

Qual URL o dev usou. Por isso a F1 **não escolhe uma causa**: torna **toda** causa visível.
Qualquer que tenha sido o caso, sai explicado na tela na F1 e resolvido na F3.

## 3. O que já existe e vamos reusar

### 3.1 Flutter

| O que | Onde (atual) | Uso |
| --- | --- | --- |
| `buildImage` + registro | `sdui_flutter/lib/src/builders/image.dart:8`, `default_registry.dart:36` | Alvo de F1, F3 e F4 |
| `SduiRenderer` — hooks opcionais: `onAction`, `nodeWrapper` e **`showDiagnostics`** (`:17,28`, entregue na F1) | `sdui_flutter/lib/src/renderer.dart` | **Onde o resolver da F3 entra.** ⚠️ **São dois hooks, não um:** o `showDiagnostics` já existe e é o precedente mais próximo do resolver (mesma fronteira editor × app cliente — D13). **Não reinventar o mecanismo** |
| `SduiView` + `SduiView.content` repassando **os três** hooks, `showDiagnostics` com default `false` (`:17,26,34,47,57`) | `sdui_flutter/lib/src/sdui_view.dart` | Os dois construtores já repassam; o resolver da F3 entra **no mesmo lugar e no mesmo formato** |
| `preview_surface.dart:104` liga `showDiagnostics: true` — o **único** ponto do repo que o liga | `apps/driva_editor/.../canvas/preview_surface.dart` | **É aqui que o editor injeta o resolver da F3.** Um ponto, um arquivo |
| `SduiDimensionBox` (px / % / "preenche") | `sdui_flutter/lib/src/layout/sdui_dimension_box.dart:13` | O que `image` passa a usar na F4 (D3) |
| `buildContainer` já usa `SduiDimensionBox` | `sdui_flutter/lib/src/builders/container.dart:29-35` | **O gabarito literal da F4** |
| `parseDouble` (**só `num`**), `parseColor`, `parseBorderRadius` | `sdui_flutter/lib/src/parsing/parsers.dart:45,9,79` | `parseDouble:45` é o que **não** entende `"100%"` |
| `boxFitFrom` (default `contain`), `alignmentFrom` | `sdui_flutter/lib/src/parsing/enums.dart:79,62` | `fit` já existe; `alignment` entra na F4 |
| `FieldKind.dimension` **já existe** | `sdui_core/lib/src/catalog/field_kind.dart:9` | A F4 não cria kind nenhum |
| Editores já existentes para **todos** os kinds da F4 | `.../prop_field/typed_prop_editor.dart:38,43,58,68,88` | **Prova de que a F4 não precisa de editor novo** — regra do item 9 |
| `NumberEditor` **sem** clamp × `DimensionEditor` **com** clamp | `number_editor.dart:55-62` × `dimension_editor.dart:73-74` | A dívida que a F1 paga |
| `PropField.helpText` existe e **não é renderizado em lugar nenhum** | `prop_field.dart:16,39`; `grep helpText apps/driva_editor/lib` = **zero** | A F4 o acende |
| **Dois** caminhos de moldura: `PropFieldEditor:64` e o self-chromed `DimensionEditor:117` | `prop_field_editor.dart:24,54-55,64`; `self_chromed_prop_editor.dart:29` | **D8** |
| `AppConfig.apiBaseUrl` (compile-time, `--dart-define-from-file`) | `apps/driva_editor/lib/core/config/app_config.dart:16,32`; `config/{dev,hml,prod}.json` | **De onde o editor monta a URL do proxy** na F3 |
| Golden do `image` **sem `src`** | `sdui_flutter/test/renderer_golden_test.dart:55`; laço `:160`; `goldens/node_image.png:172` | Regravar na F1 (R1) |
| `_UnknownTypeBox` com `Color(0xFFCC3333)` cru | `sdui_flutter/lib/src/renderer.dart:77,81` | Companheiro do hardcode da D7 |

### 3.2 Backend

| O que | Onde (atual) | Uso |
| --- | --- | --- |
| `app.enableCors({ origin: [...corsOrigins, localhost] })` alimentado por `CORS_ORIGINS` | `backend/src/main.ts:45-53` | **O mecanismo que faz o proxy funcionar** — a resposta sai com a origem do editor autorizada |
| Middleware de ACAO `*` **só** para `/v1/public` | `backend/src/main.ts:30-43` | O proxy do editor **não** vai por aqui (D11) |
| `app.setGlobalPrefix('v1', { exclude: ['health'] })` | `backend/src/main.ts:26` | O endpoint nasce em `/v1/media/proxy` |
| `ThrottlerModule.forRoot({ throttlers: [{ ttl: 60_000, limit: 60 }] })` + `@UseGuards(ThrottlerGuard)` | `backend/src/projects/projects.module.ts:11`; `projects.controller.ts:48,70` | **Precedente de rate limit no repo** — imitar, não inventar |
| `PublicController` com `x-driva-key`, ETag e `Cache-Control` | `backend/src/public/public.controller.ts` | Precedente de cache/ETag para o proxy |
| `generatePublishableKey()` = `pk_` + 32 bytes aleatórios | `backend/src/projects/publishable-key.ts` | **A chave que NÃO é segredo** — ver D10 |
| `StorageModule` (local + S3) | `backend/src/storage/` | **Não** é o proxy; é o item 27. Não confundir |

### 3.3 O que NÃO existe

- **`SduiRenderer` não tem hook de URL de imagem.** Sem criá-lo (F3/D11), o proxy seria
  hardcodado em `builders/image.dart` e **todo app cliente publicado passaria a rotear o
  tráfego de imagem pelo nosso backend**. Erro de arquitetura, não detalhe.
- **`sdui_flutter` não tem `theme/` nenhum.** O pacote inteiro tem **4** `Color(0x…)` crus:
  `image.dart:18,29` e `renderer.dart:77,81`. A F1 cria o primeiro token (D7).
- **`min: 1` em `image.width`/`height`.** Hoje é `min: 0` (D6).
- **Não há módulo de autenticação no backend.** `backend/src/` = `categories`, `contents`,
  `health`, `prisma`, `projects`, `public`, `storage`. Auth é o **item 26, ainda aberto** —
  o proxy nasce num backend sem auth (R9, e é matéria do gate CISO).

## 4. Decisões travadas

_D1, D3–D8 vieram da rodada anterior. **D2 foi substituída pela decisão do humano** e D10–D11
nasceram dela. Todas confirmadas pelo humano em **2026-08-15** — não reabrir sem passar pelo
`variance_report.md` desta pasta._

### D1 — Vazio, carregando e falhou passam a ser **três** estados visualmente distintos.

É a correção que faz o defeito parar de existir, **independentemente da causa** — e é o
coração da F1. Hoje os três são o mesmo `ColoredBox(Color(0x22000000))`.

O estado de falha carrega **o motivo em texto** (`Semantics` + tooltip), não só um ícone:
cor nunca é o único sinal de informação (CLAUDE.md, acessibilidade).

**A D1 não vira dispensável com o proxy.** O proxy resolve o caso B; **C continua falhando**
(URL errada continua errada) e D continua vazio. Sem a D1, a F2 trocaria uma falha
silenciosa por outra.

**⚠️ O estado "carregando" vem do `frameBuilder`, nunca do `loadingBuilder`** — ver D12. O
`loadingBuilder` não funciona no Flutter Web e usá-lo faz o terceiro estado sumir justamente
onde o relato do dev mora.

### D2 — **O proxy de mídia no backend.** O `WebHtmlElementStrategy.fallback` está **descartado**.

> **Decidida pelo humano em 2026-08-15**, depois de o SSRF ser explicado. **Substitui a D2 do
> plano de gaveta e da v1 deste plano**, que adotavam o `fallback` e registravam o proxy como
> evolução. A inversão é deliberada: escolhemos o caminho definitivo.

`GET /v1/media/proxy?url=<url-encoded>` busca a imagem no servidor e a devolve com o
`Access-Control-Allow-Origin` que o `main.ts:50` já governa. O `Image.network` volta ao
**caminho de bytes**, que é o caminho normal do Flutter.

**Três razões, e a terceira é a que fecha:**

1. **É o caminho definitivo.** Resolve o caso B sem depender de comportamento de plataforma,
   e vale para qualquer host, hoje e depois.
2. **Não paga o preço do platform view:** performance normal, `opacity`/filtros funcionam,
   `ClipRRect` compõe (some o risco R2 da versão anterior deste plano).
3. **A imagem continua capturável por screenshot e por golden.** O `fallback` não era
   (`flutter/lib/src/widgets/image.dart:417`) — e o **item 22 do DoD** exige exatamente um
   print comparativo dos quatro estados. **O fallback tornaria o DoD impossível de cumprir.**

**Condição inegociável, imposta pelo humano:** o proxy é **fase própria (F2) com gate CISO
obrigatório**, nunca embutido no bugfix. É superfície de SSRF: um endpoint que busca URL
arbitrária a mando de quem chama é, por construção, um pedido de "faça uma requisição por
mim". Os controles estão na F2 e a matriz que os prova está no DoD §11.4.

**Custo aceito:** o tráfego de imagem **do editor** passa a atravessar o backend (banda,
latência, cache). É limitado ao uso do editor — a D11 garante que **não** vaza para os apps
cliente.

### D3 — `width`/`height` do `image` migram de `doubleNum` para `dimension` (F4).

"Largura 100%" é o pedido mais comum de uma imagem e hoje é **impossível**: `parseDouble`
(`parsers.dart:45`) só aceita `num`. `DimensionValue.parse` aceita `num` como
`PixelDimension`, então **todo spec já salvo continua válido sem migração** — e isso vira
**teste explícito** (R4). O builder passa a usar `SduiDimensionBox`, como
`container.dart:29-35`.

### D4 — O placeholder do `sdui_flutter` é chrome de autoria, e isso é uma dívida assumida.

`buildImage` desenha um quadrado cinza quando não há `src` — no app do cliente isso é um
quadrado cinza **em produção**. É o que hoje torna o nó selecionável no canvas, então
**fica**; mas é um `SduiAuthoringScope` que não existe. Registrado em §12; **não é fatia
deste item**.

### D5 — A F1 sai sozinha, primeiro, como `bugfix/*`.

A F1 é curta, é defeito puro e **não depende do backend**. Sai antes de tudo. O que ela
**não** faz é resolver o caso B — e o plano diz isso em voz alta (§6), em vez de deixar o
PR 1 parecer a solução completa.

### D6 — O `min` de `image.width`/`height` vai de `0` para `1`, **na F1**.

> **Confirmada pelo humano em 2026-08-15 (Q2).**

**Sem isto, o clamp do `NumberEditor` não corrige nada:** clampar contra `min: 0` permite
`0`, que é exatamente o valor que some com a imagem (§2.3). São **duas linhas** em
`widget_catalog.dart:329,336`. O incômodo é de forma — um `bugfix/*` tocando `sdui_core` —,
não de risco.

**Efeito colateral aceito:** largura fracionária abaixo de 1px deixa de ser digitável no
`image`. Ninguém quer uma imagem de 0,5px.

### D7 — A F1 cria o **primeiro** arquivo de tokens do `sdui_flutter`.

> **Confirmada pelo humano em 2026-08-15 (Q3).**

O Gate 4 vale em `packages/sdui_flutter`, mas **não existe token nenhum lá**. A F1 cria
`packages/sdui_flutter/lib/src/theme/sdui_chrome_tokens.dart` (cores, tamanhos e espaçamentos
do **chrome do renderer** — o styling derivado do spec continua vindo do catálogo/props) e
migra os **4** hardcodes do pacote.

**Os valores de `_UnknownTypeBox` são preservados byte a byte** — a migração dele é de forma,
para não mexer em golden que não é desta fase. Só o placeholder do `image` muda de aparência
(R1).

### D8 — O `helpText` da F4 acende nos **dois** caminhos de moldura.

`PropFieldEditor` monta a `PropFieldShell` em `:64`, **mas os kinds self-chromed não passam
por lá**: `_selfChromed = {FieldKind.dimension}` (`prop_field_editor.dart:24`) desvia para
`SelfChromedPropEditor:29` → `DimensionEditor`, que monta a própria shell (`:117`).

Como a D3 transforma `width`/`height` em `dimension`, acender o `helpText` só no
`PropFieldEditor` deixaria **justamente os dois campos novos** sem ajuda. `PropFieldShell`
ganha o parâmetro; **os dois chamadores passam**.

### D9 — `opacity` fica **fora** do descriptor.

> **Confirmada pelo humano em 2026-08-15 (Q4).**

**⚠️ Atenção de quem for reabrir: a razão original caducou junto com o `fallback`.** O
argumento que decidiu a pergunta foi que `opacity` está na lista literal de opções ignoradas
no caminho `<img>` (`flutter/lib/src/widgets/image.dart:419-421`). **Com a D2 (proxy) não há
caminho `<img>`** — tecnicamente `opacity` funcionaria.

**A decisão continua valendo, por outra razão, e é esta que fica registrada:** `opacity` não
pertence ao recorte "o básico que o `container` já tem e o `image` não" — **o `container`
também não tem `opacity`**. Opacidade é transversal a qualquer widget e pede prop genérica ou
primitivo próprio, não um campo avulso no `image`. Entregá-la só aqui criaria assimetria de
catálogo, que é o oposto do objetivo da F4. Fica em §12 como evolução, para **todo** o
catálogo de uma vez.

### D10 — **[nova]** A `publishableKey` **não é segredo**, e o proxy não pode tratá-la como se fosse.

`generatePublishableKey()` (`backend/src/projects/publishable-key.ts`) produz `pk_` + 32
bytes aleatórios, e o app cliente a carrega em `AppConfig`
(`apps/driva_demo_app/lib/core/config/app_config.dart:30`) — **embarcada no binário**.
Qualquer um que extraia um APK tem a chave. Ela é **identificador de projeto**, não
credencial.

**Consequências que a F2 tem de respeitar:**

- A chave serve para **contabilizar e bucketizar rate limit**, nunca como fronteira de
  segurança. Nenhum controle de SSRF pode depender de "só quem tem a chave chega aqui".
- **A defesa é a allowlist, não o portão.** Todo controle da §5/F2 vale mesmo para um chamador
  legítimo e autenticado.
- Rate limit por **IP** e, onde houver identidade, **por chave** — os dois, não um ou outro.
  **Hoje o caminho do editor não tem identidade nenhuma** (não há auth, item 26 aberto):
  o bucket é por IP, e a bucketização por chave entra junto com a rota pública (§12) ou com
  o item 26, o que vier primeiro. Isso está escrito para ninguém supor que a chave já está
  protegendo alguma coisa.

### D11 — **[nova]** O proxy é **chrome do editor**, injetado — não faz parte do contrato do renderer.

**A decisão de arquitetura que impede o erro caro.** Se `builders/image.dart` montar a URL do
proxy sozinho, **todo app cliente publicado passa a puxar imagem pelo nosso backend** —
banda, latência, ponto único de falha e uma conta que cresce com o sucesso dos clientes. E
seria inútil: **em app móvel não existe CORS**, o caminho de bytes sempre vence.

Portanto:

- `SduiRenderer` ganha um hook **opcional**, no mesmo padrão do `nodeWrapper` que já existe
  (`renderer.dart:11-17`):
  ```dart
  typedef SduiImageUrlResolver = String Function(String src);
  ```
  Default `null` = identidade. `SduiView` e `SduiView.content` repassam.
- **O editor injeta** um resolver que reescreve para `{apiBaseUrl}/v1/media/proxy?url=…`,
  montado a partir de `AppConfig.apiBaseUrl` (`app_config.dart:32`).
- **O `driva_demo_app` não injeta nada** e continua puxando a imagem direto do host.
- O resolver **só se aplica a URL absoluta `http`/`https`**. `src` vazio, binding literal
  (`{{...}}` — o editor não executa binding, é dado) ou qualquer outra coisa **passa
  intocada**. Sem isso, o editor proxyaria uma string sem sentido e trocaria o estado
  "vazio" por um "falhou" mentiroso.

**Consequência para o teste:** o `buildImage` fica testável sem rede e sem backend — o golden
e o widget test injetam um resolver identidade.

### D12 — **[nova]** O estado "carregando" sai do **`frameBuilder`**. O `loadingBuilder` está **proibido** neste builder.

> **Decidida pelo tech-lead em 2026-08-15**, sobre o bloqueio **B1** levantado pelo QA na
> revisão da F1. O diagnóstico do QA está correto e a evidência é do SDK, não de opinião.

**O `loadingBuilder` não funciona no Flutter Web.** No SDK **3.38.6**:

- `_network_image_web.dart` › `loadViaDecode()` (`:128-140`) constrói o
  `MultiFrameImageStreamCompleter` **sem o argumento `chunkEvents:`**, e `_fetchImageBytes`
  registra só os listeners `load` e `error` do XHR — não há `progress`.
- `grep -c chunkEvents _network_image_web.dart` = **0**; no `_network_image_io.dart` = **9**.
  A assimetria é a prova: o caminho mobile emite progresso, o web não emite **nenhum**.
- Logo `_ImageState._loadingProgress` (`widgets/image.dart:1093`) nasce `null` e **nunca**
  recebe evento (só `:1227`, dentro do listener de chunk, o atribuiria). O `loadingBuilder`
  é chamado (`:1409`) sempre com `null`, e a convenção do builder
  (`if (loadingProgress == null) return child;`) devolve o `RawImage` vazio.

**Resultado se ignorarmos isto:** o `ImageLoadingBox` aparece **só no mobile** — o terceiro
estado não existe justamente no editor web, que é onde o relato do dev mora. Seria um
aceite cumprido no papel e falso na tela.

**O `frameBuilder` resolve, e resolve de verdade:**

- É chamado em **todo** build (`widgets/image.dart:1404-1405`), inclusive antes de existir
  qualquer frame.
- `_frameNumber` nasce `null` (`:1096`), volta a `null` a cada requisição nova (`:1262`) e só
  vira `0` quando o **primeiro frame decodificado chega** (`:1219`, dentro de
  `_handleImageFrame`).
- Portanto **`frame == null` ⇔ nenhum frame decodificado ainda ⇔ carregando**. O sinal vem da
  chegada do `ImageInfo`, **não** de `ImageChunkEvent` — e por isso funciona **idêntico em web
  e mobile**.
- A própria doc do SDK manda fazer assim (`widgets/image.dart:836-840`): _"for simpler cases
  such as displaying a placeholder widget that doesn't depend on the loading progress (e.g.
  static 'loading' text), [frameBuilder] will likely work and not incur as much cost."_

**Custo, registrado:** perdemos a **porcentagem** de progresso — que no web não existia de
qualquer forma. O estado é binário ("carregando" / "carregada"), que é exatamente o que a D1
pede: três estados **distinguíveis**, não uma barra de progresso.

**Comportamento correto que não é defeito:** em cache hit o frame chega no primeiro build
(`_wasSynchronouslyLoaded`, `:1220`) e o estado "carregando" **não pisca**. Isso é desejável —
e é por isso que o E2E exige throttling de rede para observá-lo (§10 passo 2, DoD item 22).

**Alternativa descartada:** wrapper com estado próprio (`StatefulWidget` ouvindo o
`ImageStream`). Reimplementaria o que o `_ImageState` já faz, com `didUpdateWidget`,
`dispose` e ciclo de vida de listener por conta própria — mais código e mais superfície de
bug para chegar ao mesmo `frame == null`.

**Não há saída pelo `webHtmlElementStrategy`:** a **D2** manda manter o default `never` — o
humano escolheu o proxy no backend em vez do `fallback`.

### D13 — **[nova]** `showDiagnostics` no `SduiRenderer`: o renderer precisa saber de que lado da fronteira está.

> **Nasceu de achado bloqueante do CISO na F1 (2026-08-15)** e já está implementada. Está
> registrada aqui **em atraso**, porque a §3.1 dizia que o `nodeWrapper` era _o_ padrão de
> hook — quem pegasse a F3 leria um plano que desconhecia o segundo hook e o reinventaria.

**O problema.** `sdui_flutter` é **o mesmo renderer dos dois lados**: editor e app publicado.
O `ImageErrorBox` da D1 mostra o motivo da falha em texto — e `NetworkImageLoadException`
embute a própria URL na mensagem (`'HTTP request failed, statusCode: $c, $uri'`). Num app
cliente com URL assinada, isso **vaza a URL para o usuário final**. Omitir só o campo `src`
não bastaria: o vazamento está dentro do `toString()` da exceção.

**A correção.** `SduiRenderer.showDiagnostics`, **default `false`**, repassado por `SduiView`
e `SduiView.content` (também default `false`), ligado **em um único ponto do repo**:
`preview_surface.dart:104`, o canvas do editor. Fora do editor,
`NetworkImageLoadException` vira `'HTTP $statusCode'` e todo o resto cai num `else` genérico
que **nunca** toca `.toString()`.

**É a mesma razão da D11**, e por isso as duas andam juntas: o renderer é compartilhado, então
tudo que é **chrome de autoria** (diagnóstico detalhado, proxy de imagem) entra por hook
opcional com default seguro — nunca por detecção de ambiente dentro do builder.

**Regra que fica, e vale para a F3:** hook novo no `SduiRenderer` nasce com o default do
**app cliente**, não o do editor. O editor é quem liga; o app publicado é quem não sabe que
existe.

### D14 — **[nova]** O Gate 4 passa a varrer `sdui_flutter`. O Gate 1 continua isento, e vira item próprio.

> **Decidida pelo tech-lead em 2026-08-15**, sobre apontamento do QA na F1.

`scripts/gates_guard.sh` isentava **`packages/sdui_flutter/` inteiro** dos Gates 1 e 4, com a
justificativa de que _"seu styling vem do spec SDUI"_. **A D7 tornou isso falso:** agora há
chrome tokenizado no pacote (`lib/src/theme/sdui_chrome_tokens.dart` + os quatro widgets de
estado do `image`), e sem o gate ele ficaria guardado só por revisão humana — para sempre.

**Medido antes de decidir**, que é o que torna a decisão barata:

| Gate | Se `sdui_flutter` entrasse hoje | Decisão |
| --- | --- | --- |
| **Gate 4** | **zero violações** — a migração da D7 já deixou o pacote limpo | **Entra agora**, no PR da F1. Custo nulo, e é o gate que guarda o que a F1 acabou de criar |
| **Gate 1** | **28 ocorrências, todas legítimas**: 24 funções `buildX(...)` do registry, o `typedef` de `registry.dart:7` e os métodos `render`/`renderAll`/`renderFlexChildren` do próprio renderer | **Continua isento.** Estreitar exige exceção por caminho **mais** escapes por linha no `renderer.dart` — trabalho próprio, sem urgência (§12) |

**A isenção de tokens é por caminho exato, não por nome de pasta.** `find … | grep -v '/theme/'`
seria mais curto e **erraria**: `apps/driva_editor/lib/modules/preferences_module/presentation/theme/`
existe e **não** é fonte de token — ficaria fora dos dois gates sem ninguém notar. O script usa
`/core/theme/` para os apps e `/src/theme/` para o pacote.

**Entra nesta fase** porque é a rede que guarda a entrega da própria F1; deixar para depois
significa mergear tokens novos sem gate automático desde o dia um.

### D15 — **[nova]** `width: 0` — o aceite passa a medir **o fim do silêncio**, não a visibilidade da imagem.

> **Decidida pelo tech-lead em 2026-08-15**, sobre o bloqueio **T2** do QA. **Não reabre a
> D6:** `min` continua `1`.

**O problema com o texto antigo.** O aceite dizia _"digitar `0` não faz a imagem sumir"_ e o
DoD pedia print da imagem _"continua visível"_. Com o clamp da D6, `0` vira `1` — e **1px é
invisível na prática**. O aceite era falso na tela, exatamente como o `Ctrl+Shift+W` e o
`loadingBuilder` (§8.13).

**Por que NÃO subir o piso** (a saída (b) que o QA ofereceu): `min` é uma **restrição de
domínio**, parte do contrato do catálogo — vale para o app do cliente, não só para o campo do
editor. "Visível" é um **julgamento de UX** que depende de zoom, densidade de pixel e do
tamanho do contêiner: **não existe número certo**. Escolher `8` ou `16` proibiria para sempre,
em todos os clientes, uma imagem decorativa fina de 4px — para consertar um erro de digitação
no editor. **Seria codificar uma decisão de UX na camada errada**, e é por isso que a saída (b)
está recusada.

**O que a F1 entrega de verdade, e entrega bem:** o valor deixa de sumir **em silêncio**. O
campo mostra "Ajustado para o mínimo (1)" como `helperText`, distinto do `errorText` de
entrada inválida. É a **mesma tese do item inteiro** — a D1 faz o carregamento parar de
falhar calado; a D15 faz a digitação parar de falhar calada. Reescrever o aceite não é
recuo: é o aceite finalmente descrevendo o que o mecanismo faz.

**O que fica registrado como evolução** (§12), porque é a pergunta de produto que sobra:
tratar `0` (e talvez o campo vazio) como **"automático"** — devolver a imagem ao tamanho
intrínseco em vez de clampar. É mudança de semântica de prop numérica em **todo** o catálogo,
não carona deste bugfix.

### D16 — **[nova]** O teste do contrato da D12 **não** desce para a F1. O intervalo fica registrado.

> **Decidida pelo tech-lead em 2026-08-15**, sobre o apontamento **T5** do QA.

**O que estava incoerente** era o aceite, não o cronograma: o aceite 3 dizia que o teste de
widget "é o que fecha o aceite", mas o teste está na F5. Um aceite não pode depender de prova
que só existe três PRs depois. **Corrigido no aceite** (a prova na F1 é o contrato em revisão
+ o grep + o print do E2E); o teste da F5 é o **guarda de regressão**, não a prova inicial.

**Por que o teste não desce:** "a bateria automatizada é escrita por último" é regra do
projeto (CLAUDE.md, cap. 22 do livro). Antecipá-la é **desvio**, e desvio exige aprovação do
humano com registro em `variance_report.md` — não é chamada do tech-lead sozinho.

**O intervalo, dito em voz alta:** entre o merge da F1 e a F5, o único guarda automático do
contrato da D12 é o `grep loadingBuilder` do CI. **Ele não cobre o caso real de regressão:**
alguém reescrever o `frameBuilder` de um jeito que compile, não use `loadingBuilder` e mesmo
assim não mostre o estado (devolver `child` cedo demais, por exemplo). E **F3 e F4 editam esse
mesmo arquivo** — são duas oportunidades de quebrar sem rede.

**Mitigação sem desvio:** o aceite da **F3** e o da **F4** repetem o print do estado
"carregando" (a regressão apareceria no E2E de cada fase, não só no final). Se o humano
preferir a rede automática mais cedo, a saída é aprovar **um** teste de widget descendo para a
F1 como **`VR-16-02`** (o `VR-16-01` já é o `trust proxy` da F2) — está identificado e é
barato, mas **é decisão dele**, não nossa.

### D17 — **[nova]** A matriz de segurança é a **exceção documentada** à regra "testes por último". Ela nasce **na F2**.

> **Decidida pelo tech-lead em 2026-08-15**, resolvendo contradição do próprio plano: a §5›F5
> listava `media-proxy.e2e-spec.ts` como entrega da F5 ("por último"), enquanto o aceite da
> §5›F2 já exigia "a matriz do §11.4 inteira, executada como teste `e2e` do Nest". **O dev
> seguiu a F2, e é a leitura correta.**

**A razão, e ela é curta: um gate CISO sem prova executável não é gate.** Os 11 controles da
F2 são afirmações sobre o que o endpoint **recusa** — `file://`, `169.254.169.254`, redirect
para IP interno, resposta gigante, `Content-Type: text/html`. Recusa não tem print: a única
forma de demonstrar que ela acontece é executá-la. Adiar a matriz para a F5 significaria
mergear um proxy de SSRF para homologação com a segurança **atestada por leitura de código**,
e só prová-la três PRs depois. É exatamente o que a §11.4 já proíbe ao escrever "controle sem
caso que o exercite não conta como feito".

**O recorte da exceção, para não virar brecha:** vale **só** para a matriz de segurança do
proxy. O resto da bateria (F5) continua depois do E2E atestado — inclusive o teste do contrato
da D12, que **não** desceu (D16). A régua que separa os dois casos: **teste que é a única
prova possível de uma recusa de segurança vem junto com o código; teste que é guarda de
regressão de comportamento visível vem depois do E2E.**

**Consequência editorial:** o bullet do `media-proxy.e2e-spec.ts` **saiu da F5**. Estava nos
dois lugares e alguém o escreveria duas vezes.

### D18 — **[nova]** A matriz roda contra **servidor local efêmero**. O caminho de rede real **não** é provado pela F2.

> **Registrada em 2026-08-15**, na revisão da F2.

A suíte sobe um servidor HTTP efêmero no próprio teste e aponta o proxy para ele. **É a
escolha certa** — hermética, sem dependência de rede externa, sem flakiness em CI, e é a única
forma de encenar redirect para IP interno e resposta gigante de propósito.

**O preço, que precisa estar escrito para ninguém confundir:** a matriz verde prova que o
**guarda** funciona, **não** que a imagem do relato carrega. O caminho real — DNS público,
CORS do host, ACAO na resposta que chega ao Chrome — é provado **só** pelos itens **18 e 19 do
DoD §11.3**, no E2E manual em homologação.

**Que ninguém leia "linha 44 verde" como "a URL do relato carrega".** São afirmações
diferentes: a 44 diz que o proxy repassa uma imagem servida por um servidor de teste; a 19 diz
que a URL que o dev reclamou aparece na tela dele. A segunda é a que fecha o item.

## 5. Fases

### F1 — Os três estados ficam distintos · **[base]** · **[∥ com F2]** · **[sub-agente: especialista-infra]**

**Mergeável sozinha. É `bugfix/*`. Não toca backend e não depende do proxy.**

- **`packages/sdui_flutter/lib/src/theme/sdui_chrome_tokens.dart`** (arquivo novo, D7) —
  tokens do chrome do renderer. Migrar `renderer.dart:77,81` **preservando os valores**.
- **`packages/sdui_flutter/lib/src/builders/image.dart`** —
  - **`frameBuilder`** → estado "carregando" próprio quando `frame == null` (**D12**).
    **Não usar `loadingBuilder`:** no Flutter Web ele nunca recebe progresso e o estado
    sumiria justamente no editor;
  - `errorBuilder` → estado "falhou" **visualmente distinto** do vazio, com ícone + borda +
    `Semantics`/tooltip trazendo o motivo e a URL (D1);
  - o `Color(0x22000000)` duplicado em `:18,29` **desaparece** — os dois casos deixam de
    compartilhar aparência por construção.
  - **Não** mexer em `webHtmlElementStrategy` — o default `never` fica (D2).
- **Widgets novos, arquivo próprio cada um** (Gates 1 e 3):
  `sdui_flutter/lib/src/builders/image/image_empty_box.dart`, `.../image_loading_box.dart`,
  `.../image_error_box.dart` e **`.../image_error_detail.dart`** (o detalhe do erro, só
  renderizado sob `showDiagnostics`). _A exceção de Gate 1 cobre a **função builder** do
  registry, não os widgets que ela monta._
- **`packages/sdui_flutter/lib/src/renderer.dart` + `.../sdui_view.dart`** — o flag
  `showDiagnostics`, default `false`, repassado pelos **dois** construtores (**D13**).
- **`apps/driva_editor/lib/.../canvas/preview_surface.dart`** — `showDiagnostics: true`. É o
  **único** ponto do repo que liga o flag, e é o mesmo ponto onde a F3 injeta o resolver.
- **`apps/driva_editor/lib/.../prop_field/number_text_field.dart`** — `errorText` e
  `helperText`, para o campo poder sinalizar (entrada inválida × ajuste ao mínimo).
- **`scripts/gates_guard.sh`** — o Gate 4 passa a varrer `packages/sdui_flutter/lib`
  (isentando só `lib/src/theme/`). **A D7 tornou falsa a justificativa da isenção antiga** —
  agora há chrome tokenizado no pacote, e sem isto o CI não o guardaria (D14).
- **`packages/sdui_core/lib/src/catalog/widget_catalog.dart:329,336`** — `min: 0` → `min: 1`
  (D6). **Só estas duas linhas** do descriptor.
- **`apps/driva_editor/lib/.../prop_field/number_editor.dart:55-62`** — clampar contra
  `field.min`/`field.max` como o `DimensionEditor:73-74`, e **sinalizar** entrada inválida em
  vez de descartá-la. Vale para **todo** `doubleNum`/`intNum` do catálogo.

**Aceite (validável):**

1. **Caso C** — `https://exemplo.invalido/x.png` mostra o estado **"falhou"**, com o motivo
   em texto, **visualmente distinto** do estado vazio.
2. **Caso D** — campo vazio mostra o estado **"vazio"**, distinto de (1).
3. **Caso A** — URL de host com ACAO continua renderizando (nenhuma regressão), e enquanto
   carrega aparece o estado **"carregando"**, distinto de (1) e (2), **no editor web e no
   mobile**.
   - **Como se verifica na F1, já que "esperar carregar" não é observável de propósito:**
     (a) o contrato da **D12** lido no código em revisão — `frameBuilder` com
     `frame == null` → `ImageLoadingBox`; (b) `grep -rn "loadingBuilder" packages/sdui_flutter/lib`
     = zero; (c) no E2E, o print com **throttling de rede** no DevTools (§10 passo 2).
   - **O teste de widget deste contrato mora na F5**, com o resto da bateria (regra do
     projeto: automatizado por último). Ele é o que torna o contrato **permanente**, não o que
     o torna **verdadeiro** agora — ver **D16** para o intervalo que isso abre e por que ele
     foi aceito.
   - **`grep -rn "loadingBuilder" packages/sdui_flutter/lib` devolve zero** — o mecanismo
     errado não pode reaparecer (D12).
   - **Não é falha:** em cache hit o estado não pisca (`_wasSynchronouslyLoaded`). Sem
     throttling, não esperar vê-lo.
4. **Caso B** — URL de host sem ACAO cai no estado **"falhou"** com motivo legível.
   **Ainda não carrega, e isso é esperado nesta fase** (é a F3).
5. Digitar `0` em Largura **não some em silêncio**: o valor é clampado para `1` e o campo
   mostra **"Ajustado para o mínimo (1)"** como `helperText`, **visualmente distinto** do
   `errorText` de entrada inválida (aceite 6). **A imagem fica com 1px — ou seja, continua
   praticamente invisível, e isso é esperado** (D15). O que a F1 entrega aqui é o fim do
   silêncio, não a imagem de volta: o usuário passa a saber que digitou um valor fora da
   faixa, em vez de ver a imagem evaporar sem explicação.
6. Digitar `abc` em Largura mostra `errorText` e **não** propaga o valor, em vez de descartar
   a digitação calada.
7. **Nenhum literal de cor fora do arquivo de tokens** (D7):
   `grep "Color(0x" packages/sdui_flutter/lib | grep -v "lib/src/theme/"` devolve **zero**.
   _O arquivo de tokens **contém** literais — é a definição dele; o mesmo padrão do
   `driva_editor` (`core/theme/`). Um grep que exigisse zero no pacote inteiro só se
   cumpriria trocando `Color(0x…)` por `Color.fromARGB(…)` para enganar o grep, que é o
   oposto do gate._
8. **`driva_demo_app`:** a suíte continua verde e o **fonte do app não muda** (zero diff em
   `apps/driva_demo_app/`). O **comportamento visual muda de propósito** — ele consome o mesmo
   `sdui_flutter` e passa a mostrar a caixa de erro no lugar do quadrado cinza mudo, que é a
   correção. O que **não** pode mudar é o caminho de rede: continua puxando direto do host
   (D11).
9. Golden `goldens/node_image.png` regravado com o diff citado na descrição do PR (R1).
10. **`showDiagnostics` (D13):** default `false` nos **dois** construtores
    (`SduiView` e `SduiView.content`); `grep -rn showDiagnostics apps/driva_demo_app` devolve
    **zero**; e com o flag desligado a caixa de erro **não** contém a URL nem
    `error.toString()` — provado com uma `NetworkImageLoadException`, cuja mensagem embute a
    própria URI.
11. **`gates_guard.sh` (D14):** roda verde com `packages/sdui_flutter/lib` sob o Gate 4, e um
    `Color(0x…)` plantado fora de `lib/src/theme/` **faz o script sair 1**. _Sem esse segundo
    teste o gate pode estar passando por não varrer nada._

### F2 — Backend: proxy de mídia · **[0-dep; ∥ com F1]** · **[sub-agente: especialista-infra]** · **[⛔ gate CISO obrigatório]**

**Fase própria por imposição do humano.** É superfície de SSRF: um endpoint que busca URL
arbitrária a mando de quem chama. **Nenhum controle abaixo é opcional**, e cada um tem um
caso concreto que o prova no DoD §11.4 — **controle sem caso que o exercite não conta como
feito**.

- **`backend/src/media/`** (módulo novo: `media.module.ts`, `media.controller.ts`,
  `media.service.ts`, `url-guard.ts`, **`media.constants.ts`**) — `GET /v1/media/proxy?url=<url-encoded>`,
  registrado em `app.module.ts`. Sob o prefixo `v1` (`main.ts:26`), herda o
  `app.enableCors({ origin: [...corsOrigins, localhost] })` (`main.ts:50`) — **é isso que faz
  a imagem carregar no editor**. O `media.constants.ts` tira os números mágicos (teto,
  timeout, saltos, `Content-Type` permitidos, throttle) do serviço: os limites viram valor
  nomeado e auditável num lugar só, que é o que o gate CISO precisa reler.
- **`backend/src/main.ts` — `app.set('trust proxy', 1)`.** ⚠️ **Não nasceu do plano: veio do
  gate CISO.** Registrado como **VR-16-01** em `variance_report.md` desta pasta. Sem isso o
  `req.ip` — chave do `ThrottlerGuard` — é o IP interno do Traefik, **igual para todo mundo**,
  e o rate limit do controle 7 vira balde global.
- **Infraestrutura de teste do backend** — `backend/test/jest-e2e.json`, devDependencies
  (`jest`, `ts-jest`, `supertest`) e os scripts `test`/`test:e2e`. **Aditivo e benigno, mas
  registre-se o que ele revela:** o `backend/` **não tinha bateria de teste nenhuma** até esta
  fase. Nasceu de carona aqui; virar infraestrutura de verdade é item próprio (§12).

**Controles obrigatórios:**

1. **Allowlist de esquema** — só `http` e `https`. Mata `file://`, `gopher://`, `data:`,
   `ftp://`, `blob:` e afins. Recusa por allowlist, nunca por blocklist.
2. **Recusa de destino interno, sobre o IP resolvido** — não sobre a string da URL.
   Bloquear: loopback (`127.0.0.0/8`, `::1`), privados (`10/8`, `172.16/12`, `192.168/16`),
   link-local (`169.254.0.0/16` — **`169.254.169.254` nomeadamente: é metadata de instância
   em nuvem e devolve credencial**), CGNAT (`100.64/10`), `0.0.0.0/8`, multicast e reservados.
   **Os equivalentes IPv6 também**: `fc00::/7` (ULA), `fe80::/10` (link-local) e — o bypass
   clássico — **IPv4-mapeado (`::ffff:169.254.169.254`)**.
3. **⚠️ A validação tem de valer na hora de conectar, não antes.** "Resolver, validar e
   depois chamar `fetch(url)`" **não é o controle** — o `fetch` resolve de novo e um DNS com
   TTL curto devolve outro IP na segunda resolução (**DNS rebinding**, TOCTOU clássico). O
   mecanismo correto em Node é um `http.Agent`/`https.Agent` com `lookup` customizado que
   **valida cada resolução no momento da conexão**, ou conectar ao IP já validado enviando o
   `Host` original. **Este parágrafo é critério de revisão do CISO**, não sugestão.
4. **Revalidação a cada redirect.** Não seguir redirect automaticamente: seguir manualmente,
   aplicando os controles 1–3 a **cada salto**. Sem isso, um `302` para IP interno passa
   depois da validação. Teto de saltos (recomendo **3**), e redirect para esquema fora da
   allowlist é recusa.
5. **Teto de tamanho e timeout** — para o endpoint não virar amplificador. Abortar a conexão
   **em streaming, ao ultrapassar o teto**, sem bufferizar a resposta inteira em memória.
   Recomendo teto de **10 MB** e timeout de **10 s**.
6. **`Content-Type` de imagem na resposta** — allowlist (`image/png`, `image/jpeg`,
   `image/gif`, `image/webp`, `image/avif`, `image/svg+xml` **só se** houver decisão explícita:
   SVG carrega script). Qualquer outro (`text/html` à frente) é recusa, e o corpo **não** é
   repassado.
7. **Rate limit** — `@UseGuards(ThrottlerGuard)` no padrão que `projects.controller.ts:48,70`
   já usa, com `ThrottlerModule` próprio do módulo. Por **IP**; por **chave** quando houver
   identidade (D10).
8. **Nada de confused deputy** — **não** repassar ao alvo nenhum header do chamador
   (`Authorization`, `Cookie`, `x-driva-key`, `x-project-id`). A requisição de saída é montada
   do zero.
9. **Resposta limpa** — não repassar `Set-Cookie` nem headers de autenticação do alvo.
10. **Erro genérico, sem oráculo** — a resposta de erro **não** carrega corpo, status nem
    tempo do alvo de forma que permita mapear a rede interna. Erro tipado do nosso lado
    (`400` para URL recusada, `502` para alvo que falhou, `504` para timeout), com mensagem
    própria.
11. **Cache** — `Cache-Control` e ETag no padrão do `PublicController`, para o proxy não
    repetir a busca a cada tecla digitada no inspector.

**Aceite (validável):** a **matriz de segurança do DoD §11.4 inteira**, executada como teste
`e2e` do Nest **nesta fase** (exceção da **D17**), **mais** o gate do CISO aprovado por
escrito. Uma imagem legítima atravessa o proxy e volta com `Content-Type` de imagem e ACAO da
origem do editor.

**O que este aceite NÃO prova (D18):** a suíte roda contra **servidor local efêmero**. Ela
demonstra que o **guarda** funciona; **não** demonstra que a URL do relato carrega no Chrome.
Isso são os itens **18 e 19 do DoD §11.3**, no E2E manual em homologação — e é lá que a fase
encosta na realidade.

### F3 — O renderer ganha o resolver; o editor injeta · **[depende de F1 + F2]** · **[sub-agente: especialista-infra]**

**É a fase que faz o caso B carregar** — o relato do dev fecha aqui.

- **`packages/sdui_flutter/lib/src/renderer.dart`** — `typedef SduiImageUrlResolver` e o campo
  opcional no `SduiRenderer`, no padrão do `nodeWrapper` (D11).
- **`packages/sdui_flutter/lib/src/sdui_view.dart`** — repassar nos **dois** construtores
  (`SduiView` e `SduiView.content`, `:9-31`).
- **`packages/sdui_flutter/lib/src/builders/image.dart`** — aplicar o resolver ao `src`,
  **só** para URL absoluta `http`/`https` (D11).
- **`apps/driva_editor/lib/…`** — o resolver do editor, montado de `AppConfig.apiBaseUrl`
  (`app_config.dart:32`), injetado onde o canvas monta o `SduiView.content`
  (`.../canvas/preview_surface.dart`). **Arquivo próprio**, não uma lambda inline.

**Aceite (validável):**

1. **Caso B carrega no editor web em homologação.** É o relato do dev, fechado.
2. **Caso A continua carregando** (agora via proxy) e o estado "carregando" continua
   aparecendo, com throttling — **print obrigatório**, porque esta fase edita
   `builders/image.dart` e é uma das duas janelas sem teste automático do contrato da D12
   (**D16**).
3. **Caso C** continua no estado "falhou" — o proxy devolve erro tipado e o `errorBuilder`
   da F1 o mostra.
4. **`driva_demo_app` inalterado**: não injeta resolver, puxa direto do host. Provado por
   teste, não por promessa.
5. `src` vazio ou binding literal **não** é proxyado (estado "vazio" preservado).
6. Golden do `image` continua verde com resolver identidade — a imagem **é** capturável
   (D2, o ganho colateral).

### F4 — Catálogo: `image` abrangente · **[depende de F3]** · **[sub-agente: especialista-dominio + especialista-infra]**

É o **"Incremento 4"** do item 9 (`docs/roadmap.md:72`), sem número novo no roadmap.

- **`packages/sdui_core/lib/src/catalog/widget_catalog.dart`**, descriptor do `image`:

| Campo | `FieldKind` | Grupo | Nota |
| --- | --- | --- | --- |
| `src` | `string` (mantém) | content | ganha **`helpText`** |
| `width` / `height` | `doubleNum` → **`dimension`** | size | D3; `min: 1` já veio da F1/D6 |
| `fit` | `enumeration` (mantém) | content | — |
| `alignment` | `alignment` | content | posição na caixa quando o `fit` sobra espaço |
| `borderRadius` | `doubleNum` | style | igual ao `container` — **sem o risco de platform view**, graças à D2 |
| `backgroundColor` | `color` | style | fundo enquanto carrega e atrás de PNG transparente |
| `semanticLabel` | `string` | content | acessibilidade — hoje o `image` é invisível ao leitor de tela |
| ~~`opacity`~~ | — | — | **fora** (D9) |

- **`packages/sdui_flutter/lib/src/builders/image.dart`** — `SduiDimensionBox` (**copiar a
  forma de `container.dart:29-35`**), `ClipRRect` para o raio, `alignment`, `Semantics(label:)`.
- **`apps/driva_editor/lib/.../prop_field/prop_field_shell.dart`** — **renderizar o
  `helpText`**, com os **dois** chamadores passando (D8).

**Aceite (validável):**

1. **Compatibilidade:** spec antigo com `"width": 200` (número cru) continua válido e
   renderiza **igual** — teste explícito (R4).
2. `"width": "100%"` estica a imagem à largura do pai.
3. Raio, alinhamento e cor de fundo aparecem no canvas **e** no JSON. O raio **compõe** —
   se não compuser, é bug, não limitação (a D2 tirou o platform view do caminho).
4. O `helpText` do `src` aparece no Inspector, **e o de `width` também** (prova da D8).
5. **Nenhuma linha nova no editor** foi necessária para os campos novos — regra do item 9.
   O diff em `apps/driva_editor/` é **só** o `helpText`; nada de `if (type == 'image')`.
6. `semanticLabel` chega ao leitor de tela (`find.bySemanticsLabel`).
7. O estado "carregando" **continua aparecendo** com throttling — **print obrigatório**. Esta
   fase é a segunda e última janela sem teste automático do contrato da D12 (**D16**).

### F5 — Bateria automatizada · **[por último, depois do E2E atestado]** · **[dono: qa]**

_**Não** inclui `backend/test/media-proxy.e2e-spec.ts`: a matriz de segurança nasce **na F2**,
junto com o proxy — é a exceção documentada da **D17**, porque recusa de segurança não tem
print e um gate CISO sem prova executável não é gate._

- `sdui_core/test/catalog/widget_catalog_test.dart` — descriptor novo; **round-trip de
  compatibilidade** (`{"width": 200}` e `{"width": "100%"}`).
- `sdui_flutter/test/builders/image_test.dart` (novo) — os três estados são **widgets
  diferentes**; **`frame == null` produz o `ImageLoadingBox` e `frame != null` produz a
  imagem** (o contrato da D12, e o que impede a regressão do bloqueio B1); `width: 0` não
  colapsa; `fit`/`alignment`/raio aplicados; `semanticLabel` presente; **resolver aplicado só
  a `http`/`https`** e **não** aplicado quando ausente (D11).
- `sdui_flutter/test/renderer_golden_test.dart` — golden `node_image` regravado (R1).
- `apps/driva_editor/test/.../prop_field/number_editor_test.dart` — clamp e sinalização.
- Widget test do `helpText` na `PropFieldShell`, **pelos dois caminhos** (D8).

**Aceite:** os testes acima passam e a suíte existente continua verde.

## 6. Ordem de PRs, precedências e o que fica bloqueado

```
F1 ──────────────┐
                 ├──► F3 ──► F4 ──► [E2E atestado] ──► F5
F2 (backend) ────┘
```

| PR | Fase | Branch | Depende de | Pode começar |
| --- | --- | --- | --- | --- |
| 1 | F1 | `bugfix/<issue>-image-falha-silenciosa` | — | **agora** (após o merge do item 38) |
| 2 | F2 | `feature/<issue>-media-proxy` | — | **agora, em paralelo** |
| 3 | F3 | `feature/<issue>-image-resolver` | PR 1 **e** PR 2 | após os dois |
| 4 | F4 | `feature/<issue>-image-abrangente` | PR 3 | após F3 |
| 5 | F5 | `feature/<issue>-image-testes` | PR 4 + E2E atestado | por último |

**Paralelismo real: F1 e F2.** São árvores inteiramente disjuntas — `packages/sdui_flutter` +
`apps/driva_editor` de um lado, `backend/src/media/` do outro. Dois sub-agentes podem correr
juntos desde o dia 1. Dentro da F1 ainda cabem duas mãos: **[∥]** os três widgets de estado +
tokens (`sdui_flutter`) e **[∥]** o clamp do `NumberEditor` (`driva_editor`, arquivo disjunto).

**F3 e F4 são serial com F1**: as três tocam `builders/image.dart`. Não paralelizar.

### O que fica bloqueado até o proxy existir

| Bloqueado até o PR 3 | Por quê |
| --- | --- |
| **O caso B carregar** — a URL do relato do dev | Depende do proxy (F2) **e** da injeção (F3) |
| O passo 4 do E2E (§10) e o **item 17 do DoD** | Mesmo motivo |
| Qualquer promessa ao dev de que "a URL agora funciona" | Até o PR 3, o que temos é a falha **explicada**, não resolvida |

### O que sai antes, e vale por si

| Sai no PR 1 | Valor |
| --- | --- |
| Falha deixa de ser silenciosa (casos B, C e D distinguíveis) | **É o defeito relatado.** O dev passa a saber por que a imagem não aparece — hoje ele não tem como saber |
| `width: 0` não some mais com a imagem | Segunda causa silenciosa, independente de CORS |
| Clamp e sinalização em **todo** campo numérico do catálogo | Ganho genérico, além do `image` |
| Primeiro arquivo de tokens do `sdui_flutter` | Destrava o Gate 4 no pacote |

**Se o tempo acabar, F1 é o que tem de estar no ar** — mas com o recado honesto de que a
metade CORS vem no PR 3.

## 7. Riscos

- **R1 — O golden do `image` vai quebrar.** `renderer_golden_test.dart:55` renderiza o
  `image` **sem `src`**; a D1 muda esse visual. **Mitigação:** regravar no mesmo PR, com o
  diff citado na descrição. Regravar **sem citar** é o que esconde regressão.
- **R2 — SSRF no proxy. É o risco dominante do item.** Um endpoint que busca URL arbitrária
  é, por construção, "faça uma requisição por mim". **Mitigação:** os 11 controles da F2, a
  matriz do §11.4 como prova, e o **gate CISO obrigatório** — que não é carimbo: o CISO tem
  de ler o `url-guard.ts` e o mecanismo de conexão, não só a lista.
- **R3 — DNS rebinding (TOCTOU).** O sub-risco de R2 que quase toda implementação ingênua
  deixa passar: valida o IP, depois chama `fetch(url)`, que **resolve de novo**.
  **Mitigação:** controle 3 da F2 (`lookup` customizado que valida na conexão). **Tem caso
  próprio no DoD** (host que resolve para IP privado).
- **R4 — Migrar `width`/`height` para `dimension` mexe em spec já salvo.**
  `DimensionValue.parse` aceita `num`, mas isso é promessa até haver teste. **Mitigação:**
  aceite 1 da F4, com round-trip.
- **R5 — O proxy vira ponto único de falha das imagens do editor.** Backend fora do ar =
  nenhuma imagem no canvas. **Mitigação:** é o editor, não o app do cliente (D11), e o editor
  já não funciona sem backend. Cache/ETag (controle 11) reduz a carga.
- **R6 — Banda e custo.** Toda imagem do editor atravessa o backend. **Mitigação:** limitado
  ao uso do editor pela D11; teto de tamanho e cache. **Se algum dia a rota pública existir
  (§12), a conta muda de ordem de grandeza** — decidir com número na mão, não por inércia.
- **R7 — O resolver vazar para o app cliente.** Se alguém hardcodar a URL do proxy no builder
  em vez de injetar, todo app publicado passa a puxar imagem pelo nosso backend.
  **Mitigação:** D11 + o aceite 4 da F3 (teste que prova que o `driva_demo_app` não injeta).
- **R8 — Clamp por tecla dessincroniza o campo do estado.** O valor emitido é clampado, o
  texto digitado fica como está (mesmo contrato do `DimensionEditor:73-74`). Reescrever o
  texto a cada tecla move o cursor — é o motivo documentado dos dois `didUpdateWidget`.
  **Mitigação:** aceito conscientemente; ressincronizar na perda de foco vira item próprio
  (§12). **Nenhum `field.min` do catálogo pode ser aumentado sem revisitar isto.**
- **R9 — O proxy nasce num backend sem autenticação.** Não há módulo de auth
  (`backend/src/` = categories, contents, health, prisma, projects, public, storage); auth é
  o **item 26, aberto**. O endpoint é alcançável da internet, protegido só por rate limit e
  pelos controles de SSRF. **Mitigação:** é exatamente por isso que os controles não podem
  depender de identidade (D10). **Matéria explícita do gate CISO** — se ele julgar
  insuficiente, o item para e volta ao humano.
- **R10 — Origem/Referer não é controle.** Restringir por `Origin` só afeta navegador; fora
  dele o header é forjado numa linha de `curl`. **Não contabilizar CORS como segurança** — o
  `enableCors` está ali para o editor **poder** usar, não para impedir que outros usem.

## 8. Divergências em relação ao plano de gaveta

Conferido contra `develop` + branch do item 38, Flutter **3.38.6**, backend NestJS atual. O
plano de gaveta está **substancialmente correto** na causa, nos `file:line` do builder, na
matriz CORS e na assimetria dos dois editores numéricos. Correções incorporadas:

1. **⚠️ A decisão de fundo foi invertida pelo humano.** O gaveta adotava
   `WebHtmlElementStrategy.fallback` e registrava o proxy como "evolução descartada, exige
   CISO". **O humano escolheu o proxy** (D2), com fase própria e gate CISO. Consequências que
   este plano absorve e o gaveta não previa: o item **passa a tocar o backend**; nascem F2 e
   F3; some o risco de `ClipRRect` sobre platform view; some a restrição de golden; e o
   recorte "não toca backend" — repetido no cabeçalho e no §1 do gaveta — **está corrigido em
   todos os lugares**.
2. **⚠️ O clamp sozinho não resolve o `width: 0`.** O gaveta manda clampar contra
   `field.min`, mas o `min` do `image` **é `0`** (`widget_catalog.dart:329,336`). O aceite era
   inalcançável. Virou a **D6**, confirmada pelo humano.
3. **⚠️ `sdui_flutter` não tem tokens.** O gaveta diz "estilo por token" como se houvesse
   onde. Não há `theme/` no pacote; os únicos 4 hardcodes são `image.dart:18,29` e
   `renderer.dart:77,81`. Virou a **D7**, confirmada.
4. **⚠️ `helpText` tem dois caminhos de moldura, não um.** `_selfChromed = {FieldKind.dimension}`
   (`prop_field_editor.dart:24`) desvia `dimension` para o `DimensionEditor`, que monta a
   própria shell (`:117`) — e a D3 torna `width`/`height` `dimension`. Virou a **D8**.
5. **⚠️ Não há hook de URL de imagem no renderer** — nem o gaveta nem a v1 deste plano
   notaram, porque o `fallback` não precisava de um. Com o proxy, sem hook o endereço seria
   hardcodado no builder e vazaria para os apps cliente. Virou a **D11**, e é a decisão de
   arquitetura mais cara de reverter depois.
6. **A razão do `opacity` caducou junto com o `fallback`.** O gaveta (e a v1) o excluíam por
   estar na lista de opções ignoradas no caminho `<img>`; com o proxy esse caminho não existe.
   A decisão do humano continua valendo, com **razão nova registrada** na D9 — senão alguém a
   reabre corretamente daqui a três semanas.
7. **⚠️ O `loadingBuilder` não funciona no Flutter Web — o gaveta e a v1 deste plano o
   prescreviam.** Descoberto pelo QA na reprovação da F1 (bloqueio **B1**), com evidência do
   SDK 3.38.6: `loadViaDecode()` (`_network_image_web.dart:128-140`) cria o
   `MultiFrameImageStreamCompleter` **sem `chunkEvents:`**;
   `grep -c chunkEvents _network_image_web.dart` = **0** contra **9** no
   `_network_image_io.dart`. Sem eventos de chunk, `_loadingProgress`
   (`widgets/image.dart:1093`) fica `null` para sempre e o `loadingBuilder` (`:1409`) devolve
   sempre o filho — **o estado "carregando" existiria só no mobile, e o relato do dev é no
   editor web**. Virou a **D12**: o estado vem do **`frameBuilder`** (`:1404-1405`), onde
   `frame == null` significa "nenhum frame decodificado" (`:1096,1219,1262`) e o sinal
   independe de `chunkEvents`. **Não é um aceite enfraquecido — é o mecanismo corrigido:** o
   aceite 3 continua exigindo os três estados no web, agora com como verificar.
   **É o mesmo erro do `Ctrl+Shift+W` no item 38** — um mecanismo que compila, passa em teste
   de widget e nunca dispara no ambiente real. Regra que fica: **toda promessa de
   comportamento no editor precisa ser verificada no Chrome, não só na suíte.**
8. **Dois aceites da F1 estavam mal escritos** e foram reformulados na revisão da F1:
   o de tokens exigia `grep "Color(0x" packages/sdui_flutter/lib` = zero, mas a D7 manda
   migrar os literais **para** um arquivo de tokens, que por definição os contém — o gate
   correto exclui `lib/src/theme/`, como no `driva_editor`; e "comportamento do
   `driva_demo_app` inalterado" era falso: o fonte não muda e a suíte segue verde, mas o app
   consome o mesmo `sdui_flutter` e **passa a mostrar a caixa de erro**, que é a correção
   chegando. O que não pode mudar lá é o caminho de rede (D11).
9. **A `publishableKey` não é segredo** — não aparece no gaveta. `publishable-key.ts` gera
   `pk_` + 32 bytes e o app cliente a embarca no binário. Virou a **D10**.
9b. **`showDiagnostics` não estava no plano** — nasceu de achado do CISO durante a F1 e foi
    registrado em atraso, como **D13**. O sintoma do atraso é instrutivo: a §3.1 continuou
    dizendo que o `nodeWrapper` era _o_ padrão de hook, quando já havia **dois**. Quem
    pegasse a F3 reinventaria o mecanismo. **Regra que fica: decisão de arquitetura tomada
    durante a execução volta para o plano no mesmo dia** — o plano é o estado que sobrevive
    ao reset de contexto; o que não está nele não existe para a próxima fase.
9c. **A isenção do `gates_guard.sh` ficou falsa** quando a D7 criou tokens no `sdui_flutter`
    — a justificativa escrita no script ("styling vem do spec SDUI") deixou de valer para o
    chrome do renderer. Virou a **D14**. Vale como lembrete de que **texto de justificativa
    em script de CI envelhece** e precisa ser relido quando a premissa muda.
10. **Precedente de rate limit já existe no repo** (`projects.module.ts:11`,
   `projects.controller.ts:48,70`) — a F2 imita, não inventa.
11. **F1 e F4 não são tão disjuntas quanto o gaveta diz** (ambas tocam `builders/image.dart` e
   o bloco `'image'` do catálogo), mas **F1 e F2 são**: o paralelismo real mudou de lugar.
13. **⚠️ Padrão de falha, não acidente: três aceites seguidos passaram no papel e eram falsos
    na tela.** Vale mais que qualquer um dos três isolados.

    | # | Aceite | O que prometia | Por que era falso |
    | --- | --- | --- | --- |
    | 1 | `Ctrl+Shift+W` (item 38) | atalho de envolver | o Chrome consome a tecla; o binding nunca dispara |
    | 2 | `loadingBuilder` (B1, F1) | estado "carregando" | não recebe progresso no Flutter Web; o estado só existia no mobile |
    | 3 | `width: 0` "não some" (T2, F1) | imagem continua visível | clampada para `1`, ela é invisível do mesmo jeito |

    **A forma é sempre a mesma:** o aceite foi escrito a partir da **API do mecanismo**
    ("existe um `loadingBuilder`", "existe um clamp", "existe um binding") em vez do **estado
    observável** ("o que um humano vê, e onde"). Todos os três compilavam, passariam em teste
    de widget e reprovariam na tela.

    **Regra que fica, e é a mais barata de aplicar:** _escreva o aceite como o **print** que o
    provaria._ Se não dá para descrever o print — o que aparece, em que tela, em que ambiente,
    e de que outro estado ele se distingue — **o aceite não é verificável e vai falhar
    tarde**. É a mesma disciplina que o DoD §11.3 já exige das evidências; ela precisa subir
    para o momento em que o aceite é **escrito**, não só quando é conferido.

    Os três foram achados por **medição do QA**, nunca por releitura do plano. Aceite escrito
    da API é invisível na revisão de texto, porque parece correto.

12. **Deslocamentos de linha:** descriptor do `image` em `widget_catalog.dart:310`; clamp do
    `DimensionEditor` em `:73-74`; `hasRange` em `prop_field.dart:55`; `loadViaDecode` em
    `_network_image_web.dart:128`; `WebHtmlElementStrategy` em `image_provider.dart:1495`;
    golden gerado pelo laço `for (final type in widgetCatalog.keys)` (`:160`), arquivo
    `goldens/node_image.png` (`:172`).

## 9. Perguntas fechadas — **o plano está fechado**

As quatro perguntas foram **respondidas pelo humano em 2026-08-15**. Nenhuma decisão de
produto ou de recorte está pendente: os especialistas podem começar.

| # | Pergunta | Resposta do humano | Onde virou decisão |
| --- | --- | --- | --- |
| Q1 | `fallback` ou proxy no backend? | **O proxy**, com **fase própria e gate CISO obrigatório**; o `fallback` sai de cena | **D2** · D10 · D11 · F2 |
| Q2 | `min: 0` → `min: 1` entra na F1? | **Sim** — sem isso o aceite do `0` é inalcançável | **D6** |
| Q3 | Criar o primeiro arquivo de tokens do `sdui_flutter`? | **Sim** — sem ele os estados novos reprovam no Gate 4 | **D7** |
| Q4 | `opacity` entra no descriptor? | **Não** | **D9** (com razão nova — ver §8.6) |

**Já decidido antes, não reabrir:** 38 e 39 saem **antes** do item 24; a F1 é **defeito** e
sai como `bugfix/*`; a F4 é o **Incremento 4** do item 9, sem número novo no roadmap; a doc
viva é **`docs/16-image-url-e-props/`**.

**Duas notas de execução, não perguntas** (registradas para não virarem surpresa):

1. **Rate limit "por chave" hoje é por IP.** O caminho do editor não tem identidade nenhuma
   (não há auth — item 26 aberto), então não existe chave para bucketizar. A bucketização por
   chave entra com a rota pública (§12) ou com o item 26. A D10 explica por que isso **não**
   enfraquece a segurança: a defesa é a allowlist, não o portão.
2. **O gate CISO pode reprovar a F2.** Se o CISO julgar que um endpoint de proxy sem
   autenticação (R9) é inaceitável no estado atual do backend, o item **para** e volta ao
   humano com a alternativa — adiar a F3 até o item 26, ou aceitar o risco por escrito. O
   plano não presume aprovação.

**O que reabre uma decisão:** só um desvio registrado em `variance_report.md` desta pasta,
com aprovação do humano. Especialista que discordar de uma D **para e avisa o tech-lead** —
não corrige o plano por conta própria.

## 10. Roteiro de E2E manual

_Ponto de partida do QA. **Em homologação** (não localhost — lição do item 9g), editor web no
Chrome. O QA instrumenta o que der em script idempotente; o resto é olho humano._

**Preparar** — três URLs à mão, uma de cada natureza:

| Rótulo | URL | Natureza |
| --- | --- | --- |
| `URL_A` | `https://picsum.photos/300/200` | host **com** `Access-Control-Allow-Origin` |
| `URL_B` | `https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png` | host **sem** ACAO — **o caso do relato** |
| `URL_C` | `https://exemplo.invalido/x.png` | inexistente |

_Se `URL_B` passar a servir ACAO, trocar por outra obtida com "copiar endereço da imagem" em
qualquer site — e **conferir no DevTools › Network que a resposta não traz
`access-control-allow-origin`** antes de usar. Um caso B que na verdade é A invalida o teste
inteiro._

**Roteiro:**

1. Criar conteúdo novo e arrastar `image` da paleta. **Esperado:** estado **vazio**,
   reconhecível como "falta a URL", não como erro.
2. **Ligar o throttling de rede no DevTools** (`Slow 3G`) e colar **`URL_A`**. **Esperado:**
   durante o carregamento, estado **carregando**; depois, a imagem. _Sem throttling o estado
   pode não piscar — é cache hit, não defeito (D12). Se a imagem já foi carregada antes,
   desmarcar o cache do DevTools._
3. Colar **`URL_C`**. **Esperado:** estado **falhou**, com o motivo em texto, **diferente do
   passo 1**. Tooltip diz o motivo e mostra a URL.
4. Colar **`URL_B`**. **Esperado:** **a imagem aparece.** É o passo que fecha o relato — e
   **só vale a partir do PR 3**; no PR 1 o esperado é o estado "falhou" com motivo.
5. Abrir o **DevTools › Network** e conferir que a requisição da imagem sai para
   `…/v1/media/proxy?url=…`, e **não** direto para o host. É a prova da D11 no caminho do
   editor.
6. Apagar a URL. **Esperado:** volta ao estado **vazio** do passo 1, distinto de 2 e 3.
7. **Prova da distinção, com os quatro prints lado a lado:** vazio, carregando, falhou e
   carregado são **quatro imagens diferentes**. Se dois forem iguais, a F1 não está pronta.
8. Digitar `0` em Largura. **Esperado:** a imagem **não some**. Repetir em Altura.
9. Digitar `abc` em Largura. **Esperado:** o editor **sinaliza**; a digitação não some.
10. _(F4)_ Trocar a unidade de Largura para **%** e digitar `100`. **Esperado:** a imagem
    estica à largura do mock.
11. _(F4)_ Mexer em `alignment`, `borderRadius` e `backgroundColor`. **Esperado:** cada um
    aparece no canvas **e** no painel de JSON; o raio **compõe** com a imagem carregada.
12. _(F4)_ Olhar "URL da imagem" e "Largura". **Esperado:** o **`helpText`** aparece nos
    **dois** (prova da D8).
13. **Compatibilidade:** abrir um conteúdo salvo **antes** da F4, com `image` de `width`
    numérico. **Esperado:** reabre e renderiza **igual**.
14. Salvar e **recarregar a página do navegador**. **Esperado:** o conteúdo reabre idêntico.
15. Abrir o mesmo conteúdo no **`driva_demo_app`** (celular ou emulador). **Esperado:** a
    imagem carrega, e no log de rede a requisição vai **direto ao host**, sem passar pelo
    proxy — a prova da D11 no caminho do cliente.

## 11. Definition of Done

**O item 39 só está pronto quando todas as linhas abaixo estiverem marcadas.** Cada linha diz
**como se prova** — nada aqui se atesta por opinião.

### 11.1 Cancela de máquina

| # | Item | Como se prova |
| --- | --- | --- |
| 1 | `flutter analyze` verde no workspace | saída do comando, zero issues, colada no PR |
| 2 | Suíte existente passando em `sdui_core`, `sdui_flutter` e `driva_editor` | `flutter test -r compact`, saída no PR |
| 3 | Suíte do backend passando (`npm test` + `test:e2e`) | saída no PR 2 |
| 4 | Golden `goldens/node_image.png` regravado **com o diff citado na descrição do PR** (R1) | o PR mostra o antes/depois; regravação sem citação **reprova** |
| 5 | Nenhum literal de cor **fora** do arquivo de tokens (D7) | `grep "Color(0x" packages/sdui_flutter/lib \| grep -v "lib/src/theme/"` = **zero**. O arquivo de tokens contém literais por definição — exigir zero no pacote inteiro só se cumpriria enganando o grep |
| 5b | O `loadingBuilder` **não** foi usado (D12) | `grep -rn "loadingBuilder" packages/sdui_flutter/lib` = **zero** |
| 5c | **`showDiagnostics` com default seguro** (D13) | default `false` nos dois construtores; `grep -rn showDiagnostics apps/driva_demo_app` = **zero**; e com o flag desligado a caixa de erro não contém a URL nem `error.toString()` |
| 5d | **O Gate 4 do CI guarda o `sdui_flutter`** (D14) | `bash scripts/gates_guard.sh` verde **e** um `Color(0x…)` plantado fora de `lib/src/theme/` faz o script sair `1` |
| 6 | O diff em `apps/driva_editor/` na F4 é **só** o `helpText` — nenhum `if (type == 'image')` | leitura do diff pelo QA na `revisar-fase` |
| 7 | CI verde em todos os PRs — a mesma régua do humano | checks do GitHub |

### 11.2 Aceite por fase

| # | Item | Como se prova |
| --- | --- | --- |
| 8 | Os **9 critérios da F1** atestados | `revisar-fase` do QA no PR 1 |
| 9 | O aceite da **F2** atestado — matriz §11.4 verde **e** gate CISO aprovado **por escrito** | parecer do CISO anexado ao PR 2 |
| 10 | Os **6 critérios da F3** atestados | `revisar-fase` do QA no PR 3 |
| 11 | Os **6 critérios da F4** atestados | `revisar-fase` do QA no PR 4 |
| 12 | Nenhum desvio das decisões D1–D11 sem `variance_report.md` aprovado pelo humano | a pasta `docs/16-image-url-e-props/` |

### 11.3 E2E — **faz parte do DoD, não é apêndice**

**A feature não está pronta enquanto o roteiro da §10 não tiver sido executado e atestado.**

| # | Item | Como se prova |
| --- | --- | --- |
| 13 | O roteiro da **§10** executado **em homologação** — não em localhost (lição do item 9g) | a URL do ambiente aparece nos prints |
| 14 | **QA instrumenta** o que der em script idempotente e auto-limpante (skill `instrumentar-e2e`); o que exige olho fica para o humano | script em `docs/16-image-url-e-props/evidencias/rodada_MM/` |
| 15 | **O dev humano confere os prints e atesta.** Ninguém mais atesta E2E | atestado escrito no `final_report.md`, com data |
| 16 | Evidência arquivada em **`docs/16-image-url-e-props/evidencias/rodada_MM/`** (`rodada_01`, `rodada_02`…) | a pasta existe e tem os prints |
| 17 | E2E reprovado → o tech-lead conserta e **abre `rodada_MM+1`**; a rodada anterior **não é apagada** | histórico de rodadas |

**A peculiaridade do item 39 — o que faz este E2E valer alguma coisa.** O defeito é o erro
**não ficar visível**. Um E2E que só testa a URL feliz **não prova nada aqui** — é exatamente
o defeito que estamos corrigindo (§2.1: hoje a URL feliz já funciona; é o resto que mente). O
DoD exige a **matriz inteira**, cada caso com print próprio:

| # | Caso obrigatório | Print exigido | Falha o DoD se |
| --- | --- | --- | --- |
| 18 | **URL com ACAO** (`URL_A`) | imagem carregada | não carrega — regressão |
| 19 | **URL sem ACAO** (`URL_B`) — **o caso do relato** | imagem carregada **e** a aba Network mostrando `…/v1/media/proxy?url=…` | não carrega — a D2 não entregou e o relato do dev continua de pé |
| 20 | **URL 404/inexistente** (`URL_C`) | estado "falhou" **com o motivo legível em texto** | mostra quadrado cinza mudo, ou é igual ao print 21 |
| 21 | **Campo vazio** | estado "vazio" | é igual ao 20 ou ao 22 |
| 22 | **Carregando** — **obrigatoriamente com throttling de rede ligado no DevTools** (sem ele o estado não pisca em cache hit, e isso é correto: D12) | estado "carregando" **no editor web**, mais o teste de widget de `frame == null` (F1 aceite 3) | é igual ao 20 ou ao 21 — **ou** se só existir no mobile, que era o bloqueio B1 |
| 23 | **`width` = `0`** (D15) | print do **campo**, mostrando "Ajustado para o mínimo (1)" como `helperText` — e um segundo print com `abc`, mostrando o `errorText`, para provar que os dois sinais **se distinguem** | o valor é engolido sem sinal nenhum, ou os dois casos produzem a mesma mensagem. **Não** falha por a imagem ficar invisível em 1px: isso é esperado (D15) |
| 24 | **Os quatro estados lado a lado** (20, 21, 22 + carregado) | um único print comparativo | **dois quaisquer forem visualmente iguais** — é literalmente o bug original |
| 25 | **Compatibilidade** — conteúdo salvo antes da F4 reabrindo igual | antes/depois | o `width` numérico antigo deixa de renderizar |
| 26 | **`driva_demo_app` no celular** com o mesmo conteúdo, log de rede à vista | imagem carregada **direto do host**, sem proxy | passou pelo proxy — a D11 vazou para o app cliente |

**O item 24 é a cancela desta feature.** Se os quatro estados não forem quatro imagens
distintas, nada mais no DoD importa: o defeito relatado continua no ar.

### 11.4 Matriz de segurança do proxy — **mesma régua: controle sem caso não conta**

Cada linha é um teste `e2e` do Nest **e** um caso do gate CISO. **Nenhuma pode ficar em
aberto.**

| # | Controle (F2) | Caso concreto que o prova | Esperado |
| --- | --- | --- | --- |
| 27 | Allowlist de esquema | `?url=file:///etc/passwd` | `400`, corpo genérico, nenhum acesso a disco |
| 28 | Allowlist de esquema | `?url=gopher://x/`, `?url=data:text/html,<script>` | `400` |
| 29 | Recusa de loopback | `?url=http://127.0.0.1:3000/v1/contents` | `400` — o proxy não fala com o próprio backend |
| 30 | **Metadata de instância** | `?url=http://169.254.169.254/latest/meta-data/` | `400` — **é onde mora credencial de nuvem** |
| 31 | Recusa de privados | `?url=http://10.0.0.1/`, `172.16.0.1`, `192.168.0.1` | `400` |
| 32 | **IPv6 e o bypass IPv4-mapeado** | `?url=http://[::1]/`, `?url=http://[::ffff:169.254.169.254]/` | `400` — o bypass clássico |
| 33 | **Validação é do IP resolvido, não da string** | host público que **resolve** para IP privado (ex.: `127.0.0.1.nip.io`) | `400` |
| 34 | **DNS rebinding / TOCTOU** (R3) | host cujo DNS devolve IP público na 1ª resolução e privado na 2ª | `400` — prova que a validação vale **na conexão**, não antes |
| 35 | Revalidação a cada redirect | alvo que responde `302` para `http://169.254.169.254/` | `400`, e o redirect **não** é seguido |
| 36 | Teto de saltos | cadeia de redirects acima do teto | `400` |
| 37 | Teto de tamanho | resposta maior que o teto | erro, com a conexão abortada **em streaming**, sem bufferizar tudo |
| 38 | Timeout | alvo que segura a conexão aberta | `504` no teto configurado |
| 39 | `Content-Type` de imagem | alvo devolve `Content-Type: text/html` | `400`, corpo **não** repassado |
| 40 | Rate limit | N+1 requisições dentro da janela | `429` |
| 41 | Nada de confused deputy | requisição com `Authorization`, `Cookie`, `x-driva-key` | headers **não** chegam ao alvo (provado por servidor de eco) |
| 42 | Resposta limpa | alvo devolve `Set-Cookie` | não repassado ao navegador |
| 43 | Erro sem oráculo | alvo interno devolve corpo/status distintivos | resposta de erro **não** vaza corpo, status nem tempo do alvo |
| 44 | Caminho feliz **contra o servidor efêmero da suíte** — não contra a internet (**D18**) | imagem servida pelo servidor de teste | `200`, `Content-Type` de imagem, ACAO da origem do editor, ETag presente. **Não confundir com os itens 18/19:** esta linha verde **não** prova que a URL do relato carrega no Chrome |
| 45 | **Parecer do CISO por escrito**, tendo lido `url-guard.ts` **e** o mecanismo de conexão | — | aprovado; se reprovado, o item para e volta ao humano (§9, nota 2) |

### 11.5 Fechamento

| # | Item | Como se prova |
| --- | --- | --- |
| 46 | **Bateria automatizada (F5) escrita DEPOIS do E2E atestado**, nunca antes | o PR 5 é posterior em data ao atestado do item 15 |
| 47 | Gate do CISO em cada fase e os dois gates gerais | registro do agente `ciso` |
| 48 | `CHANGELOG` `Unreleased` atualizado **no mesmo PR** de cada mudança | o diff do PR contém o CHANGELOG |
| 49 | Variáveis novas do proxy (teto, timeout, rate limit) documentadas em `docs/deploy/coolify.md` e configuradas no painel — **nunca no repo** | a doc e o painel |
| 50 | Docs vivas desta pasta: `final_report.md` ao fechar; **`variance_report.md` já aberto com o `VR-16-01`** — desvios novos entram como `VR-16-NN` | os arquivos existem, e todo desvio tem "como estava / por que mudou / o que mudou" |
| 51 | `docs/roadmap.md` — item **39** vira `[x]` e o **"Incremento 4"** do item 9 vira `[x]` | as duas linhas marcadas |
| 52 | `docs/plans/README.md` atualizado; o plano de gaveta aponta para esta pasta | o índice |

## 12. Fora de escopo — evoluções registradas

- **Rota pública do proxy** (`/v1/public/media/proxy`) para apps cliente que rodem em Flutter
  Web. Hoje o `driva_demo_app` é móvel e não precisa (D11). **Quem construir isso leia a
  D10 antes:** a `publishableKey` é pública, então a rota nasce sem fronteira de identidade —
  e a conta de banda (R6) muda de ordem de grandeza.
- **⭐ O `backend/` ganha bateria de testes de verdade — merece item próprio no roadmap.**
  Até a F2 deste item, o backend **não tinha infraestrutura de teste nenhuma**. Ela nasceu
  aqui de carona, e isso se vê: o `jest-e2e.json` é one-off (não há config de teste
  unitário) e a suíte redeclarava o bootstrap em vez de reusar o `main.ts` — os dois pontos
  corrigidos ainda nesta fase, mas o buraco de fundo continua. **O que falta:** config de
  unitário, cobertura dos módulos que já existem (`contents`, `projects`, `categories`,
  `public`, `storage`), e o backend entrando na mesma cancela de CI que o Flutter.
  **Enquanto não for item, isso vai continuar nascendo de carona na próxima feature que
  precisar** — que é exatamente como chegou aqui.
- **Rate limit por chave** — hoje o balde é por IP (VR-16-01 fez o por-IP funcionar de fato).
  Bucketização por chave depende de identidade no caminho do editor: item 26 (auth) ou a rota
  pública. Ver D10 e R9.
- **Gate 1 automático no `sdui_flutter`** — hoje o pacote segue isento (D14). Estreitar exige
  isentar `lib/src/builders/*.dart` (as 24 funções `buildX` do registry) **e** escapar
  `render`/`renderAll`/`renderFlexChildren` em `renderer.dart`, que são a API do renderer.
  Medido: **28 ocorrências, todas legítimas** — é refino de script, sem urgência.
- **`0` (e campo vazio) como "automático"** nas props numéricas de dimensão — devolver a
  imagem ao tamanho intrínseco em vez de clampar para o mínimo (D15). É a pergunta de produto
  que sobra do T2, e muda a semântica de prop numérica em **todo** o catálogo.
- **`opacity` para o catálogo inteiro** — prop genérica ou primitivo próprio, não campo
  avulso no `image` (D9).
- **`SduiAuthoringScope`** — separar o chrome de autoria (placeholders) do que o app do
  cliente desenha (D4). Hoje um `image` sem `src` publicado desenha um quadrado cinza **em
  produção**.
- **Ressincronizar o campo numérico na perda de foco** — fecha a dessincronização do R8 nos
  **dois** editores. UX transversal do inspector, não carona de bugfix.
- **`isRequired` que valida de verdade** — hoje é só um asterisco (`prop_field_shell.dart:56`).
  Candidato natural: regra nova em `diagnoseTree`.
- **Cache de imagem no proxy com storage** (`backend/src/storage/`, item 27) — hoje só cache
  HTTP/ETag. Vale se a banda incomodar.
- **Upload de imagem pelo editor** — item 27 (storage).
- **`Image.memory`/base64, `svg`, blurhash, `avatar`, `aspectRatio`** — fila do item 9.
