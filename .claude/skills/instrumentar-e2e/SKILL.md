---
name: instrumentar-e2e
description: Instrumenta o E2E por script (contrato por API + prints headless por CDP) quando o plano registrou que ele é necessário. NÃO é o default — o padrão hoje é roteiro manual curto; use esta skill só quando o plano justificar o script. Nada aqui vai para produção.
---

# Skill: instrumentar o E2E

> ⚠️ **Skill parada: **E2E suspenso desde 2026-08-20** (`CLAUDE.md` › _Método de trabalho_).** Enquanto ela valer, nenhuma fase escreve E2E — nem script, nem roteiro manual —, e esta skill não deve ser invocada. O conteúdo abaixo fica registrado para quando a suspensão cair.

> **Antes de usar esta skill, confirme que o plano admitiu o script.** _(decisão do dono, 2026-08-20 — `CLAUDE.md` › _Método de trabalho_.)_ O default do repositório passou a ser o **roteiro manual curto** em `docs/NN-<nome>/e2e_roteiro.md`: passos numerados que o dev humano executa em homologação, com print só do que a automação não prova. O par de scripts descrito abaixo continua válido e tem modelos no repo, mas é **escolha justificada no plano**, não a rota automática — e nunca substitui a cobertura de unit/widget da mesma tela, que fecha a própria fase. Se você chegou aqui sem essa justificativa escrita, volte ao tech-manager.

Objetivo: validar de ponta a ponta o que fizemos **em homologação** (nunca em `localhost` — lição do item 9g), **minimizando o passo manual** — quanto mais clique manual, mais chance de o dev testar errado e mascarar bug. A regra é: **automatize tudo que a máquina consegue verificar; deixe ao humano só o que exige olho** (o visual/UX que uma asserção não enxerga). Esta fase não gera PR — tudo aqui é temporário.

## 1. Script de E2E — `docs/NN-<nome>/e2e_hml.sh` (o coração)

Um script `bash` (curl + jq) que valida o **máximo por API**, com `PASS/FAIL` explícito, **contra a homologação**. Isso não é preferência: rodar o E2E em `localhost` é o erro do item 9g, e virou regra permanente do projeto (CLAUDE.md › Método de trabalho e a tabela de vigilâncias do `docs/roadmap.md`). Default `BASE_URL=https://api-hml.driva.duckdns.org/v1`, `PROJECT=default`; a variável de ambiente existe para um smoke local **antes** da rodada, nunca no lugar dela. Modelos prontos para copiar: `docs/24-publicacao-versionamento/e2e_hml.sh` e `docs/16-image-url-e-props/e2e_hml.sh`.

Requisitos inegociáveis:

- **Determinístico e idempotente.** Roda N vezes seguidas sem limpeza manual. Em ambiente compartilhado não existe "base efêmera": o script **cria o próprio rastro com nome reconhecível** (um conteúdo de slug `e2e-NN-<assunto>`, um projeto descartável quando o caso pede cross-tenant) e o **purga por API no começo E no fim**.
- **Nunca destrua o que não criou.** Nada de `docker compose down -v`, nada de ação destrutiva de Prisma (`migrate reset`, `db push --force-reset`/`--accept-data-loss`) — o agente é bloqueado por uma trava de IA, e apagar dado de ambiente compartilhado não é papel de script de teste. A seed `default` não é tocada além do conteúdo de teste que o próprio script cria e apaga.
- **Cobre o contrato inteiro** que a feature toca: cada verbo/rota, os campos de resposta, os invariantes (formato de id, envelope, unicidade), os erros do PRD (ex.: `409`, `400`) e os casos de borda. Uma asserção por invariante.
- **Auto-limpante e rastreável.** Todo rastro (o que foi semeado, arquivos temporários, o Chrome headless do harness de prints) é listado **no cabeçalho do script** e no `test_plan.md`, e removido pelo próprio script.
- **Zero mudança de código-fonte e zero build.** O que se exercita é o artefato que o Coolify já publicou. Rode o script você mesmo e só entregue quando estiver **verde**.

## 2. Instrumentação de código — só se inevitável

Se a stack real **não** está pronta (ex.: backend ausente), aí sim instrumente o app: fakes no DI do flavor dev (honrando o contrato de verdade — erros e bordas, não só a interface) e `log()` (`dart:developer`) nos pontos que contam a história. **Prefixo `[e2e]` em tudo** e a lista completa (arquivos + trechos) no `test_plan.md` — é o mapa da limpeza no wrap. Prefira sempre o script à instrumentação de código.

## 3. Prints do visual — o QA gera; o humano confere

