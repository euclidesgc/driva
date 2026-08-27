# Error Logs

> O que cada erro monitorado significa, quem dispara e em que situação.

## Redes globais (erros imprevistos) — `apps/driva_editor/lib/bootstrap.dart`

| Rede | Captura | Destino |
|---|---|---|
| `FlutterError.onError` | Erros do framework (build/layout/paint) | `log(name: 'app')` — trocar por Crashlytics/Sentry em produção |
| `PlatformDispatcher.onError` | Erros assíncronos não tratados | idem |
| `runZonedGuarded` | O que escapar de tudo (inclusive bootstrap) | idem |
| `AppBlocObserver.onError` | Erros dentro de cubits (o que escapou do Either) | `log(name: '<Cubit>')` + rastro de transições em dev |

## Failures tipadas (erros previstos) — `core/error/failure.dart`

| Failure | Quem dispara | Situação | UX |
|---|---|---|---|
| `NetworkFailure` | Repositórios (Dio) | Timeout/sem conexão/5xx | Mensagem + "tentar de novo"; no save, `saveFailed` sem perder o documento |
| `NotFoundFailure` | Repositórios | 404 (conteúdo inexistente ou de outro tenant — o backend não distingue, de propósito) | Tela tratada com volta à lista. No editor (item 46), a UX passa a citar o projeto em que procurou (via `GetProjectUseCase`, já buscado para o breadcrumb): "não encontramos este conteúdo no projeto _\<Nome\>_" quando o projeto da URL resolve, "este link aponta para um projeto que não existe" quando não resolve, e "não encontramos este conteúdo" (sem nomear nada) quando a **consulta do projeto** falhou por rede — nesse caso o app não sabe se o projeto existe, e afirmar que não existe repetiria o defeito que o item corrige. Mudou a **apresentação**; a **semântica** da falha (404 do backend, que não distingue inexistente de outro tenant) não muda |
| `ConflictFailure` | Repositório de conteúdos (traduz o `409`) | `slug` já em uso no projeto ao criar | Mostra o `suggestedSlug` e "slug já em uso neste projeto"; o cliente auto-resolve para o slug sugerido |
| `ValidationFailure` | `parseContentSpec` (kernel), models zard, 400 do backend | Spec/payload fora do schema (inclui `slug` fora de `^[a-z][a-z0-9-]*$`) | Mensagem descritiva; save barrado pela trava do `SaveDraftUseCase` |
| `UnexpectedFailure` | Repositórios | O resto | "Algo deu errado." |

## Runtime do app cliente (`packages/driva_client`, 0.2.0+) e o app de demonstração

`DrivaContentRepository.load(slug)` resolve **memória → disco → rede**. Enquanto
alguma fonte serve conteúdo **não há falha**: rede caída com cache local vira só
uma linha de log. `DrivaLoadFailure {slug, cause}` nasce apenas quando nada,
absolutamente nada, pôde ser desenhado — sem cache, sem 200 válido, sem fallback
embarcado — e fecha o **canal de erro** do `Stream<ContentSpec>`. Quem usa
`DrivaContent` recebe o objeto no `errorBuilder` (nenhuma exceção sobe para a
árvore); quem consome o repositório direto precisa tratar o `onError`.

| `DrivaLoadCause` | Quem dispara | Situação | UX no app de demonstração |
|---|---|---|---|
| `network` | `_fetchAndValidate` | O `http.Client` lançou — sem conexão, DNS, timeout; nunca houve resposta HTTP | `ContentErrorView` (nuvem cortada): "pode ser sua conexão ou o servidor" + tentar de novo |
| `notFound` | idem | `404` da rota pública: slug sem publicação **ou** chave publicável inválida — a API não distingue os dois, de propósito | `ContentNotFoundView` (lupa cortada), nomeando as **duas** causas possíveis + tentar de novo |
| `invalidSpec` | idem | Corpo indecodificável, envelope sem `spec`, ou `parseContentSpec` devolvendo `Left` — inclusive `specVersion` mais novo que o do app instalado | `ContentErrorView` (é falha do servidor do ponto de vista do usuário; tentar de novo não resolve, e é a única causa em que não resolve) |
| `serverError` | idem | Qualquer outro status ≠ 200/304, inclusive um `304` chegando sem cache local para revalidar | `ContentErrorView` |

Fora da família tipada, e **antes** de qualquer rede: chave publicável fora do
formato `pk_...` (o placeholder que os `config/*.json` versionam) não vira
`DrivaLoadFailure` nenhum — a `ContentPage` mostra `ContentKeyMissingView` e nem
monta o `DrivaContent`. Todos os caminhos acima também escrevem
`log(name: 'driva_client')`.

## Backend (`backend/`)

- 400 — DTO inválido (class-validator, inclui `slug` fora de `^[a-z][a-z0-9-]*$`) ou `spec.specVersion` não suportada.
- 404 — conteúdo inexistente **no tenant do header** (`x-project-id`).
- 409 — `slug` já em uso no projeto (`@@unique([projectId, slug])`), com `suggestedSlug` (slug livre) no corpo.
- Logs de request não são persistidos ainda; observabilidade real entra com o serving.
