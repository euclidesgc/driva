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

## 3. Prints do visual — o QA gera; o humano confere

Regra nova: **o QA gera TODOS os prints, o dev humano só confere** — nunca opera o browser. Um harness ao lado do `e2e.sh` (ex.: `docs/NN-<nome>/e2e_shots.sh`) faz: build web (dev) → semeia via API o projeto que o app lê → serve o `build/web` **com SPA fallback** (deep links do path strategy) → captura, em `evidencias/rodada_MM/`, **dois tipos** de estado:
> - **por URL** (lista vazia/cheia, cards, editor carregado, NotFound): `google-chrome --headless=new … --screenshot` em cada rota.
> - **de interação dentro do canvas** (digitar → derivação ao vivo, colisão, drag-drop, salvar): dirigidos por **CDP puro** (`e2e_drive.mjs` — WebSocket/fetch nativos do Node, **sem dependências**; nada de chromedriver/puppeteer/`flutter_driver`), lançando um Chrome com `--remote-debugging-port` e mandando `Input.dispatchMouseEvent`/`insertText`/`captureScreenshot`.

O canvas do Flutter não tem DOM por widget, então o driver clica/arrasta por **coordenadas** num tamanho de janela fixo (ex.: 1366×900) — **acopladas ao layout**; se a UI se mover, ajuste as coordenadas no `e2e_drive.mjs`. Ao humano sobra **só conferir as imagens**. Divergência comportamento×spec que a captura revelar (ex.: um fluxo que age diferente do previsto) vira **achado** no `test_plan.md` para o dev decidir.

> **Gotcha Flutter Web — ícones "tofu" (□):** **não é bug de código nem de build.** O `build/web` emite `MaterialIcons-Regular.otf` + FontManifest corretos e os ícones renderizam (o próprio `e2e_shots.sh` prova por headless). Tofu aparece só no `flutter run` (debug) por **estado sujo do browser** — e **não** cede a `flutter clean` nem a hard-refresh. Fix: **incognito** (`flutter run -d chrome --web-browser-flag=--incognito …`) — sem cache/SW, novo a cada vez, nada a limpar; se persistir, é render de OTF no CanvasKit debug → rode o visual em **`--profile`** (caminho do release). **Nunca** use `--user-data-dir=<pasta fixa>`: persiste e reacumula o cache. Para conferência, os prints do harness dispensam o browser do dev.

## 4. Rodadas e evidências

O E2E roda **em rodadas**. Cada rodada tem sua pasta de evidências:

```
docs/NN-<nome>/evidencias/rodada_01/   ← 1ª rodada
docs/NN-<nome>/evidencias/rodada_02/   ← 2ª rodada (após correções), etc.
```

Em cada `rodada_MM/` ficam: o **snapshot do script** (`e2e.sh`/`e2e_shots.sh`), os **prints** (gerados pelo QA via harness headless) e um **`README.md`** que o `e2e_shots.sh` emite automaticamente — cada imagem com a descrição do que testa (é assim que o dev confere: abre o README e olha). O ciclo:

1. O dev roda `e2e.sh` + `e2e_shots.sh` (os prints por URL saem prontos) e **confere** as imagens; só os poucos estados de interação ele fotografa à mão. Tudo salvo na `rodada_MM/`.
2. Se **tudo passou** → a feature segue para o wrap (limpeza + testes automatizados + DoD). Fim das rodadas.
3. Se **achou problema/pediu mudança** → o time **analisa os logs, os prints e o código**, corrige o que for código e **ajusta o script** se preciso. Só então **avisa o dev** que a `rodada_MM+1` está pronta — e o dev roda de novo, salvando na próxima pasta.

## Regras de ouro

- **Máquina valida contrato; humano valida percepção.** Se um passo manual pode virar asserção de script, ele deve virar.
- **Uma rodada = uma pasta.** Nunca sobrescreva a evidência de uma rodada anterior — o histórico das rodadas é o rastro do que quebrou e do que foi corrigido.
- Quando o E2E falhar: o time lê logs/prints/código, conserta e ajusta o script; o dev só re-executa na rodada seguinte.
- Todo o rastro (script e, se houver, instrumentação `[e2e]`) fica listado no `test_plan.md` — é o mapa da limpeza no wrap.
