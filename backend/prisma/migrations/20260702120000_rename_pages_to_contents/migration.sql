-- Rename destrutivo `pages` -> `contents` (Fase 5 · Conteudos).
--
-- Ordem EXPAND -> BACKFILL -> CONSTRAIN -> CONTRACT. O porque da ordem: o slug
-- e semeado A PARTIR de `screen_target`, entao a coluna-fonte so pode ser
-- dropada no fim (CONTRACT); e a UNIQUE/NOT NULL so entram DEPOIS do backfill
-- deduplicado (aplicar antes violaria com slug NULL/colidido).
--
-- Backfill em SQL puro (nao script TS) de proposito: `prisma migrate deploy`
-- aplica TODAS as migrations pendentes ANTES de qualquer codigo da app rodar,
-- logo um passo TS "no meio" nao tem como se intercalar num deploy automatico.
-- Manter expand+backfill+constrain+contract numa unica migration garante a
-- ordem e roda tudo numa unica transacao (tudo-ou-nada) no deploy. A
-- transformacao de acento usa `translate` (sem extensao `unaccent`, que exige
-- privilegio que o Postgres gerenciado do Coolify pode nao conceder).
-- Idempotencia: o `_prisma_migrations` garante execucao unica; alem disso o
-- backfill so toca linhas com `slug IS NULL`, entao reexecutar o bloco e no-op.

-- EXPAND: colunas novas NULLABLE (a fonte `screen_target` segue viva).
ALTER TABLE "pages" ADD COLUMN "slug" TEXT;
ALTER TABLE "pages" ADD COLUMN "description" TEXT;

-- Slugify deterministico: minusculas, dobra de acentos PT-BR via translate,
-- nao-alfanumerico -> hifen, apara hifens das bordas, garante inicio [a-z].
CREATE OR REPLACE FUNCTION pg_temp.content_slugify(input TEXT) RETURNS TEXT AS $slug$
  SELECT
    CASE
      WHEN s = '' THEN 'content'
      WHEN s ~ '^[a-z]' THEN s
      ELSE 'c-' || s
    END
  FROM (
    SELECT trim(BOTH '-' FROM
      regexp_replace(
        translate(
          lower(COALESCE(input, '')),
          'áàâãäéèêëíìïîóòôõöúùûüçñ',
          'aaaaaeeeeiiiiooooouuuucn'
        ),
        '[^a-z0-9]+', '-', 'g'
      )
    ) AS s
  ) folded;
$slug$ LANGUAGE SQL IMMUTABLE;

-- BACKFILL: por registro (ordem deterministica), semeia slug livre no projeto
-- (base, base-2, base-3...) espelhando o `freeSlug` do backend, e reescreve o
-- envelope JSONB (kind:"content", slug; remove screenTarget). `id` UUID legado
-- fica INTACTO (nunca e tocado). So processa linhas ainda NULL -> idempotente.
DO $backfill$
DECLARE
  row_record  RECORD;
  base_slug   TEXT;
  free_slug   TEXT;
  suffix      INT;
BEGIN
  FOR row_record IN
    SELECT "id", "project_id", "screen_target"
    FROM "pages"
    WHERE "slug" IS NULL
    ORDER BY "project_id", "created_at", "id"
  LOOP
    base_slug := pg_temp.content_slugify(row_record."screen_target");
    free_slug := base_slug;
    suffix := 2;
    WHILE EXISTS (
      SELECT 1 FROM "pages"
      WHERE "project_id" = row_record."project_id" AND "slug" = free_slug
    ) LOOP
      free_slug := base_slug || '-' || suffix;
      suffix := suffix + 1;
    END LOOP;

    UPDATE "pages"
    SET
      "slug" = free_slug,
      "spec" = ("spec" - 'screenTarget')
        || jsonb_build_object('kind', 'content', 'slug', free_slug)
    WHERE "id" = row_record."id";
  END LOOP;
END
$backfill$;

-- CONSTRAIN: agora que todo registro tem slug unico por projeto.
ALTER TABLE "pages" ALTER COLUMN "slug" SET NOT NULL;
CREATE UNIQUE INDEX "contents_project_id_slug_key" ON "pages"("project_id", "slug");

-- CONTRACT: dropa a fonte e adota a forma final `contents` (nomes que o Prisma
-- espera do schema atual, para nao gerar drift num futuro `migrate dev`).
ALTER TABLE "pages" DROP COLUMN "screen_target";
ALTER TABLE "pages" RENAME TO "contents";
ALTER INDEX "pages_project_id_idx" RENAME TO "contents_project_id_idx";
ALTER TABLE "contents" RENAME CONSTRAINT "pages_pkey" TO "contents_pkey";
