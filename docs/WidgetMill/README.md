# WidgetMill

Construtor visual de widgets (Widget Builder) que produz um **spec JSON** versionado — não código Dart. O spec é o kernel do qual tudo deriva (tipos, validação, forms do Inspector, renderer Flutter).

## Organização (monorepo)

| Diretório | O que vive ali |
|---|---|
| [packages/spec](packages/) | `@widgetmill/spec` — kernel Zod (fonte de verdade do spec) |
| [apps/](apps/) | `web` (Next.js, editor) e `api` (NestJS, RBAC/workflow) |
| [flutter/](flutter/) | `sdui_flutter` (renderer) e `sdui_preview` (preview Web) |
| [infra/](infra/) | docker-compose (Postgres+Redis) e Prisma |
| [docs/](docs/) | planejamento, spec v1, roadmap de execução |

## Documentação

- [Plano](docs/plano-construtor-de-widgets.md) · [Spec v1](docs/spec-json-v1.md)
- [Elaboração da construção](docs/elaboracao-construcao.md) · [Roadmap de execução](docs/roadmap-execucao.md)

## Desenvolvimento

```bash
pnpm install      # instala o workspace TS
pnpm test         # roda os testes de todos os pacotes
pnpm typecheck    # checagem de tipos
```

Requer Node ≥ 18.18 (20 recomendado) e pnpm 10. O lado Flutter é isolado em `flutter/`.
