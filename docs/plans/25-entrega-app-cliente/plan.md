# plan.md — Item 25: Entrega ao app cliente (API pública, runtime SDK e app de exemplo)

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 5.
> Regra do "pronto": **`flutter analyze` verde + `pnpm build` verde + testes existentes passando**.
> **Gate CISO obrigatório e pesado**: é o primeiro endpoint do driva exposto a um consumidor externo.
> **Precedência dura: item 24 concluído.** Sem versão publicada não há o que servir — este plano chama `ContentVersion`, `publishedVersionId` e `publishedAt`, que nascem lá.

## 1. Objetivo e recorte

O driva se descreve como "plataforma de Server-Driven UI para apps Flutter", mas **nenhum app consegue consumir nada**. As duas pontas soltas, hoje, no código:

- `packages/sdui_flutter/lib/src/driva_content.dart` — `DrivaContent(slug:)` é um `throw UnimplementedError('a resolução por slug em runtime chega no próximo incremento')`.
- `backend/src/contents/contents.controller.ts` — todos os endpoints são do editor (`x-project-id`, lista paginada, rascunho). Não existe leitura por slug para app.

Este item fecha o ciclo: **editor publica → app cliente renderiza**.

1. `GET /v1/public/contents/:slug` — só versão publicada, autenticado por **chave publicável** do projeto, com `ETag`/304 e rate limit.
2. `packages/driva_client` — package novo: `Driva.init(...)` + `DrivaContent(slug:)` com cache em disco, *stale-while-revalidate* e **fallback embarcado**.
3. `apps/driva_showcase` — app Flutter de exemplo que prova o ciclo fim-a-fim contra a homologação.

**Fica fora:** execução de ações (item 28 — nesta fatia um botão publicado continua inerte), binding com dados reais (item 29), consumo por app **web** de terceiro (limitação de CORS, ver D6), SDK para outras plataformas (React Native etc.).

## 2. Precedências

**Do item 24 (obrigatório antes de começar):** `ContentVersion(contentId, version, spec)`, `Content.publishedVersionId`, `Content.publishedAt`, e a garantia de que só spec validado pelo kernel é publicado (D5 de lá).

**Do que já existe hoje:**

| O que | Onde | Uso |
| --- | --- | --- |
| `SduiView.content(spec)` / `SduiView(node:, registry:, onAction:, nodeWrapper:, safeArea:)` | `packages/sdui_flutter/lib/src/sdui_view.dart` | É o que o `DrivaContent` vai montar quando o spec chega. **Já pronto — nada a mudar no renderer.** |
| `parseContentSpec(json)` → `Either<SpecValidationError, ContentSpec>` | `packages/sdui_core/lib/src/schema/content_schema.dart` | Única porta JSON→entidade, também no app cliente. |
| `kSpecVersion` + recusa de versão diferente | `packages/sdui_core/lib/src/schema/spec_version.dart` | O runtime precisa tratar "spec mais novo que o app" sem crashar (D5). |
| `defaultRegistry` (24 builders) | `packages/sdui_flutter/lib/src/builders/default_registry.dart` | Registry default do app cliente; ele pode estender. |
| Padrão de package do workspace: `resolution: workspace`, entrada em `pubspec.yaml` raiz | `pubspec.yaml`, `packages/sdui_flutter/pubspec.yaml` | Gabarito para os dois alvos novos. |
| `main.ts` com `setGlobalPrefix('v1', {exclude:['health']})` e `enableCors({origin:[...], allowedHeaders:['content-type','x-project-id']})` | `backend/src/main.ts:25` | O header novo precisa entrar no `allowedHeaders`. **Ponto fácil de esquecer.** |
| `ProjectsService` com `toSummary` e imagem por key | `backend/src/projects/projects.service.ts` | Onde a chave publicável nasce. |

## 3. Decisões de design travadas

