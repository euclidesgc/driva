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
| `NotFoundFailure` | Repositórios | 404 (página inexistente ou de outro tenant) | Tela tratada com volta à lista |
| `ValidationFailure` | `parsePageSpec` (kernel), models zard, 400 do backend | Spec/payload fora do schema | Mensagem descritiva; save barrado pela trava do `SaveDraftUseCase` |
| `UnexpectedFailure` | Repositórios | O resto | "Algo deu errado." |

## Backend (`backend/`)

- 400 — DTO inválido (class-validator) ou `spec.specVersion` não suportada.
- 404 — página inexistente **no tenant do header** (`x-project-id`).
- Logs de request não são persistidos no I1; observabilidade real entra com o serving (I4).
