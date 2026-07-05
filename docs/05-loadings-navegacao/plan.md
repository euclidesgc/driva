# Plan — Enxugar loadings e rebuilds da navegação

> **Plano vivo** (guardião: tech-lead). Fonte do escopo: `prd.md` (APROVADO 2026-07-04, decisões A=SIM, B=INCLUIR, C=NÃO, D=some direto) e `specs.md` (mesma pasta). Roadmap item 2.
> UI/docs em pt-BR. Cancela de máquina: `flutter analyze` verde + testes passando.

- **Feature:** Enxugar loadings e rebuilds da navegação (create sem flash + exclusão otimista).
- **Branch:** `feature/roadmap-2-enxugar-loadings-navegacao` (nasce de `develop`).
- **PR alvo:** `develop`.
- **Status do plano:** todas as fases **[ ] não iniciadas**.
- **Camada tocada:** **presentation apenas.** `delete` já devolve `Either<Failure, Unit>` fim a fim (`DeleteContentUseCase.call` → `ContentsRepository.deleteContent`); **domain e data NÃO são tocadas** (confirmado no código). Nenhuma `Failure` nova (as de `core/error/` cobrem tudo).

---

## Decisão de fatiamento (1 fase = 1 PR)

Feature pequena, mas **create (A)** e **exclusão otimista (B/D)** são fatias verticais independentes (o create não depende do delete — ver risco "escopo de B" no PRD). Ambas mexem nos **mesmos arquivos** (`content_list_cubit.dart`, `content_list_state.dart` leitura, `content_list_page.dart`, os 3 testes) → **alto acoplamento de arquivo → fases SEQUENCIAIS, não paralelas.** Duas fases dão PRs pequenos e revisáveis de relance; a Fase 2 rebaseia na Fase 1. A Fase 3 é E2E por prints + fechamento das docs vivas.

Especialista das Fases 1 e 2: **`especialista-apresentacao`** (presentation é o centro; nada de data/domain). QA valida cada fase (`revisar-fase`) e CISO revisa cada PR + os dois gates gerais.

---

## Fase 1 — Criar → editor sem flash (decisão A)

**Objetivo.** No sucesso do `create()`, a lista **não** emite `ContentListLoading` nem dispara `getContents()` extra: navega direto ao editor. O único loading que sobra é o `EditorLoading` legítimo.

**Especialista:** `especialista-apresentacao`. **[não paralela]** (bloqueia Fase 2 — mesmos arquivos). **[sub-agente? não]** (mudança pontual e focada).

**Tarefas concretas:**
1. `content_list_cubit.dart` → `ContentListCubit.create()`: **remover a linha `if (!isClosed && result.isRight()) await load();`**. O método passa a só `await createContent(...)` e retornar o `Either`. Ajustar o doc-comment (não "cria e recarrega" — agora "cria e devolve; a UI navega para fora, sem reload"). Nenhuma emissão de estado no caminho de sucesso.
2. `content_list_page.dart` → `_showCreateDialog`: **sem mudança de lógica** — o `fold` de sucesso já faz `context.goNamed('editor', pathParameters: {'id': content.id})` e o de falha já trata `ConflictFailure` (reabre diálogo) e demais falhas (snackbar). Só confirmar que continua correto após a mudança do cubit.
3. **Reescrita dos testes acoplados (na MESMA fase):**
   - `test/.../content_list/cubit/content_list_cubit_test.dart` → caso "sucesso do create": de `expect: [Loading, Loaded]` + `verify(getContents).called(1)` para **`expect: []`** (nenhuma emissão) + **`verifyNever(getContents)`** + verificar que o `Either` devolvido é `Right(ContentSummary)`. Casos de conflito e outras falhas do create: **inalterados** (já espelham o alvo).
   - `test/.../content_list/content_list_page_test.dart` → revalidar o fluxo criar→navegar (mock de `goNamed`/router; garantir que não pisca `CircularProgressIndicator` entre create e navegação).
   - `test/.../content_list/content_list_golden_test.dart` → revalidar; não deve haver golden de "lista em Loading pós-create".

**Fase pronta quando:** `flutter analyze` verde + `flutter test apps/driva_editor -r compact` verde com os testes acima reescritos; DoD do create atendido (nenhum `getContents()` entre create e navegação, verificável por `verifyNever`).

---

## Fase 2 — Exclusão otimista (decisões B + D)

**Objetivo.** Excluir não blanka a grade: o card some na hora sobre o estado `Loaded` atual (mapear para `ContentListEmpty` ao esvaziar); em falha, reconcilia (reload) e a UI avisa por snackbar. Sem spinner full-screen, sem affordance "excluindo" por card.

**Especialista:** `especialista-apresentacao`. **[não paralela]** (depende da Fase 1 mergeada; mesmos arquivos). **[sub-agente? não]**.

**Tarefas concretas:**
1. `content_list_cubit.dart` → `ContentListCubit.delete(String id)`: mudar assinatura de `Future<void>` para **`Future<Either<Failure, Unit>>`** (o contrato do use case já é `Either<Failure, Unit>` — sem tocar data/domain). Lógica otimista:
   - Ler `state`. Se `ContentListLoaded`, calcular `remaining = contents.where((c) => c.id != id)` e **emitir na hora** `remaining.isEmpty ? ContentListEmpty() : ContentListLoaded(contents: remaining)`.
   - `await deleteContent(id)`; guardar `isClosed` após o await.
   - `fold`: em **falha**, reconciliar com `await load()` (restaura o card do estado real do servidor) e **retornar o `Left`**; em **sucesso**, retornar o `Right` (o estado otimista já está correto, sem novo `getContents`).
   - Remover o `emit(ContentListLoading())`/`await load()` incondicional atual e o `fold((_){},(_){})` vazio.
