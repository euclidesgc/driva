# Variance report — item 26 (autenticação e multi-tenant real)

Desvios em relação ao PRD aprovado (`docs/26-auth-multi-tenant/prd.md`) e ao `plan.md`,
com a decisão do dev humano que os autorizou.

---

## VR-26-01 — A capa de projeto exige código novo no editor: o cookie NÃO viaja no caminho de imagem do CanvasKit

**O PRD dizia:** caminho feliz nº 5 — "As capas de projeto continuam aparecendo — o
cookie viaja no `<img>` same-site, sem código novo."

**O que é de fato:** falso no engine. Evidência
(`~/.puro/envs/3.38.6/flutter/packages/flutter/lib/src/painting/_network_image_web.dart:184-198`,
Flutter 3.38.6): no CanvasKit, `Image.network` busca os bytes por `XMLHttpRequest`
**sem `withCredentials`** — o cookie não é anexado em requisição cross-origin, mesmo
sendo same-site elegível. O caminho que de fato usa `<img>` (`loadViaImgElement`) só
roda sob `WebHtmlElementStrategy.prefer/fallback`, rejeitada por este repositório no
item 39 porque platform view quebra golden/screenshot.

**O que muda (correção de forma, não de exigência):** a exigência do PRD fica intacta —
as capas continuam funcionando sob o guard e `@Public()` na rota de mídia continua
proibido (`:id` enumerável). A **mecânica** passa a ser o `SessionImageProvider` da
T4.5 do `plan.md`: um `ImageProvider` que busca os bytes pelo `Dio` compartilhado (que
tem `withCredentials`) e decodifica, substituindo `Image.network` nos dois call sites da
capa.

**Decisão do dev (2026-08-27):** registrar esta variance agora e **corrigir a linha do
PRD quando a T4.5 entregar — não antes**: a mecânica final é a que a implementação
provar. Consequência para quem fecha a fase: **o fechamento da F4 inclui a correção da
linha do PRD** (caminho feliz nº 5 e a linha correspondente da tabela de exceções),
citando esta entrada. A F4 não fecha com o PRD ainda afirmando "sem código novo".

**Aprovado pelo dev humano** em 2026-08-27, sobre achado do tech-lead na revisão do
plano (D26.4).
