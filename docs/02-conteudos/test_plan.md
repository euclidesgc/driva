# Test Plan — Conteúdos

> Documento vivo. A bateria automatizada completa (unit/widget/golden/backend) é
> escrita na **Fase 6**, após o E2E manual. Este documento cobre: (1) o **E2E
> manual da Fase 6** — o caminho feliz e os casos de borda que o dev executa no
> editor; e (2) o **roteiro OPS da Fase 5** — a migração destrutiva `pages` →
> `contents` que o dev executa contra hml/prod.

---

## Fase 6 — E2E manual (o dev executa no editor)

> Testa o editor + backend reais de ponta a ponta. **Instrumentação temporária:
> NENHUMA** — o backend está pronto e o fluxo é 100% observável pela UI, pelos
> logs de estado do `AppBlocObserver` e pelo `LogInterceptor` do dio (em debug).
> Nada a limpar no wrap.

### Pré-condições — subir o ambiente local

Três terminais (Postgres → backend → editor):

```bash
# 1. Postgres local (postgres:16 em localhost:5433)
cd backend && docker compose up -d

# 2. Backend: .env (uma vez) + schema + subir
cd backend
cp .env.example .env                 # DATABASE_URL já aponta p/ localhost:5433; CORS_ORIGINS vazio libera localhost
pnpm install --frozen-lockfile
pnpm prisma:generate
pnpm prisma:migrate:deploy            # banco novo: baseline cria + rename migra → tabela final `contents`
pnpm start:dev                        # Nest em http://localhost:3000, prefixo /v1

# sanity (outro terminal): lista vazia, HTTP 200
curl -s http://localhost:3000/v1/contents -H 'x-project-id: default'   # → []

# 3. Editor (fala com o backend real: dev.json tem USE_FAKE_DATA=false)
flutter run -d chrome --target apps/driva_editor/lib/main_dev.dart \
  --dart-define-from-file=apps/driva_editor/config/dev.json
```

Salve os prints em `docs/02-conteudos/evidencias/`.

### A. Caminho feliz — criar um conteúdo

1. Abra `/contents` (URL **limpa, sem `#`**). **Observar:** título "Conteúdos", wordmark "Driva Builder", estado vazio "Nenhum conteúdo ainda". → *print A1*
2. "Novo conteúdo". Nome = `Home`. **Observar:** o campo **Slug** deriva ao vivo → `home`; Descrição é opcional. → *print A2*
3. Descrição = `Vitrine principal`. "Criar". **Observar:** abre o editor do conteúdo; a barra mostra o nome `Home` (sem nenhum "screenTarget"). → *print A3*

### B. Editar a árvore e salvar

4. Arraste um primitivo da paleta pro canvas e ajuste props no inspector. **Observar:** o preview reflete no mesmo frame; indicador **"Não salvo"**. → *print B1*
5. **Ctrl+S** (ou botão Salvar). **Observar:** indicador → **"Salvo"**. → *print B2*
6. **F5** (recarrega). **Observar:** a URL limpa persiste e o conteúdo reabre com a árvore salva. → *print B3*

### C. Lista e card

7. Clique no wordmark "Driva Builder" para voltar. **Observar:** o card do `Home` mostra o **slug em destaque** (`home`), o **"ID de suporte"** (um CUID2), o nome e a descrição. → *print C1*

### D. Caso de borda — colisão de slug (`409` com sugestão)

8. "Novo conteúdo", Nome = `Home` de novo. **Observar:** o campo Slug deriva `home` (o mesmo já existente). → *print D1*
9. "Criar". **Observar:** o backend responde `409`; o diálogo **reabre** com o Slug já preenchido `home-2` e a mensagem **"Slug já em uso neste projeto. Sugerimos \"home-2\"."**; nada foi criado. → *print D2*
10. "Criar" (aceitando `home-2`). **Observar:** cria com sucesso e abre o editor.

### E. Casos de borda — validação e resiliência

