---
name: escrever-testes
description: Escreve a bateria automatizada do driva (unit + widget + golden) — por último, após o E2E atestado e o segundo gate do CISO. Usada pelo QA na etapa 11 do fluxo.
---

# Skill: escrever os testes automatizados

Objetivo: blindar o comportamento **já estável** (o alvo parou de se mexer). Guiado pelo PRD: caminho feliz, exceções, casos de borda.

Convenções (cap. 19 do livro):
- `test/` espelha `lib/` em cada pacote. Sem build_runner: **mocktail** (`class MockX extends Mock implements X {}`) e **bloc_test**.
- Pacotes Dart puro (`sdui_core`): `package:test`. Pacotes Flutter: `flutter_test`.
- `registerFallbackValue` para `any()` com tipo custom; entidades precisam de `Equatable` para os matchers.

O que escrever, por camada:
1. **Use cases** — regra e cada `Failure` previsto (`when(() => repo.x()).thenAnswer(...)`; asserte `Left`/`Right`).
2. **Cubits** — `blocTest` com `build/act/expect` afirmando a **sequência exata** de estados (incluindo falhas). Cubits do editor: cada mutação da árvore (add/move/remove/updateProps) e o save.
3. **Widget** — um teste por estado do sealed (`whenListen` + `BlocProvider.value`); interações (tap, drag, atalhos de teclado); acessibilidade (tooltip presente, seleção não só por cor).
4. **Golden** — captura de referência dos estados visuais estáveis (página renderizada pelo `SduiView`, painéis do editor). Gere com `flutter test --update-goldens` e commite.
5. **Contratos do kernel** — fixtures de `packages/sdui_core/test/fixtures/` validam no schema e renderizam no `sdui_flutter` (o teste de contrato catálogo ↔ registry já existe — mantenha-o passando).

Pirâmide: muito domínio/cubit, alguns widget, poucos integração. DoD: **tudo verde** (`dart test packages/sdui_core`, `flutter test packages/sdui_flutter`, `flutter test apps/driva_editor`) — e só então a tarefa fecha.
