# PRD — Enxugar loadings e rebuilds da navegação

> **Status: APROVADO pelo humano em 2026-07-04.** Decisões: **A = SIM** (loading da lista ao criar some por completo; navega direto ao editor) · **B = INCLUIR** exclusão otimista (card some na hora, reconcilia em falha; sem spinner full-screen) · **C = NÃO** (mantém o `EditorLoading` legítimo; sem navegação otimista para o editor) · **D = card some direto** na exclusão, sem affordance "excluindo". Ciência confirmada: a reescrita dos testes acoplados às emissões de Loading faz parte da MESMA fase da mudança. Roadmap item 2 (origem: item 10 de `docs/03-melhorias/`). Base técnica em `specs.md` (mesma pasta), validada com o tech-lead. Dono: PM. UI/docs em pt-BR.

## Objetivo e valor

Remover o **flash de loading** que a lista de conteúdos dá antes de navegar para o editor ao **criar um conteúdo**, e o **spinner full-screen desnecessário** em operações que não precisam blanquear a tela (excluir). A transição de rota já está boa (avaliação do dev humano); o alvo é a percepção de "load esquisito" que quebra a fluidez.

Valor: o fluxo mais frequente do produto — criar um conteúdo e cair no editor — fica **instantâneo e limpo** (sem spinner intermediário nem round-trip redundante). Ganho de UX percebido direto, sem custo de arquitetura.

## Escopo

### Dentro (proposta A–D)

- **[A] Criar → editor sem flash.** No sucesso da criação, a lista **não** exibe `CircularProgressIndicator` nem repinta a grade: navega **direto** ao editor. O único loading que o usuário vê passa a ser o `EditorLoading` (legítimo — busca o spec no backend).
- **[B] Exclusão otimista** *(decisão-chave — pode sair do escopo, ver "Decisões pendentes")*. Ao excluir, a grade permanece visível e o card **some na hora**; em falha, o card reaparece com aviso (snackbar). Sem spinner full-screen.
- **[D] Exclusão sem affordance intermediário.** O card **some direto** (otimista puro), sem estado "excluindo" por card. A reconciliação em falha cobre o caso raro.
- **Reescrita dos testes já acoplados** às emissões de `ContentListLoading` que esta feature remove — **na mesma fase** da mudança (ver DoD).

### Fora

- **[C] Navegação otimista para o editor** (semear `EditorReady` sem carregar do backend). Descartado: cria segunda fonte de verdade para o "spec default", a rota é atingível por deep-link/refresh e por card existente (que exigem `loadContent` de verdade), e o proibido `extra:` do go_router forçaria gambiarra de query-param. Overkill para economizar um round-trip curto.
- **O `EditorLoading` ao abrir um conteúdo** — round-trip legítimo (o `ContentSummary` do create não traz o spec). Mantido.
- **Rebuilds/loading dentro do editor em uso** (paleta, árvore, canvas, inspector) — já resolvidos no item 3b.
- **Offline-first / cache local da lista** — item de roadmap separado.
- **Qualquer mudança na transição de rota em si** — já está boa.

## Requisitos funcionais

1. **Criar (sucesso):** ao confirmar o formulário de novo conteúdo e a criação retornar sucesso, o app navega imediatamente para o editor do conteúdo criado, **sem** emitir `ContentListLoading` nem disparar um `getContents()` adicional na lista.
2. **Criar (conflito de slug):** comportamento **inalterado** — reabre o diálogo com a sugestão de slug livre e a mensagem de conflito.
3. **Criar (outras falhas):** comportamento **inalterado** — snackbar com a mensagem do erro; permanece na lista.
4. **Excluir (sucesso) [B]:** o card some imediatamente do estado atual; se era o último, a lista passa a exibir o estado vazio (`ContentListEmpty`). A grade não é blanqueada por spinner.
5. **Excluir (falha) [B]:** o card reaparece (reconciliação) e um snackbar informa que não foi possível excluir.
6. **Abrir editor (qualquer origem):** o `EditorLoading` permanece durante o carregamento do spec; sem regressão.
7. **Voltar do editor para a lista:** comportamento **inalterado** — a lista remonta e carrega fresca.

## Impacto técnico (arquivos e símbolos concretos)