**D1 — Chave publicável por projeto, não token de usuário.**
`Project` ganha `publishableKey String @unique @map("publishable_key")`, gerada na criação (`pk_` + 32 bytes base64url de `crypto.randomBytes`). Ela vai **embarcada no app do cliente** — logo é pública por natureza e só serve para **ler conteúdo publicado**. Nunca dá escrita, nunca lista projetos, nunca vê rascunho.
Rotação: `POST /v1/projects/:id/rotate-key` (autenticado como o resto do editor).
> Isso **não** substitui o item 26. Auth do editor (quem edita) e chave publicável (quem lê) são coisas diferentes e coexistem.

**D2 — A rota pública é um controller separado, com service separado.**
`backend/src/public/` — `public.controller.ts` + `public.service.ts` + `public.module.ts`. Motivo: o `ContentsController` inteiro é escopado por `x-project-id` vindo do header **sem verificação**; misturar a rota pública ali é o caminho mais curto para alguém, num refactor futuro, vazar rascunho. Isolar o superfície pública em um módulo próprio é o que o CISO vai pedir de qualquer forma.

**D3 — O que a rota devolve, exatamente:**
```json
{ "slug": "home", "version": 3, "publishedAt": "2026-08-13T12:00:00.000Z", "spec": { ... } }
```
Com `ETag: W/"<contentId>-<version>"` e `Cache-Control: public, max-age=60, stale-while-revalidate=86400`.
`If-None-Match` casando → **304 sem corpo**. Motivo do ETag ser derivado de `(contentId, version)`: é imutável por definição (versão nunca muda depois de criada), então não precisa hash do corpo.
Conteúdo sem publicação → **404** (não 403, não "existe mas não publicado" — não revela a existência do rascunho).

**D4 — Package novo `packages/driva_client`, e o `DrivaContent` muda de casa.**
`sdui_flutter` é o **renderer puro** e é dependência do **editor**. Se o runtime (HTTP + cache em disco) morasse lá, o editor web carregaria `shared_preferences`/cliente HTTP do runtime sem usar. Então:
- `packages/driva_client` (novo) → `dependencies: sdui_core, sdui_flutter, http, shared_preferences`.
- `packages/sdui_flutter/lib/src/driva_content.dart` é **deletado**, e o export sai de `sdui_flutter.dart` (linhas 11–15 daquele arquivo, incluindo os dois `import ... show DrivaContent` autorreferentes que hoje só existem para o dartdoc). O dartdoc da `library` é reescrito.
- Ninguém depende de `DrivaContent` hoje (é `UnimplementedError`), então a remoção não quebra nada — verificado.
- `http` em vez de `dio`: o package é consumido por apps de terceiros; `http` é a dependência mais leve e menos opinativa. O editor continua com `dio` — são consumidores diferentes.

**D5 — O runtime nunca derruba a tela do cliente.**
Ordem de resolução do `DrivaContent`: **memória → disco → rede** para exibir, e revalidação em background. Se tudo falhar:
1. `fallback` embarcado registrado no `Driva.init` (JSON de asset) → renderiza;
2. sem fallback → `errorBuilder` do app;
3. sem `errorBuilder` → `SizedBox.shrink()` **e log**, nunca exceção.
Spec com `specVersion` maior que o `kSpecVersion` do app (app desatualizado na loja) → trata como falha de parse e cai no fallback. **Este é o cenário que mais assusta em SDUI e precisa estar no teste.**

**D6 — Alvo desta fatia é app Flutter nativo (mobile/desktop).**
Web de terceiro exigiria CORS por origem cadastrada por projeto — escopo próprio. O `enableCors` ganha `x-driva-key` no `allowedHeaders` (para o app de exemplo rodar em Chrome durante o desenvolvimento), mas a lista de origens permitidas continua sendo a do `CORS_ORIGINS`. Limitação registrada, não resolvida aqui.

**D7 — Rate limit desde o primeiro dia.**
`@nestjs/throttler` na rota pública: 120 req/min por IP. Sem isso, um app com bug em loop derruba o backend do editor junto (mesmo processo).

