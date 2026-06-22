# Driva — instruções do repositório

Server Driven UI para aplicações Flutter (BMJTech).

## Branching: GitFlow (OBRIGATÓRIO)

Este repo segue **GitFlow**. A especificação completa está em [`docs/GITFLOW.md`](docs/GITFLOW.md) —
leia antes de mexer em branches. Resumo operacional:

- **`main`** = produção, **protegida**. **Nunca** comite, faça push ou checkout para trabalhar nela.
- **`develop`** = integração e **base de todo trabalho**. Sem push direto — só via Pull Request.
- Toda tarefa roda no **seu próprio branch** (a worktree já vem criada pelo Paperclip):
  - `feature/<issue>-<slug>` — nova funcionalidade (**default**), nasce de `develop`.
  - `bugfix/<issue>-<slug>` — bug em desenvolvimento, nasce de `develop`.
  - `hotfix/<issue>-<slug>` — correção urgente de produção, nasce de **`main`**.
- **Pull Request:**
  - `feature/*` e `bugfix/*` → `gh pr create --base develop`
  - `hotfix/*` → `gh pr create --base main` (e garantir merge de volta em `develop` depois)
- Antes de abrir/atualizar o PR, atualize o branch a partir da base (`develop`/`main`).
- Ao terminar: mova a tarefa para `in_review` e avise o Tech Lead. **Não** faça merge em `main`.
- Releases (`develop → main`) e abertura de `hotfix/*` são **decisão humana**, salvo instrução explícita.

> Se a sua worktree não estiver em um branch `feature/ | bugfix/ | hotfix/`, **pare** e reporte —
> algo está fora do padrão.

## Documentação

O mini-site de docs/specs/PRD está em `docs/` (ver `docs/GITFLOW.md`, `docs/content/`).
