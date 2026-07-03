-- Baseline: reflete o estado JÁ DEPLOYADO (criado por `db push` a partir do
-- schema antigo `model Page`). Em prod/hml esta migration NÃO roda: é marcada
-- como aplicada com `prisma migrate resolve --applied 0_baseline`, adotando o
-- histórico sem re-executar SQL sobre a tabela `pages` existente. Em bancos
-- novos (local/CI) ela roda e recria exatamente esse estado de partida.

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "pages" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL DEFAULT 'default',
    "name" TEXT NOT NULL,
    "screen_target" TEXT NOT NULL,
    "spec" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "pages_project_id_idx" ON "pages"("project_id");