## 3b. Revisão de 2026-08-19 — o que a Fatia 1 mudou neste plano

Este plano foi escrito **antes** da Fatia 1. Ela foi entregue em 2026-08-15
(`docs/13-loop-sdui/`) e o item 24 fechou em 2026-08-17, então três suposições
do §4 caducaram. **Onde esta seção contradiz o §4, ela ganha.**

**R1 — O P1 está entregue; não há backend a escrever nesta fatia.**
`Project.publishableKey`, o header `x-driva-key`, `GET /v1/public/contents[/:slug]`
com `ETag`/`304` e o CORS restrito ao prefixo público já existem
(`backend/src/public/public.controller.ts:18-59`). O item 24 fechou o VR-13-01:
a rota serve `publishedVersionId`, não mais o rascunho. **As perguntas 1–3 do §8
já foram respondidas em código** — só a 4 (`http` como dependência) segue valendo
para o P2, e a resposta continua sendo a do §3 D4: `http`, com `Client` injetável.

**R2 — `apps/driva_showcase` não nasce. O `apps/driva_demo_app` é o showcase.**
O P3 previa um app mínimo novo. A Fatia 1 entregou algo maior: um app com Clean
Architecture completa (`published_module` com `dio`, models zard, use cases,
repositório), na CI, com job de build Android e sob os mesmos gates do editor.
Criar um segundo app de exemplo agora significaria manter dois. **O P3 vira
"migrar o `driva_demo_app` para o `driva_client`"** — e essa migração é a melhor
prova que o package pode ter: ela **apaga** `published_module/data` inteiro e o
substitui por três linhas de `Driva.init` + `DrivaContent`. Se o package não der
conta, a migração não fecha, e isso é exatamente o sinal que se quer.

**R3 — O `driva_demo_app` é a régua do contrato do `driva_client`.**
O que ele faz hoje é o mínimo que o package precisa cobrir:
`published_repository_impl.dart` traduz `DioException` em `NotFoundFailure`/
`ValidationFailure`/`NetworkFailure` e lê o `etag` do header de resposta. O
`driva_client` **não** expõe `Either<Failure, T>` para o app do cliente (é API
pública de terceiro, não camada interna) — ele resolve por dentro e entrega ao
widget conteúdo, `loadingBuilder` ou `errorBuilder`. **A tradução de erro
some do app e vira responsabilidade do package.**

**R4 — `DrivaContent` continua o `UnimplementedError` que o §1 descreve.**
Verificado em `packages/sdui_flutter/lib/src/driva_content.dart`: nada mudou lá,
e nenhum código o importa. A deleção do §4 P2 segue válida palavra por palavra,
incluindo o bump `sdui_flutter` 0.3.0 → 0.4.0 e o ajuste da constraint.
**Acrescentar ao §4:** `apps/driva_demo_app/pubspec.yaml` também trava
`sdui_flutter: ^0.3.0` e `sdui_core: ^0.3.0` — ele entra na mesma lista de
dependentes a ajustar, que o plano original dizia conter "só o editor".

**R5 — Fases desta fatia, substituindo P2–P5 do §4:**

| Fase | O que é | Paralela? |
| --- | --- | --- |
| **F1** | `packages/driva_client` nasce (§4 P2, sem alteração de conteúdo) + remoção do `DrivaContent` do `sdui_flutter` + bumps e constraints | — (é a base) |
| **F2** | `driva_demo_app` migra para o `driva_client`; `published_module/data` é apagado | dep. F1 |
| **F3** | Guia de integração (`README.md` do package + `docs/25-entrega-app-cliente/integracao.md`) | **∥ com F1** — o contrato público está congelado no §4 |
| **F4** | E2E do ciclo completo contra hml, atestado pelo humano | dep. F2 |
| **F5** | Bateria automatizada (§4 P5) | dep. F4 — regra do cap. 22 |

**R6 — O mapa do §5 fica assim** (o P1 sai; F1 e F3 são as duas frentes que
correm juntas, e tocam arquivos disjuntos — `packages/driva_client/lib` × `docs/`
e `README.md`):