11. **Slug inválido:** num novo conteúdo, edite o Slug à mão para algo com maiúscula/acento (ex.: `Ínicio`). **Observar:** a validação do cliente barra antes de salvar, com mensagem de formato (`^[a-z][a-z0-9-]*$`). → *print E1*
12. **Backend fora:** pare o `start:dev` (Ctrl+C) e recarregue a lista. **Observar:** mensagem de erro de rede + botão **"Tentar de novo"**, **sem crash** no console. Suba o backend e clique "Tentar de novo" → a lista volta. → *print E2*
13. **Conteúdo inexistente:** acesse `/contents/nao-existe/edit`. **Observar:** tela de erro tratada (NotFound) com caminho de volta à lista, sem crash. → *print E3*

> Durante todo o roteiro, o console do Chrome mostra as transições de estado dos
> cubits (`AppBlocObserver`) e, em debug, os logs do dio — use-os se algo divergir
> do esperado.

**Critério de passagem:** todos os passos observados sem erro não-tratado no
console; vocabulário "Conteúdo/Conteúdos" na UI; slug derivado/editável/livre;
`409` tratado com sugestão. Anexe os prints e me avise o resultado.

---

## Fase 5 — Roteiro OPS da migração destrutiva `pages` → `contents`

### Natureza da mudança (leia antes)

- A migração é **destrutiva e irreversível**: dropa `screen_target`, cria
  `@@unique([project_id, slug])` e **reescreve o JSONB** de cada `spec`
  (`kind:"page"` → `"content"`, remove `screenTarget`, injeta `slug`).
- A migração **roda AUTOMATICAMENTE no deploy**. O `Dockerfile` passou de
  `prisma db push` para **`prisma migrate deploy`**; o start do container aplica
  as migrations pendentes. **Não é um passo manual** — por isso o **backup vem
  ANTES do merge que dispara o deploy**.
- `id` de registros legados (UUID) é **preservado** — a migração nunca toca a
  coluna `id`. Só registros novos nascem CUID2.

### Baseline (feito uma única vez, já entregue no código)

O prod/hml foi criado por `db push` (sem histórico de migrations). Adotamos o
Prisma Migrate com um **baseline** = estado deployado atual (`pages` +
`screen_target`), em `prisma/migrations/0_baseline/`. Ele **não deve rodar SQL**
sobre o banco que já tem esse estado — marca-se como aplicado:

```bash
# Uma vez, por ambiente (hml e prod), ANTES do primeiro `migrate deploy`.
# DATABASE_URL vem do ambiente/Coolify — nunca do repo.
pnpm exec prisma migrate resolve --applied 0_baseline
```

> **O `resolve --applied 0_baseline` é PRÉ-CONDIÇÃO OBRIGATÓRIA**, executado no
> banco (via shell/console do Coolify) **antes** de habilitar o auto-deploy da
> branch que contém as migrations. Depois disso, `migrate deploy` aplica só a
> `20260702120000_rename_pages_to_contents`.
>
> **Por que é obrigatório (verificado em Postgres efêmero):** se o `migrate
> deploy` rodar sobre o banco deployado (criado por `db push`, sem histórico de
> migrations) **sem** o resolve, o Prisma aborta no preflight com **`P3005 — The
> database schema is not empty`**, *antes* de executar qualquer SQL. A falha é
> limpa e **não muta dados** (nada é criado/apagado), mas o deploy **não avança**
> e o rename **não** é aplicado. Só o `migrate resolve` registra a baseline em
> `_prisma_migrations` e destrava o `migrate deploy`.
>
> **Nota R2 (idempotência da baseline):** a `0_baseline` é toda idempotente
> (`CREATE SCHEMA/TABLE/INDEX IF NOT EXISTS`) como defesa em profundidade — se
> algum dia ela for reexecutada, é no-op seguro. Isso **não** contorna o P3005
> (o gate é do Prisma, anterior ao SQL); serve só para não haver erro de "objeto
> já existe" caso a baseline rode sobre o schema legado.

### Passo a passo (o humano executa)

1. **Backup ANTES do merge** (obrigatório — o deploy aplica sozinho):
   ```bash
   # hml
   pg_dump "$DATABASE_URL_HML"  -Fc -f backup_hml_pre_conteudos_$(date +%Y%m%d%H%M).dump
   # prod
   pg_dump "$DATABASE_URL_PROD" -Fc -f backup_prod_pre_conteudos_$(date +%Y%m%d%H%M).dump
   ```
   Guarde também a contagem de referência: `SELECT count(*) FROM pages;` (em hml e prod).

