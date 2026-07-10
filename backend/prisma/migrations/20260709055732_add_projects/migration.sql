-- Projeto vira o novo topo da hierarquia (Projeto -> Categorias -> Conteudos).
--
-- Ordem CRITICA (banco recriado do zero, sem backfill de dados legados):
-- 1) CREATE TABLE "projects" (sem isso nao ha onde inserir o seed);
-- 2) SEED do Project "default" ANTES da FK NOT NULL ser exigida em "contents"
--    -- se a FK entrasse primeiro e ja houvesse alguma linha em "contents"
--    apontando para "default", a constraint falharia por FK orfa;
-- 3) DROP DEFAULT de "contents.project_id" (deixa de ser string livre) e
--    ADD CONSTRAINT da FK com onDelete: Restrict (Decisao 1 do prd.md -- nao
--    se apaga projeto com conteudos).
--
-- Seed em SQL puro (nao script TS) pelo mesmo racional da migration de rename
-- (`20260702120000_rename_pages_to_contents`): `prisma migrate deploy` aplica
-- todas as migrations pendentes ANTES de qualquer codigo da app rodar, entao
-- um seed TS "no meio" nao teria como se intercalar num deploy automatico.
-- `ON CONFLICT DO NOTHING` mantem o bloco idempotente (reexecucao segura).

-- CreateTable
CREATE TABLE "projects" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "image_key" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "projects_pkey" PRIMARY KEY ("id")
);

-- Seed: Project "default" -- mantem `x-project-id=default` resolvendo e
-- garante que nenhum Content (existente ou por vir nesta transacao) fica com
-- FK orfa. Decisao 2 do prd.md (default provisorio, a confirmar com o
-- humano); a UX de mostrar/esconder este projeto na home e do frontend.
INSERT INTO "projects" ("id", "title", "description", "image_key", "created_at", "updated_at")
VALUES ('default', 'Projeto Padrão', NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;

-- AlterTable: project_id deixa de ter default -- toda criacao de Content
-- passa a exigir um Project real (via x-project-id ja resolvido no backend).
ALTER TABLE "contents" ALTER COLUMN "project_id" DROP DEFAULT;

-- AddForeignKey: Decisao 1 do prd.md -- Restrict, nao Cascade. Apagar um
-- projeto com conteudos falha (traduzido para 409 no service, F2), o usuario
-- esvazia antes.
ALTER TABLE "contents" ADD CONSTRAINT "contents_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "projects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