2. `content_list_state.dart`: **sem novo estado** — a exclusão otimista reusa `ContentListLoaded`/`ContentListEmpty`; o `switch` exaustivo da página já cobre os dois. (Só leitura de confirmação.)
3. `content_list_page.dart` → `_ContentCard._confirmDelete`: hoje faz `await cubit.delete(content.id)` sem tratar retorno. Passar a **`fold`** o `Either` devolvido: em falha, `ScaffoldMessenger.showSnackBar` com "Não foi possível excluir. Tente de novo." (usar `_messageFor` ou string dedicada; guardar `context.mounted` após o await). Sucesso: nada (o card já sumiu). Sem loading intermediário.
4. **Reescrita dos testes acoplados (na MESMA fase):**
   - `content_list_cubit_test.dart` → caso "recarrega após excluir": de `expect: [Loading, Empty]` para os casos otimistas: (a) `Loaded(2 itens)` → delete ok → `expect: [Loaded(1 item)]` **sem** `Loading` e `verifyNever(getContents)`; (b) `Loaded(1 item)` → delete ok → `expect: [Empty]`; (c) `Loaded(2)` → delete **falha** → `expect: [Loaded(1) otimista, Loading, Loaded(2) reconciliado]` (a última via `load()`), retorno `Left`, e `verify(getContents).called(1)` (reconciliação).
   - `content_list_page_test.dart` → card some ao confirmar exclusão; snackbar aparece em falha (mock do use case devolvendo `Left`).
   - `content_list_golden_test.dart` → revalidar (grade sem card removido; nenhum golden de grade blanqueada por spinner na exclusão).

**Fase pronta quando:** `flutter analyze` verde + `flutter test apps/driva_editor -r compact` verde com os testes acima; DoD do delete atendido (card some sem flash; falha reaparece com snackbar; último card → estado vazio).

---

## Fase 3 — E2E por prints + fechamento das docs vivas

**Objetivo.** Confirmar visualmente a ausência do flash no fluxo criar→editor e a exclusão otimista; fechar a documentação viva.

**Responsável:** `qa` (instrumenta o E2E e mantém as docs). CISO faz o **gate antes de instrumentar o E2E** e o **gate após limpar** (método cap. 22–23). **[não paralela]** (depende das Fases 1 e 2).

**Tarefas concretas:**
1. Gate CISO nº 1 (pré-E2E).
2. QA prepara/atualiza `e2e_shots.sh` + `e2e_drive.mjs` (skill `instrumentar-e2e`): prints headless por rodada em `evidencias/rodada_MM/` cobrindo (a) criar conteúdo → cai no editor **sem** `CircularProgressIndicator` na lista; (b) excluir card → grade permanece, card some na hora; (c) último card → estado vazio. `e2e.sh` para o contrato de API (create/delete) se aplicável. O humano só **confere** os prints; problema → time corrige → próxima rodada.
3. Gate CISO nº 2 (pós-limpeza).
4. Docs vivas (skill `manter-docs-vivas`): `final_report.md` nesta pasta; `CHANGELOG` (seção `Unreleased`) no mesmo PR; atualizar `docs/roadmap.md` (item 2 → `[x]`, próximo item → `[-]`). Faxina de branches pós-merge.

**Fase pronta quando:** prints da rodada conferidos pelo humano sem flash/regressão; docs vivas em dia; roadmap marcado.

---

## Verificação / DoD (herdado do PRD)

- Criar com sucesso **não** pisca `CircularProgressIndicator` na lista e navega direto ao editor; **nenhum `getContents()` extra** entre create e navegação (`verifyNever` no bloc_test).
- Conflito de slug e demais falhas do create **inalterados** (reabre diálogo / snackbar).
- Excluir não blanka a grade: card some na hora; em falha reaparece (reconciliação) com snackbar; último card removido → `ContentListEmpty`.
- `EditorLoading` ao abrir um conteúdo **permanece** (sem regressão) — fora do escopo, decisão C=NÃO.
- Testes acoplados (`content_list_cubit_test.dart`, `content_list_page_test.dart`, `content_list_golden_test.dart`) **reescritos na mesma fase** da mudança (não na bateria "por último").
- Cancela de máquina: `flutter analyze` verde + testes existentes passando. CI verde é pré-requisito de merge.
- E2E por prints (rodada) confirma a ausência do flash.

## Riscos (herdados do PRD)

- **Regressão em testes existentes (principal):** não é greenfield. Mitigação: reescrita in-phase (já nas Fases 1 e 2).
- **Reconciliação da exclusão otimista:** falha de servidor não pode deixar a UI mentindo. Mitigação: em falha, `load()` (reload real) + snackbar + retorno `Left`; caso de teste dedicado (Fase 2, caso c).
- **Escopo coeso:** a Fase 1 (create) é entregável sozinha se a Fase 2 travar — o create não depende do delete.

## Desvios do plano

Nenhum registrado. Desvio só entra com aprovação do humano e registro em `variance_report.md` (como estava / por que mudou / o que mudou).
