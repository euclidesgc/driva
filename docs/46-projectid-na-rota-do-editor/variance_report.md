# Variance report — item 46 (projectId na rota do editor)

Desvios em relação ao recorte aprovado no `prd.md`, com a decisão do dev humano que os
autorizou. Detalhe técnico de cada um: `plan.md` §9.

---

## VR-46-01 — A tela de falha entra no mesmo PR da rota

**O PRD dizia:** F1 (rota) e F2 (tela de falha) como fases separadas.

**O que foi feito:** uma fase, um PR.

**Por quê:** a A4 travou correção pontual em 1 PR, e a tela de falha é o que torna o E2E
provável — sem ela o primeiro PR não tem os dois modos de falha visualmente distintos que
o DoD exige.

**Aprovado pelo dev humano** em 2026-08-17, na apresentação do plano.

---

## VR-46-02 — A tela de falha tem três saídas, não duas

**O PRD dizia:** duas saídas — projeto existe (conteúdo não está nele) × projeto não existe.

**O que foi feito:** três saídas, incluindo o caso de **falha de rede** ao buscar o projeto.

**Por quê:** com o `projectFuture` falhando por rede, o app **não sabe** se o projeto existe.
Afirmar que não existe seria repetir, em escala menor, o defeito que este item corrige — uma
tela que mente sobre a causa.

**Aprovado pelo dev humano** em 2026-08-17, na apresentação do plano.

---

## Correções do plano ao discovery (não são desvios de escopo)

Registradas aqui porque mudam instruções que o `prd.md` deu por certas.

| # | O discovery afirmava | O código mostrou | Consequência de seguir o discovery |
| --- | --- | --- | --- |
| 1 | Cinco scripts de E2E vivos citam a rota antiga | **oito arquivos** (`plan.md` D11) | Três `.sh` ficariam para trás — entre eles o `docs/02-conteudos/e2e_shots.sh:111`, que passaria a fotografar a home com legenda de tela de erro, **sem falhar** |
| 2 | Os `goto(projectUrl())` das linhas 339 / 378 / 508 do `docs/24-.../e2e_drive.mjs` ficam obsoletos (PRD › R2) | **nenhuma sai** (`plan.md` D11b, revista em 2026-08-17 pela conferência da frente B) | As três abrem os `step('1')`, `step('5')` e `step('15')`. `cardBadge()` (`:230`) lê a árvore semântica da tela aberta, não a API — sem o `goto`, o passo leria `about:blank` ou o editor: FAIL e print da tela errada. O carimbo do `ProjectScope` que elas faziam de quebra é que fica desnecessário depois da F1 — a navegação, não. A primeira redação da D11b salvava só a 508; a conferência corrigiu |
| 3 | A mudança de rota derruba os quatro testes do `VR-16-02` | não derruba (`plan.md` D3) | O que os derrubaria é promover `projectId` a parâmetro obrigatório de `EditorPage`; a cerca é sobre a assinatura, não sobre a rota |
