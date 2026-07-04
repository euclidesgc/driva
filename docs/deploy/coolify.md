# Deploy no Coolify — driva

Guia de configuração do projeto **Driva** no Coolify (painel). O deploy é **automático por branch** via GitHub App do Coolify: `develop` → homologação, `main` → produção. Este documento é o passo-a-passo do painel; o fluxo de branches está em [`../GITFLOW.md`](../GITFLOW.md).

> **driva e love-secret são projetos separados.** O único ponto em comum é este servidor Coolify. Nada aqui toca o love-secret.

## Visão geral

| Ambiente | Branch | Frontend (Flutter Web) | Backend (Nest API) | Banco |
|---|---|---|---|---|
| **Homologação** (`hml`) | `develop` | `https://hml.driva.duckdns.org` | `https://api-hml.driva.duckdns.org` | Postgres (recurso Coolify) |
| **Produção** (`prod`) | `main` | `https://driva.duckdns.org` | `https://api.driva.duckdns.org` | Postgres (recurso Coolify) |

- O DuckDNS `driva` tem wildcard: qualquer `*.driva.duckdns.org` resolve para o servidor (`64.181.165.16`, confirmado por `dig`). Usar `https://` faz o Coolify emitir **Let's Encrypt automático** (portas 80/443 abertas). O `bmjtech.duckdns.org` é o host principal/infra compartilhada (ex.: Garage em `s3.bmjtech.duckdns.org`); o driva vive sob seu próprio `driva.duckdns.org`.
- Repositório: `github.com/euclidesgc/driva`. Reuse a **GitHub App/Source** já conectada ao servidor.
- **Nenhum segredo no repositório.** Toda config sensível é env/Build Variable no Coolify.

## Pré-requisito: histórico do repo

`develop` e `main` já foram unificados com o app (baseline `v0.1.0`). O Coolify buildará a partir do estado atual dessas branches. Nada a fazer aqui além de garantir que a GitHub App enxerga o repo `euclidesgc/driva`.

---

## Passo a passo — repita para cada ambiente

No projeto **Driva**, entre no ambiente (`hml` ou `prod`) e crie **três recursos**, nesta ordem. Onde aparecer `[-hml]`/`[-api-hml]`, use o sufixo em homologação e **omita em produção**.

### 1. Postgres (banco gerenciado)

1. **+ New Resource → Database → PostgreSQL** (16).
2. Nome sugerido: `driva-db-hml` / `driva-db`.
3. Após criar, copie a **connection string interna** (algo como `postgresql://<user>:<pass>@<host-interno>:5432/<db>`). Ela será o `DATABASE_URL` do backend.
4. Não exponha porta pública; o backend fala com o banco pela rede interna do Coolify.

### 2. Backend (Nest API)

1. **+ New Resource → Application → Public Repository / GitHub App** → repo `euclidesgc/driva`.
2. **Branch**: `develop` (hml) / `main` (prod). Ligue **Automatic Deployment**.
3. **Build Pack**: `Dockerfile`.
   - **Base Directory**: `/backend`
   - **Dockerfile Location**: `/Dockerfile`  *(relativo ao Base Directory — **não** repita `backend/` aqui, senão o Coolify resolve `backend/backend` e o build falha)*
   - **Ports Exposes**: `3000`
4. **Domains**: `https://api-hml.driva.duckdns.org` (hml) / `https://api.driva.duckdns.org` (prod).
5. **Environment Variables** (runtime):
   - `DATABASE_URL` = a connection string interna do passo 1.
   - `PORT` = `3000`
   - `CORS_ORIGINS` = `https://hml.driva.duckdns.org` (hml) / `https://driva.duckdns.org` (prod) — a origem do frontend do mesmo ambiente.
6. Deploy. O container **registra a baseline e roda `prisma migrate deploy`** automaticamente no start (`resolve --applied 0_baseline` idempotente + `migrate deploy`), então sobe o Nest.
   > O banco de hml/prod foi criado por `db push` (sem histórico de migrations); `migrate deploy` sozinho abortaria com `P3005` ("schema não vazio"). O `CMD` do `backend/Dockerfile` resolve a baseline sozinho antes de migrar — **nenhum passo manual** (ver `variance_report.md` 002). Banco 100% novo/vazio não usa esse caminho.
7. Teste: `curl https://api-hml.driva.duckdns.org/v1/contents -H 'x-project-id: default'` deve responder `200` com uma lista JSON.

### 3. Frontend (Flutter Web)

1. **+ New Resource → Application → GitHub App** → mesmo repo `euclidesgc/driva`.
2. **Branch**: `develop` (hml) / `main` (prod). Ligue **Automatic Deployment**.
3. **Build Pack**: `Dockerfile`.
   - **Base Directory**: `/`  *(a raiz — o app faz parte do pub workspace e depende de `packages/`)*
   - **Dockerfile Location**: `/apps/driva_editor/Dockerfile`
   - **Ports Exposes**: `80`
4. **Build Variable** (build-time — a URL da API é compilada no bundle do Flutter Web):
   - `API_BASE_URL` = `https://api-hml.driva.duckdns.org` (hml) / `https://api.driva.duckdns.org` (prod).
5. **Domains**: `https://hml.driva.duckdns.org` (hml) / `https://driva.duckdns.org` (prod).
6. Deploy. (O primeiro build do Flutter é demorado — baixa a imagem do SDK.)
7. Teste: abra a URL do front; a lista de páginas deve carregar consumindo a API do mesmo ambiente, **sem erro de CORS** no console.

---

## Como o fluxo fica no dia a dia

- Merge de um PR em **`develop`** → Coolify rebuilda e publica **hml** automaticamente. Teste em `driva-hml…`.
- Uma **release** (PR `release/* → main`, veja a skill `publicar-release`) → Coolify publica **prod**.
- Um **hotfix** (`hotfix/* → main`) → publica prod; lembre de trazer de volta para `develop`.

## Troubleshooting

- **`lstat .../backend/backend: no such file or directory`** (ou caminho duplicado no build): o **Dockerfile Location** é relativo ao **Base Directory** e os dois foram repetidos. Com Base Directory `/backend`, o Dockerfile Location tem de ser só `/Dockerfile`. (No frontend não ocorre: o Base Directory é `/`.)
- **Erro de CORS no console do front**: confira `CORS_ORIGINS` no backend do **mesmo ambiente** — deve conter exatamente a origem do frontend (com `https://`, sem barra no fim).
- **Front carrega mas não fala com a API**: a URL da API é **build-time**; se trocou o domínio da API, rebuilde o frontend (a Build Variable `API_BASE_URL` só entra num novo build).

## Notas e limites (I1)

- **Migrations versionadas** (a partir da feature Conteúdos): o backend roda `prisma migrate deploy` no start. A baseline (`0_baseline`) precisa ser resolvida uma vez por ambiente (passo 6). Config de hml e prod **conferida via API do Coolify em 2026-07-03** — env/build vars e domínios corretos.
- **Branch protection**: `main` tem o ruleset `protect-main` (PR obrigatório, sem force-push). Mantenha ligado.
- **CORS**: se um ambiente tiver mais de uma origem de frontend, liste-as em `CORS_ORIGINS` separadas por vírgula.
- **Ordem de subida** importa: Postgres → Backend → Frontend.
