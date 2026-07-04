-- Baseline: reflete o estado JÁ DEPLOYADO (criado por `db push` a partir do
-- schema antigo `model Page`). O caminho recomendado em prod/hml é marcá-la
-- como aplicada com `prisma migrate resolve --applied 0_baseline`, adotando o
-- histórico sem re-executar SQL. Ainda assim, todo comando aqui é idempotente
-- (`IF NOT EXISTS`): se o operador esquecer o resolve, a baseline roda como
-- no-op seguro sobre a tabela `pages` existente e o deploy segue para o rename.
-- Em bancos novos (local/CI) ela cria exatamente esse estado de partida.

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE IF NOT EXISTS "pages" (
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
CREATE INDEX IF NOT EXISTS "pages_project_id_idx" ON "pages"("project_id");
