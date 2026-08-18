---
name: iniciar-feature
description: Abre uma feature no GitFlow do driva (branch de develop → PR para develop → auto-deploy em homologação). Use ao começar qualquer funcionalidade nova. Fonte da verdade das branches: docs/GITFLOW.md.
---

# Skill: iniciar uma feature

Objetivo: conduzir uma funcionalidade nova do começo ao PR, no GitFlow (`docs/GITFLOW.md`). Feature nasce e morre em `develop`.

Passos:
1. Parta de `develop` atualizado: `git switch develop && git pull --ff-only origin develop`.
2. Crie o branch: `git switch -c feature/<issue>-<slug>` (ex.: `feature/BMJ-7-filtro-de-paginas`). **Nunca** trabalhe direto em `develop`/`main`.
3. Implemente seguindo o método do time (fase a fase; use `criar-modulo` quando for módulo novo). `flutter analyze` verde e testes passando a cada fase — a mesma régua da CI.
4. Atualize o **CHANGELOG** na seção `Unreleased` no mesmo PR (Keep a Changelog).
5. Antes de abrir o PR, traga a base: `git fetch origin && git merge --no-edit origin/develop` (ou rebase), resolva conflitos, rode a cancela local.
6. Abra o PR para `develop`: `gh pr create --base develop --fill`. A CI (`.github/workflows/ci.yml`) roda no PR.
7. Com a CI verde e a revisão do humano, faz-se o merge. O Coolify publica automaticamente em **homologação** (`develop` → `hml.driva.duckdns.org`).
8. Valide na URL de hml; delete o branch de suporte após o merge.

Regras inegociáveis — e quem cobra cada uma **de verdade**:

- **Sem push direto em `main`/`develop`**; PR de `feature/*` **sempre** para `develop`. Quem barra é a **proteção de branch do GitHub** (config do repositório): o `ci.yml` não sabe de onde veio o commit e nunca reprova por isso.
- **Sem segredo/URL no repo** — config sensível só como env/Build Variable no Coolify. Quem varre é o **GitGuardian**, um GitHub App separado que aparece como check no PR; não há job de segredo no `ci.yml`.
- **Não declare pronto com CI vermelha.** A cancela local que reproduz o `.github/workflows/ci.yml` inteiro:

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
bash scripts/gates_guard.sh
dart test -r compact packages/sdui_core
(cd packages/sdui_flutter && flutter test -r compact)
(cd apps/driva_editor     && flutter test -r compact)
(cd apps/driva_demo_app   && flutter test -r compact)
(cd backend && pnpm install --frozen-lockfile && pnpm prisma:generate \
            && pnpm lint && pnpm build && pnpm test && pnpm test:e2e)
```

Fora dessa lista fica só o job de Android (`cd apps/driva_demo_app && flutter build apk --debug --target lib/main_dev.dart`), que custa minutos e exige JDK 17 + Gradle: rode-o quando o PR tocar `apps/driva_demo_app`, `packages/sdui_flutter`, o `pubspec.yaml` da raiz ou a versão do Flutter no workflow.
