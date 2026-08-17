# plan.md — Item 24: Publicação e versionamento do conteúdo

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 5.
> Regra do "pronto": **`flutter analyze` verde + `pnpm build` (backend) verde + testes existentes passando**.
> Escopo: `backend/` (schema + migração + API) e `apps/driva_editor` (data/domain/presentation do editor). **Gate CISO obrigatório** — nasce endpoint de escrita novo e o conceito de "no ar".

## 1. Objetivo e recorte

Hoje o botão do topo é literalmente um placeholder: `AppBarAction.outlined(label: 'Publish', tooltip: 'Publicação chega no incremento I4')` — sem `onPressed`. E o modelo tem **um** campo `spec`: **salvar é publicar**. Um app cliente lendo esse registro veria cada tecla do editor entrar em produção, e não haveria como voltar atrás.

Este item cria o ciclo de vida que a plataforma precisa antes de qualquer app consumir (item 25):

1. **Rascunho × publicado** — salvar mexe no rascunho e nunca no que está no ar.
2. **Versões imutáveis** — publicar carimba uma versão numerada, com data (e autor, quando o item 26 existir).
3. **Rollback** — restaurar uma versão antiga para o rascunho, revisar e republicar.
4. **Despublicar** — tirar do ar sem apagar nada.
5. **O editor mostra o estado**: publicado / rascunho com alterações não publicadas / nunca publicado.

**Fica fora:** agendamento de publicação, aprovação por papéis/workflow (o "I4" original mencionava papéis — fica para depois do item 26, que traz usuário), diff visual entre versões (registrado em §9) e publicação em lote.

## 2. Precedências — o que já existe (levantado em 2026-08-13)

| O que | Onde | Uso aqui |
| --- | --- | --- |
| `model Content { spec Json }` + `@@unique([projectId, slug])` + índices de cursor | `backend/prisma/schema.prisma:62` | `spec` vira `draftSpec`; nasce `ContentVersion`. |
| `ContentsService.update()` já **valida `spec.specVersion === SPEC_VERSION`** e devolve 400 | `backend/src/contents/contents.service.ts:180` | A mesma checagem protege o publish. |
| `ContentsService` usa `$transaction`, traduz P2002 → 409 com `suggestedSlug`, e tem `toSummary(row)` como forma única do item de lista | idem, linhas 113–159 e 281 | `toSummary` ganha os campos de publicação — **um** lugar. |
| `cursor.ts` (`encodeCursor`/`decodeCursor`) + padrão keyset `take: limit+1` | `backend/src/contents/cursor.ts` | A lista de versões reusa **o mesmo** padrão de paginação. Zero invenção. |
| `ValidationPipe` global com `whitelist: true, forbidNonWhitelisted: true` e prefixo `/v1` | `backend/src/main.ts:16` | Campo extra no body → 400. Todo DTO novo precisa declarar tudo que o editor envia. |
| `EditorRepository` (`loadContent`, `saveDraft`) + `EditorRepositoryImpl` (Dio, `_failureFor` traduzindo 404/409/400) + `EditorRepositoryFake` | `modules/editor_module/{domain,data}/repositories/` | Ponto de extensão; o **fake precisa acompanhar** (`AppConfig.useFakeData`). |
| `FakeContentsStore` (`_contents`, `_updatedAt`, `save`, `find`) no `core/dev/` | `core/dev/fake_contents_store.dart` | Ganha as versões em memória. |
| `EditorCubit.save()` + `SaveStatus {saved, dirty, saving, saveFailed}` + `_statusFor` (se o item 23 já tiver entrado) | `.../cubit/editor_cubit.dart:239` | `publish()` nasce ao lado, com enum próprio. |
| `EditorTopRegistrar` publicando `actions` e `status` no shell via `AppBarAction`/`AppBarStatus` | `.../page/editor_top_registrar.dart:50` | O botão Publish real e o indicador "no ar" entram aqui. |
| `EditorReady.diagnostics` → `sdui.diagnoseTree(document.root)` e a barra de status do item 8e | `.../cubit/editor_state.dart:56` | **Publicar exige zero diagnósticos de erro** — reaproveita inteiro o que o item 8e construiu. |
| `ContentSummaryModel` com zard `z.map` — o zard **só devolve as chaves declaradas**, então campo novo na resposta não quebra o parse antigo | `contents_module/data/models/content_summary_model.dart` | Permite entregar backend e editor em PRs próximos sem quebra de runtime (mas ver R1). |

