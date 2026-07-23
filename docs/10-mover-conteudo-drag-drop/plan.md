# Plano — Mover conteúdo entre categorias por drag-and-drop

> Feature 10. Plano vivo (1 fase = 1 PR). Fonte do "pronto": `prd.md` desta
> pasta. Deriva do `specs.md`. Guardião: tech-lead. Desvio só entra com
> aprovação do dev humano + registro em `variance_report.md`.

## Enquadramento técnico

- **Frontend puro.** O backend já move (`PUT /v1/contents/:id` devolve o
  `ContentSummary` — PR #55, em `develop`). **domain e data são intocados:**
  `UpdateContentUseCase(id, {categoryId})` já existe e faz tudo. Nenhum model,
  contrato ou use case novo. **Toda a mudança vive em `presentation` do
  `contents_module`.**
- **Dono das fases:** `especialista-apresentacao` (todas).
- **Onde a coordenação drag→move mora — DECIDIDO: na página, não num cubit.**
  `ProjectDetailPage` já é o único ponto que toca o `getIt`, já orquestra os
  dois cubits (`CategoryTreeCubit` + `ContentListCubit` num `MultiBlocProvider`),
  já tem `_messageFor` e `_openMoveContentDialog`. O drop reusa exatamente esse
  caminho. Extrair para um cubit novo exigiria injetar ambos os cubits + o use
  case num terceiro objeto e reimplementar `_messageFor`/snackbar — mais código,
  menos coeso, sem ganho. **Um método estático único** —
  `_moveContent(context, content, targetCategoryId, {required bool offerUndo})`
  — concentra: no-op guard, `UpdateContentUseCase`, `isClosed`/`context.mounted`
  guard após o `await`, duplo `load()` (lista + árvore), snackbar de erro/sucesso
  e o undo. Dialog **e** drop chamam esse método (o dialog com `offerUndo: false`;
  o drag com `offerUndo: true`).
- **`_CategoryRow` não expõe `categoryId` — DECIDIDO.** Mesmo padrão de
  `onSelect`/`onEdit`/`onDelete`: `_TreeList` passa um callback
  `onAcceptContent: (ContentSummary c) => onMoveContent(c, node.id)` com o
  `node.id` **capturado na closure**. O `_CategoryRow` nunca vê o `id` cru — só
  recebe um `ValueChanged<ContentSummary>?`. **Pseudo-nó "Todos" recebe
  `onAcceptContent: null`** → sem `DragTarget`, nunca é alvo. Não vaza interno do
  módulo (o id não sobe para fora de `_TreeList`).

## Branch (GitFlow)

Nasce de `develop` via skill `iniciar-feature`. **NÃO criar aqui** — só o nome
sugerido: `feature/<issue>-mover-conteudo-drag-drop`. PR → `develop`.

---

## Fase 1 — Corrigir contadores no fluxo de mover (dialog) + recarregar árvore

**Objetivo.** Fatia vertical independente que já corrige o bug existente: mover
por dialog passa a recarregar **os dois** cubits. Base para o drop reusar o
mesmo caminho na Fase 3.

**Arquivos tocados**
- `apps/driva_editor/lib/modules/contents_module/presentation/project_detail/project_detail_page.dart`
  - Em `_openMoveContentDialog`, no `fold` de sucesso: além de
    `context.read<ContentListCubit>().load()`, chamar também
    `context.read<CategoryTreeCubit>().load()`.
  - (Preparação p/ Fase 3, opcional nesta fase) extrair o corpo do sucesso para
    o método reusável `_moveContent(...)`. Se ficar limpo, extrair já; senão,
    deixar p/ a Fase 3 — decisão do especialista, sem ampliar contrato.

**Aceitação (mapeada ao PRD)**
- CA 9 (parcial): dialog "mover" continua funcional e agora recarrega **também**
  a árvore (contadores atualizam).
- CA 5 (parcial): os dois cubits recarregam no fluxo de dialog.

**Marcas:** independente das fases 2–4 → **[paralelo]** com a Fase 2.
Não precisa de sub-agente (mudança pequena e localizada).

---

## Fase 2 — Origem arrastável: `Draggable<ContentSummary>` no card e na linha

**Objetivo.** Tornar card (grade) e linha (lista) arrastáveis, com feedback de
chip compacto (D2), origem esmaecida (`childWhenDragging`), cursor `grab` (D6) e
tooltip curta — **sem** consumir o drop ainda (alvo entra na Fase 3). Puramente
visual/origem; não dispara nada.

**Arquivos tocados**
- `apps/driva_editor/lib/modules/contents_module/presentation/project_detail/widgets/content_panel_view.dart`
  - Envolver o conteúdo de `_ContentCard` e `_ContentRow` num
    `Draggable<ContentSummary>` com `data: content`.
  - `feedback:` chip compacto com o título (`content.name`) + ícone do slug —
    `Material` leve (evita "unbounded"/tema perdido no overlay de drag). D2.
  - `childWhenDragging:` a própria árvore do card/linha com `Opacity(0.4)`. D2.
  - Cursor `grab`/`grabbing`: `MouseCursor` do `Draggable`
    (`SystemMouseCursors.grab`) ou `MouseRegion` externo. D6.
  - `Semantics`/`Tooltip` curta ("Arraste para mover") **sem** conflitar com o
    tooltip de slug/ações já existentes. D6/CA10.
  - **Não** remover nem alterar o botão "mover" de `_CardActions` (caminho
    acessível primário permanece).

**Aceitação (mapeada ao PRD)**
- CA 1: card **e** linha são `Draggable<ContentSummary>`.
- CA 10: cursor "grab" + tooltip curta na origem; drag não é o único sinal
  (botão "mover" segue visível e anunciado).
- CA 11 (parcial): nenhum analytics adicionado.

**Marcas:** **[paralelo]** com a Fase 1 (arquivos distintos). A Fase 3 depende
desta. Não precisa de sub-agente.

---

## Fase 3 — Alvo do drop na árvore + coordenação do move (sem undo)

**Objetivo.** Categorias reais viram `DragTarget<ContentSummary>` com highlight
no hover (D3); soltar dispara o move imediato reusando `_moveContent(...)`.
"Todos" nunca é alvo. No-op na categoria atual. Erro → snackbar. **Undo entra na
Fase 4** (mantém o PR revisável de relance).

**Arquivos tocados**
- `.../presentation/category_tree/category_tree_view.dart`
  - `_CategoryRow`: novo campo `final ValueChanged<ContentSummary>? onAcceptContent;`
    Quando **não-nulo**, envolver a `row` num `DragTarget<ContentSummary>`:
    - `onWillAcceptWithDetails:` aceita (a menos que se decida barrar a própria
      categoria aqui; o no-op também é garantido no `_moveContent`, então basta
      um dos dois — preferir o guard central em `_moveContent`).
    - `builder:` quando `candidateData.isNotEmpty`, aplica o highlight = reusa o
      visual de seleção (`primaryTint` + contorno `colorScheme.primary`). D3/CA7.
      Cor **não** é o único sinal: o contorno acompanha.
    - `onAcceptWithDetails:` chama `onAcceptContent!(details.data)`.
  - `_TreeList`: só nas **categorias reais**, passar
    `onAcceptContent: (c) => onMoveContent(c, node.id)` (`node.id` na closure).
    Pseudo-nó "Todos": `onAcceptContent: null` (CA 2). Novo parâmetro
    `onMoveContent` sobe por `CategoryTreeView` → página.
  - `CategoryTreeView`: novo `required void Function(ContentSummary, String categoryId) onMoveContent;`
    repassado a `_TreeList`.
- `.../presentation/project_detail/project_detail_page.dart`
  - Novo método estático `_moveContent(context, content, targetCategoryId, {required bool offerUndo})`:
    - **No-op:** `if (targetCategoryId == content.categoryId) return;` (CA 4).
    - `await getIt<UpdateContentUseCase>()(content.id, categoryId: targetCategoryId)`.
    - Guard `context.mounted` após o `await` antes de qualquer `read`/snackbar.
    - Erro → snackbar `_messageFor` (CA 8, D5); a lista não muda (sem otimismo).
    - Sucesso → `ContentListCubit.load()` + `CategoryTreeCubit.load()` (CA 5).
    - `offerUndo` → tratado na Fase 4 (nesta fase, sucesso só recarrega +
      snackbar simples; a assinatura já entra pronta).
  - Refatorar `_openMoveContentDialog` para delegar a `_moveContent(..., offerUndo: false)`
    (consolida com a Fase 1).
  - Passar `onMoveContent: (content, categoryId) => _moveContent(context, content, categoryId, offerUndo: true)`
    à `CategoryTreeView`.

**Aceitação (mapeada ao PRD)**
- CA 2: toda categoria real é `DragTarget`; "Todos" NÃO é alvo.
- CA 3: soltar em categoria diferente chama `UpdateContentUseCase` com o
  `categoryId` alvo (folha **ou** pai — D1).
- CA 4: no-op na categoria atual (sem chamada, sem snackbar).
- CA 5: os dois cubits recarregam.
- CA 7: highlight só enquanto há item pairando.
- CA 8: erro → snackbar; lista não muda.
- CA 11: sem autoscroll; sem analytics.

**Marcas:** depende das Fases 1 e 2. **[sub-agente]** para varrer o uso de
`CategoryTreeView`/`_TreeList` (garantir que a nova prop `onMoveContent` não
quebra outros call-sites — provável só a página, mas confirmar). Resto é edição
localizada pelo `especialista-apresentacao`.

---

## Fase 4 — Undo (D4): snackbar de sucesso com "Desfazer" (só no drag)

**Objetivo.** No fluxo de drag, o snackbar de sucesso oferece "Desfazer" que
restaura à categoria de origem com um 2º `UpdateContentUseCase` e recarrega os
dois cubits. Dialog segue sem undo (`offerUndo: false`).

**Arquivos tocados**
- `.../presentation/project_detail/project_detail_page.dart`
  - Em `_moveContent`, no sucesso quando `offerUndo == true`:
    - Guardar a **origem** = `content.categoryId` (capturado **antes** do move —
      já disponível no `ContentSummary` recebido).
    - Resolver o rótulo da categoria alvo (para o texto "Movido para «X»") a
      partir do `CategoryTreeState` — reusar a lógica de
      `_selectedCategoryLabel` (extrair helper `_categoryLabel(state, id)` se
      ajudar).
    - `SnackBar` com `SnackBarAction(label: 'Desfazer', onPressed: ...)`.
    - Ação "Desfazer": `getIt<UpdateContentUseCase>()(content.id, categoryId: <origem>)`
      → guard `mounted` → sucesso recarrega os dois cubits; erro cai no mesmo
      snackbar `_messageFor` (D4 passos 4–5; CA 6). Undo **não** oferece undo do
      undo (`offerUndo: false` na chamada interna, ou caminho direto).

**Aceitação (mapeada ao PRD)**
- CA 6: snackbar de sucesso oferece "Desfazer"; clicar restaura à origem e
  recarrega os dois cubits.
- Casos de borda do PRD: falha do undo → snackbar de erro, conteúdo permanece na
  categoria nova (sem otimismo).

**Marcas:** depende da Fase 3. Sem sub-agente. Isolar num PR próprio mantém o
diff de "coordenação + undo" pequeno e revisável (o risco de estado
inconsistente do PRD concentra-se aqui).

---

## Fases finais (padrão do fluxo — cap. 22–23)

- **Fase 5 — Gate CISO + E2E por rodadas.** QA prepara `e2e.sh` (API do hml) e
  `e2e_shots.sh`/`e2e_drive.mjs` (prints CDP: drag do card e da linha, highlight
  do alvo, snackbar com "Desfazer", no-op, erro). Humano confere os prints.
  Evidências em `evidencias/rodada_MM/`.
- **Fase 6 — Testes automatizados (por último).** Widget: `Draggable` em card e
  linha; `DragTarget` em categoria real e **ausente** em "Todos"; drop chama
  `UpdateContentUseCase` com o `categoryId` certo + recarrega os dois cubits;
  no-op na categoria atual; highlight só com item pairando; undo restaura;
  regressão do dialog (agora recarrega a árvore). `mocktail` + `bloc_test`,
  `test/` espelhando `lib/`.
- **Fase 7 — Docs vivas + DoD.** `final_report.md`, CHANGELOG (`Unreleased`),
  `roadmap.md` (marca o item `[x]`), README se preciso. DoD =
  `flutter analyze` verde + testes passando + docs em dia.

---

## Riscos vigiados (do PRD)

- **`_CategoryRow` sem `categoryId`** → resolvido via closure em `_TreeList`
  (`onAcceptContent`), "Todos" com `null`. (Fase 3)
- **Undo amplia o fluxo / estado inconsistente** → isolado na Fase 4; sem
  otimismo, conteúdo permanece onde está se o undo falhar. (Fase 4)
- **Duplo `load()` pode piscar a UI** → aceitável neste corte (sem otimismo);
  vigiar percepção de latência no E2E (Fase 5).
- **`feedback` do `Draggable` fora da árvore de tema** → embrulhar o chip num
  `Material`/`DefaultTextStyle` para não perder tema no overlay de drag. (Fase 2)

## Progresso

- [x] Fase 1 — Contadores no dialog + recarregar árvore
- [x] Fase 2 — Origem arrastável (Draggable)
- [x] Fase 3 — Alvo do drop + coordenação do move (sem undo)
- [x] Fase 4 — Undo (snackbar "Desfazer", só drag)
- [ ] Fase 5 — Gate CISO + E2E por rodadas
- [ ] Fase 6 — Testes automatizados
- [ ] Fase 7 — Docs vivas + DoD
