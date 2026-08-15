# Plano — Loop SDUI fechado

_Fatia do item 25 do roadmap. Base: `docs/plans/25-entrega-app-cliente/plan.md`;
os desvios estão em `variance_report.md`._

## F1 — API pública de consumo (backend)

- `Project.publishableKey` (`pk_` + 32 bytes base64url), gerada na criação;
  migration preenche os projetos existentes com uma chave por linha antes de
  aplicar o `NOT NULL` + índice único.
- `backend/src/public/` — módulo próprio (`PublicController`, `PublicService`),
  fora do CRUD do editor.
- Header `x-driva-key` resolve o projeto; chave ausente/inválida/de projeto
  arquivado → `404` genérico (não revela existência).
- ETag de `id` + `updatedAt.getTime()`; `304` quando `If-None-Match` casa.
- CORS aberto **só** em `/v1/public`, via middleware no `main.ts` (preflight
  `OPTIONS` → `204`), com `x-driva-key` nos `allowedHeaders`.

Aceite: `evidencias/e2e_public.sh` — contrato completo, auto-limpante, roda
contra qualquer ambiente.

## F2 — App de demonstração (`apps/driva_demo_app`)

Clean Architecture por módulo, como o editor:

- `domain` — `PublishedSummary`, `PublishedContent` (embrulha o `ContentSpec` do
  kernel + `updatedAt` + `etag`), contrato `PublishedRepository`, dois use cases.
- `data` — `PublishedListModel` / `PublishedSummaryModel` /
  `PublishedContentModel` validam o **envelope da API** com zard; o `spec` é
  validado por `parseContentSpec` (o kernel segue o único portão de entrada de
  spec). `PublishedRepositoryImpl` é o único lugar com `try/catch`.
- `presentation` — `CatalogCubit` e `ContentCubit` com estado `sealed`, páginas
  `StatelessWidget` com `static pageBuilder` (único ponto que toca o get_it),
  widgets de view por arquivo.
- `core` — config por flavor, `Failure` sealed, Dio com o header da chave,
  tokens de tema, observer.

Fixtures: `evidencias/vitrine_spec.json` + `evidencias/seed_vitrine.sh`
(idempotente). `tool/run_demo.sh` descobre a chave na API e sobe o app.

## F3 — Relatório do consumo

`final_report.md` › _O que o consumo real revelou_.

## Riscos assumidos

- **Serve rascunho, não versão publicada** (VR-13-01) — o item 24 é precedência
  formal e não foi feito. Não abrir para cliente real antes dele.
- **Chave sem rotação nem rate limit** (VR-13-03, VR-13-04).
- A chave é pública por natureza: quem a tiver lê todo conteúdo do projeto.
  É o modelo previsto no plano (como chave publicável de gateway de pagamento),
  mas só é seguro quando existir a separação rascunho × publicado.
