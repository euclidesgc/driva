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

### Opção A — Upload como attachment (recomendado para deliverables)

Use o script `paperclip-upload-artifact.sh` disponível em `/app/skills/paperclip/scripts/`:

```bash
bash /app/skills/paperclip/scripts/paperclip-upload-artifact.sh \
  docs/content/<slug>/<tipo>/v1.html \
  --title "PRD: <Feature> v1" \
  --summary "Descrição curta do documento."
```

O script faz upload do arquivo, cria um work product `artifact` linkado ao attachment, e imprime
os links markdown para o comentário final. Use para: HTML de specs/PRDs, PDF, imagem, vídeo, zip.

### Opção B — Referência no workspace (para arquivos que ficam no repo)

Para arquivos cujo valor está ligado ao checkout (logs, índices gerados, código):

```bash
curl -sS -X POST "$PAPERCLIP_API_URL/api/issues/$PAPERCLIP_TASK_ID/work-products" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "X-Paperclip-Run-Id: $PAPERCLIP_RUN_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "document",
    "provider": "workspace",
    "title": "...",
    "status": "ready_for_review",
    "reviewState": "needs_board_review",
    "summary": "...",
    "metadata": {
      "resourceRef": {
        "kind": "workspace_file",
        "issueId": "'"$PAPERCLIP_TASK_ID"'",
        "workspaceKind": "execution_workspace",
        "workspaceId": "<execution-workspace-id>",
        "relativePath": "docs/content/<slug>/<tipo>/v1.html",
        "displayPath": "docs/content/<slug>/<tipo>/v1.html"
      }
    }
  }'
```

O `execution-workspace-id` está em `executionWorkspaceId` na resposta de
`GET /api/issues/$PAPERCLIP_TASK_ID`. **Nota:** `PAPERCLIP_PROJECT_WORKSPACE_ID` pode vir
vazio no ambiente — sempre busque o ID via API se necessário.

### Regra

- **Sempre** use a **Opção A** para specs/PRDs/HTMLs que o board vai revisar — o upload garante
  acesso mesmo sem o workspace ativo.
- **Sempre** linke o artifact no **comentário final** da tarefa, e só então mude o status.

As envs (`PAPERCLIP_API_URL/API_KEY/TASK_ID/RUN_ID/COMPANY_ID`) já vêm injetadas no ambiente.
Detalhes completos: `skills/paperclip/references/artifacts.md`.

## Documentação

O mini-site de docs/specs/PRD está em `docs/` (ver `docs/GITFLOW.md`, `docs/content/`).
