---
name: criar-modulo
description: Cria um módulo novo no driva_editor seguindo o gabarito (pages_module e cap. 8 do livro). Use ao iniciar qualquer módulo/feature nova no editor.
---

# Skill: criar um módulo novo

Objetivo: criar um módulo seguindo o gabarito do `pages_module` (e o capítulo 8 de `docs/livro-flutter/`).

Passos:
1. Crie `apps/driva_editor/lib/modules/<nome>_module/` com `domain/`, `data/`, `presentation/`.
2. **Domain**: entidade (`Equatable`, imutável, sem `fromMap`), contrato `abstract interface class` devolvendo `Either<Failure, T>` (fpdart), e **um use case por operação** com método `call()` (mesmo o passa-fica).
3. **Data**: model com (de)serialização validada (**zard** `safeParse` → Either; para specs de página, delegue a `parsePageSpec` do `sdui_core`), impl atrás do contrato. O único `try/catch` mora aqui, traduzindo `DioException` → `Failure` tipada.
4. **Presentation**: cubit com estado `sealed` (via `part of`) + `switch` exaustivo, guarda `isClosed` após `await`; página `StatelessWidget` com `static Widget pageBuilder` (o único lugar que toca o get_it).
5. Fiação: `<nome>_routes.dart` (classe `XRoutes`, rotas nomeadas), `<nome>_injection.dart` (`registerXModule(GetIt)`: repositório lazySingleton, use cases factory), e o barrel público `<nome>_module.dart` que exporta **só** esses dois. Cada pasta termina com seu barrel; os de `data/` são internos.
6. Registre no `injection.dart` e no `app_router.dart` da raiz (que só importam o barrel público).
7. Rode `flutter analyze`. Não dê por pronto com lint vermelho.

Regras inegociáveis (o CLAUDE.md e o lint cobram):
- presentation NUNCA importa data.
- nenhuma classe de lógica chama o service locator por dentro (só o `pageBuilder`).
- estado imutável; cor não carrega informação sozinha (acessibilidade).
- zero build_runner.
