# PRD — Mover conteúdo entre categorias por drag-and-drop

> Feature 10. Contrato do "pronto". Deriva do `specs.md` desta pasta, com as
> decisões do dev humano integradas. O que contradiz este PRD não está pronto.

## Objetivo

Na tela do projeto (`/projects/:id`), permitir mover um conteúdo para outra
categoria **arrastando** o card (grade) ou a linha (lista) do painel à direita
e soltando-o sobre uma categoria da árvore à esquerda. O drag é um **atalho**;
o botão/dialog "mover" permanece como caminho primário e acessível. Ao mover,
lista e contadores da árvore refletem a mudança imediatamente, e o usuário pode
desfazer.

## Escopo

### Dentro
- `Draggable<ContentSummary>` em `_ContentCard` (grade) e `_ContentRow` (lista).
- `DragTarget<ContentSummary>` nas linhas de **categoria real** da árvore, com
  highlight no hover.
- Ao soltar: `UpdateContentUseCase(content.id, categoryId: <alvo>)`; em sucesso
  recarrega **`ContentListCubit.load()` + `CategoryTreeCubit.load()`**.
- **Desfazer:** snackbar de sucesso com ação "Desfazer" (só no fluxo de drag).
- **No-op** ao soltar na categoria atual do conteúdo.
- **Correção de contadores (bug existente):** o fluxo de mover — **drag E
  dialog** — passa a recarregar também o `CategoryTreeCubit`, não só a lista.
- Descoberta: cursor `grab` + tooltip curta na origem.

### Fora
- **Autoscroll** da árvore durante o drag.
- **Analytics:** nada — sem instrumentação nem marcador para futuro.
- Reordenar conteúdos dentro de uma categoria; reordenar/mover categorias.
- Suporte a toque/mobile para o drag (desktop-first; o dialog cobre qualquer
  dispositivo).
- Multi-seleção / arrastar vários conteúdos de uma vez.
- Update otimista (não há; a lista só muda em sucesso).

## Decisões integradas

| # | Decisão |
|---|---------|
| D1 | Alvo = **qualquer categoria real** (folha ou pai). Soltar numa pai move para ela. Pseudo-nó "Todos os conteúdos" (`categoryId: null`) **nunca** é alvo. |
| D2 | Feedback do arraste = **chip compacto com o título**; origem esmaecida (`childWhenDragging`). |
| D3 | Highlight do alvo = reusa o visual da seleção (`EditorColors.primaryTint` + contorno `colorScheme.primary`) enquanto há item pairando. |
| D4 | Mover é **imediato + snackbar com "Desfazer"** (só no drag). |
| D5 | Erro do PUT = **snackbar de erro** (`_messageFor`), **sem** update otimista. |
| D6 | Descoberta = **cursor grab + tooltip curta** na origem; botão/dialog "mover" permanece caminho acessível primário anunciado por leitor de tela. |
| D7 | Autoscroll da árvore = **fora de escopo**. |
| — | Analytics = **nada**. |
| — | Contadores = mover (drag **e** dialog) recarrega **os dois** cubits. |

## Comportamento do "Desfazer" (D4, detalhado)

1. Ao soltar numa categoria diferente, guardar a **categoria de origem**
   (`content.categoryId` antes do move).
2. Disparar `UpdateContentUseCase(id, categoryId: <alvo>)`.
3. Em sucesso: recarregar lista + árvore e mostrar snackbar
   "Movido para «<categoria>»" com ação **"Desfazer"** por alguns segundos.
4. Se o usuário clicar "Desfazer": disparar
   `UpdateContentUseCase(id, categoryId: <origem>)` e recarregar de novo os dois
   cubits. Erro no undo cai no mesmo snackbar de erro de D5.
5. O undo vale **só para o drag**. O dialog segue imediato sem undo (a menos que
   unificar o snackbar seja trivial — decisão de implementação do tech-lead, sem
   ampliar o contrato).

## Caminho feliz

1. Cursor sobre um card/linha → vira "grab" (tooltip curta).
2. Arrasta → chip com o título aparece sob o cursor; origem esmaece.
3. Passa sobre uma categoria real → a linha destaca (`primaryTint` + contorno).
4. Solta → move dispara.
5. Sucesso → lista recarrega, contadores da árvore atualizam, snackbar com
   "Desfazer".

## Exceções e casos de borda

- **Soltar na categoria atual** → no-op (nenhuma chamada, nada muda, sem snackbar).
- **Soltar em "Todos os conteúdos"** → não é alvo; nada acontece.
- **Soltar fora de qualquer alvo** → drag cancelado; nada acontece.
- **Falha do PUT** (rede/validação/conflito) → snackbar `_messageFor(failure)`;
  a lista não muda.
- **Falha do undo** → snackbar de erro; o conteúdo permanece na categoria nova.
- **Árvore carregando/erro** → sem linhas-alvo; o drag não encontra destino.
- **Filtro atual = categoria de origem** → após mover, o item sai da lista
  (mudou de categoria) — esperado.

## Critérios de aceitação (testáveis)

1. Card (grade) **e** linha (lista) são arrastáveis (`Draggable<ContentSummary>`).
2. Toda linha de **categoria real** é `DragTarget`; o pseudo-nó **"Todos os
   conteúdos" NÃO é alvo**.
3. Soltar numa categoria diferente chama `UpdateContentUseCase` com o
   `categoryId` da categoria alvo (folha **ou pai**).
4. **No-op:** soltar na categoria atual do conteúdo não dispara chamada nem
   snackbar.
5. Em sucesso, **os dois cubits recarregam**: a lista à direita e os contadores
   por categoria na árvore refletem a mudança.
6. Snackbar de sucesso oferece **"Desfazer"**; clicar restaura o conteúdo à
   categoria de origem e recarrega os dois cubits novamente.
7. Highlight do alvo (visual da seleção) aparece **só** enquanto há um item
   pairando sobre a linha.
8. Em erro do PUT, aparece snackbar de erro e a lista **não** muda.
9. O **botão/dialog "mover" permanece** funcional (caminho acessível por
   teclado/leitor de tela) e, tal como o drag, agora recarrega **também** a
   árvore.
10. A origem mostra cursor "grab" e tooltip curta; o drag **não** é o único
    sinal da ação (botão "mover" continua visível e anunciado).
11. **Fora de escopo, verificável por ausência:** nenhum autoscroll durante o
    drag; nenhuma chamada/marcador de analytics adicionado.

## Riscos

- **Escopo do undo (D4):** guardar a origem e disparar um segundo PUT amplia o
  fluxo vs. o dialog atual. Risco de estado inconsistente se o undo falhar
  (mitigado: snackbar de erro, o conteúdo permanece onde está — sem otimismo).
- **`_CategoryRow` não expõe o `categoryId` hoje** (só closures). A implementação
  precisa passar o `id`/`onDropContent` a partir de `_TreeList` sem vazar o
  interno do módulo nem quebrar o pseudo-nó "Todos".
- **Duplo `load()` dos cubits** (mover + undo) pode piscar a UI se as respostas
  demorarem; aceitável neste corte (sem otimismo), mas vigiar a percepção de
  latência.
- **Web/mouse-only:** `Draggable` com mouse é adequado ao desktop-first; o
  caminho por dialog cobre qualquer outro cenário (sem regressão de acesso).

## Dependências

- PR #55 (PUT devolve `ContentSummary`) — já em `develop`. ✔
