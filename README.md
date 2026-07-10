# driva

Plataforma de **Server-Driven UI** para apps Flutter: monte conteúdos num editor web, publique um **spec JSON**, e o app do cliente os renderiza sem republicar. Este repositório contém o editor (Flutter Web), o kernel do spec, o renderer e o backend.

## Estrutura (Dart pub workspace)

| Pasta | O que é |
|---|---|
| `packages/sdui_core` | Kernel do spec (Dart puro): modelos, validação zard (`parseContentSpec`), catálogo de 14 primitivos, operações puras de árvore |
| `packages/sdui_flutter` | Renderer: registry `type → builder`, `SduiView`. Roda no preview do editor e, futuramente, nos apps dos clientes |
| `apps/driva_editor` | O editor (Flutter Web): home de Projetos + tela do projeto (árvore de categorias + painel de conteúdos) + builder de 3 colunas com preview fiel |
| `backend/` | NestJS + Prisma + Postgres: hierarquia Projeto → Categoria → Conteúdo (`/v1/projects`, `/v1/categories`, `/v1/contents`), tenant por `x-project-id` |
| `docs/01-modulo-pagina/` | Docs vivas do incremento I1 (specs, prd, plan, test_plan, final_report) |
| `docs/02-conteudos/` | Docs vivas da feature Conteúdos (rename página→conteúdo: slug, CUID2, migração) |
| `docs/09-crud-projeto/` | Docs vivas do CRUD de Projeto (upload seguro, StorageService, `Content.projectId` FK) |
| `docs/08-api-conteudos-filtro-busca/` | Docs vivas da API de conteúdos (envelope/cursor/busca) + Categorias + tela do projeto |
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

Sem backend? Rode o editor **sem** o `--dart-define-from-file`: entra em modo fake (conteúdos em memória, com um conteúdo de exemplo).

## Qualidade

```bash
flutter analyze                       # workspace inteiro
dart test packages/sdui_core          # kernel (30 testes)
flutter test packages/sdui_flutter    # renderer (7 testes)
flutter test apps/driva_editor        # editor (47 testes: cubits, slug, widget por estado, golden)
```

## Arquitetura (resumo)

Clean Architecture por módulo (`domain`/`data`/`presentation` + barrel público só com rota e DI), Cubit + estados sealed, `Either<Failure, T>` (fpdart), validação zard na borda, get_it via `pageBuilder`, go_router, **zero build_runner**. Regras completas no [CLAUDE.md](CLAUDE.md); o método de trabalho com o time de IA está em `.claude/agents/` e `.claude/skills/`.

**Hierarquia do produto:** Projeto → Categoria → Conteúdo. `/v1/projects` guarda os projetos (com upload de imagem atrás de um pipeline de segurança e storage por port), `/v1/categories` a árvore de categorias por projeto, e `/v1/contents` os specs — a listagem responde um envelope `{ data, nextCursor }` com keyset cursor, busca acento-insensível, sort e filtro por categoria. Tenant por header `x-project-id` (auth real chega no I4).

## Incrementos

- **I1 — Módulo Página** (renomeado para **Conteúdos**): montar conteúdo com primitivos, editar props, preview fiel, salvar rascunho; identidade por `slug` (referência do dev) + `id` CUID2. ✅ implementado + E2E (`docs/02-conteudos/`)
- **I2** — condições de exibição + filtros por widget + simulação de usuário
- **I3** — construtor de widget composto (estados + fonte de dados)
- **I4** — workflow, papéis, versionamento, agendamento e serving
