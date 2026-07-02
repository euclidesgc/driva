# Variance Report — Módulo Página (I1)

> Histórico dos desvios **aprovados pelo dev**. Como estava → por que mudou → o que mudou. Dono: Tech Lead.

## 2026-07-01 — Editor passa de Next.js para Flutter Web

- **Como estava:** `docs/specs/visao-geral.html` definia a stack da plataforma como Next.js (editor com Puck) + NestJS + Flutter Web só para o preview em iframe/postMessage.
- **Por que mudou:** decisão do dev na retomada do I1: com o editor em Flutter Web, o renderer `sdui_flutter` roda dentro do próprio editor — preview fiel por construção (sem iframe/postMessage), e o kernel do spec vira Dart puro (zard), eliminando o risco de drift Zod(TS) ↔ Dart.
- **O que mudou:** editor 100% Flutter Web (`apps/driva_editor`), kernel portado para `packages/sdui_core` (Dart + zard), specs.md/prd.md desta feature refletem a nova stack. O Puck e o app `sdui_preview` da POC deixam de ser herdados.

## 2026-07-01 — Suspensão do board encerrada

- **Como estava:** I1 suspenso desde 2026-06-21 aguardando o design system ("Claude Design").
- **Por que mudou:** decisão explícita do dev na sessão de 2026-07-01.
- **O que mudou:** trabalho retomado; a referência visual passa a ser o protótipo `docs/web-prototipe/Driva Builder.dc.html` e o design system evolui dentro do app (`core/theme/`).

## 2026-07-01 — Formato da página: árvore com root column (não lista plana de blocos)

- **Como estava:** o esboço na spec antiga modelava a página como `blocks[]` referenciando widgets do catálogo por `slug`+`version`.
- **Por que mudou:** com a paleta do I1 sendo os 14 primitivos (decisão do board) e o construtor de widget ficando para o I3, a referência slug+version não tem o que referenciar ainda; a árvore com `root: column` unifica "lista ordenada de blocos" (topo) e "subárvores por bloco" num modelo só, já compatível com o renderer.
- **O que mudou:** spec `{specVersion, kind, id, name, screenTarget, root}`; todo nó tem `id`. Referência a widgets compostos volta a ser discutida no I3.