```
F1 (runtime) ─┬─► F2 (demo app migra) ─► F4 (E2E) ─► F5 (bateria)
F3 (docs) ────┘
```

## 4. Fases

### P1 — Backend: chave publicável + rota pública  **[CISO]**

**Arquivos a modificar:**
- **`backend/prisma/schema.prisma`** — `Project.publishableKey String @unique @map("publishable_key")`.
- **`backend/prisma/migrations/<ts>_add_publishable_key/migration.sql`** — ordem: adicionar coluna **nullable** → backfill com chave gerada para cada projeto existente (`UPDATE ... SET publishable_key = ...` por linha, ou um `gen_random_uuid()` prefixado se a extensão `pgcrypto` estiver disponível — checar; se não, backfill em script Node no start) → `SET NOT NULL` → `CREATE UNIQUE INDEX`. **Nunca** criar `NOT NULL UNIQUE` direto com tabela populada.
- **`backend/src/projects/projects.service.ts`** — `create()` gera a chave na mesma `$transaction` que já cria o projeto e a "Geral"; `toSummary()` **não** expõe a chave na listagem; método novo `rotateKey(id)`; a chave aparece só no `findOne`/detalhe.
- **`backend/src/projects/projects.controller.ts`** — `@Post(':id/rotate-key')`.
- **`backend/src/main.ts`** — `allowedHeaders: ['content-type', 'x-project-id', 'x-driva-key']`.
- **`backend/src/app.module.ts`** — importar `PublicModule`.
  > **`@nestjs/throttler` já é dependência do projeto** — `ProjectsController` usa `@UseGuards(ThrottlerGuard)` + `@Throttle(UPLOAD_THROTTLE)` no upload de imagem (linhas 20, 48–49). A rota pública **imita esse padrão**, não instala nada novo. Verificar apenas se o `ThrottlerModule.forRoot` já está no `app.module.ts`; se o uso atual for só por-rota, adicionar a config raiz.

**Arquivos a criar:**
- **`backend/src/public/public.module.ts`**, **`public.controller.ts`**, **`public.service.ts`**.
  - `PublicController`: `@Controller('public')`, `@Get('contents/:slug')`, lê `@Headers('x-driva-key')`, `@Headers('if-none-match')`, e usa `@Res({passthrough:true})` para setar `ETag`/`Cache-Control`/status 304. Guard `@UseGuards(ThrottlerGuard)`.
  - `PublicService.findPublished(publishableKey, slug)`:
    1. `project = await prisma.project.findUnique({where:{publishableKey}, select:{id:true, archivedAt:true}})` → sem projeto **ou** `archivedAt != null` → 404 (projeto arquivado some do ar também — decisão a confirmar em §8);
    2. `content = findFirst({where:{projectId: project.id, slug}, select:{id, publishedVersionId, publishedAt}})` → sem conteúdo ou sem `publishedVersionId` → 404;
    3. `version = findUnique({where:{id: content.publishedVersionId}, select:{version, spec}})`;
    4. devolve `{slug, version, publishedAt, spec}`.
  - **Nenhuma query aqui aceita `projectId` do cliente** — o tenant vem da chave. É a diferença central para o resto do backend.
- **`backend/src/public/dto/`** — não há body; nenhum DTO. (Registrado para o revisor não procurar.)

**Critério de aceite:**
- `GET /v1/public/contents/home` sem header → 401 (chave ausente) — **decidir 401 vs 404**: o plano assume **401**, porque ausência de credencial não vaza existência.
- Chave válida + slug publicado → 200 com o spec **da versão publicada**, nunca o rascunho (testar: alterar rascunho, não publicar, e conferir que o corpo não mudou).
- Repetir com `If-None-Match` do ETag anterior → **304** sem corpo.
- Publicar versão nova → ETag muda → 200 com o novo spec.
- `unpublish` → 404.
- Chave de outro projeto + slug do primeiro → 404.
- 121 requisições em um minuto → 429.

