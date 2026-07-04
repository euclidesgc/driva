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
| `NotFoundFailure` | Repositórios | 404 (conteúdo inexistente ou de outro tenant) | Tela tratada com volta à lista |
| `ConflictFailure` | Repositório de conteúdos (traduz o `409`) | `slug` já em uso no projeto ao criar | Mostra o `suggestedSlug` e "slug já em uso neste projeto"; o cliente auto-resolve para o slug sugerido |
| `ValidationFailure` | `parseContentSpec` (kernel), models zard, 400 do backend | Spec/payload fora do schema (inclui `slug` fora de `^[a-z][a-z0-9-]*$`) | Mensagem descritiva; save barrado pela trava do `SaveDraftUseCase` |
| `UnexpectedFailure` | Repositórios | O resto | "Algo deu errado." |

## Backend (`backend/`)

- 400 — DTO inválido (class-validator, inclui `slug` fora de `^[a-z][a-z0-9-]*$`) ou `spec.specVersion` não suportada.
- 404 — conteúdo inexistente **no tenant do header** (`x-project-id`).
- 409 — `slug` já em uso no projeto (`@@unique([projectId, slug])`), com `suggestedSlug` (slug livre) no corpo.
- Logs de request não são persistidos ainda; observabilidade real entra com o serving.
