# Specs — Módulo Página (I1)

> Destilada de `docs/specs/modulo-pagina.html` (2026-06-21) + decisões de retomada (2026-07-01). Documento vivo: descreve o que o incremento **é**. Dono: PM.

## O que é

O núcleo do Page Builder do driva: um editor Flutter Web onde o usuário compõe uma **página SDUI** a partir de um catálogo de widgets, organiza a ordem, edita propriedades e vê em tempo real, num **preview 100% fiel**, como a página aparecerá no app — salvando como rascunho reabrível.

## Conceitos

| Conceito | Definição (I1) |
|---|---|
| Página | Fragmento SDUI anexado a uma tela existente do app (`screenTarget`); uma árvore de blocos cujo topo é `root.children` |
| Bloco | Instância de um primitivo do catálogo, com props próprias e `id` único |
| Catálogo | Os 14 primitivos Flutter (`packages/sdui_core/lib/src/catalog/widget_catalog.dart`) |
| Rascunho | Working copy salva/reabrível; sem máquina de estados (workflow = I4) |
| Preview fiel | O renderer real (`sdui_flutter`) rodando **dentro** do editor — mesma árvore Dart, sem iframe |

## Dentro do I1

- Editor em 3 colunas + canvas: paleta (busca + categorias), árvore/organização dos blocos, inspector de propriedades (forms derivados do catálogo), preview com moldura de dispositivo (3 presets) e zoom.
- Arrastar da paleta para a página; reordenar, selecionar e remover blocos.
- Salvar explícito (botão + Ctrl+S) com indicador de estado; reabrir página.
- Listagem de páginas (criar, abrir, excluir), escopada por `project_id` (default "default").
- Persistência no backend NestJS (`/v1/pages`, Postgres/JSONB).
- **UX é critério de aceite**: referência visual = protótipo `docs/web-prototipe/Driva Builder.dc.html`.

## Fora do I1

Condições/filtros/simulação de usuário (I2) · construtor de widget com estados e fonte de dados (I3) · workflow/papéis/versionamento/agendamento/publish real (I4) · serving `GET /pages` ao app cliente · undo/redo · auto-save · auth · resolução de binding `{{prop}}` · copy/paste de nós.

## Decisões que sustentam esta spec

1. Editor **100% Flutter Web** (2026-07-01; substitui Next.js — ver variance_report).
2. Backend **NestJS desde já**, storage burro de spec (não interpreta o JSON; kernel é Dart).
3. Paleta = 14 primitivos da POC (board, 2026-06-21).
4. Página = fragmento (`screenTarget`), não rota inteira (board, 2026-06-21).
5. Formato do spec: `{specVersion: 1, kind: "page", id, name, screenTarget, root}`; `root` sempre `column`; todo nó tem `id`.
6. Suspensão do board encerrada em 2026-07-01 por decisão do dev; design system evolui em `core/theme/` guiado pelo protótipo.