- `apps/driva_editor/lib/modules/contents_module/presentation/content_list/cubit/content_list_cubit.dart`
  - `ContentListCubit.create()` — remover o `await load()` do caminho de sucesso; retornar o `Either` para a página navegar direto (sem emitir `ContentListLoading`).
  - `ContentListCubit.delete()` [B] — trocar `emit(ContentListLoading)` + `load()` por remoção otimista sobre o estado `Loaded` atual (mapear para `ContentListEmpty` quando esvaziar) e reconciliação em falha (reload + sinal para a UI).
- `apps/driva_editor/lib/modules/contents_module/presentation/content_list/content_list_page.dart`
  - `_showCreateDialog` — o `fold` de sucesso já navega com `context.goNamed('editor', ...)`; passa a ser o único efeito no sucesso.
  - Fluxo de exclusão (`_ContentCard._confirmDelete`) [B] — exibir snackbar de falha na reconciliação.
- `apps/driva_editor/lib/app_router.dart` — sem alteração; referência do porquê o reload é desperdício (rotas flat: `goNamed('editor')` dispõe a `ContentListPage` e seu `BlocProvider`).
- **Fora do escopo, referência:** `apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_cubit.dart` (`EditorCubit.loadContent`, `EditorLoading`) e `content_summary.dart` (não carrega o spec) — justificam manter o `EditorLoading` e descartar navegação otimista.

## Decisões pendentes de aprovação humana

O humano confirma ou ajusta cada uma ao aprovar o PRD:

- **A — O loading da lista ao criar some por completo?** Proposta: **sim** (navega direto; o `EditorLoading` cobre a percepção de "abrindo").
- **B — Exclusão entra no escopo (vira otimista)?** *Decisão-chave.* Proposta: **incluir**. Se o humano preferir **escopo mínimo**, B sai e a feature entrega **só o create** — o `delete()` fica como está, e os requisitos 4–5 e a parte de teste do delete saem do DoD.
- **C — Navegação otimista para o editor?** Proposta: **não** (overkill; risco de segunda fonte de verdade do spec default).
- **D — Exclusão otimista com affordance "excluindo" no card?** Proposta: **não** — card some direto; reconciliação em falha cobre o caso raro. (Só relevante se B = sim.)

## Critérios de aceite / DoD

- Criar com sucesso **não** pisca nenhum `CircularProgressIndicator` na lista e navega direto ao editor; **nenhum `getContents()` extra** é disparado entre o create e a navegação (verificável no bloc_test via `verifyNever`).
- Conflito de slug e demais falhas do create seguem inalterados (reabrir diálogo / snackbar).
- *(Se B = sim)* Excluir não blanka a grade: o card some na hora; em falha reaparece com aviso; último card removido leva ao estado vazio.
- O `EditorLoading` ao abrir um conteúdo permanece (sem regressão); editor em uso continua sem rebuilds indevidos.
- **Testes acoplados às emissões de Loading reescritos na MESMA fase da mudança** (não na bateria "por último"):
  - `apps/driva_editor/test/modules/contents_module/presentation/content_list/cubit/content_list_cubit_test.dart` — caso de sucesso do create vira `expect: []` + `verifyNever(getContents)` (espelhando o caso de conflito); caso do delete ajustado à decisão B.
  - `content_list_page_test.dart` e `content_list_golden_test.dart` — revalidados no fluxo criar/navegar (e excluir, se B = sim).
- Cancela de máquina: `flutter analyze` verde + testes existentes passando.
- E2E por prints (rodada) confirma visualmente a ausência do flash no fluxo criar → editor.

## Riscos

- **Regressão em testes existentes (principal):** a feature não é greenfield — há testes acoplados às emissões de `ContentListLoading` em create e delete. Mitigação: reescrevê-los na mesma fase (já no DoD).
- **Reconciliação da exclusão otimista [B]:** hoje `delete()` engole a falha e recarrega; o caminho otimista precisa de tratamento explícito de falha (reload + snackbar) e do mapeamento `Loaded` vazio → `ContentListEmpty` para casar com o `switch` da página. Sem isso, um erro de servidor deixaria a UI mentindo. Mitigação: requisito 5 + caso de teste dedicado.
- **Escopo de B:** se o humano cortar B, garantir que a fatia do create fica coesa e entregável sozinha (é — o create não depende do delete).
