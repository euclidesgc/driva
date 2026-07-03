-- Validacao pos-migracao `pages` -> `contents` (Fase 5 · Conteudos).
-- Rodar contra o banco JA migrado:  psql "$DATABASE_URL" -f prisma/validate_migration.sql
-- (o DATABASE_URL vem do ambiente; NUNCA versionar segredo/URL no repo).
--
-- Reporta metricas e ABORTA (exit != 0) se qualquer invariante for violada.
-- OPS compara o total abaixo com a contagem de `pages` do backup PRE-migracao
-- (devem bater: a migracao nao cria nem apaga linhas).

\echo '== Total de conteudos (comparar com count(pages) do backup pre-migracao) =='
SELECT count(*) AS total_contents FROM "contents";

\echo '== ids UUID legados preservados (informativo; comparar com o backup) =='
SELECT count(*) AS legacy_uuid_ids
FROM "contents"
WHERE "id" ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

\echo '== Amostra (10) =='
SELECT "id", "project_id", "slug", "spec"->>'kind' AS kind
FROM "contents"
ORDER BY "created_at"
LIMIT 10;

DO $validate$
DECLARE
  bad_slug_format   BIGINT;
  dup_slug          BIGINT;
  has_screen_target BIGINT;
  kind_not_content  BIGINT;
  slug_mismatch     BIGINT;
  root_not_column   BIGINT;
BEGIN
  SELECT count(*) INTO bad_slug_format
  FROM "contents" WHERE "slug" !~ '^[a-z][a-z0-9-]*$';

  SELECT COALESCE(sum(c), 0) INTO dup_slug FROM (
    SELECT count(*) - 1 AS c
    FROM "contents" GROUP BY "project_id", "slug" HAVING count(*) > 1
  ) d;

  SELECT count(*) INTO has_screen_target
  FROM "contents" WHERE "spec" ? 'screenTarget';

  SELECT count(*) INTO kind_not_content
  FROM "contents" WHERE "spec"->>'kind' IS DISTINCT FROM 'content';

  SELECT count(*) INTO slug_mismatch
  FROM "contents" WHERE "spec"->>'slug' IS DISTINCT FROM "slug";

  SELECT count(*) INTO root_not_column
  FROM "contents" WHERE "spec"->'root'->>'type' IS DISTINCT FROM 'column';

  RAISE NOTICE 'slug fora do padrao ^[a-z][a-z0-9-]*$ : %', bad_slug_format;
  RAISE NOTICE 'slugs duplicados por projeto            : %', dup_slug;
  RAISE NOTICE 'spec ainda com screenTarget             : %', has_screen_target;
  RAISE NOTICE 'spec com kind != content                : %', kind_not_content;
  RAISE NOTICE 'spec.slug divergente da coluna slug      : %', slug_mismatch;
  RAISE NOTICE 'spec.root.type != column                : %', root_not_column;

  IF bad_slug_format > 0 OR dup_slug > 0 OR has_screen_target > 0
     OR kind_not_content > 0 OR slug_mismatch > 0 OR root_not_column > 0 THEN
    RAISE EXCEPTION 'VALIDACAO FALHOU: ver contadores acima (nao promover para prod).';
  END IF;

  RAISE NOTICE 'VALIDACAO OK: todos os invariantes passaram.';
END
$validate$;
