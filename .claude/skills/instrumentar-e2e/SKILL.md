---
name: instrumentar-e2e
description: Prepara o E2E de uma feature do driva automatizando o máximo num script idempotente e auto-limpante, deixando ao dev humano só o que exige olho (visual/UX). Usada pelo QA após o gate do CISO. Nada aqui vai para produção.
---

# Skill: instrumentar o E2E

Objetivo: validar de ponta a ponta o que fizemos, **minimizando o passo manual** — quanto mais clique manual, mais chance de o dev testar errado e mascarar bug. A regra é: **automatize tudo que a máquina consegue verificar; deixe ao humano só o que exige olho** (o visual/UX que uma asserção não enxerga). Esta fase não gera PR — tudo aqui é temporário.

## 1. Script de E2E — `docs/NN-<nome>/e2e.sh` (o coração)

Um script `sh` que sobe a stack local e valida o **máximo por API/CLI**, com `PASS/FAIL` explícito. Requisitos inegociáveis:

- **Determinístico e idempotente.** Pode rodar N vezes seguidas sem limpeza manual. Prefira uma **base de teste efêmera** (ex.: `docker compose down -v` + `up` → schema nasce do zero) a mutar dados vivos. **Nunca** rode ação destrutiva de Prisma (`migrate reset`, `db push --force-reset`/`--accept-data-loss`) dentro do script — o agente é bloqueado por uma trava de IA, e destruir dados não é papel do script; use a base efêmera.
- **Cobre o contrato inteiro** que a feature toca: cada verbo/rota, os campos de resposta, os invariantes (formato de id, envelope, unicidade), os erros do PRD (ex.: `409`, `400`) e os casos de borda. Uma asserção por invariante.
- **Auto-limpante e rastreável.** Todo rastro (processos, containers/volumes, arquivos temporários) é listado e removido por um subcomando `down`. Escreva o rastro no cabeçalho do script e no `test_plan.md`.
- **Zero mudança de código-fonte** quando a stack real está pronta. Rode o script você mesmo e só entregue quando estiver **verde**.

## 2. Instrumentação de código — só se inevitável

Se a stack real **não** está pronta (ex.: backend ausente), aí sim instrumente o app: fakes no DI do flavor dev (honrando o contrato de verdade — erros e bordas, não só a interface) e `log()` (`dart:developer`) nos pontos que contam a história. **Prefixo `[e2e]` em tudo** e a lista completa (arquivos + trechos) no `test_plan.md` — é o mapa da limpeza no wrap. Prefira sempre o script à instrumentação de código.

## 3. Roteiro manual — só o visual/UX

No `docs/NN-<nome>/test_plan.md`, além de documentar o script, escreva o **checklist curto** do que só o humano confirma na tela (o que a API não vê): navegação/URL, derivação ao vivo em campo, render de preview, estados visuais, mensagens. Cada item: o que fazer, o que observar, onde salvar o print (`docs/NN-<nome>/evidencias/`). Nada de "teste a feature" — checklist de voo.

## Regras de ouro

- **Máquina valida contrato; humano valida percepção.** Se um passo manual pode virar asserção de script, ele deve virar.
- Quando o E2E falhar: quem lê logs/prints e conserta é o **tech-lead**; você atualiza o roteiro se o fluxo mudou.
- Todo o rastro (script e, se houver, instrumentação `[e2e]`) fica listado no `test_plan.md` — é o mapa da limpeza no wrap.
