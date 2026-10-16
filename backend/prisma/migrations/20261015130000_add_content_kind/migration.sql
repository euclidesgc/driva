ALTER TABLE "contents" ADD COLUMN "kind" TEXT NOT NULL DEFAULT 'content';

CREATE INDEX "contents_project_id_kind_updated_at_id_idx" ON "contents"("project_id", "kind", "updated_at" DESC, "id");