## 3. Decisões de design travadas

**D1 — `spec` vira `draftSpec`; a versão publicada mora em outra tabela.**
```
model Content {
  ...
  draftSpec          Json      @map("draft_spec")
  draftUpdatedAt     DateTime  @map("draft_updated_at")
  publishedVersionId String?   @map("published_version_id")
  publishedAt        DateTime? @map("published_at")
  versions           ContentVersion[]
}

model ContentVersion {
  id        String   @id @default(cuid(2))
  contentId String   @map("content_id")
  content   Content  @relation(fields: [contentId], references: [id], onDelete: Cascade)
  version   Int
  spec      Json
  note      String?
  createdAt DateTime @default(now()) @map("created_at")
  createdBy String?  @map("created_by")   // null até o item 26 existir
  @@unique([contentId, version])
  @@index([contentId, version(sort: Desc)])
  @@map("content_versions")
}
```
- `onDelete: Cascade` aqui (e **não** `Restrict` como no resto do schema) porque versão não é entidade de negócio independente: apagar o conteúdo tem que levar o histórico junto, senão a exclusão de projeto do item 9e volta a travar. **Este é um desvio consciente do padrão do schema** — precisa de aprovação explícita no gate.
- `publishedVersionId` é uma FK "solta" (sem `@relation` bidirecional) para evitar ciclo de dependência na criação. Guardar só o id é suficiente; o join é explícito no service.
- `createdBy` nasce nullable e **não é preenchido** até o item 26. Existir desde já evita uma segunda migração destrutiva depois.

**D2 — A migração NÃO publica nada retroativamente.**
Renomeia `spec` → `draft_spec`, cria `content_versions` vazia, `published_version_id = NULL` para todos. Motivo: nada estava publicado antes (não havia consumo); carimbar versão 1 automaticamente inventaria um fato histórico falso. Consequência aceita: em homologação, todos os conteúdos aparecem como "nunca publicado" até alguém clicar em Publicar. Comunicar isso no PR.

**D3 — Publicar é idempotente por conteúdo.**
`POST /contents/:id/publish` com `hasUnpublishedChanges == false` **não** cria versão nova: devolve 200 com a versão publicada atual. Motivo: evitar lixo de versões idênticas por duplo clique. Não é 409 porque não é erro do usuário — o resultado desejado (estar no ar com este spec) já vale.

**D4 — Restaurar traz para o rascunho; nunca republica direto.**
`POST /contents/:id/versions/:version/restore` copia o spec da versão para `draftSpec` e devolve o conteúdo. O que está no ar **não muda** até um publish explícito. Motivo: rollback com um clique é como se derruba produção sem querer; duas etapas dão a chance de revisar no canvas.

**D5 — Quem valida o spec continua sendo o kernel Dart.**
O backend **não interpreta** o spec (regra do `CLAUDE.md`) — só confere `specVersion`. Quem garante que o spec publicado é válido é o **editor**, e o gate é explícito: **publicar fica bloqueado enquanto houver diagnóstico de severidade erro** (`EditorReady.diagnostics`, do item 8e). Avisos não bloqueiam.
Risco residual registrado: um cliente HTTP fora do editor pode publicar spec inválido. Vira responsabilidade do item 26 (só quem tem credencial publica) e do item 25 (o runtime do app não pode quebrar a tela do cliente com spec ruim — tem fallback lá).