**Riscos:**
- **R1 — chave em log.** `LogInterceptor`/observabilidade não pode registrar o header. Verificar no gate CISO.
- **R2 — enumeração de slug.** Com uma chave válida, dá para descobrir quais slugs existem por 200 vs 404. Aceitável (a chave já dá acesso ao conteúdo do projeto), mas registrar.
- **R3 — a coluna `publishableKey` no `toSummary`.** Se vazar na listagem de projetos, qualquer um com acesso ao editor pega chaves de todos os projetos. Enquanto o item 26 não existir, **isso é o mesmo nível de exposição que já existe** — mas a decisão de não expor na lista precisa ser explícita no código.

---

### P2 — `packages/driva_client`: o runtime  **[∥ com P1 depois do contrato congelado]**

**Por quê.** É o que transforma "tem um endpoint" em "o app renderiza".

**Arquivos a criar:**

```
packages/driva_client/
  pubspec.yaml                     name: driva_client, resolution: workspace,
                                   deps: flutter, sdui_core ^0.3.0, sdui_flutter ^0.3.0,
                                         http ^1.2.0, shared_preferences ^2.5.5
  lib/driva_client.dart            barrel: Driva, DrivaContent, DrivaConfig, DrivaCacheStore
  lib/src/driva.dart               class Driva  (singleton de configuração)
  lib/src/driva_config.dart        class DrivaConfig (Equatable)
  lib/src/driva_content.dart       class DrivaContent extends StatefulWidget
  lib/src/content_repository.dart  class DrivaContentRepository (memória→disco→rede)
  lib/src/cache/driva_cache_store.dart          abstract interface class
  lib/src/cache/prefs_cache_store.dart          impl com shared_preferences
  lib/src/cache/memory_cache_store.dart         impl de teste/opt-out
  lib/src/cached_content.dart      class CachedContent {spec json, etag, fetchedAt}
```

**Contrato público (o que o app do cliente escreve):**
```dart
await Driva.init(DrivaConfig(
  baseUrl: 'https://api.driva.example',
  publishableKey: 'pk_...',
  fallbacks: {'home': homeSpecJson},        // opcional, asset embarcado
  registry: myRegistry,                     // opcional, default = defaultRegistry
  cache: PrefsCacheStore(),                 // opcional, default = PrefsCacheStore
));

DrivaContent(
  slug: 'home',
  onAction: (action) { ... },               // inerte até o item 28
  loadingBuilder: (context) => ...,         // opcional
  errorBuilder: (context, error) => ...,    // opcional
)
```

**Detalhes que precisam estar certos:**
- **`Driva.init` é idempotente** e lança `StateError` claro se `DrivaContent` for usado antes dele — mensagem acionável, no espírito do `UnimplementedError` que existe hoje.
- **`DrivaContentRepository.load(slug)`** devolve um `Stream<ContentSpec>` ou um par (cached, future)? **Decisão: `Stream`** — emite o cache imediatamente (se houver) e emite de novo se a revalidação trouxer versão nova. O `DrivaContent` é `StatefulWidget` com `StreamSubscription` e `setState`. Alternativa (`FutureBuilder` + refetch) piscaria a tela.
- **Chave de cache:** `driva:<publishableKeyHashCurto>:<slug>` — inclui a chave para não misturar projetos no mesmo app.
- **Parse sempre pelo kernel:** `parseContentSpec(json)`; `Left` → trata como cache corrompido, **apaga a entrada** e cai para a rede/fallback. Nunca renderiza spec não validado.
- **`specVersion` incompatível** (D5): o `parseContentSpec` já devolve `Left` com a mensagem certa (`'specVersion X não suportada'`) — o runtime só precisa não engolir isso como sucesso.
- **Sem `dart:io`**: `http` + `shared_preferences` funcionam em web também, então o package não fecha portas.