Regra nova: **o QA gera TODOS os prints, o dev humano só confere** — nunca opera o browser. Um harness ao lado do `e2e_hml.sh` (`docs/NN-<nome>/e2e_shots.sh`) aponta um Chrome headless para o **front de homologação já publicado** (`WEB_BASE=https://hml.driva.duckdns.org`, o mesmo artefato que o Coolify serve) — sem `flutter build web`, sem servir `build/web` local —, semeia por API o que a tela precisa mostrar e captura, em `evidencias/rodada_MM/`, **dois tipos** de estado:
> - **por URL** (lista vazia/cheia, cards, editor carregado, NotFound): `google-chrome --headless=new … --screenshot` em cada rota.
> - **de interação dentro do canvas** (digitar → derivação ao vivo, colisão, drag-drop, salvar): dirigidos por **CDP puro** (`e2e_drive.mjs` — WebSocket/fetch nativos do Node, **sem dependências**; nada de chromedriver/puppeteer/`flutter_driver`), lançando um Chrome com `--remote-debugging-port` e mandando `Input.dispatchMouseEvent`/`insertText`/`captureScreenshot`.

O Chrome sobe com um `--user-data-dir` **temporário** (nunca um fixo — perfil fixo é a origem de meio diagnóstico errado de render) e com o pid num pidfile, para o script conseguir derrubá-lo. O canvas do Flutter não tem DOM por widget, então o driver clica/arrasta por **coordenadas** num tamanho de janela fixo (ex.: 1366×900) — **acopladas ao layout**; se a UI se mover, ajuste as coordenadas no `e2e_drive.mjs`. Ao humano sobra **só conferir as imagens**. Divergência comportamento×spec que a captura revelar (ex.: um fluxo que age diferente do previsto) vira **achado** no `test_plan.md` para o dev decidir.

> **Gotcha Flutter Web — ícones "tofu" (□):** causa raiz **conhecida e resolvível em código**. No Chrome com GPU o Flutter auto-seleciona a variante **`chromium`** do CanvasKit, que em alguns drivers **falha ao registrar fontes de ícone OTF** (`MaterialIcons` é OTF; texto TTF passa) → console loga *"Could not find a set of Noto fonts…"*. **Não é cache/SW** (não caia nessa — incognito/clean/hard-refresh não resolvem). Fix definitivo: um `web/flutter_bootstrap.js` custom que força `canvasKitVariant: "full"` (variante portável) — pega em `flutter run` e no build. Ao diagnosticar tofu, peça o **console (DevTools)** do dev, não só o print do browser: a linha do Noto é o que confirma. Reproduza o modo do dev (headless via CDP contra o build) e cheque a variante no `flutter.js`.

## 4. Rodadas e evidências

O E2E roda **em rodadas**. Cada rodada tem sua pasta de evidências:

```
docs/NN-<nome>/evidencias/rodada_01/   ← 1ª rodada
docs/NN-<nome>/evidencias/rodada_02/   ← 2ª rodada (após correções), etc.
```

Em cada `rodada_MM/` ficam: o **snapshot dos scripts** (`e2e_hml.sh`, `e2e_shots.sh`, `e2e_drive.mjs`), os **prints** (gerados pelo QA via harness headless) e um **`README.md`** que o `e2e_shots.sh` emite automaticamente — cada imagem com a descrição do que testa (é assim que o dev confere: abre o README e olha). O ciclo:

1. O dev roda `e2e_hml.sh` + `e2e_shots.sh` (os prints por URL saem prontos) e **confere** as imagens; só os poucos estados de interação ele fotografa à mão. Tudo salvo na `rodada_MM/`.
2. Se **tudo passou** → a feature segue para o wrap (limpeza + testes automatizados + DoD). Fim das rodadas.
3. Se **achou problema/pediu mudança** → o time **analisa os logs, os prints e o código**, corrige o que for código e **ajusta o script** se preciso. Só então **avisa o dev** que a `rodada_MM+1` está pronta — e o dev roda de novo, salvando na próxima pasta.

## Regras de ouro

- **Máquina valida contrato; humano valida percepção.** Se um passo manual pode virar asserção de script, ele deve virar.
- **Uma rodada = uma pasta.** Nunca sobrescreva a evidência de uma rodada anterior — o histórico das rodadas é o rastro do que quebrou e do que foi corrigido.
- Quando o E2E falhar: o time lê logs/prints/código, conserta e ajusta o script; o dev só re-executa na rodada seguinte.
- Todo o rastro (script e, se houver, instrumentação `[e2e]`) fica listado no `test_plan.md` — é o mapa da limpeza no wrap.