**D6 — O contrato de leitura do editor mantém a chave `spec`.**
`GET /v1/contents/:id` continua devolvendo `spec` — que agora é **o rascunho**. Motivo: é o que o editor abre e o que ele sempre abriu; renomear a chave forçaria mudança no `EditorRepositoryImpl.loadContent` sem ganho. Os campos novos entram **ao lado**: `publishedVersion` (objeto ou null) e `hasUnpublishedChanges` (bool).

**D7 — `hasUnpublishedChanges` é derivado de timestamps, não de diff de JSON.**
`publishedAt == null || draftUpdatedAt > publishedAt`. Comparar dois JSONB a cada `GET` seria caro e não vale a precisão. `draftUpdatedAt` só é tocado quando o `spec` muda (rename de nome/slug **não** conta) — por isso ele existe separado de `updatedAt`.

## 4. Fases

### P1 — Backend: schema, migração e API de publicação  **[CISO]**

**Por quê.** Nada no editor pode existir antes do contrato. Fase de backend puro, isolada, com E2E de contrato próprio.

**Arquivos a modificar/criar:**

- **`backend/prisma/schema.prisma`** — `model ContentVersion` novo (D1) + os quatro campos em `Content`. Atualizar o comentário-dartdoc do `model Content` (hoje diz "papéis/workflow chegam no I4" — passa a descrever rascunho×publicado).
- **`backend/prisma/migrations/<ts>_add_content_versions/migration.sql`** — **ordem obrigatória**:
  1. `ALTER TABLE contents RENAME COLUMN spec TO draft_spec;`
  2. `ALTER TABLE contents ADD COLUMN draft_updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;` (default só na migração; o Prisma passa a preencher explicitamente)
  3. `ADD COLUMN published_version_id TEXT NULL`, `ADD COLUMN published_at TIMESTAMP(3) NULL`
  4. `CREATE TABLE content_versions (...)` + `@@unique` + índice
  Nenhum backfill (D2). **Rename e não drop/create** — dropar a coluna perderia todos os specs.
- **`backend/src/contents/dto/publish-content.dto.ts`** (novo) — `note?: string` (`@IsOptional() @IsString() @MaxLength(200)`). Sem mais nada: o spec publicado é sempre o rascunho corrente do servidor, **nunca** vem do cliente (impede publicar algo que não passou pelo save).
- **`backend/src/contents/dto/list-versions.query.dto.ts`** (novo) — `cursor?`, `limit?` (1–100), espelhando `list-contents.query.dto.ts`.
- **`backend/src/contents/contents.service.ts`** — métodos novos:
  - `async publish(projectId, id, dto: PublishContentDto)`:
    carrega o conteúdo escopado (`findFirst({where:{id, projectId}})`, 404 se não achar);
    se `!this.hasUnpublishedChanges(row)` → devolve `this.toPublishState(row)` sem escrever (D3);
    `$transaction`: `max(version)` do conteúdo → `create` da `ContentVersion` com `version: max+1` e `spec: row.draftSpec` → `update` do `Content` com `publishedVersionId` e `publishedAt: new Date()`.
    Concorrência: o `@@unique([contentId, version])` transforma corrida em P2002 → traduzir para **409 "publicação concorrente, tente de novo"**.
  - `async unpublish(projectId, id)` → `updateMany({where:{id, projectId}, data:{publishedVersionId: null, publishedAt: null}})`; 404 se `count === 0`. **Não apaga versões.**
  - `async listVersions(projectId, id, query)` → keyset por `version desc` reusando `encodeCursor/decodeCursor`; select **sem** o campo `spec` (a lista não carrega os JSONs — seria pesado).
  - `async findVersion(projectId, id, version)` → o spec daquela versão; 404 se não existir.
  - `async restoreVersion(projectId, id, version)` → lê a versão, grava em `draftSpec` + `draftUpdatedAt: new Date()`; devolve o mesmo shape do `find()`.
  - privados: `hasUnpublishedChanges(row)` (D7), `toPublishState(row)` (`{version, publishedAt}` ou `null`).
  - **`update()` passa a gravar `draftUpdatedAt: new Date()` somente quando `dto.spec !== undefined`** (D7). Ponto fácil de esquecer.
  - **`find()`** passa a devolver `spec: row.draftSpec` (D6) + `publishedVersion` + `hasUnpublishedChanges`.
  - **`toSummary(row)`** ganha `publishedAt: Date|null` e `hasUnpublishedChanges: boolean` — assim a lista de conteúdos pode mostrar o selo sem request extra. Exige incluir os campos no `select` de `list`/`create`/`update` (**quatro** selects a atualizar — listados aqui para não escapar: linhas ~88, ~142, ~216, e o `find`).