**Arquivos a modificar:**
- **`pubspec.yaml` (raiz)** — acrescentar `packages/driva_client` (e `apps/driva_showcase` na P3) na lista `workspace:`.
- **`packages/sdui_flutter/lib/sdui_flutter.dart`** — remover `export 'src/driva_content.dart';` e os dois `import ... show DrivaContent`; reescrever o dartdoc da `library` (hoje ele promete a resolução por slug "no próximo incremento" — passa a apontar para o `driva_client`).
- **`packages/sdui_flutter/lib/src/driva_content.dart`** — **deletar**.
- **`packages/sdui_flutter/pubspec.yaml`** — bump de versão (0.3.0 → 0.4.0): é uma remoção de API pública.
- **`apps/driva_editor/pubspec.yaml`** — a constraint atual é `sdui_flutter: ^0.3.0`, que **não aceita 0.4.0** (em SemVer pré-1.0, o caret trava no minor). Sem este ajuste, o `pub get` do editor quebra no mesmo PR do bump. Atualizar para `^0.4.0`. **Conferir também `packages/driva_client/pubspec.yaml` (que nasce nesta fase) e qualquer outro dependente** — hoje só o editor depende de `sdui_flutter` (verificado).

**Critério de aceite:**
- App sem rede, sem cache, com fallback → renderiza o fallback.
- App sem rede, com cache → renderiza o cache, e o log diz que a revalidação falhou.
- Servidor com versão nova → o widget troca o conteúdo **sem** piscar branco.
- Servidor devolvendo 304 → nenhuma reconstrução do renderer (o `Stream` não emite).
- Spec com `specVersion: 999` → fallback, sem exceção subindo.

---

### P3 — `apps/driva_showcase`: o app de exemplo

**Por quê.** É a prova viva de que a plataforma funciona, e o lugar onde o E2E do ciclo completo roda. Também é a primeira vez que alguém usa o `driva_client` — a dor de usar aparece aqui, e é barata de corrigir agora.

**Arquivos a criar:**
- `apps/driva_showcase/` — app Flutter mínimo: `main.dart` com `Driva.init` lendo `--dart-define`, uma tela com `DrivaContent(slug: ...)`, um campo para trocar o slug e um botão "recarregar". `assets/fallback_home.json` embarcado.
- `apps/driva_showcase/config/dev.json` e `hml.json` — no padrão `--dart-define-from-file` que o editor já usa (`apps/driva_editor/config/dev.json`).
- `apps/driva_showcase/README.md` — como apontar para o hml e qual chave usar (**a chave real nunca vai para o repo** — é `--dart-define`).

**Critério de aceite (o E2E do item inteiro):** publicar um conteúdo no editor em hml → abrir o showcase → a tela aparece; editar e salvar sem publicar → o showcase **não muda**; publicar → recarregar → mudou.

---

### P4 — Documentação de integração

- **`docs/25-entrega-app-cliente/integracao.md`** — o guia que o cliente lê: adicionar o package, `Driva.init`, obter a chave, o que acontece offline, como embarcar fallback.
- **`packages/driva_client/README.md`** — versão curta do mesmo, com o exemplo mínimo.
- Atualizar **`docs/deploy/coolify.md`** com a variável de ambiente nova, se houver (throttler configurável).

---

### P5 — Testes (por último)

- **`packages/driva_client/test/`**: `content_repository_test.dart` (memória→disco→rede, 304 não emite, parse inválido limpa cache, fallback), com um `http.Client` fake (`package:http/testing.dart` — `MockClient`) e `MemoryCacheStore`.
- **Widget test** `driva_content_test.dart`: mostra `loadingBuilder`, depois o conteúdo; erro sem fallback chama `errorBuilder`.
- **Backend**: e2e de contrato da rota pública (os 7 casos do P1), no `e2e_hml.sh` da feature.
- **`packages/sdui_flutter`**: rodar a suíte existente para confirmar que remover `DrivaContent` não quebrou nada (`sdui_view_test.dart`, `renderer_golden_test.dart`).

