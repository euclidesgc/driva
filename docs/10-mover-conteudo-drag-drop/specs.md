# Specs — Mover conteúdo entre categorias por drag-and-drop

> Feature 10. Atalho de arrastar-e-soltar para mover um conteúdo para outra
> categoria na tela do projeto (`/projects/:id`), complementando (sem
> substituir) o dialog "mover" existente.

## Contexto e origem

- **Pedido:** arrastar um conteúdo (card da grade ou linha da lista, no painel
  à direita) e soltá-lo sobre uma categoria da árvore à esquerda para movê-lo.
- **Backend já pronto:** move via `PUT /v1/contents/:id` com `categoryId`; o PUT
  devolve o `ContentSummary` (PR #55, já em `develop`).
- **Frontend puro:** reusa `UpdateContentUseCase(id, categoryId:)` — a mesma
  lógica de `_openMoveContentDialog` em `project_detail_page.dart`.
- **Referência de UX:** `docs/web-prototipe/design-handoff-projetos/`; o plan de
  `docs/08-api-conteudos-filtro-busca/` já citava drag-and-drop card→árvore como
  polimento futuro (agora priorizado).

## Estado atual do código (o que já existe)

- **Origem do drag** — `content_panel_view.dart`:
  - `_ContentCard` (grade) e `_ContentRow` (lista), ambos recebem `content` +
    callbacks (`onOpen/onEdit/onMove/onDelete`) e já são `StatelessWidget`
    simples envolvendo um `InkWell(onTap: onOpen)`.
  - `_CardActions` já tem o botão "mover" (ícone `drive_file_move_outline`,
    tooltip "Mover conteúdo para outra categoria") — o **caminho acessível
    primário**, que permanece.
- **Alvo do drop** — `category_tree_view.dart`:
  - `_CategoryRow` (`StatefulWidget`, já tem `_hovered` via `MouseRegion`) é
    reusado por dois casos:
    - o **pseudo-nó "Todos os conteúdos"** (`isAllContentsShortcut: true`,
      `onSelect` → `select(null)`, `onEdit/onDelete` nulos) — **NÃO é alvo**;
    - as **categorias reais** (`onSelect` → `select(node.id)`, `node.id`
      disponível via `onEdit/onDelete` closures em `_TreeList`).
  - Hoje `_CategoryRow` **não expõe** o `id` da categoria diretamente (só via
    closures `onSelect/onEdit/onDelete`) — o drop precisa do `categoryId` alvo,
    então será necessário passar o `id` (ou um `onDropContent(String categoryId)`
    montado em `_TreeList`).
- **Ação de mover** — `project_detail_page.dart::_openMoveContentDialog`:
  - `getIt<UpdateContentUseCase>()(content.id, categoryId: newCategoryId)`
    → `.fold(erro → snackbar `_messageFor`, sucesso → `ContentListCubit.load()`)`.
  - O dialog (`MoveContentDialog`) já trata **no-op**: botão "Mover" fica
    desabilitado quando `_categoryId == currentCategoryId`.
  - **Bug conhecido a corrigir junto:** o fluxo de mover **só** recarrega a
    lista (`ContentListCubit.load()`), **não** a árvore
    (`CategoryTreeCubit.load()`) — os contadores por categoria na árvore ficam
    desatualizados. A feature deve recarregar **os dois** cubits após mover.
- **Convivência dos cubits** — a página monta `CategoryTreeCubit` +
  `ContentListCubit` num `MultiBlocProvider`; ambos alcançáveis por
  `context.read` no subtree.
- **Tokens de tema disponíveis** (`EditorColors`, já em uso na árvore):
  `primaryTint` (fundo do item selecionado), `colorScheme.primary` (contorno
  accent), `panelAlt` (hover). Suficiente para o highlight do alvo — sem cor
  hardcoded.

## Resultado esperado

Na tela do projeto, o usuário pode arrastar um conteúdo (card ou linha) e
soltá-lo sobre uma categoria real da árvore para movê-lo para lá. Ao soltar,
o conteúdo muda de categoria, a lista à direita e os contadores da árvore à
esquerda refletem a mudança imediatamente. O botão/dialog "mover" continua
funcionando como antes (caminho acessível por teclado).

## Escopo

**Dentro:**
- `Draggable<ContentSummary>` em `_ContentCard` e `_ContentRow`.
- `DragTarget<ContentSummary>` nas linhas de **categoria real** da árvore, com
  feedback visual de hover.
- Ao soltar: `UpdateContentUseCase(content.id, categoryId: <alvo>)`, reusando a
  mesma lógica do dialog; recarregar **lista + árvore**.
- No-op ao soltar na categoria atual do conteúdo.
- Corrigir o fluxo existente (dialog **e** drag) para recarregar a árvore além
  da lista (contadores).
- Manter o botão/dialog "mover" intacto (atalho vs. caminho primário).

**Fora (confirmado):**
- Reordenar conteúdos dentro de uma categoria (drag para ordenar).
- Reordenar/mover categorias na árvore (drag de categoria).
- Suporte a toque/mobile para o drag (desktop-first; mouse basta). O caminho
  por dialog cobre qualquer dispositivo.
- Multi-seleção / arrastar vários conteúdos de uma vez.
- Autoscroll da árvore durante o drag (ver decisão D5).

## Decisões do dev humano (a consolidar no PRD)

As ambiguidades abaixo precisam de decisão. Cada uma tem opções e a
recomendação do PM. **O `specs.md` fica com a recomendação marcada como
_provisória_ até o dev confirmar no PRD.**

### D1 — Escopo do alvo: categorias-pai também são alvo? (ALTA)
- Contexto: a árvore é recursiva por `parentId`; uma categoria pode ter filhas.
- Opções:
  - (a) **Qualquer categoria real é alvo** (pai ou folha); soltar numa pai move
    o conteúdo para a própria pai (não para uma filha).
  - (b) Só categorias folha são alvo.
- **Recomendação: (a).** O backend aceita `categoryId` de qualquer categoria; o
  dialog atual já permite escolher qualquer categoria (inclui pais). Restringir a
  folhas divergiria do dialog e confundiria. O pseudo-nó "Todos" continua **não**
  sendo alvo (não é categoria real).

### D2 — Feedback visual durante o arraste (MÉDIA)
- Opções para `feedback` do `Draggable`:
  - (a) **Chip compacto com o título + ícone do slug** (leve, legível).
  - (b) Miniatura do próprio card/linha (mais fiel, mais pesada).
- E `childWhenDragging`: (i) card/linha esmaecido (opacity) vs. (ii) inalterado.
- **Recomendação: (a) chip compacto + (i) origem esmaecida.** Barato, claro,
  não carrega o layout inteiro sob o cursor.

### D3 — Highlight do alvo no hover do drop (MÉDIA)
- Opções: reusar os tokens já usados na seleção — `primaryTint` (fundo) +
  contorno `colorScheme.primary` — **ou** um realce mais forte (ex.: borda
  tracejada) para diferenciar "alvo de drop" de "selecionado".
- **Recomendação: reusar `primaryTint` + contorno `primary`**, o mesmo visual da
  seleção, aplicado só enquanto há um item pairando (`onWillAccept`/`candidateData`).
  Consistente com o design system; sem token novo. Confirmar se o dev quer
  distinção visual entre "alvo pairado" e "selecionado".

### D4 — Confirmação vs. imediato (MÉDIA)
- O dialog atual move sem confirmação extra (o próprio dialog já é a confirmação).
- Opções para o drag: (a) **mover imediato**, sem confirmação (drag já é ato
  deliberado); (b) mover imediato + **snackbar com "Desfazer"**; (c) pedir
  confirmação (dialog) ao soltar.
- **Recomendação: (a) imediato, sem confirmação nem undo** neste primeiro corte
  (paridade com o dialog, que também não tem undo). Undo é polimento futuro —
  confirmar se o dev quer já um snackbar de "Desfazer".

### D5 — Erro do PUT (MÉDIA)
- Opções: (a) **snackbar de erro** (reusando `_messageFor`), **sem** mudança
  visual otimista para reverter (a lista só recarrega em sucesso — nada a
  reverter); (b) update otimista + rollback em erro.
- **Recomendação: (a).** Igual ao dialog hoje: em erro mostra snackbar, em
  sucesso recarrega. Sem otimismo, não há o que reverter — mais simples e seguro.

### D6 — Descoberta e acessibilidade do drag (MÉDIA)
- O drag não pode ser o único sinal (regra de acessibilidade). O botão "mover"
  já é o caminho primário e permanece.
- Opções de affordance do drag: (a) **cursor `grab`/`grabbing`** sobre o
  card/linha + tooltip "Arraste para mover"; (b) só cursor, sem tooltip;
  (c) nenhuma dica (drag como atalho oculto).
- **Recomendação: (a) cursor grab + tooltip curta**, mantendo o botão/dialog como
  caminho anunciado por leitor de tela. Confirmar se o dev quer a tooltip (pode
  poluir com o tooltip do slug já existente).

### D7 — Autoscroll da árvore durante o drag (BAIXA)
- Se a árvore for mais alta que o viewport, arrastar até uma categoria fora de
  vista exige rolar.
- Opções: (a) **fora de escopo** nesta fase (árvores curtas hoje; o dialog cobre
  o caso); (b) implementar autoscroll nas bordas.
- **Recomendação: (a) fora de escopo.** Confirmar.

## Caminho feliz

1. Usuário posiciona o cursor sobre um card (grade) ou linha (lista) → cursor vira
   "grab".
2. Pressiona e arrasta → aparece o feedback (chip com o título); a origem esmaece.
3. Passa sobre uma categoria real na árvore → a linha destaca (primaryTint + contorno).
4. Solta sobre a categoria → `UpdateContentUseCase(id, categoryId:)` dispara.
5. Sucesso → lista recarrega (item some do filtro atual se mudou de categoria) e
   contadores da árvore atualizam.

## Exceções e casos de borda

- **Soltar na categoria atual** → no-op (nenhuma chamada; nada muda).
- **Soltar em "Todos os conteúdos"** (pseudo-nó) → não é alvo; nada acontece.
- **Soltar fora de qualquer alvo** → drag cancelado; nada acontece.
- **Falha do PUT** (rede/validação/conflito) → snackbar `_messageFor(failure)`;
  a lista não muda (sem otimismo).
- **Árvore ainda carregando/erro** → não há linhas-alvo; drag simplesmente não
  encontra destino.
- **Filtro atual = a categoria de origem** → após mover, o item sai da lista
  (mudou de categoria); é o comportamento esperado e coerente.

## Analytics (a detalhar no PRD)

- Evento de "mover por drag" (origem: `grid`/`list`), distinto do "mover por
  dialog", com `fromCategoryId`/`toCategoryId`. Confirmar se há pipeline de
  analytics ativo nesta fase (pode ser só marcador para futuro).

## Erros monitorados

- Falha do `PUT /v1/contents/:id` no move por drag (mesma `Failure` tipada do
  dialog) — cair no observador de erros já existente do app.

## Testes esperados (a bater com o test_plan)

- Widget: `Draggable` presente em card e linha; `DragTarget` presente em
  categoria real e **ausente** no pseudo-nó "Todos".
- Widget/unit: soltar em outra categoria chama `UpdateContentUseCase` com o
  `categoryId` certo e recarrega os dois cubits; soltar na categoria atual é
  no-op.
- Widget: highlight do alvo aparece só com item pairando.
- Regressão: o botão/dialog "mover" continua funcionando e agora também
  recarrega a árvore.

## Dependências

- PR #55 (PUT devolve `ContentSummary`) — já em `develop`. ✔