- **`backend/src/contents/contents.controller.ts`** — rotas novas, todas com `@Headers('x-project-id')` → `projectOf`, no padrão exato das existentes:
  `@Post(':id/publish')`, `@Post(':id/unpublish')` (`@HttpCode(200)`), `@Get(':id/versions')`, `@Get(':id/versions/:version')`, `@Post(':id/versions/:version/restore')`.
  > **Ordem de rota importa no Nest:** `@Get(':id/versions')` precisa estar declarada **antes** de qualquer rota curinga que possa capturá-la. Hoje só existe `@Get(':id')`, que não conflita (segmento a mais), mas manter as específicas acima é a prática segura.
- **`backend/src/public/public.service.ts`** e **`backend/src/public/public.controller.ts`** — **adicionado em 2026-08-16, gap do plano original.** É a API `GET /public/contents[/:slug]` (chave publicável, `x-driva-key`) que a fatia 1 do item 25 já entrega em produção servindo o **rascunho** — débito registrado como **VR-13-01** em `docs/13-loop-sdui/variance_report.md` e no `docs/roadmap.md` ("não abrir para cliente real antes do 24"). É o P1 quem fecha esse débito, então os dois arquivos entram na lista de arquivos da fase, não só o `ContentsService`:
  - `list()` e `findBySlug()` passam a filtrar `publishedVersionId: { not: null }` — conteúdo nunca publicado ou despublicado some da API pública.
  - `findBySlug()` busca o `spec` na `ContentVersion` referenciada por `publishedVersionId`, não mais em `draftSpec`.
  - `etagOf`/`updatedAt` do envelope público passam a refletir `publishedAt`, não o `updatedAt` da linha — autosave do rascunho não pode invalidar o cache/ETag de quem consome a versão publicada.
  - Nenhuma mudança de contrato de campo (nomes da resposta continuam os mesmos); só a fonte dos dados muda.

**Critério de aceite (E2E de contrato, no padrão do `docs/09.../e2e_hml.sh`):**
- Criar conteúdo → `GET :id` devolve `publishedVersion: null`, `hasUnpublishedChanges: true`.
- `PUT` com spec → `POST :id/publish` → `publishedVersion.version == 1`; `GET :id` → `hasUnpublishedChanges: false`.
- Publicar de novo sem mudar nada → **mesma** versão 1, sem criar registro (contar `GET :id/versions` = 1).
- `PUT` novo spec → publish → versão 2; `GET :id/versions` devolve 2 itens, mais nova primeiro.
- `restore` da versão 1 → `GET :id` traz o spec da 1 como rascunho, e `publishedVersion.version` continua **2**.
- `unpublish` → `publishedVersion: null`; `GET :id/versions` continua com 2.
- Cross-tenant: publicar com `x-project-id` de outro projeto → **404** (não 403 — não revela existência), consistente com o resto do service.
- `DELETE` do conteúdo apaga as versões (cascade) e não trava a exclusão de projeto do item 9e.
- Conteúdo nunca publicado → `GET /public/contents/:slug` (chave publicável) devolve **404**, e não aparece em `GET /public/contents`.
- Publicar → `GET /public/contents/:slug` passa a devolver o `spec` da versão publicada (não o rascunho, mesmo que o rascunho tenha mudado depois).
- `unpublish` → `GET /public/contents/:slug` volta a **404**; conteúdo some de `GET /public/contents`.

