# WidgetMill — guia do projeto (Claude Code)

Construtor visual de widgets (Widget Builder) que produz um **spec JSON** versionado — não código Dart. O **spec é o kernel** do qual tudo deriva: tipos, validação, forms do Inspector, paleta do editor e o renderer Flutter.

## Estrutura (monorepo pnpm + Flutter isolado)

| Caminho | O que é |
|---|---|
| `packages/spec` | `@widgetmill/spec` — kernel Zod (fonte de verdade). Sem dependência de framework. |
| `apps/web` | Editor Next.js 15 / React 19 + Puck (`@measured/puck`). |
| `flutter/sdui_flutter` | Renderer (spec JSON → widgets Flutter). |
| `flutter/sdui_preview` | App Flutter Web embarcado no editor via iframe + `postMessage`. |
| `infra/` | docker-compose (Postgres+Redis) e Prisma (M3, ainda não scaffolded). |
| `docs/` | Planejamento, spec v1 e **`roadmap-execucao.md`** (log de progresso — manter atualizado). |

## Comandos

```bash
# Kernel (TS)
cd packages/spec && pnpm exec vitest run          # testes
pnpm exec tsc --noEmit                            # typecheck

# Web
cd apps/web && pnpm exec tsc --noEmit             # typecheck
pnpm exec next build                              # build (rede de segurança rápida)
pnpm dev                                          # dev server (ou launch "Web: editor (Next.js dev)")

# Flutter (via puro)
cd flutter/sdui_flutter && puro flutter test
cd flutter/sdui_preview && puro flutter test
# Recompilar o preview embarcado (após mudar o Flutter):
#   task "Preview: build → public/preview" (.vscode/tasks.json)
```

Rodar/depurar pelo VS Code: configs em `.vscode/launch.json`. (`pnpm lint` ainda **não** está configurado — gap conhecido.)

## Arquitetura e convenções

- **Tudo deriva do spec.** Lógica de domínio (enums, slots, categorias da paleta, descriptors, versionamento, diff, diagnósticos) mora no kernel `packages/spec` — **fonte única**, reusada pelo web e (futuro) backend. Evite duplicar essas listas/regras no `apps/web`.
- **Tradução Puck ↔ spec** em `packages/spec/src/puck/translate.ts` (simétrica). Um widget tem **raiz única**.
- **Preview** = iframe `/preview/index.html` (mesma origem) falando por `postMessage`; componente `apps/web/components/preview/PreviewFrame.tsx`.
- **Versionamento estilo Squidex** (event-sourced, em memória) atrás da interface `apps/web/lib/widget-repo/WidgetRepository` — o M3 troca a implementação por uma que chama a API, **sem mexer na UI**.
- **TypeScript estrito** (inclui `noUncheckedIndexedAccess`). Web usa **estilos inline** (sem framework de CSS). Arquivos pequenos, responsabilidade única (KISS/DRY).
- **Idioma: pt-BR** em comentários, UI e mensagens (com acentuação correta).

## Regras do projeto

> Regras que **sobrepõem** o comportamento padrão e as skills (ex.: TDD). Lista viva — cresce conforme decidirmos.

1. **Testes vêm depois da validação manual — não antes.** TDD está **desligado** neste projeto. Ao implementar uma mudança: implemente primeiro; o usuário testa manualmente; só então escrevemos/ajustamos os testes (quando ele pedir ou como passo de consolidação após o "ok"). Durante o desenvolvimento, use `tsc`/`next build` como rede de segurança rápida e **não** fique rodando a suíte de testes inteira repetidamente — isso desperdiça tempo/tokens.
2. **Trabalhar sempre em branch — nunca commitar direto na `main`.** A branch de integração é a **`develop`**; a **`main` é reservada para release** (ainda não usada). Ao iniciar uma implementação, criar a branch **a partir de `develop`** no padrão **Gitflow**, conforme o tipo (eu classifico pelo que você pedir):
   - `feature/<slug>` — nova funcionalidade
   - `bugfix/<slug>` — correção de bug
   - `refactor/<slug>` — refatoração sem mudança de comportamento
   - `hotfix/<slug>` — correção urgente
   - `chore/<slug>` — tooling/config/infra

   `<slug>` em kebab-case. Ao concluir, **merge de volta na `develop`** (`--no-ff`) e voltar para a `develop`. **Commitar só quando o usuário autorizar.**

## Estado atual

M0 (kernel) e M1 (renderer+preview) completos. M2 (editor): núcleo + Puck + versionamento (em memória) + diagnósticos de montagem entregues. **M3 (backend) postergado**. Detalhes e histórico em `docs/roadmap-execucao.md`.

## Armadilhas

- O asset do preview (`apps/web/public/preview/`) é **gitignored** e gerado a partir de `flutter/sdui_preview` — recompile com a task do VS Code após mudar o Flutter.
- O layout do Puck usa `height: 100dvh`; o override está em `apps/web/app/editor.css` (`.wm-editor-host`).
- `.claude/` é gitignored; o `CLAUDE.md` (raiz) **é** versionado.
