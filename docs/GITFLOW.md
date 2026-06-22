# GitFlow — Padrão de branches do Driva

Este projeto segue o **GitFlow** (modelo de Vincent Driessen, *"A successful Git branching
model"*), com a variante prática **feature / bugfix / hotfix** adotada pelo `git-flow (AVH)`.
Este documento é a **fonte da verdade** sobre branches. Toda automação (agentes Paperclip) e
todo humano devem segui-lo.

---

## 1. Branches permanentes

| Branch | Papel | Regras |
|---|---|---|
| **`main`** | Produção. Cada commit é uma versão entregue (com tag `vX.Y.Z`). | **PROTEGIDA.** Nunca recebe push direto nem trabalho de agente. Só recebe merges de `release/*` e `hotfix/*`. |
| **`develop`** | Integração. Reflete o próximo release em construção. | Branch **base** de todo o trabalho. Só recebe features/bugfixes **completos**, sempre via Pull Request. Sem push direto. |

> Regra de ouro: **ninguém comita direto em `main` ou `develop`.** Todo trabalho nasce em um
> branch de suporte e volta por Pull Request.

---

## 2. Branches de suporte (temporários)

| Tipo | Nasce de | Volta para | Naming | Uso |
|---|---|---|---|---|
| **`feature/*`** | `develop` | `develop` | `feature/<issue>-<slug>` | Nova funcionalidade do próximo release. **Default dos agentes.** |
| **`bugfix/*`** | `develop` | `develop` | `bugfix/<issue>-<slug>` | Correção de bug encontrado **em desenvolvimento** (ainda não em produção). |
| **`hotfix/*`** | **`main`** | `main` **e** `develop` | `hotfix/<issue>-<slug>` | Correção **urgente de produção**. Sobe a versão (patch). Geralmente iniciado por humano. |
| **`release/*`** | `develop` | `main` **e** `develop` | `release/<vX.Y.Z>` | Estabilização para um release (bump de versão, ajustes finais, **sem novas features**). Conduzido por humano. |

Notas do modelo oficial:
- Merges de volta para `main`/`develop` usam **`--no-ff`** (mantêm o agrupamento do branch no histórico).
- Ao fechar `release/*` ou `hotfix/*`: faz-se merge em `main`, **cria-se a tag de versão**, e
  faz-se merge de volta em `develop` (para não perder a correção). Se houver um `release/*` aberto,
  o `hotfix/*` é integrado nele em vez de `develop`.
- Branches de suporte são **deletados** após o merge.

---

## 3. Fluxo visual

```
  hotfix/*  ──────────────┐ (sai de main)
                          v
main  ●─────────────────────●──────────────●   (tags vX.Y.Z; protegida)
       \                   ^                ^
        \           release/* (estabiliza) │
         \               ^                  │
develop   ●──●──●──●──●───●──────●──●──●─────●   (integração)
              ^     ^            ^     ^
        feature/*  bugfix/*  feature/*  (saem e voltam para develop, via PR)
```

---

## 4. Como o Paperclip implementa isto

O Paperclip **não tem GitFlow nativo**. A conformidade vem de 3 camadas:

1. **Config do projeto** (`executionWorkspacePolicy.workspaceStrategy`):
   - `baseRef = "develop"` → toda worktree de tarefa **nasce de `develop`**.
   - `branchTemplate = "feature/{{issue.identifier}}-{{slug}}"` → nome **default** = `feature/...`.
2. **Este documento + `CLAUDE.md`** na raiz → lido automaticamente pelos agentes (Claude Code).
3. **GitHub** → `main` protegida (sem push direto, PR obrigatório), `develop` como branch default.

### Tipo de branch por tarefa (feature é o default)

Como o template do projeto é único, o **tipo** (feature/bugfix/hotfix) é definido **por tarefa**
por quem a cria (Tech Lead / Architect / operador), via override no Paperclip:

- **feature** (default): nada a fazer.
- **bugfix**: no momento de criar/atualizar a issue, setar
  `executionWorkspaceSettings.workspaceStrategy.branchTemplate = "bugfix/{{issue.identifier}}-{{slug}}"`
  (base continua `develop`).
- **hotfix**: setar
  `executionWorkspaceSettings.workspaceStrategy.branchTemplate = "hotfix/{{issue.identifier}}-{{slug}}"`
  **e** `executionWorkspaceSettings.workspaceStrategy.baseRef = "main"`.

Via API/CLI do Paperclip (ex.): `PATCH /api/issues/<id>` com o corpo
`{"executionWorkspaceSettings": {"workspaceStrategy": {"branchTemplate": "...", "baseRef": "..."}}}`.
Use a skill `paperclip` para isso.

---

## 5. Regras operacionais para os agentes

1. Trabalhe **somente** no branch da sua tarefa (a worktree que o Paperclip já criou). Confira com
   `git rev-parse --abbrev-ref HEAD` — deve ser `feature/…`, `bugfix/…` ou `hotfix/…`.
2. **Nunca** faça `git commit`/`git push` direto em `main` ou `develop`. **Nunca** dê `git checkout main`
   para trabalhar.
3. Abra o Pull Request com base correta:
   - `feature/*` e `bugfix/*` → **PR para `develop`**.
   - `hotfix/*` → **PR para `main`** (e, depois do merge, garantir o merge de volta em `develop`).
   - Comando: `gh pr create --base develop ...` (ou `--base main` para hotfix).
4. Antes de abrir/atualizar o PR, **rebase/merge da base** (`develop` ou `main`) para o diff ficar atual.
5. Ao concluir, mova a tarefa para `in_review` e notifique o Tech Lead. **Não** faça merge em `main`.
6. Merges `develop → main` (releases) e a criação de `hotfix/*` são **decisão humana**, salvo
   instrução explícita.