**Riscos:**
- **R1 — o rename `spec`→`draft_spec` é destrutivo se errado.** Mitigação: `RENAME COLUMN` (não drop), rodar `prisma migrate diff` contra o hml antes, e o `docs/deploy/coolify.md` já prevê `migrate status` no start (blindagem do PR #47).
- **R2 — `toSummary` mudando afeta a lista de conteúdos do editor.** Campos **adicionados** não quebram o zard do `ContentSummaryModel` (só devolve chaves declaradas). Logo, P1 pode ir sozinha **sem** quebrar a home — diferente do caso do envelope no item 10. Confirmado por leitura do model. Ainda assim, P1 e P2 devem mergear na mesma janela.
- **R3 — CISO.** Endpoint que muda "o que está no ar" precisa de tenant check idêntico ao resto (`where: {id, projectId}` em **toda** query, inclusive nas de versão) e de limite no `note`. Sem auth ainda (item 26), o risco é o mesmo já aceito para os outros endpoints — mas registrar de novo no gate.

---

### P2 — Editor: domain + data de publicação  **[∥ com P3 depois de definidos os tipos]**

**Por quê.** Camadas puras primeiro, no gabarito do módulo. Sem UI, sem risco visual.

**Arquivos a criar:**

- **`modules/editor_module/domain/entities/content_version.dart`** — `class ContentVersion extends Equatable { final int version; final DateTime createdAt; final String? note; final String? createdBy; }`. Sem spec (a lista não carrega JSON).
- **`.../domain/entities/publication_state.dart`** — `class PublicationState extends Equatable { final int? publishedVersion; final DateTime? publishedAt; final bool hasUnpublishedChanges; }` + getter `bool get isPublished => publishedVersion != null`.
- **`.../domain/entities/entities.dart`** — barrel novo do editor_module (hoje o módulo não tem `domain/entities/`; os outros módulos têm — seguir o padrão de `contents_module`).
- **`.../domain/use_cases/publish_content_use_case.dart`** — `call(String id, {String? note}) → Future<Either<Failure, PublicationState>>`.
- **`.../domain/use_cases/unpublish_content_use_case.dart`**, **`get_content_versions_use_case.dart`** (`call(String id, {String? cursor})`), **`restore_content_version_use_case.dart`** (`call(String id, int version) → Future<Either<Failure, ContentSpec>>`).
  > Um use case por operação, com `call()`, mesmo passa-fica — regra do projeto.
- **`.../data/models/content_version_model.dart`** — zard `z.map({'version': z.int(), 'createdAt': z.date(), 'note': z.string().optional(), 'createdBy': z.string().optional()})` + `tryParse` devolvendo `Either<Failure, ContentVersionModel>`, no formato exato do `ContentSummaryModel`.
- **`.../data/models/publication_state_model.dart`** — idem para `{publishedVersion: {version, publishedAt} | null, hasUnpublishedChanges: bool}`.

**Arquivos a modificar:**
- **`.../domain/repositories/editor_repository.dart`** — quatro métodos novos na interface. `loadContent` passa a devolver **`ContentSpec` + estado de publicação**: criar `class LoadedContent extends Equatable { final ContentSpec spec; final PublicationState publication; }` em `domain/entities/` e mudar a assinatura para `Future<Either<Failure, LoadedContent>>`.
  > **Quebra de compilação intencional e localizada:** `EditorCubit.loadContent`, `EditorRepositoryImpl`, `EditorRepositoryFake` e `load_content_use_case.dart` param de compilar até serem ajustados. Isso é bom — o compilador vira a checklist. Todos os quatro estão nesta fase.
- **`.../data/repositories/editor_repository_impl.dart`** — implementar os quatro; `loadContent` passa a ler também `publishedVersion`/`hasUnpublishedChanges`; reusar o `_failureFor(e)` existente (já traduz 404/409/400/timeout).
- **`.../data/repositories/editor_repository_fake.dart`** + **`core/dev/fake_contents_store.dart`** — versões em memória: `Map<String, List<ContentSpec>> _versions`, `Map<String, int> _publishedVersion`, métodos `publish(id)`, `unpublish(id)`, `versionsOf(id)`, `restore(id, version)`. **Sem isso o modo `useFakeData` quebra** — é o modo que a maioria dos widget tests usa.
- **`.../editor_injection.dart`** — registrar os quatro use cases novos com `registerFactory`, no mesmo bloco em cascata.

**Critério de aceite:** `flutter analyze` verde; nenhum widget mudou; `save_draft_use_case_test.dart` (existente) continua passando; o app em `useFakeData` abre um conteúdo e mostra "nunca publicado".

---

### P3 — Editor: publicar de verdade (cubit + topo)

**Precedência dura:** P1 (rotas) e P2 (use cases). Não começar antes.

**Arquivos a modificar:**
- **`.../cubit/editor_state.dart`** — `enum PublishStatus { idle, publishing, published, publishFailed }` (arquivo próprio? **não**: enums do cubit podem coabitar via `part of`, como `SaveStatus` já faz). `EditorReady` ganha `final PublicationState publication` e `final PublishStatus publishStatus`, ambos no `copyWith` e no `props`.
  Getter derivado: `bool get canPublish => publishStatus != PublishStatus.publishing && saveStatus != SaveStatus.saving && !diagnostics.any((d) => d.severity == DiagnosticSeverity.error)`.
  > Assinatura confirmada no código: `SpecDiagnostic {nodeId, nodeType, code, severity, message}` e `enum DiagnosticSeverity { error, warning }` em `packages/sdui_core/lib/src/diagnostics/spec_diagnostic.dart`. Hoje só dois códigos existem (`flexOnlyOutsideFlex` = erro, `emptySingleSlot` = aviso), então na prática **só o `expanded`/`spacer` fora de flex bloqueia publicar**.
- **`.../cubit/editor_cubit.dart`** — construtor ganha os quatro use cases (`publishContentUseCase`, …) por parâmetro nomeado obrigatório, como os dois atuais.
  - **`Future<void> publish({String? note})`**: guarda `canPublish`; emite `publishing`; **se `saveStatus == dirty`, salva primeiro** (`await save()`) — publicar o que está na tela e não no servidor seria mentira; depois chama o use case; `isClosed` após o await; emite `publication` novo + `published`/`publishFailed`.
  - **`Future<void> unpublish()`**, **`Future<void> restoreVersion(int version)`** (recebe o `ContentSpec`, troca o documento, marca `dirty` — e, se o item 23 já existir, **passa pelo `_emitDocument`** para virar uma entrada de histórico desfazível).
  - `loadContent` passa a preencher `publication` a partir do `LoadedContent`.
- **`.../page/editor_top_registrar.dart`** — o `AppBarAction.outlined('Publish')` placeholder vira ação real:
  `onPressed: state.canPublish ? () => _confirmPublish(context, cubit) : null`, com `tooltip` explicando **por que** está desabilitado quando há erro no documento (acessibilidade: cor/estado não pode ser o único sinal).
  O `status:` do shell passa a refletir três estados: "No ar (v3)" / "Alterações não publicadas" / "Nunca publicado", via `_statusFor` estendido — usando `AppBarStatus(icon, label, tone)` que já existe.
- **`.../presentation/editor/widgets/publish/publish_dialog.dart`** (novo) — `StatelessWidget` de confirmação: mostra a versão que será criada, o campo `note` opcional (máx. 200, casando com o DTO) e a contagem de avisos não bloqueantes. Widget novo em arquivo próprio, tier **feature** (Gate 2).

**Critério de aceite:**
- Com um `expanded` fora de flex (erro conhecido do `diagnoseTree`), o botão Publicar fica **desabilitado** e o tooltip diz o motivo.
- Publicar com rascunho sujo salva antes e o topo passa a "No ar (v1)".
- Falha de rede no publish deixa `publishFailed` visível e **não** altera `publication`.

---

### P4 — Histórico de versões na UI (diálogo) e selo na lista  **[∥ com P3 na segunda metade]**

**Por quê.** Sem ver as versões, o rollback do P1 não existe para o usuário.

**Arquivos a criar:**
- **`.../presentation/editor/widgets/versions/version_history_dialog.dart`** — diálogo com a lista paginada (reusa o padrão de scroll infinito do item 16: `NotificationListener` + rodapé "Carregando mais…"), cada linha com versão, data, nota, selo "no ar" e ação **Restaurar para o rascunho** (com confirmação, porque descarta o rascunho atual).
- **`.../presentation/editor/widgets/versions/version_row.dart`** — uma linha (Gate 3: arquivo próprio).
- **`.../presentation/editor/cubit/version_history_cubit.dart`** + `version_history_state.dart` (`part of`) — cubit **escopado ao diálogo**, não ao editor: carregar histórico não pode reconstruir o canvas (regra de escopo mínimo de rebuild).

**Arquivos a modificar (o selo na lista de conteúdos — outro módulo):**
- **`contents_module/domain/entities/content_summary.dart`** — `+ final DateTime? publishedAt; + final bool hasUnpublishedChanges;`
- **`contents_module/data/models/content_summary_model.dart`** — duas chaves novas no `_schema` (`z.date().optional()`, `z.boolean()`), com **default seguro** se ausente (o backend antigo em cache não as manda).
- **`contents_module/presentation/project_detail/widgets/content_panel/content_card_body.dart`** (e `content_row_body.dart`) — selo discreto "No ar" / "Rascunho", ao lado do `category_label` que o item 16b já colocou. **Ícone + texto**, nunca só cor (acessibilidade).

**Critério de aceite:** lista mostra o selo certo sem request extra; abrir o histórico não pisca o canvas; restaurar fecha o diálogo e o canvas passa a mostrar a versão restaurada como rascunho sujo.

---

### P5 — Testes automatizados (por último)

- **Backend:** e2e de contrato `docs/24-publicacao-versionamento/e2e_hml.sh` no padrão do item 9g — **contra o hml real**, auto-limpante, cobrindo os 8 casos do aceite do P1.
- **`packages/sdui_core`:** nada muda aqui — o kernel não participa deste item (registrar explicitamente, é um sinal de bom recorte).
- **Editor:** `editor_cubit_test.dart` (publicar com erro bloqueado; publish salva antes quando dirty; falha não altera `publication`), `content_version_model_test.dart` e `publication_state_model_test.dart` (parse feliz e parse quebrado), widget test do `publish_dialog` e do selo no card.

## 5. Mapa de paralelismo

```
P1 (backend) ──► P2 (domain+data) ──► P3 (cubit+topo) ──► P5 (testes)
                                  └─► P4 (histórico+selo) ┘
```
- **P1 é o gargalo** e não paraleliza com nada (define o contrato).
- **P2 pode começar antes de P1 terminar** se os tipos do contrato estiverem congelados no §3 deste plano — é literalmente para isso que o plano existe. Recomendado: congelar o JSON de resposta num bloco combinado (PM + tech-lead) no início do P1.
- **P3 e P4 rodam em paralelo** por pessoas diferentes: P3 mexe em `cubit`/`top_registrar`, P4 em `widgets/versions/` + `contents_module`. Colisão só no `editor_state.dart` — combinar que P3 é dono desse arquivo.

## 6. Impacto nos planos já escritos (revisão cruzada)

- **Item 23 (histórico do editor) — compatível, com dois contratos a respeitar:**
  1. `publish()` **não pode** empilhar histórico (publicar não muda o documento). Já está assim no P3.
  2. `restoreVersion()` **deve** empilhar (muda o documento) — por isso o P3 manda passar pelo `_emitDocument`.
  3. A D7 do plano 23 (`_lastSavedDocument` reconciliando `saveStatus`) continua válida; publicação usa timestamps do servidor e não interfere.
  **Se o item 24 entrar antes do 23**, nada quebra: o 23 passa a ter que incluir `publication`/`publishStatus` nos `copyWith` — trabalho trivial, mas registrar na fase F1 dele.
- **Item 21 (componentes) — obrigação futura sobre o `publish()`, registrada na revisão cruzada de 2026-08-13.** Quando os componentes existirem, publicar deixa de ser "manda o rascunho" e passa a ser "**expande os componentes referenciados e manda a árvore expandida**" (item 21, D2 — o rascunho guarda referência, a versão publicada guarda árvore completa). Duas consequências para este plano:
  1. O `PublishContentUseCase` (P2) é o lugar onde a expansão entra. **Nada muda agora**, mas ele deve nascer como um use case que **transforma** o documento antes de enviar, e não como um passa-fica — assim o item 21 só acrescenta a transformação.
  2. O backend já suporta isso sem mudança: `draftSpec` e `ContentVersion.spec` são campos distintos (D1), então rascunho e versão publicada **podem legitimamente diferir**. Verificado.
- **Item 17 (offline-first) — armadilha registrada na revisão cruzada de 2026-08-13.** O P4 acrescenta `publishedAt` e `hasUnpublishedChanges` ao `ContentSummary`. Se o item 17 já estiver entregue, existirão **listas cacheadas em disco sem esses campos**; um `z.boolean()` sem default faria o `tryParse` falhar e a lista inteira sumir na primeira abertura pós-deploy. **Por isso o P4 exige default tolerante — não é preciosismo, é a diferença entre atualizar e quebrar a home de quem já usava.** Registrado nos dois planos.
- **Nenhuma contradição** com os itens já entregues. O item 9e (exclusão em cascata de projeto) é o único que poderia travar: resolvido pelo `onDelete: Cascade` da D1 — **verificar na P1** que o `$transaction` de exclusão do `ProjectsService` continua funcionando com a tabela nova (as versões somem junto com o conteúdo automaticamente; nenhuma linha nova de código é necessária, mas o E2E do 9e precisa rodar de novo).

## 7. Definition of Done

- [ ] `pnpm build` + `pnpm lint` verdes no backend; `flutter analyze` verde no workspace.
- [ ] Migração aplicada em hml com `migrate status` limpo e **nenhum spec perdido** (conferir contagem antes/depois).
- [ ] E2E de contrato 100% PASS contra o hml, auto-limpante.
- [ ] E2E de UI (Playwright/CDP, padrão 9g): publicar, ver o selo mudar, abrir histórico, restaurar.
- [ ] E2E do item 9e re-executado (exclusão de projeto com conteúdo publicado).
- [ ] `CHANGELOG.md` › `Unreleased` e `docs/24-publicacao-versionamento/final_report.md`.
- [ ] `docs/roadmap.md`: item 24 `[x]`, item 25 `[-]`.

## 8. Perguntas para o humano (bloqueiam o início do P1)

1. **Retenção de versões.** Guardar todas para sempre, ou podar (ex.: manter as 50 últimas + todas as publicadas)? O plano assume **todas**; podar depois é migração.
2. **Despublicar deve existir na UI já nesta fatia?** A API vem de graça; o botão custa uma confirmação a mais. Assumido: **API sim, botão sim** (escondido atrás do menu do topo, não no botão principal).
3. **O `note` da publicação é obrigatório?** Assumido: opcional. Se a operação quiser rastreabilidade de "por que subiu", vira obrigatório — decisão de produto.

## 9. Evoluções deixadas de fora (registro para o roadmap futuro)

- Diff visual entre duas versões (reaproveitaria o `json_highlighter` do item 8).
- Agendamento de publicação e janelas de deploy.
- Aprovação por papéis — depende do item 26.
- Publicar vários conteúdos de uma vez ("release" do projeto).