2. **hml primeiro.** Garanta o baseline resolvido em hml (comando acima) e faça
   o merge `feature/conteudos` → `develop`. O Coolify auto-deploya em hml e o
   start do container roda `prisma migrate deploy` → aplica a migração de rename.
   - Acompanhe o log do deploy no Coolify: procure
     `Applying migration 20260702120000_rename_pages_to_contents` →
     `All migrations have been successfully applied.`

3. **Validar hml** (com o `DATABASE_URL` de hml, do ambiente — nunca no repo):
   ```bash
   psql "$DATABASE_URL_HML" -f backend/prisma/validate_migration.sql
   ```
   Confira: `total_contents` bate com o `count(pages)` do passo 1; todos os
   contadores de invariante = 0; `legacy_uuid_ids` bate com o backup; a mensagem
   final `VALIDACAO OK`. O script **aborta com exit != 0** se qualquer invariante
   falhar.

4. **Só com hml validado: prod.** Garanta o baseline resolvido em prod, publique
   o `release/*` → `main` (skill `publicar-release`). O auto-deploy em prod roda
   `migrate deploy` sozinho. Repita a validação com o `DATABASE_URL` de prod.

### Rollback (a migração é irreversível — restaura-se o backup)

Não há "down migration": `screen_target` foi dropada e o JSONB reescrito. Se a
validação falhar:

1. No Coolify, **pare o deploy/serviço do backend** do ambiente afetado (evita
   escrita nova sobre o estado migrado).
2. Restaure o backup daquele ambiente:
   ```bash
   # Recria o banco a partir do dump (destino limpo).
   pg_restore --clean --if-exists -d "$DATABASE_URL_<AMB>" backup_<amb>_pre_conteudos_<ts>.dump
   ```
3. Reverta o merge que disparou o deploy (`git revert` do merge em `develop`/`main`)
   para a imagem voltar ao backend antigo (`/v1/pages`), **ou** faça o redeploy da
   imagem anterior no Coolify.
4. Após restaurar, o `_prisma_migrations` volta ao estado do backup (a migração
   de rename deixa de constar como aplicada) — reavaliar a causa antes de tentar
   de novo.

### Segurança

- **Nenhum segredo/URL de banco no repositório.** `DATABASE_URL`, `PORT`,
  `CORS_ORIGINS` vêm do ambiente (Coolify). O `validate_migration.sql` e as
  migrations recebem a conexão por `$DATABASE_URL`; os comandos acima usam
  variáveis de ambiente, não literais.

---

## Evidência da cancela local (Postgres docker descartável)

Executado contra um container **efêmero e isolado** (tmpfs, sem volume
persistente; `driva-postgres`/`driva-pgdata` **não** foram tocados). Semeada a
tabela `pages` no formato antigo, incluindo colisão (`Home` + `home`),
sanitização (`Promoções 2026`) e um segundo projeto (`acme`).

Resultado de `prisma migrate deploy`:

| id (UUID legado)        | project_id | slug             | kind    | tem screenTarget |
|-------------------------|------------|------------------|---------|------------------|
| aaaa… (Home)            | default    | `home`           | content | não              |
| bbbb… (home)            | default    | `home-2`         | content | não              |
| cccc… (Promoções 2026)  | default    | `promocoes-2026` | content | não              |
| dddd… (Sobre)           | default    | `sobre`          | content | não              |
| eeee… (Home)            | acme       | `home`           | content | não              |

- **Dedupe por projeto:** `home` / `home-2` (colisão resolvida); `home` coexiste
  em `acme` (unique é por `project_id`).
- **Sanitização:** `Promoções 2026` → `promocoes-2026` (acento dobrado, espaço → hífen).
- **JSONB reescrito:** `kind:"content"`, `slug` no envelope, **sem** `screenTarget`.
- **UUID preservado:** `legacy_uuid_ids = 5`.
- **Unique ativa:** inserir `slug` duplicado no mesmo projeto → erro
  `duplicate key value violates unique constraint "contents_project_id_slug_key"`;
  mesmo slug em projeto diferente → sucesso.
- **Idempotência:** rodar o backfill 2x produziu snapshots MD5 idênticos
  (guard `WHERE slug IS NULL` torna a 2ª execução um no-op).
- **Sem drift:** `migrate diff` das migrations vs. `schema.prisma` = "empty migration".
- `pnpm build` verde.
