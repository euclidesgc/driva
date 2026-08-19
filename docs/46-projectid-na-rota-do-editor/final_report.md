# Final report — item 46: o `projectId` entra na rota do editor

> **Fases F1 e F2 fechadas.** A F3 (bateria automatizada + varredura de docs) segue como
> trabalho próprio, destravada por este atestado. Docs irmãs: [`specs.md`](specs.md) ·
> [`prd.md`](prd.md) · [`plan.md`](plan.md).

---

## Atestado do dev humano

**Em 2026-08-18, o dev humano conferiu os prints da `evidencias/rodada_02/` e executou o passo
4b em aparelho Android físico. A rodada está atestada.**

O passo 4b abriu, no aparelho, a URL que o próprio app gerou —
`https://hml.driva.duckdns.org/preview/qyk9xbclx0moxwno3wplb4u9/p5ha2j9x7dgjkaqla0gy2wyt` — e
mostrou o conteúdo **"Canvas do conteúdo A (item 46)"**, sem barra de endereços (modo
standalone entregue pela F2c do item 41). Não foi 404, e não foi o projeto `default`.

Isso satisfaz o **§11.3›26** do `plan.md`: ninguém além do dev humano atesta E2E.

---

## O que o bug fazia, e o que a rodada provou

O defeito tinha dois rostos. O barulhento: recarregar o editor num projeto que não fosse o
`default` mostrava **"Conteúdo não encontrado."** — mensagem falsa, porque o conteúdo existia.
O silencioso, e pior: o link do diálogo "ver no celular", gerado depois de um reload, saía
como `/preview/default/<id>` **sem erro nenhum na tela**. O usuário copiava um link quebrado e
o erro aparecia do outro lado.

A `rodada_02` correu **contra homologação servida pelo Coolify**, com backend real e num
projeto que não é o `default` (`Portal da RE`), e fechou em **35 PASS / 0 FAIL / 0 bloqueado**.

| O que a feature promete | Como ficou provado |
| --- | --- |
| F5 recarrega o mesmo conteúdo, em projeto ≠ `default` (§11.4›29) | `02` — breadcrumb continua "Portal da RE" depois do reload |
| Link colado numa aba que nunca viu o app abre o conteúdo certo (§11.4›30) | `03` + `03b` — e o `x-project-id` correto já na **primeira** requisição, com HTTP 200 |
| **O link "ver no celular" aponta para o projeto certo** (§11.4›31) | `04` (a URL, lida da árvore semântica do diálogo) + `04b` (ela abre no aparelho) |
| Breadcrumb e "Voltar para o projeto" levam ao projeto certo (§11.4›32) | `05` |
| Conteúdo inexistente **naquele** projeto nomeia o projeto (§11.4›33) | `06` |
| Projeto inexistente dá mensagem **diferente** (§11.4›34, ›35) | `07` — lupa riscada × pasta riscada, frases e ações distintas, mesma cor: a distinção não depende de matiz |
| Link antigo cai na home, sem aviso dedicado (§11.4›37) | `08` |
| Alternar entre conteúdos de dois projetos funciona nos dois sentidos (§11.4›38) | `09a`, `09b`, `09c` |

---

## O passo que estava bloqueado, e por quê

Na `rodada_01` o passo 4 ficou **não verificado**: o diálogo "ver no celular" abria mas não
pintava, e a árvore semântica não entregava o link. A hipótese registrada era defeito do
diálogo.

**Era artefato do ambiente, não defeito.** A rodada 01 dirigia um build de **debug em
`localhost`**; a 02 dirige o **artefato de release publicado pelo Coolify**, e ali a subárvore
do diálogo é exposta por inteiro. Isso corrige uma hipótese que estava no roadmap: o que o
**item 45** descreve como "a árvore colapsa sob a barreira modal" é o `BlockSemantics`
funcionando — some o que está *atrás* da barreira, não o conteúdo dela.

O achado do item 45 que **continua de pé** é outro, e foi reconfirmado aqui: o topo do shell e
a barra de breadcrumb não expõem semântica nenhuma.

---

## Instrumentação

`e2e_shots.sh` + `e2e_drive.mjs` (CDP puro, sem dependência de npm) vivem nesta pasta e estão
copiados dentro da rodada, conforme o **§11.3›25**. São idempotentes: resolvem as fixtures em
vez de recriá-las, e sem argumento abrem a próxima rodada em vez de sobrescrever a anterior.

As fixtures ficaram **de pé** em homologação de propósito — apagá-las inviabilizaria repetir o
passo 4b. `PROJ_A` = `Portal da RE`, `CT_A` = `E2E 46 — conteúdo A`, `PROJ_B` = `E2E item 46 —
projeto B`, `CT_B` = `E2E 46 — conteúdo B`.

`evidencias/rodada_01/` permanece **intocada** (D11): foi pré-checagem local contra a API de
homologação, e vale como registro histórico do que ainda não fechava.

---

## O que fica para a F3

A bateria automatizada (os cinco testes da §5›F3 do `plan.md`) e a varredura das docs que
citavam a rota antiga (§11.5›40). **Nenhum teste foi escrito antes deste atestado** — é a
regra do cap. 22, e é o motivo de a F3 existir como fase separada.

Também segue registrado como débito, apontando para o item 26: o singleton `ProjectScope`
continua vivo (A4›A), e o `DEFAULT_PROJECT_ID` continua compilado nos quatro flavors.
