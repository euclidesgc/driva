# variance_report.md — Item 39 (`docs/16-image-url-e-props/`)

Registro dos desvios em relação ao `plan.md` desta pasta, no formato **como estava / por que
mudou / o que mudou**. Regra do CLAUDE.md: desvio do plano só entra com aprovação do humano e
registro aqui.

Numeração: `VR-16-NN`, na ordem em que os desvios acontecem.

| # | Fase | Desvio | Origem | Estado |
| --- | --- | --- | --- | --- |
| VR-16-01 | F2 | `app.set('trust proxy', 1)` em `backend/src/main.ts` | Gate CISO | **Aplicado** |
| VR-16-02 | F3 | O ponto de injeção do resolver: **8** arquivos do editor, não 1 | Regra do CLAUDE.md cobrada por 5 testes | **Aplicado** |

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
