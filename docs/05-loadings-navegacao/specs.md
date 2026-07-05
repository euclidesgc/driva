# Specs — Enxugar loadings e rebuilds da navegação

> Roadmap item 2 (origem: item 10 de `docs/03-melhorias/`). Documento vivo: descreve o que a feature **é** e o comportamento-alvo. Dono: PM. Base técnica levantada e validada com o tech-lead sobre o estado atual do repo. UI em pt-BR.

## Contexto / problema

Relato do dev humano (item 10): *"As telas de loading estão esquisitas, acho que tem muita coisa sendo rebuildada sem necessidade. Percebi que quando clica em criar no form de novo conteúdo, a tela entra em load, e logo em seguida vai para a tela de construção. Esse loading talvez não seja necessário, e acho que é ele que está causando esse efeito estranho. A transição de telas ficou ótima."*

A transição de rota em si já está boa. O alvo desta feature é o **flash de loading que a lista de conteúdos dá antes de navegar para o editor ao criar um conteúdo**, e o **loading full-screen desnecessário em operações que não precisam blanquear a tela** (excluir). Não é o editor em uso (rebuilds de paleta/árvore/canvas/inspector já foram tratados no item 3b, concluído) — é a **navegação e as telas de carregamento** da lista.

## Diagnóstico técnico

Fluxo real de **criar conteúdo → editor** (arquivos absolutos):

1. `apps/driva_editor/lib/modules/contents_module/presentation/content_list/content_list_page.dart` → `ContentListPage._showCreateDialog`: no `_submit` do formulário, faz `final created = await cubit.create(...)` e, no sucesso do `fold`, `context.goNamed('editor', pathParameters: {'id': content.id})`.
2. `apps/driva_editor/lib/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart` → `ContentListCubit.create()`: no sucesso executa **`await load()`** antes de retornar.
3. `ContentListCubit.load()`: faz `emit(ContentListLoading())` → aguarda `getContents()` → `emit(ContentListLoaded/Empty)`.

Consequência: ao criar, a lista **pisca o `CircularProgressIndicator`** (estado `ContentListLoading`, renderizado pelo `BlocBuilder` em `content_list_page.dart`) e **repinta a grade inteira** ANTES de navegar; e a navegação fica **bloqueada** esperando um `getContents()` redundante (o fake `ContentsRepositoryFake.getContents` em `data/repositories/contents_repository_fake.dart` tem 300ms de latência; em produção é um round-trip HTTP).

**A raiz:** `create()` chama `load()` incondicionalmente no sucesso, mas o único chamador navega para fora imediatamente. Como as rotas são **flat** (`apps/driva_editor/lib/app_router.dart`: `ContentsRoutes.route` e `EditorRoutes.route` são irmãs de topo, sem `ShellRoute`/keep-alive), o `goNamed('editor')` **descarta a `ContentListPage` e dispõe o `BlocProvider`** logo em seguida (validado com o tech-lead). O reload é **desperdício duplo**: (a) mostra um spinner e repinta uma grade que será destruída, e (b) bloqueia a navegação por um round-trip inútil. Ao voltar para a lista, o `pageBuilder` roda de novo com `..load()`, então a lista sempre carrega fresca — não há nada a "manter atualizado" antes de sair.

Operação de **excluir** (mesma família): `ContentListCubit.delete()` também faz `emit(ContentListLoading())` + `load()`. Aqui o usuário **permanece** na lista, então recarregar faz sentido, mas o spinner full-screen **blanka a grade inteira** por um round-trip só para remover um card — o "loading esquisito" também aparece aqui.

Estado do **editor** (fora do escopo, registrado para não haver dúvida): `apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_cubit.dart` → `EditorCubit.loadContent` emite `EditorLoading` e busca o spec via `LoadContentUseCase` (round-trip legítimo — o `ContentSummary` devolvido pelo create **não carrega o spec**, confirmado em `domain/entities/content_summary.dart`). O `editor_page.dart` já usa `buildWhen: previous.runtimeType != current.runtimeType`. Esse loading é **legítimo e já otimizado** — não é o flash do relato.

## Comportamento atual vs. desejado

| Ação | Atual | Desejado |
|---|---|---|
| Criar conteúdo (sucesso) | Fecha o diálogo → lista pisca spinner → repinta a grade (getContents 300ms+) → navega ao editor | Fecha o diálogo → **navega direto ao editor** (só o `EditorLoading` legítimo aparece). Sem flash na lista, sem round-trip redundante |
| Criar conteúdo (conflito de slug) | Reabre o diálogo com sugestão livre (sem reload) | **Inalterado** — já é o comportamento correto |
| Criar conteúdo (outra falha) | Snackbar com a mensagem do erro | **Inalterado** |
| Excluir conteúdo | Spinner full-screen blanka a grade → recarrega | Grade permanece visível; o card **some na hora** (remoção otimista). Em falha: recarrega + snackbar (item some por engano volta) *(ver ambiguidade B)* |
| Voltar do editor para a lista | `pageBuilder` remonta e recarrega (load fresco) | **Inalterado** |

## Escopo

