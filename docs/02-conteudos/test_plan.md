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

### Parte visual automatizada — `docs/02-conteudos/e2e_shots.sh` (o QA gera TODOS os prints)

Com a stack no ar (após o `e2e.sh`), o QA captura **todo o visual** por screenshot
**headless** — o dev humano só **confere** as imagens, nunca opera o browser:

```bash
docs/02-conteudos/e2e.sh            # sobe a stack (Postgres efêmero + backend)
docs/02-conteudos/e2e_shots.sh 04   # gera os 8 prints em evidencias/rodada_04/
docs/02-conteudos/e2e.sh down
```

Gera, em `evidencias/rodada_MM/`:

| # | print | estado |
|---|---|---|
| 01 | `01_lista_vazia` | lista vazia (`/contents`, sem `#`) |
| 02 | `02_lista_com_conteudos` | cards com slug em destaque + "ID de suporte" |
| 03 | `03_editor_carregado` | editor de um conteúdo real (paleta, inspector) |
| 04 | `04_notfound` | `/contents/nao-existe/edit` → NotFound tratado |
| 05 | `05_slug_ao_vivo` | diálogo "Novo conteúdo": Nome → **slug derivado ao vivo** |
| 06 | `06_colisao_home2` | slug repetido → resolve p/ **`home-2`** (ver achado abaixo) |
| 07 | `07_drag_preview` | **drag-drop** da paleta → preview renderiza |
| 08 | `08_salvo` | após **Salvar** → estado "Salvo" |

Como funciona: **build web (dev)** → semeia `default` via API → serve o `build/web`
(SPA fallback p/ deep links) → **01-04** por URL (`--screenshot`) e **05-08** dirigindo
o canvas por **CDP** (`e2e_drive.mjs`, sem dependências: WebSocket/fetch nativos do
Node). As coordenadas de clique/drag são acopladas ao layout **1366×900** — se a UI se
mover, ajuste em `e2e_drive.mjs`.

> **Ícones "tofu" (□) — CAUSA RAIZ (resolvida em `web/flutter_bootstrap.js`).**
> No Chrome/Chromium com GPU, o Flutter auto-seleciona a variante **`chromium`** do
> CanvasKit (`flutter.js`: `s = hasChromiumBreakIterators && hasImageCodecs && variant!=="full"`
> → carrega `/chromium/canvaskit`). Essa variante usa APIs experimentais e, em alguns
> drivers, **falha ao registrar a fonte de ícones OTF** (`MaterialIcons`, que é OTF; as
> fontes de texto são TTF e passam). Os ícones viram "caracteres sem fonte" e o console
> loga *"Could not find a set of Noto fonts to display all missing characters"*.
> **Fix aplicado:** `web/flutter_bootstrap.js` força `canvasKitVariant: "full"` (variante
> portável) — pega em `flutter run` (debug) e no build. Não era cache/SW nem bug de
> código; era a seleção de variante do CanvasKit. Se reaparecer, confira se o
> `flutter_bootstrap.js` custom ainda existe e traz `canvasKitVariant: "full"`.

### Colisão de slug — comportamento (aceito pelo dev em 2026-07-03)

Ao submeter um `Nome` cujo slug já existe no projeto, o app **fecha o diálogo, cria
automaticamente com o slug ajustado (`home-2`) e abre o editor** (print
`06_colisao_home2`). Bate com o PRD (§ Exceções): *"Backend `409` → editor mostra o
slug ajustado sugerido e explica"*. O contrato é: backend devolve `409 + suggestedSlug`
(coberto pelo `e2e.sh`), o cliente **auto-resolve** para o sugerido. **Este é o UX
desejado** (menos fricção — o dev o confirmou; a descrição antiga "reabre o diálogo com
aviso" era do test_plan, não do PRD, e foi corrigida). *Obs.: a explicação "slug já em
uso" prevista no PRD é um aviso transitório — não aparece no print estático; confirmar
que está sendo exibida é item de conferência do dev.*

### Parte manual — nada além de conferir

Todos os 8 estados saem prontos do `e2e_shots.sh`. Ao dev sobra **conferir as imagens**
e o console (sem erro não-tratado). Só volte ao modo manual se mudar a UI a ponto de
as coordenadas do `e2e_drive.mjs` saírem do lugar (aí ajuste-as e regenere).

**Critério de passagem:** `e2e.sh` verde (contrato) **+** os 8 prints do `e2e_shots.sh`
conferidos. Ao terminar: `e2e.sh down`.

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
