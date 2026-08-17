-- Rascunho x publicado: renomeia a coluna existente (nunca perde specs já
-- salvos) e cria o histórico de versões imutáveis. Sem backfill (D2): nada
-- estava marcado como publicado antes desta feature, então
-- published_version_id/published_at nascem NULL para todo conteúdo
-- existente — passam a "nunca publicado" até alguém publicar de fato.

ALTER TABLE "contents" RENAME COLUMN "spec" TO "draft_spec";

ALTER TABLE "contents" ADD COLUMN "draft_updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "contents" ADD COLUMN "published_version_id" TEXT;
ALTER TABLE "contents" ADD COLUMN "published_at" TIMESTAMP(3);

CREATE TABLE "content_versions" (
    "id" TEXT NOT NULL,
    "content_id" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "spec" JSONB NOT NULL,
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,

    CONSTRAINT "content_versions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "content_versions_content_id_version_key" ON "content_versions"("content_id", "version");

CREATE INDEX "content_versions_content_id_version_idx" ON "content_versions"("content_id", "version" DESC);

ALTER TABLE "content_versions" ADD CONSTRAINT "content_versions_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- schema.prisma declara draftUpdatedAt sem @default: o DEFAULT acima só
-- existiu para preencher as linhas já existentes nesta migração.
ALTER TABLE "contents" ALTER COLUMN "draft_updated_at" DROP DEFAULT;
