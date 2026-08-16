# variance_report.md — Item 39 (`docs/16-image-url-e-props/`)

Registro dos desvios em relação ao `plan.md` desta pasta, no formato **como estava / por que
mudou / o que mudou**. Regra do CLAUDE.md: desvio do plano só entra com aprovação do humano e
registro aqui.

Numeração: `VR-16-NN`, na ordem em que os desvios acontecem.

| # | Fase | Desvio | Origem | Estado |
| --- | --- | --- | --- | --- |
| VR-16-01 | F2 | `app.set('trust proxy', 1)` em `backend/src/main.ts` | Gate CISO | **Aplicado** |

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