**Entra:**
- Eliminar o `await load()` (e portanto o `emit(ContentListLoading)`) do **caminho de sucesso** de `ContentListCubit.create()`, navegando direto ao editor. O flash e o round-trip redundante somem.
- Reescrever/ajustar os testes automatizados **já existentes** que estão acoplados a essas emissões (ver "Impacto em testes"), na mesma fase da mudança.
- *(Condicional à ambiguidade B)* Tornar a exclusão otimista: manter a grade visível, remover o card imediatamente, reconciliar em caso de falha.

**NÃO entra:**
- Rebuilds/loading **dentro do editor em uso** (paleta, árvore, canvas, inspector) — já resolvidos no item 3b.
- O `EditorLoading` ao abrir um conteúdo — é um round-trip legítimo (busca o spec).
- **Navegação otimista para o editor** (semear `EditorReady` sem carregar do backend) — descartado: criaria segunda fonte de verdade para o "spec default", a rota é atingível por deep-link/refresh e por card existente (que precisam do `loadContent` de verdade), e o proibido `extra:` do go_router forçaria gambiarra de query-param. Overkill para economizar um round-trip curto (ver ambiguidade C).
- Offline-first / cache local da lista (item de roadmap separado).
- Qualquer mudança na transição de rota em si (o dev disse que já está ótima).

## Impacto em testes (atenção: não é greenfield)

Já existem testes acoplados às emissões de `ContentListLoading` que esta feature vai remover — **reescrevê-los faz parte da mesma fase**, não fica para a bateria "por último":
- `apps/driva_editor/test/modules/contents_module/presentation/content_list/cubit/content_list_cubit_test.dart` — o caso "sucesso: recarrega a lista e devolve o conteúdo criado" afirma `expect: [Loading, Loaded]` + `verify(getContents).called(1)` (vira `expect: []` + `verifyNever(getContents)`, espelhando o caso de conflito). O caso "recarrega após excluir" afirma `expect: [Loading, Empty]` (muda conforme a decisão da ambiguidade B).
- `content_list_page_test.dart` e `content_list_golden_test.dart` — exercitam o fluxo de criar/navegar; revalidar.

## Ambiguidades (decisão humana) com recomendação

**A. O loading da lista ao criar deve sumir por completo?**
Recomendação: **sim, sumir por completo** no caminho de sucesso — navegar direto ao editor. É a leitura literal do relato ("esse loading talvez não seja necessário") e o `EditorLoading` legítimo já cobre a percepção de "está abrindo". Nenhuma perda de informação para o usuário.

**B. A exclusão entra no escopo (vira otimista) ou fica só o create nesta feature?**
Recomendação: **incluir a exclusão como otimista** — é a mesma família de "loading esquisito" e o custo é baixo. Comportamento proposto: remover o card do estado `Loaded` na hora (mapear para `ContentListEmpty` se cair o último); em falha, recarregar + snackbar ("Não foi possível excluir. Tente de novo.") e o card reaparece. Alternativa mais barata (se o humano quiser escopo mínimo): deixar a exclusão para depois e entregar só o create nesta feature. *Precisa de decisão porque muda o desenho de estado e os testes do delete.*

**C. Vale investir em navegação otimista para o editor (abrir o recém-criado sem round-trip)?**
Recomendação: **não** — overkill e risco de segunda fonte de verdade do spec default (detalhado em "NÃO entra"). Reabrir só se a latência real medida incomodar de fato.

**D. A exclusão otimista precisa de affordance de "excluindo" no card, ou some direto?**
Recomendação: **some direto** (otimista puro) — mais simples e a reconciliação em falha (card volta + snackbar) cobre o caso raro. Um estado "excluindo" por card é refinamento opcional, fora do mínimo.

## Critérios de aceite (DoD desta feature)

- Ao criar um conteúdo com sucesso, a lista **não pisca** nenhum `CircularProgressIndicator` e navega direto ao editor; nenhum `getContents()` extra é disparado entre o create e a navegação (verificável no bloc_test com `verifyNever`).
- Conflito de slug e demais falhas do create seguem com o comportamento atual (reabrir diálogo / snackbar).
- *(Se B = sim)* Excluir um conteúdo não blanka a grade: o card some imediatamente; em falha o card reaparece com aviso.
- O `EditorLoading` ao abrir um conteúdo permanece (não é regressão) e o editor em uso continua sem rebuilds indevidos.
- Testes automatizados já existentes (`content_list_cubit_test.dart`, `content_list_page_test.dart`, `content_list_golden_test.dart`) atualizados e verdes.
- Cancela de máquina: `flutter analyze` verde + testes existentes passando. E2E por prints (rodada) confirma visualmente a ausência do flash no fluxo criar → editor.

## Analytics e erros monitorados

- **Analytics:** o projeto ainda não tem infraestrutura de analytics (só `core/observability/app_bloc_observer.dart` para log de transições de estado). Nada novo a instrumentar nesta feature. Se/quando houver analytics, o candidato natural seria o evento "conteúdo criado" — mas está fora deste escopo.
- **Erros monitorados:** falha de exclusão otimista (se B = sim) deve ser sinalizada ao usuário (snackbar) e passa pelo `AppBlocObserver` como qualquer transição; nenhuma nova `Failure` tipada é introduzida (as de `core/error/` já cobrem os casos).
