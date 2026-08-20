-- Ponto de trabalho marcado pelo autor ao salvar — o "commit" do editor.
-- Tabela própria, e não uma espécie de content_versions: `version` é o número
-- que o usuário lê como "no ar (v3)" e que a API pública serve, então
-- checkpoints não podem consumi-lo nem deixá-lo nulo.
CREATE TABLE "content_checkpoints" (
    "id" TEXT NOT NULL,
    "content_id" TEXT NOT NULL,
    "spec" JSONB NOT NULL,
    "note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,

    CONSTRAINT "content_checkpoints_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "content_checkpoints_content_id_created_at_idx" ON "content_checkpoints"("content_id", "created_at" DESC);

ALTER TABLE "content_checkpoints" ADD CONSTRAINT "content_checkpoints_content_id_fkey" FOREIGN KEY ("content_id") REFERENCES "contents"("id") ON DELETE CASCADE ON UPDATE CASCADE;
