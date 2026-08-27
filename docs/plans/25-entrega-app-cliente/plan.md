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

**R7 — A F2 apaga a tela de catálogo, e isso obriga uma decisão que o plano não tinha.**
O roadmap já decidiu que a tela de catálogo do app de demonstração sai neste item
("apagar o arquivo `content_meta_bar.dart`, a tela de catálogo e o restante da
branch `parked/demo-app-internet-e-casca`"). Consequência que ninguém escreveu:
**hoje é o catálogo que escolhe o slug**, e sem ele o app não sabe o que abrir.
O `driva_client` **não tem API de listagem** — e não deve ter: `GET /v1/public/contents`
lista o projeto inteiro, o que serve a um app de demonstração e a mais ninguém.
**Decidido:** o app passa a abrir um **slug de entrada vindo de config**
(`DEFAULT_SLUG` no `--dart-define-from-file`, ao lado de `API_BASE_URL` e
`PUBLISHABLE_KEY` que já existem em `apps/driva_demo_app/config/*.json`), com o
campo para trocar de slug e o botão de recarregar que a fase P3 do §4 já previa.
É a forma que um app de cliente de verdade usaria: ele conhece os slugs dele.

**R8 — Fronteira com o item 43, para não apagar duas vezes.** A branch
`parked/demo-app-internet-e-casca` (commit `c1d16c0`) remove **o `content_meta_bar.dart`
e a casca da tela de conteúdo no mesmo commit**. A casca (`appBar`/`bottomNavigationBar`)
é **F0 do item 43** por decisão de 2026-08-17; o `content_meta_bar.dart` é desta F2.
Quem chegar primeiro apaga o arquivo; o outro encontra o trabalho feito e segue.

**R9 — Regressão a corrigir ANTES do E2E (F4), achada pela supervisão da F2.**
A migração apagou `missing_key_view.dart` junto com o resto da tela de catálogo.
Ele existia por um motivo: os `config/*.json` versionados trazem
`PUBLISHABLE_KEY: "cole-aqui-a-chave-do-projeto"` (nenhuma chave real é
versionada), e o app **explicava como obter a chave** em vez de falhar genérico —
isso está anunciado como feature no CHANGELOG da fatia 1. Hoje, chave placeholder
ou errada devolve 404 do servidor, o `_fetchAndValidate` retorna `null` e a tela
cai na **mesma** `ContentErrorView` de "sem rede". **Dois modos de falha
distintos, um único estado visual** — exatamente o que a regra de E2E do projeto
proíbe, e o que já custou uma tarde na fatia 1 (o APK release que abria com a
vitrine vazia por causa do placeholder). Quem executar a F4 corrige isto antes de
rodar o roteiro, senão o primeiro erro do E2E será indistinguível de falta de
internet. **[Superado em 2026-08-27: a F4 saiu do caminho crítico com a suspensão
do E2E; o conserto do R9 virou as Fases A e B do §3c (R10), provado por teste de
widget em vez de roteiro.]**

**R6 — O mapa do §5 fica assim** (o P1 sai; F1 e F3 são as duas frentes que
correm juntas, e tocam arquivos disjuntos — `packages/driva_client/lib` × `docs/`
e `README.md`):

```
F1 (runtime) ─┬─► F2 (demo app migra) ─► F4 (E2E) ─► F5 (bateria)
F3 (docs) ────┘
```

## 3c. R10 — Fechamento da fatia 2 (revisão de 2026-08-27): conserto do R9 + F5 sob a pirâmide

Escrita depois de duas decisões do dono que superam a P5 do §4 e as fases F4/F5 do R5 —
isto é **correção de forma por decisão já registrada, não desvio novo** (sem entrada de
variance): **(a) 2026-08-20** — E2E suspenso no repositório inteiro e revogação da regra
"bateria por último" (a F5 deixou de depender da F4, que saiu do caminho crítico — ver
`docs/roadmap.md` › Marco 5, item 25, e `CLAUDE.md` › _Método de trabalho_);
**(b) 2026-08-21** — régua de conclusão: **a pirâmide automatizada verde fecha o item**; o
ciclo em aparelho já está registrado na linha do item 25 em _Validações de campo
pendentes_ do `docs/roadmap.md`. **Onde o §3b (R5, R9), o §4 P5 e o §7 contradizem esta
seção, ela ganha.**

**Estado verificado em 2026-08-27 (develop):**

- `packages/driva_client/test/` tem **só** `content_repository_test.dart` — o widget test
  `driva_content_test.dart` previsto na P5 não existe.
- `apps/driva_demo_app/test/` tem **só** `android_manifest_test.dart`; `ContentPage`,
  `ContentSlugBar` e `ContentErrorView`
  (`lib/modules/published_module/presentation/content/`) não têm cobertura de widget.
- **Os 4 testes que a F2 apagou não voltam literais** (`published_content_model_test`,
  `catalog_cubit_test`, `content_cubit_test`, `rendered_content_view_test` — commit
  `396fd9a`): cobriam camadas que deixaram de existir (`data/`, cubits, catálogo). A
  cobertura equivalente é a desta seção — repositório e widget no package, widget no app.
- **A raiz técnica do R9, confirmada no código:** `_fetchAndValidate`
  (`packages/driva_client/lib/src/content_repository.dart`) colapsa **todas** as falhas em
  `null` — exceção de rede, 404, status ≠ 200, corpo indecodificável, spec inválido — e
  `load()` completa em silêncio; `_DrivaContentState._subscribe`
  (`packages/driva_client/lib/src/driva_content.dart`) fabrica no `onDone` um único
  `StateError` genérico. O `errorBuilder` recebe sempre o mesmo objeto: **o app não tem
  como distinguir nada.** O conserto exige mexer no contrato público do package.

### Decisões técnicas travadas

**D-R10.1 — A causa da falha entra no contrato público do `driva_client`, sem breaking.**
Nasce `DrivaLoadFailure` (com `slug` e `cause`) e o enum
`DrivaLoadCause {network, notFound, invalidSpec, serverError}`. Mapa: exceção do
`http.Client` → `network`; resposta 404 → `notFound`; corpo que não vira spec válido
(decode, envelope, `parseContentSpec` `Left` — inclusive `specVersion` mais novo) →
`invalidSpec`; qualquer outro status ≠ 200/304 → `serverError`. **`load()` passa a fechar
com `DrivaLoadFailure` no canal de erro do `Stream` quando nada pôde ser servido** (sem
cache, sem 200 válido, sem fallback), em vez de completar em silêncio — a conclusão
silenciosa é exatamente a falha silenciosa que o R9 existe para matar. Quando cache ou
fallback serviu, nada muda. A garantia "nenhuma exceção sobe para a tela do cliente"
**permanece**: o `DrivaContent` já tem `onError` e entrega o objeto ao `errorBuilder`; a
assinatura `DrivaErrorBuilder = Widget Function(BuildContext, Object)` **não muda** — app
que ignora o tipo continua funcionando. É mudança de comportamento documentada, não de
assinatura: `packages/driva_client/pubspec.yaml` 0.1.0 → 0.2.0 (workspace-only, nenhum
dependente externo).

**D-R10.2 — O 404 não separa "chave inválida" de "slug não publicado" — e não vai
separar.** É decisão de segurança registrada da fatia 1 (CHANGELOG: 404, não 401, para não
distinguir "chave errada" de "conteúdo inexistente" para quem sonda de fora), e este plano
não a reabre. O caso **placeholder** — o que custou a tarde do APK de vitrine vazia — é
distinguível **localmente**: a chave real tem formato `pk_...` (D1), o placeholder dos
`config/*.json` não. Logo o app trata: chave sem prefixo `pk_` → estado "falta a chave"
**sem chamada de rede**; 404 com chave bem-formada → estado "conteúdo não encontrado",
cujo texto nomeia as duas causas possíveis (slug sem publicação **ou** chave inválida).

**D-R10.3 — `Driva.init` ganha `httpClient` opcional.** Hoje só o construtor de
`DrivaContentRepository` aceita `http.Client`, e `Driva.init` não o repassa — o app
hospedeiro **não tem como** simular rede em teste de widget. `Driva.init(config,
{http.Client? httpClient})` encaminha ao repositório. Adição pura, sem breaking; é o que
torna a bateria da Fase B possível.

**Contrato congelado (o que a Fase B pode assumir antes de a Fase A terminar):**

```dart
enum DrivaLoadCause { network, notFound, invalidSpec, serverError }

class DrivaLoadFailure implements Exception {
  const DrivaLoadFailure({required this.slug, required this.cause});
  final String slug;
  final DrivaLoadCause cause;
}

static Future<void> Driva.init(DrivaConfig config, {http.Client? httpClient})
```

### Fase A — `driva_client`: causa tipada + bateria do package **(1 PR)** — ✔ **Concluída em 2026-08-27** (`cdcc022`..`9d0e83e`; 16 testes verdes no package, `flutter analyze` limpo)

Branch `feature/25-driva-client-causa-tipada`, de `develop`.

#### T-A1 — Contrato e repositório emitem a causa **[paralela: não — é a base]** **[sub-agente: especialista-dados]** — ✔ **Entregue em 2026-08-27** (commit `cdcc022`, 13 testes verdes)

Criar `packages/driva_client/lib/src/driva_load_failure.dart` com o contrato congelado
acima e exportá-lo no barrel. Em `content_repository.dart`, `_fetchAndValidate` passa a
devolver resultado que preserva a causa, e `load()` fecha com `DrivaLoadFailure` no canal
de erro quando nada foi servido (D-R10.1). `Driva.init` ganha `httpClient` opcional
(D-R10.3). A bateria entra **junto**: os casos novos em `content_repository_test.dart`
(o teste existente "falha total sem fallback não emite e não lança" é reescrito — agora a
falha total **emite erro tipado**, e continua sem lançar exceção não capturada). Bump
0.2.0 + entrada no `CHANGELOG.md` raiz (`Unreleased`) no mesmo PR.

**DoD**
- `packages/driva_client/lib/src/driva_load_failure.dart` existe com a classe `DrivaLoadFailure` (campos `slug` e `cause`) e o enum `DrivaLoadCause` com exatamente os valores `network`, `notFound`, `invalidSpec` e `serverError`; `grep -n "driva_load_failure" /home/euclidesgc/development/driva/packages/driva_client/lib/driva_client.dart` mostra o export no barrel.
- `packages/driva_client/test/content_repository_test.dart` prova, com `MockClient`, que `load()` de um slug sem cache e sem fallback termina com erro `DrivaLoadFailure` nas quatro causas: exceção de rede → `cause == DrivaLoadCause.network`, resposta 404 → `notFound`, resposta 500 → `serverError`, resposta 200 com spec que não passa no parse → `invalidSpec`.
- No mesmo arquivo de teste, quando há fallback embarcado servível a falha de rede **não** produz erro no stream — o teste `specVersion incompatível cai no fallback embarcado` segue passando com a mesma expectativa de emissão.
- `Driva.init` em `packages/driva_client/lib/src/driva.dart` aceita o parâmetro nomeado opcional `httpClient` e um teste prova que o client injetado é o usado (o `MockClient` do teste registra ao menos uma requisição feita via `Driva.instance.repository.load`).
- `packages/driva_client/pubspec.yaml` declara `version: 0.2.0`, e a seção `Unreleased` de `/home/euclidesgc/development/driva/CHANGELOG.md` tem entrada citando `driva_client` e a causa tipada.
- `cd packages/driva_client && flutter analyze && flutter test -r compact` saem verdes.

#### T-A2 — Widget test do `DrivaContent` **[paralela: sim — ∥ T-B1, arquivos disjuntos]** **[sub-agente: especialista-apresentacao]** _(dep. T-A1)_ — ✔ **Entregue em 2026-08-27** (`74baad0` conserto do `onDone`, `75ed043`, `e6593af`; 3 testes de widget)

Criar `packages/driva_client/test/driva_content_test.dart` (o arquivo que a P5 previa e
nunca nasceu): loading → conteúdo; falha total entrega o `DrivaLoadFailure` tipado ao
`errorBuilder`; sem `errorBuilder`, nada explode. Usa `Driva.resetForTesting()` +
`Driva.init(..., httpClient: MockClient(...), cache: MemoryCacheStore())`.
**Inclui um conserto mínimo, achado na entrega da T-A1** (refinamento por realidade de
implementação, não mudança de exigência — o DoD abaixo não muda): em
`packages/driva_client/lib/src/driva_content.dart`, o `onDone` de `_subscribe` fabrica o
`StateError` genérico sempre que `_spec == null` e **não checa `_error`** — e como stream
que fecha com erro também dispara `onDone`, ele **sobrescreve** o `DrivaLoadFailure` que o
`onError` acabou de guardar (antes da T-A1 não havia erro tipado para sobrescrever). O
`onDone` passa a retornar também quando `_error != null`, mantendo o `StateError` só para
o caso real de stream que completa sem emitir nada.

**DoD**
- `packages/driva_client/test/driva_content_test.dart` existe e `cd packages/driva_client && flutter test -r compact test/driva_content_test.dart` sai verde.
- Um teste prova que o widget entregue pelo `loadingBuilder` está na árvore antes da primeira emissão e que, após a resposta 200 do `MockClient`, o conteúdo do spec está renderizado (finder por chave ou semântica, não por texto de log).
- Um teste com resposta 404, sem cache e sem fallback, captura o argumento `error` recebido pelo `errorBuilder` e asserta `error is DrivaLoadFailure && error.cause == DrivaLoadCause.notFound`.
- Um teste com falha total e **sem** `errorBuilder` termina com `SizedBox.shrink` na árvore e `tester.takeException()` retornando `null`.
- Todos os testes passam por `Driva.resetForTesting()` em `setUp` ou `tearDown` — rodar o arquivo duas vezes em sequência passa igual.

#### T-A3 — Guia de integração acompanha o contrato **[paralela: sim — só toca `docs/`]** **[textual — sem supervisor, cobrada no lote da fase]** — ✔ **Entregue em 2026-08-27** (`b50f383`)

`docs/25-entrega-app-cliente/integracao.md`: a seção do `errorBuilder` (e a tabela de
cenários) passa a documentar `DrivaLoadFailure`/`DrivaLoadCause`, o comportamento novo de
`load()` (erro tipado no stream em falha total — relevante para quem consome o repositório
direto) e o `httpClient` do `Driva.init` para testes do app hospedeiro.

**DoD**
- `grep -c "DrivaLoadCause" /home/euclidesgc/development/driva/docs/25-entrega-app-cliente/integracao.md` ≥ 2 (seção do `errorBuilder` e tabela de cenários).
- O guia diz explicitamente que `load()` fecha com `DrivaLoadFailure` quando nada pôde ser servido, e mostra o `Driva.init(..., httpClient:)` num exemplo de teste.
- Nenhuma promessa do guia contradiz o código entregue na T-A1 (conferência de leitura do QA no lote da fase).

### Fase B — demo app: três estados de falha visualmente distintos + bateria do app **(1 PR, empilhado na Fase A)** — ✔ **Concluída em 2026-08-27** (`def242c`..`fb958f2`; suíte do app verde, `gates_guard.sh` limpo)

Branch `feature/25-demo-app-estados-de-falha`, criada **da branch da Fase A** (pilha,
`docs/GITFLOW.md` § 6 — nunca dois PRs independentes contra `develop`).

#### T-B1 — Os três estados na UI **[paralela: sim — ∥ T-A2 após a T-A1; arquivos disjuntos]** **[sub-agente: especialista-apresentacao]** _(dep. T-A1 — compila contra o contrato congelado)_ — ✔ **Entregue em 2026-08-27** (`def242c`, mais `07a5721` com o token `AppIconSizes.emptyState` achado pelo QA da fase)

Em `apps/driva_demo_app/lib/modules/published_module/presentation/content/widgets/`:
criar `content_key_missing_view.dart` (devolve a feature anunciada no CHANGELOG da fatia
1: ícone de chave + "Falta a chave publicável" + instrução nomeando `PUBLISHABLE_KEY` no
config do flavor e o `tool/run_demo.sh` — o texto do `missing_key_view.dart` apagado é o
gabarito, recuperável em `git show 396fd9a^`); criar `content_not_found_view.dart` (ícone
próprio + texto nomeando as duas causas da D-R10.2 + botão de tentar de novo); ajustar o
texto do `content_error_view.dart` para falar de conexão/servidor. Em `content_page.dart`:
chave sem prefixo `pk_` → `ContentKeyMissingView` sem montar `DrivaContent` (D-R10.2); com
chave bem-formada, o `errorBuilder` escolhe a view pela causa. A chave chega pelo
construtor; `pageBuilder` continua o único ponto que toca o `getIt`. Acessibilidade: cada
estado com ícone **e** texto próprios — cor nunca é o único sinal. Tokens de
`core/theme/` (o `gates_guard.sh` cobra).

**DoD**
- `apps/driva_demo_app/lib/modules/published_module/presentation/content/widgets/content_key_missing_view.dart` e `content_not_found_view.dart` existem, um widget por arquivo, e os três estados (junto com `content_error_view.dart`) têm ícone e texto distintos entre si — nenhum par compartilha o mesmo ícone.
- O texto do `ContentKeyMissingView` menciona literalmente `PUBLISHABLE_KEY` e `tool/run_demo.sh` (como obter a chave).
- Em `apps/driva_demo_app/lib/modules/published_module/presentation/content/page/content_page.dart`, chave que não começa com `pk_` resulta em `ContentKeyMissingView` na árvore **sem** nenhum `DrivaContent` construído; com chave `pk_...`, o `errorBuilder` devolve `ContentNotFoundView` quando o erro é `DrivaLoadFailure` com `cause == DrivaLoadCause.notFound` e `ContentErrorView` nos demais casos.
- `grep -c "getIt" apps/driva_demo_app/lib/modules/published_module/presentation/content/page/content_page.dart` mostra ocorrência apenas dentro de `pageBuilder`.
- `cd apps/driva_demo_app && flutter analyze` verde e, da raiz do repo, `bash scripts/gates_guard.sh` verde.

#### T-B2 — Bateria do app: os três estados provados distintos **[paralela: não — dep. T-B1; mesmo agente da T-B1, retomado]** **[sub-agente: especialista-apresentacao]** — ✔ **Entregue em 2026-08-27** (`a91869a`, mais `fb958f2` com a distinção por `find.bySemanticsLabel`; 6 testes de widget)

Criar `apps/driva_demo_app/test/modules/published_module/presentation/content/`
`content_page_test.dart` e `content_slug_bar_test.dart`. É a F5 do roadmap: a cobertura
equivalente aos 4 testes apagados, no desenho novo. Finders por chave/semântica (regra do
repo). `http` entra em `dev_dependencies` do app para o `MockClient`.

**DoD**
- `apps/driva_demo_app/test/modules/published_module/presentation/content/content_page_test.dart` prova os três estados, cada um por finder próprio: (1) chave placeholder → `ContentKeyMissingView` presente e `find.byType(DrivaContent)` vazio; (2) chave `pk_test` + `MockClient` respondendo 404 → `ContentNotFoundView` presente; (3) chave `pk_test` + `MockClient` lançando exceção → `ContentErrorView` presente. Os casos 2 e 3 usam `Driva.resetForTesting()` + `Driva.init(..., httpClient: MockClient(...))`.
- No mesmo arquivo, nenhum teste vaza exceção: `tester.takeException()` é `null` em todos.
- `apps/driva_demo_app/test/modules/published_module/presentation/content/content_slug_bar_test.dart` prova: submeter um slug novo chama `onSubmit` com o valor sem espaços das pontas; submeter vazio ou o slug atual **não** chama `onSubmit`.
- `cd apps/driva_demo_app && flutter test -r compact` sai verde, com `test/android_manifest_test.dart` intocado e passando.

#### T-B3 — CHANGELOG do app **[paralela: sim]** **[textual — sem supervisor, cobrada no lote da fase]** — ✔ **Entregue em 2026-08-27** (`a55cd51`)

Entrada em `Unreleased` do `CHANGELOG.md` raiz, no mesmo PR: os três estados de falha do
app de demonstração, nomeando a regressão (a feature "explica como obter a chave" da fatia
1 volta) e a distinção nova chave × não-encontrado × rede.

**DoD**
- A seção `Unreleased` de `/home/euclidesgc/development/driva/CHANGELOG.md` tem entrada citando os três estados de falha do `apps/driva_demo_app` e o retorno da instrução de obtenção da chave.

#### T-C — Fechamento do item 25 **[paralela: sim — só toca `docs/`]** **[textual — sem supervisor, cobrada no lote da fase]** — ✔ **Entregue em 2026-08-27** (lote do QA: roadmap, `final_report.md`, marcas deste plano, README do package, `ERROR_LOGS.md`)

No PR da Fase B: `docs/roadmap.md` — F5 do item 25 vira `[x]`, o item 25 vira `[x]`, o
parágrafo do gargalo (linha ~32) atualizado, e a linha do 25 em _Validações de campo
pendentes_ deixa de citar o pré-requisito R9 como pendente (o que resta lá é só o ciclo em
aparelho). `docs/25-entrega-app-cliente/final_report.md` escrito. Marcas de progresso
neste `plan.md`.

**DoD**
- `docs/roadmap.md`: a F5 e o item 25 marcados `[x]`; a célula "Por quê" da linha do item 25 em _Validações de campo pendentes_ não afirma mais que o R9 está por corrigir.
- `docs/25-entrega-app-cliente/final_report.md` existe, citando as Fases A e B e as decisões D-R10.1–3.
- Este `plan.md` com as fases A e B marcadas como concluídas.

### Ordem de despacho

```
T-A1 (base) ─┬─► T-A2 (∥, worktree A) ─┐
             └─► T-B1 (∥, worktree B) ─► T-B2 (mesmo agente) ─┐
T-A3 ∥ T-B3 ∥ T-C (textuais, lote do QA) ─────────────────────┴─► consolidação
```

1. **T-A1** sozinha — todo o resto compila contra o que ela entrega. ✔ **Entregue**
   (`cdcc022`, 2026-08-27).
2. **T-A2 ∥ T-B1** — worktrees separadas (branch A × branch B empilhada); arquivos
   disjuntos (`packages/driva_client/` × `apps/driva_demo_app/`). ✔ **Entregues**
   (`e6593af` / `def242c`, 2026-08-27).
3. **T-B2** — mesmo agente da T-B1, retomado (contexto quente; é quem sabe onde estão as
   chaves dos widgets que acabou de criar). ✔ **Entregue** (`a91869a`).
4. **T-A3 ∥ T-B3 ∥ T-C** — textuais, a qualquer momento após a T-A1; QA cobra no lote.
   ✔ **Entregues** (`b50f383` / `a55cd51` / lote da T-C).
5. **Consolidação:** suíte completa nos dois alvos + `bash scripts/gates_guard.sh` na
   branch integrada da pilha; publicar a pilha (skill `empilhar-prs`). ✔ **Cancela de
   máquina verde em 2026-08-27** (ver o _DoD do fechamento_ abaixo); resta publicar a
   pilha em dois PRs (Fase A → `develop`, Fase B → Fase A).

### DoD do fechamento (substitui as linhas riscadas do §7) — ✔ **fechado em 2026-08-27, na branch integrada da pilha (`fb958f2` + o lote de docs da T-C)**

- [x] `cd packages/driva_client && flutter analyze && flutter test -r compact` verdes. _(`No issues found!`; 16/16 `All tests passed!`)_
- [x] `cd apps/driva_demo_app && flutter analyze && flutter test -r compact` verdes. _(`No issues found!`; 7/7 `All tests passed!` — 6 de widget + `android_manifest_test.dart` intocado)_
- [x] `bash scripts/gates_guard.sh` verde na branch integrada da pilha. _(Gates 1 e 4 limpos)_
- [x] Os três estados de falha do app provados **visualmente distintos por teste de widget** (chave placeholder × 404 × sem rede), cada um por finder próprio — `content_page_test.dart` é a prova. _(por `find.byType` e por `find.bySemanticsLabel`, com `takeException()` nulo nos três)_
- [x] `load()` do `driva_client` provado emitindo `DrivaLoadFailure` com as quatro causas em `content_repository_test.dart`.
- [x] `CHANGELOG.md` (`Unreleased`) com as duas entradas, cada uma no PR da sua fase.
- [x] `docs/roadmap.md`: item 25 `[x]`, F5 `[x]`, linha de _Validações de campo pendentes_ conferida; `docs/25-entrega-app-cliente/final_report.md` escrito.

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

### P5 — Testes (por último) **[Superada em 2026-08-27 pelo §3c (R10)]**

> Escrita antes das decisões do dono de 2026-08-20 (E2E suspenso; revogação de "bateria
> por último") e de 2026-08-21 (pirâmide verde fecha o item). O que dela continua vivo —
> `driva_content_test.dart` e a cobertura do app — está redistribuído nas Fases A e B do
> §3c, junto das fases que cobrem. O "e2e de contrato no `e2e_hml.sh`" não se escreve
> (suspensão); o contrato Jest existente (`backend/test/public-rate-limit.e2e-spec.ts`)
> continua. A suíte do `sdui_flutter` já provou a remoção do `DrivaContent` na F1.

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

> **Revisto em 2026-08-27 (R10):** as linhas de E2E abaixo estão superadas pela suspensão
> de 2026-08-20 e pela régua de 2026-08-21 — a régua vigente é o **DoD do fechamento** no
> §3c; o ciclo em aparelho está na linha do item 25 em _Validações de campo pendentes_ do
> `docs/roadmap.md`.

- [x] `pnpm build`/`pnpm lint` verdes; `flutter analyze` verde nos 4 pacotes/apps do workspace. _(recobrado pelo DoD do §3c a cada fase)_
- [x] Migração da chave publicável aplicada em hml sem projeto órfão (contagem antes/depois). _(fatia 1)_
- [x] ~~E2E de contrato da rota pública 100% PASS contra o hml.~~ _(17 PASS na fatia 1, antes da suspensão; o contrato Jest — `backend/test/public-rate-limit.e2e-spec.ts` — segue na CI)_
- [ ] ~~**E2E do ciclo completo** com o showcase apontado para o hml (publicar → aparecer; salvar sem publicar → não aparecer).~~ _(suspenso — registrado em_ Validações de campo pendentes _do `docs/roadmap.md`)_
- [x] `docs/25-entrega-app-cliente/final_report.md` + guia de integração. _(guia entregue na fatia 2 e atualizado pela T-A3; `final_report` escrito na T-C, 2026-08-27)_
- [x] `CHANGELOG.md` com o **breaking change** do `sdui_flutter` (remoção do `DrivaContent`).
- [x] `docs/roadmap.md`: item 25 `[x]`. _(T-C do §3c, 2026-08-27 — F5 e fatia 2 também marcadas, e a linha de_ Validações de campo pendentes _reescrita: o pré-requisito R9 saiu, sobrou o ciclo em aparelho)_

## 8. Perguntas para o humano (bloqueiam o P1)

1. **Projeto arquivado sai do ar?** O plano assume **sim** (404 na rota pública). Alternativa: continuar servindo, já que arquivar é organização do editor, não despublicação. **Precisa de decisão** — muda o comportamento visível de um app em produção.
2. **401 ou 404 para chave ausente/ inválida?** Assumido 401 para ausente, 404 para inválida.
3. **Uma chave por projeto ou por ambiente?** Assumido: uma por projeto. Se dev/prod do cliente precisarem de chaves distintas, vira `ProjectKey` (tabela) — decidir agora é mais barato que migrar depois.
4. **`http` como dependência do package público** — confirma? (Alternativa: aceitar um `Client` injetado e não depender de nada, deixando o app escolher. Mais puro, um pouco menos conveniente. O plano assume `http` com `Client` injetável no construtor — o melhor dos dois.)
