-- Category nasce como o nível intermediário da hierarquia
-- (Projeto -> Categorias -> Conteudos). Toda categoria vive dentro de um
-- Project (`onDelete: Restrict` -- nao se apaga projeto com categorias);
-- arvore por auto-relacao `parent_id` (`onDelete: SetNull` -- apagar um pai
-- zera o parentId dos filhos, a subarvore nao cascateia exclusao).
--
-- Ordem CRITICA (banco recriado do zero, mesmo racional da migration da 09
-- `20260709055732_add_projects`):
-- 1) CREATE TABLE "categories" (sem isso nao ha onde inserir o seed);
-- 2) SEED da categoria raiz "Geral" -- uma por projeto ja existente (o
--    projeto `default` da 09 e qualquer outro projeto criado antes desta
--    migration) -- ANTES da FK NOT NULL ser exigida em "contents";
-- 3) BACKFILL de "contents.category_id" para a "Geral" do respectivo projeto
--    e de "contents.name_normalized" (lowercase + sem acento, replicando em
--    SQL puro a normalizacao que o Node passa a fazer na escrita dai em
--    diante) -- cobre linhas de dev que ja existam neste banco descartavel;
-- 4) so entao DROP DEFAULT / SET NOT NULL das colunas novas e ADD as FKs
--    (Restrict em Content->Category, Decisao 2 do prd.md).
--
-- Seed/backfill em SQL puro (nao script TS), mesmo racional das migrations
-- anteriores: `prisma migrate deploy` aplica todas as migrations pendentes
-- ANTES de qualquer codigo da app rodar. `ON CONFLICT DO NOTHING` mantem o
-- bloco idempotente (reexecucao segura).

-- CreateTable
CREATE TABLE "categories" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "parent_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey (Category -> Project) -- antes do seed, a tabela ja referencia
-- "projects" corretamente.
ALTER TABLE "categories" ADD CONSTRAINT "categories_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "projects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey (Category -> parent Category)
ALTER TABLE "categories" ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "categories_project_id_parent_id_idx" ON "categories"("project_id", "parent_id");

-- CreateIndex
CREATE UNIQUE INDEX "categories_project_id_slug_key" ON "categories"("project_id", "slug");

-- Seed: categoria raiz "Geral" por projeto ja existente. Cobre o projeto
-- `default` (seed da 09) e qualquer projeto de dev criado antes desta
-- migration. Projetos criados em runtime dai em diante ganham a sua "Geral"
-- no `ProjectsService.create`, na mesma `$transaction` (adendo pos-feature-09
-- do prd.md, item 3).
INSERT INTO "categories" ("id", "project_id", "name", "slug", "parent_id", "created_at", "updated_at")
SELECT
    'cat_geral_' || p."id",
    p."id",
    'Geral',
    'geral',
    NULL,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM "projects" p
ON CONFLICT ("project_id", "slug") DO NOTHING;

-- AlterTable: novas colunas em "contents", sem NOT NULL ainda -- o backfill
-- abaixo precisa de uma janela para preencher as linhas existentes antes da
-- constraint entrar em vigor.
ALTER TABLE "contents" ADD COLUMN "category_id" TEXT;
ALTER TABLE "contents" ADD COLUMN "name_normalized" TEXT;

-- Backfill: todo conteudo existente cai na "Geral" do seu proprio projeto.
UPDATE "contents" c
SET "category_id" = cat."id"
FROM "categories" cat
WHERE cat."project_id" = c."project_id"
  AND cat."slug" = 'geral'
  AND c."category_id" IS NULL;

-- Backfill de name_normalized: lowercase + sem acento (unaccent via
-- translate, sem depender de extensao Postgres -- Decisao 6 do prd.md).
-- Cobre o conjunto usual de vogais acentuadas/cedilha do pt-BR; a
-- normalizacao "de verdade" dai em diante e feita em Node na escrita.
UPDATE "contents"
SET "name_normalized" = lower(
    translate(
        "name",
        'ÁÀÂÃÄáàâãäÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÕÖóòôõöÚÙÛÜúùûüÇç',
        'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCc'
    )
)
WHERE "name_normalized" IS NULL;

-- AlterTable: agora que todo conteudo tem categoria/nome normalizado, as
-- colunas passam a NOT NULL.
ALTER TABLE "contents" ALTER COLUMN "category_id" SET NOT NULL;
ALTER TABLE "contents" ALTER COLUMN "name_normalized" SET NOT NULL;

-- AddForeignKey (Content -> Category): Restrict, nao Cascade -- nao se apaga
-- categoria com conteudos (Decisao 2 do prd.md); o usuario move/apaga os
-- conteudos antes (UX do item 14).
ALTER TABLE "contents" ADD CONSTRAINT "contents_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- CreateIndex: cobre a ordenacao default de GET /v1/contents (updatedAt desc,
-- id como desempate estavel do keyset cursor).
CREATE INDEX "contents_project_id_updated_at_id_idx" ON "contents"("project_id", "updated_at" DESC, "id");
