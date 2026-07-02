# driva

Plataforma de **Server-Driven UI** para apps Flutter: monte páginas num editor web, publique um **spec JSON**, e o app do cliente as renderiza sem republicar. Este repositório contém o editor (Flutter Web), o kernel do spec, o renderer e o backend.

## Estrutura (Dart pub workspace)

| Pasta | O que é |
|---|---|
| `packages/sdui_core` | Kernel do spec (Dart puro): modelos, validação zard (`parsePageSpec`), catálogo de 14 primitivos, operações puras de árvore |
| `packages/sdui_flutter` | Renderer: registry `type → builder`, `SduiView`. Roda no preview do editor e, futuramente, nos apps dos clientes |
| `apps/driva_editor` | O editor (Flutter Web): lista de páginas + builder de 3 colunas com preview fiel |
| `backend/` | NestJS + Prisma + Postgres: storage de specs (`/v1/pages`), tenant por `x-project-id` |
| `docs/feature-modulo-pagina/` | Docs vivas do incremento I1 (specs, prd, plan, test_plan, final_report) |
| `docs/livro-flutter/` | O livro que define a arquitetura e o método de trabalho (gabarito) |

## Rodando em dev

```bash
# 1. Dependências Dart (na raiz do workspace)
dart pub get

# 2. Backend (Postgres na porta 5433 + Nest em :3000)
cd backend
cp .env.example .env
pnpm install
docker compose up -d
pnpm prisma:push
pnpm start:dev

# 3. Editor (em outro terminal, a partir de apps/driva_editor)
cd apps/driva_editor
flutter run -d chrome --target lib/main_dev.dart --dart-define-from-file=config/dev.json
```

Sem backend? Rode o editor **sem** o `--dart-define-from-file`: entra em modo fake (páginas em memória, com uma página de exemplo).

## Qualidade

```bash
flutter analyze                       # workspace inteiro
dart test packages/sdui_core          # kernel (30 testes)
flutter test packages/sdui_flutter    # renderer (7 testes)
flutter test apps/driva_editor        # editor (20 testes)
```

## Arquitetura (resumo)

Clean Architecture por módulo (`domain`/`data`/`presentation` + barrel público só com rota e DI), Cubit + estados sealed, `Either<Failure, T>` (fpdart), validação zard na borda, get_it via `pageBuilder`, go_router, **zero build_runner**. Regras completas no [CLAUDE.md](CLAUDE.md); o método de trabalho com o time de IA está em `.claude/agents/` e `.claude/skills/`.

## Incrementos

- **I1 — Módulo Página** (este repositório): montar página com primitivos, editar props, preview fiel, salvar rascunho. ✅ implementado (E2E manual pendente — `docs/feature-modulo-pagina/test_plan.md`)
- **I2** — condições de exibição + filtros por widget + simulação de usuário
- **I3** — construtor de widget composto (estados + fonte de dados)
- **I4** — workflow, papéis, versionamento, agendamento e serving
