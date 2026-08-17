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

## VR-46-03 — O `e2e_shots.sh` do item 02 ganhou cerca estrutural, não só a troca de URL

**A D11 travava:** uma linha de montagem de URL em cada arquivo de E2E. Sete dos oito
cumpriram.

**O que foi feito:** `docs/02-conteudos/e2e_shots.sh` saiu **+94/−22**. Entrou um
`shot_route <nome> <path>` que abre a URL num Chrome com CDP e **só fotografa se o
roteamento do app tiver parado no path pedido**; o `04_notfound` passou a exigir que a API
confirme **404** antes do print; o `03_editor_carregado` ganhou a mesma cerca; e PNG vazio,
driver falhando ou `node` ausente passaram a contar como falha, com `exit 1`, onde antes
saía `✗` cosmético ou nota cinza.

**Por quê:** o `shot()` só verificava `[ -s "$OUT/$1.png" ]` — qualquer tela que
renderizasse produzia `✓`. Com a rota antiga removida, `/contents/nao-existe/edit` cai na
home e o script **continuaria "passando"**, fotografando a home com legenda de tela de erro.
É o próprio defeito que este item corrige, reproduzido na ferramenta que deveria prová-lo.
A troca de URL sozinha consertaria este caso; a cerca conserta a classe.

**O que custa:** é ferramenta viva de **outro item**, e o contrato dela mudou — quem rodar
sem Chrome/CDP ou sem `node` agora recebe `exit 1` onde antes levava evidência parcial.

**Aprovado pelo dev humano** em 2026-08-17, sobre o achado do gate de QA, que recomendou
registrar em vez de reverter.

---

## Correções do plano ao discovery (não são desvios de escopo)

Registradas aqui porque mudam instruções que o `prd.md` deu por certas.

| # | O discovery afirmava | O código mostrou | Consequência de seguir o discovery |
| --- | --- | --- | --- |
| 1 | Cinco scripts de E2E vivos citam a rota antiga | **oito arquivos** (`plan.md` D11) | Três `.sh` ficariam para trás — entre eles o `docs/02-conteudos/e2e_shots.sh:111`, que passaria a fotografar a home com legenda de tela de erro, **sem falhar** |
| 2 | Os `goto(projectUrl())` das linhas 339 / 378 / 508 do `docs/24-.../e2e_drive.mjs` ficam obsoletos (PRD › R2) | **nenhuma sai** (`plan.md` D11b, revista em 2026-08-17 pela conferência da frente B) | As três abrem os `step('1')`, `step('5')` e `step('15')`. `cardBadge()` (`:230`) lê a árvore semântica da tela aberta, não a API — sem o `goto`, o passo leria `about:blank` ou o editor: FAIL e print da tela errada. O carimbo do `ProjectScope` que elas faziam de quebra é que fica desnecessário depois da F1 — a navegação, não. A primeira redação da D11b salvava só a 508; a conferência corrigiu |
| 3 | A mudança de rota derruba os quatro testes do `VR-16-02` | não derruba (`plan.md` D3) | O que os derrubaria é promover `projectId` a parâmetro obrigatório de `EditorPage`; a cerca é sobre a assinatura, não sobre a rota |
