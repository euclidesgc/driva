-- Chave publicável por projeto: o app do cliente a embarca para ler conteúdo
-- publicado. Projetos existentes recebem uma chave gerada no próprio banco.
ALTER TABLE "projects" ADD COLUMN "publishable_key" TEXT;

UPDATE "projects"
SET "publishable_key" = 'pk_' || replace(gen_random_uuid()::text, '-', '')
                              || replace(gen_random_uuid()::text, '-', '')
WHERE "publishable_key" IS NULL;

ALTER TABLE "projects" ALTER COLUMN "publishable_key" SET NOT NULL;

CREATE UNIQUE INDEX "projects_publishable_key_key" ON "projects"("publishable_key");