## 5. Mapa de paralelismo

```
P1 (backend) ─────┐
                  ├─► P3 (showcase) ─► P5 (testes)
P2 (driva_client) ┘        │
                           └─► P4 (docs)  [∥ com P3]
```
- **P1 e P2 são independentes** desde que o §3 (D3: forma da resposta + ETag) esteja congelado. São linguagens e repositórios de arquivos diferentes — zero conflito de merge.
- **P3 é o encontro** e não começa antes das duas.
- **P4 pode ser escrita em paralelo com P3** (a API pública já está definida).

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 24 — dependência satisfeita, sem contradição.** Uma coisa a acrescentar **lá**: o `PublicService` lê `publishedVersionId`; se o item 24 implementar `unpublish` apenas zerando `publishedAt` e não `publishedVersionId`, a rota pública continuaria servindo conteúdo despublicado. O plano 24 já manda zerar **os dois** (P1 › `unpublish`) — mantido de propósito. **Não mudar isso sem revisar aqui.**
- **Item 23 — nenhum contato.** O runtime não usa `EditorCubit`, e a remoção do `DrivaContent` do `sdui_flutter` não toca o editor (que nunca o importou — o editor usa `SduiView`).
- **Aviso para o item 26 (auth):** quando o `x-project-id` for substituído por sessão, **a rota pública não entra nessa mudança** — ela é autenticada por chave, não por sessão. O plano 26 precisa excluir `src/public/` do guard global. Registrado lá.
- **Aviso para o item 28 (ações):** `DrivaContent.onAction` já nasce no contrato deste plano, mesmo inerte, **de propósito** — assim o item 28 não precisa de breaking change no package publicado.
- **Aviso para o item 19 (componentes), acertado na revisão cruzada de 2026-08-13:** o item 19 decide que **componente é um `Content` com `kind='component'`** (mesma tabela). Consequência para esta rota: `GET /v1/public/contents/:slug` passaria a poder devolver um **componente** se alguém pedir o slug dele — peça de montagem servida como se fosse tela. **Ação:** o `PublicService.findPublished` deve filtrar `kind: 'content'` na query. Se o item 25 for entregue **antes** do 19 (ordem recomendada), a coluna ainda não existe — então a linha entra no item 19, e o plano dele carrega essa obrigação. **Registrado nos dois.**

## 7. Definition of Done

- [ ] `pnpm build`/`pnpm lint` verdes; `flutter analyze` verde nos 4 pacotes/apps do workspace.
- [ ] Migração da chave publicável aplicada em hml sem projeto órfão (contagem antes/depois).
- [ ] E2E de contrato da rota pública 100% PASS contra o hml.
- [ ] **E2E do ciclo completo** com o showcase apontado para o hml (publicar → aparecer; salvar sem publicar → não aparecer).
- [ ] `docs/25-entrega-app-cliente/final_report.md` + guia de integração.
- [ ] `CHANGELOG.md` com o **breaking change** do `sdui_flutter` (remoção do `DrivaContent`).
- [ ] `docs/roadmap.md`: item 25 `[x]`.

## 8. Perguntas para o humano (bloqueiam o P1)

1. **Projeto arquivado sai do ar?** O plano assume **sim** (404 na rota pública). Alternativa: continuar servindo, já que arquivar é organização do editor, não despublicação. **Precisa de decisão** — muda o comportamento visível de um app em produção.
2. **401 ou 404 para chave ausente/ inválida?** Assumido 401 para ausente, 404 para inválida.
3. **Uma chave por projeto ou por ambiente?** Assumido: uma por projeto. Se dev/prod do cliente precisarem de chaves distintas, vira `ProjectKey` (tabela) — decidir agora é mais barato que migrar depois.
4. **`http` como dependência do package público** — confirma? (Alternativa: aceitar um `Client` injetado e não depender de nada, deixando o app escolher. Mais puro, um pouco menos conveniente. O plano assume `http` com `Client` injetável no construtor — o melhor dos dois.)
