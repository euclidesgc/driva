# final_report.md — CRUD de Projeto (docs/09)

> Relatório de fechamento da feature. Fonte da verdade do "pronto": `prd.md` + `plan.md`
> (aprovados) e o gate do CISO. Branch: `feature/api-conteudos` (a 09 empilhou com o item 10
> — ver `docs/08-api-conteudos-filtro-busca/`).

## O que foi entregue

`Project` nasce como **topo da hierarquia** do produto (Projeto → Categoria → Conteúdo),
inspirado no Squidex. A feature entrega:

- **Backend `/v1/projects`** — CRUD completo (list/get/create/update/delete) com **upload de
  imagem** por multipart e serving seguro.
- **`StorageService`** — port de armazenamento com adapter local (default de dev) e adapter S3
  codado e pronto, ativado por env.
- **`Content.projectId` vira FK real** (`onDelete: Restrict`) com seed do projeto `default`;
  banco de dev recriado do zero (sem backfill).
- **Editor `projects_module`** — Clean Architecture completa (domain/data/presentation): home
  com cards de projeto, formulário criar/editar com drag-and-drop de imagem, exclusão com
  confirmação e 409 amigável. A rota raiz `/` passa a ser a home de Projetos.

## Contrato final `/v1/projects`

| Método | Rota | Resposta |
|---|---|---|
| `GET` | `/v1/projects` | `200` lista de resumos: `id, title, description?, imageUrl, createdAt, updatedAt, contentCount, categoryCount` |
| `GET` | `/v1/projects/:id` | `200` detalhe · `404` inexistente |
| `POST` | `/v1/projects` | `201` (multipart: `title`, `description?`, `image?`) · `400` inválido/imagem rejeitada · `413` oversize |
| `PUT` | `/v1/projects/:id` | `200` (campos opcionais + `removeImage`) · `404` · `400`/`413` |
| `DELETE` | `/v1/projects/:id` | `204` vazio · `409` com filhos (`Restrict`) · `404` |
| `GET` | `/v1/projects/:id/image` | imagem com content-type detectado + `X-Content-Type-Options: nosniff` |

`imageUrl` é `null` quando o projeto não tem imagem. `contentCount`/`categoryCount` vêm do
`_count` do Prisma (adendo do item 10 — ver VR na seção de variâncias).

## Arquitetura / decisões

- **Pipeline de upload (não-negociável do CISO):** detecção por **magic bytes** (allowlist
  fechada PNG/JPEG/WebP; **SVG rejeitado**), reencode com `sharp` (strip EXIF, teto de
  dimensão anti decompression-bomb), **chave UUID gerada no servidor** (nunca o filename do
  cliente), serving com `nosniff`, limite de body em duas camadas e rate-limit no upload.
- **Storage atrás de port** — troca local↔S3 por `STORAGE_DRIVER` sem tocar no service.
- **`onDelete: Restrict`** — apagar projeto com filhos é `409` traduzido (P2003), nunca 500.
- **Editor:** entidade `Project` única (sem split summary/detail); `imageBytes` (`List<int>`)
  é o transporte no contrato do domain (mantém domain sem `dart:io`); a `data` monta o
  `MultipartFile`. Import condicional web/VM para o drag-and-drop.

## Variâncias

Registradas em `variance_report.md`:

- **VR-01** — `GET /v1/projects` inclui `createdAt` (a lista e o detalhe passaram a ter a
  mesma forma; refinamento técnico de contrato, reversível).
- **Adendo de contadores (item 10 / P3)** — `contentCount`/`categoryCount` via `_count`
  entram no contrato de lista da 09 (aditivo, não-breaking).

## Gate CISO

**APROVADO com follow-up.** O pipeline de upload foi auditado: magic bytes próprios
não-burláveis, reencode `sharp`, chave UUID de servidor, `nosniff`, limite em duas camadas,
rate-limit; `pnpm audit` limpo (`multer` forçado a `^2.2.0` via overrides). Follow-up
não-bloqueante: o débito **sem-auth** cresceu com o CRUD de Projeto (ver Débitos).

## Evidência E2E

`docs/09-crud-projeto/evidencias/e2e_api.sh` — script idempotente e auto-limpante do contrato
por API do fluxo inteiro Projetos/Categorias/Conteúdos.

- **Rodada 01:** `59 PASS / 0 FAIL`, cleanup total (DB volta ao estado inicial). Evidência em
  `evidencias/rodada_01/resultado.txt`.
- Cobre: CRUD de projeto; upload válido (PNG) e inválido (SVG→400, magic bytes forjados→400,
  oversize→413); serving com `nosniff` + content-type; contadores nos cards; DELETE com filhos
  (`409`) e DELETE de projeto realmente vazio (`204`).

## Débitos conhecidos

1. **Sem-auth ampliado** — o escopo de tenant vem do header `x-project-id`, controlável pelo
   cliente. Com o CRUD de Projeto a superfície cresceu: um `x-project-id` forjado alcança
   operações **destrutivas e de upload**. Enquanto não houver auth real, o CRUD de projetos é
   efetivamente global. **Implementar auth antes de expor em produção real ou ligar S3.**
2. **Storage S3 a ligar** — adapter codado e pronto, mas não habilitado em hml/prod; falta a
   decisão de infra (Garage vs R2 + creds por env no Coolify). Dev roda 100% no adapter local.
3. **DELETE de projeto na prática** — como todo projeto nasce com a categoria "Geral"
   (`onDelete: Restrict`), não há caminho de API que deixe um projeto categoria-vazio no fluxo
   feliz; apagar de fato exige esvaziar e remover a "Geral" antes. Comportamento **intencional**
   (registrado no resultado do E2E), não bug.
