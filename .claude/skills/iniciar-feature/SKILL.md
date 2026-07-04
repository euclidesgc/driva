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

Regras inegociáveis (o `docs/GITFLOW.md`, o CLAUDE.md e a CI cobram):
- Sem push direto em `main`/`develop`; PR de `feature/*` **sempre** para `develop`.
- Não declare pronto com CI vermelha (`dart format`, `flutter analyze`, testes; `build` no backend).
- Sem segredo/URL no repo — config sensível só como env/Build Variable no Coolify.
