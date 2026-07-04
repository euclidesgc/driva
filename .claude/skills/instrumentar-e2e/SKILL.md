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

No `docs/NN-<nome>/test_plan.md`, além de documentar o script, escreva o **checklist curto** do que só o humano confirma na tela (o que a API não vê): navegação/URL, derivação ao vivo em campo, render de preview, estados visuais, mensagens. Cada item: o que fazer, o que observar, qual print salvar. Nada de "teste a feature" — checklist de voo.

> **Gotcha Flutter Web — ícones "tofu" (□):** quase sempre é **cache/service worker do Chrome no `localhost`**, não bug de código nem de build. O `build/web` emite `MaterialIcons-Regular.otf` + FontManifest corretos (confirme por screenshot headless do build servido antes de suspeitar do código). O SW **sobrevive** a `flutter clean` e a hard-refresh (Ctrl+Shift+R) — não confie neles. A correção **determinística** é lançar com um **perfil de Chrome descartável**: `flutter run -d chrome --web-browser-flag=--user-data-dir=/tmp/<feature>-e2e-chrome …`. O checklist visual deve trazer essa flag, não o hard-refresh.

## 4. Rodadas e evidências

O E2E roda **em rodadas**. Cada rodada tem sua pasta de evidências:

```
docs/NN-<nome>/evidencias/rodada_01/   ← 1ª rodada
docs/NN-<nome>/evidencias/rodada_02/   ← 2ª rodada (após correções), etc.
```

Em cada `rodada_MM/` ficam: o **snapshot do script** usado (`e2e.sh`), os **logs** gerados e os **prints** do dev (`evidencia_01.png`, `02`, …). O ciclo:

1. O dev roda o script + o visual e salva tudo na `rodada_MM/`.
2. Se **tudo passou** → a feature segue para o wrap (limpeza + testes automatizados + DoD). Fim das rodadas.
3. Se **achou problema/pediu mudança** → o time **analisa os logs, os prints e o código**, corrige o que for código e **ajusta o script** se preciso. Só então **avisa o dev** que a `rodada_MM+1` está pronta — e o dev roda de novo, salvando na próxima pasta.

## Regras de ouro

- **Máquina valida contrato; humano valida percepção.** Se um passo manual pode virar asserção de script, ele deve virar.
- **Uma rodada = uma pasta.** Nunca sobrescreva a evidência de uma rodada anterior — o histórico das rodadas é o rastro do que quebrou e do que foi corrigido.
- Quando o E2E falhar: o time lê logs/prints/código, conserta e ajusta o script; o dev só re-executa na rodada seguinte.
- Todo o rastro (script e, se houver, instrumentação `[e2e]`) fica listado no `test_plan.md` — é o mapa da limpeza no wrap.
