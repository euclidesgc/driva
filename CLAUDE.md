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

## Entregáveis = Artifacts (OBRIGATÓRIO no Definition of Done)

Commitar no repo **não basta**: um arquivo no checkout não aparece na aba **Artifacts** do
Paperclip e quem revisa pela web não acessa o disco do agente. **Todo entregável inspecionável por
humano** (PRD, spec, HTML renderizado, screenshot, relatório, vídeo, PDF, diagrama) deve ser
**promovido como artifact ANTES de mover a tarefa para `in_review`**:

- **Arquivo que fica no repo** (ex.: PRD/spec em `docs/`): registre um **work product `workspace_file`**
  apontando pro caminho relativo no workspace —
  `POST /api/issues/$PAPERCLIP_TASK_ID/work-products` com
  `{"type":"workspace_file","title":"...","resourceRef":{"kind":"workspace_file","issueId":"$PAPERCLIP_TASK_ID","workspaceKind":"project_workspace","workspaceId":"$PAPERCLIP_PROJECT_WORKSPACE_ID","relativePath":"docs/...","displayPath":"docs/..."}}`
  (use `Authorization: Bearer $PAPERCLIP_API_KEY` e `X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID`).
- **Arquivo gerado pra download** (vídeo, PDF, zip, imagem): **suba como anexo** com
  `paperclip-upload-artifact.sh <arquivo> --title "..." --summary "..."` (skill `paperclip`). Ele cria o
  artifact e imprime o link markdown.
- **Sempre** linke o artifact no **comentário final** da tarefa, e só então mude o status.

As envs (`PAPERCLIP_API_URL/API_KEY/TASK_ID/RUN_ID/COMPANY_ID/PROJECT_WORKSPACE_ID`) já vêm injetadas
no ambiente do run. Detalhes: skill `paperclip` e `AGENT-ARTIFACTS.md`.

## Documentação

O mini-site de docs/specs/PRD está em `docs/` (ver `docs/GITFLOW.md`, `docs/content/`).
