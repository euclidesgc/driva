# Test Plan — Conteúdos

> Documento vivo. A bateria automatizada completa (unit/widget/golden/backend) é
> escrita na **Fase 6**, após o E2E manual. Este documento cobre: (1) o **E2E
> manual da Fase 6** — o caminho feliz e os casos de borda que o dev executa no
> editor; e (2) o **roteiro OPS da Fase 5** — a migração destrutiva `pages` →
> `contents` que o dev executa contra hml/prod.

---

## Fase 6 — E2E (script automatiza o backend; só o visual é manual)

> **Instrumentação temporária: NENHUMA mudança de código.** O único "instrumento"
> é o script `e2e.sh`, e todo o rastro dele é auto-removível (ver `e2e.sh down`).
> O fluxo de UI é observável direto na tela + logs de estado do `AppBlocObserver`.

### Parte automatizada — `docs/02-conteudos/e2e.sh`

Um comando sobe a stack local e valida **todo o contrato do backend** por API:

```bash
docs/02-conteudos/e2e.sh          # sobe Postgres de teste efêmero + backend, valida /v1/contents
docs/02-conteudos/e2e.sh down     # encerra o backend e destrói o Postgres de teste
```

O script é **determinístico e idempotente** (recria um Postgres de teste limpo a
cada run via `docker compose down -v`, então o schema nasce do zero — sem ação
destrutiva de Prisma) e valida, com `PASS/FAIL` explícito:

- `POST` cria (201), `id` novo é **CUID2**, `slug` ecoado;
- envelope do `spec`: `kind:"content"`, `slug`, `spec.id` = id do registro, `root` column, **sem `screenTarget`**;
- slug repetido no projeto → **`409`** com `suggestedSlug` (`home-2`);
- mesmo slug em **outro projeto** coexiste;
- slug fora de `^[a-z][a-z0-9-]*$` → **400**;
- `PUT` (200), `GET` lista, `DELETE` (204), `GET` após delete → **404**.

**Rastro (tudo removível):** processo do backend (`.e2e-backend.pid`), log
(`.e2e-backend.log`) e o container/volume `driva-postgres` — todos encerrados por
`e2e.sh down`. Nenhum arquivo de código é tocado.

### Parte manual — só o que a API não enxerga (visual da UI)

Com a stack no ar (após o script), rode o editor e confirme na tela (projeto
`default`, lista começa vazia). Salve prints em `docs/02-conteudos/evidencias/`:

```bash
flutter run -d chrome --target apps/driva_editor/lib/main_dev.dart \
  --dart-define-from-file=apps/driva_editor/config/dev.json
```

1. A URL abre em `/contents` **sem `#`** (path strategy). → *print 1*
2. Em "Novo conteúdo", digitar o **Nome deriva o Slug ao vivo** no campo. → *print 2*
3. O card mostra o **slug em destaque** + o **"ID de suporte"** (CUID2). → *print 3*
4. Criar dois `Home`: o 2º **reabre o diálogo com `home-2`** e a msg de slug em uso. → *print 4*
5. Arrastar um widget → preview renderiza; **Ctrl+S** → "Salvo"; **F5** mantém. → *print 5*
6. Acessar `/contents/nao-existe/edit` → **tela de NotFound tratada**, sem crash. → *print 6*

**Critério de passagem:** `e2e.sh` verde (contrato do backend) **e** os 6 pontos
visuais confirmados sem erro não-tratado no console. Ao terminar: `e2e.sh down`.

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
