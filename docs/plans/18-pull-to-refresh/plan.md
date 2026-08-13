# plan.md — Item 18: Pull-to-refresh que refaz o cache

> Documento de planejamento. Dono na execução: **especialista-apresentacao**. Base: `docs/roadmap.md` › Marco 9.
> **Precedência dura: item 17.** Sem cache, "refazer o cache" não quer dizer nada.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend.**

## 1. Objetivo e recorte

Depois do item 17, a lista pode estar mostrando dados salvos. O usuário precisa de um jeito **explícito** de dizer "busca de novo agora" — e de ver que a busca aconteceu.

**Entra:**
1. Gesto de puxar-para-atualizar no painel de conteúdos (`RefreshIndicator`).
2. Um botão de atualizar, para desktop/web com mouse — **o editor é Flutter Web**, e puxar com o mouse não é gesto natural para todo mundo.
3. `forceRefresh` no caminho de carga: ignora o cache, busca na rede, **reescreve** o cache.
4. Retorno claro de sucesso e de falha (falhou → continua mostrando o que tinha, com aviso).

**Fica fora:** refresh automático por timer ou por foco de janela (registrado em §7), refresh da árvore de categorias (poderia entrar junto — ver §7), sincronização em segundo plano.

## 2. Precedências

| O que | Onde | Uso |
| --- | --- | --- |
| `ContentListCubit.load()` com *stale-while-revalidate*, `fromCacheAt`, `isRevalidating` | item 17, F2 | `refresh()` é uma variação de `load()`. |
| `LocalContentsCache.write` e a chave da consulta | item 17, F1 | Reescrita do cache. |
| `ContentsCollection` / `ContentPanel` com `NotificationListener` de scroll (item 16) e o rodapé "Carregando mais…" | `contents_module/.../content_panel/` | O `RefreshIndicator` embrulha a **mesma** área rolável. **Cuidado com o conflito de gestos** (D2). |
| `ContentViewMode` (grade/lista) e `ViewModeToggle` no header do painel | `.../content_panel/view_mode_toggle.dart` | O botão de atualizar entra ao lado, no header já existente. |
| `SortControl` no header (item 15) | `.../content_panel/sort_control.dart` | Gabarito de controle de header: widget próprio, recebe callback, sem lógica. |

## 3. Decisões

**D1 — `refresh()` é um método próprio, não um parâmetro de `load()`.**
`load()` pode mostrar cache; `refresh()` **nunca** mostra cache — vai direto à rede e só então emite. Motivo: se fosse um `bool` em `load()`, o corpo viraria uma sequência de `if`s sobre o mesmo fluxo, e o estado de "puxando" se confundiria com o de "revalidando". Dois métodos, dois estados, leitura fácil.

**D2 — O `RefreshIndicator` embrulha o mesmo `ScrollView` do scroll infinito.**
`RefreshIndicator` exige um `Scrollable` filho com `AlwaysScrollableScrollPhysics` — senão, com poucos itens (lista que não rola), o gesto não dispara e o usuário conclui que está quebrado. **Isso é o erro clássico desta feature.** Ajustar a `physics` do `GridView`/`ListView` do painel é parte da fase, não detalhe.
E o `NotificationListener` do item 16 (que antecipa a próxima página ~400px antes do fim) continua funcionando: os dois observam o mesmo scroll sem conflito, porque um reage a `ScrollNotification` e o outro a overscroll no topo.

**D3 — Em web/desktop, o botão é o caminho primário.**
O gesto fica disponível (funciona com trackpad e touch), mas o header ganha um `IconButton` de atualizar com tooltip, que é o que a maioria vai usar. Acessibilidade: gesto **nunca** pode ser o único caminho para uma ação (regra do projeto — cor e gesto não são o único sinal).

**D4 — Falha no refresh não destrói a tela.**
Mantém a lista atual, para o indicador e mostra o aviso ("Não foi possível atualizar — mostrando dados de …"). O único caso que leva a `ContentListError` é falhar **sem** nada em tela.

## 4. Fases

### F1 — `refresh()` no cubit

**Arquivos a modificar:**
- **`.../content_list/cubit/content_list_cubit.dart`**:
  ```dart
  Future<void> refresh() async {
    final current = state;
    if (current is ContentListLoaded && current.isRefreshing) return;   // reentrância
    if (current is ContentListLoaded) emit(current.copyWith(isRefreshing: true));
    final result = await getContents(
      categoryId: _categoryId, query: _query, sort: _sort, order: _order,
      forceRefresh: true,
    );
    if (isClosed) return;
    ...
  }
  ```
  Reseta o cursor (refresh volta à primeira página — comportamento esperado) e, em falha com lista em tela, aplica a D4.
- **`.../content_list/cubit/content_list_state.dart`** — `final bool isRefreshing;` no `Loaded` (`copyWith` + `props`).
- **`contents_module/domain/repositories/contents_repository.dart`** e o **decorator `CachedContentsRepository`** (item 17 D5) — parâmetro `bool forceRefresh = false`: pula a leitura do cache e **reescreve** depois do sucesso.
- **`domain/use_cases/get_contents_use_case.dart`** — repassa o parâmetro.
  > **Precedência interna:** o parâmetro precisa existir na interface **antes** do cubit chamá-lo. Ordem: repositório → use case → cubit. Óbvio, mas é exatamente o tipo de coisa que quebra o build no meio do PR se feita ao contrário.

**Aceite:** `refresh()` com rede boa troca os dados e regrava o cache (verificável pelo `savedAt`); com rede ruim, mantém a lista; chamadas concorrentes não empilham.

### F2 — UI: gesto e botão

**Arquivos a modificar:**
- **`.../content_panel/contents_collection.dart`** (ou o widget que monta a grade/lista — **confirmar qual**) — embrulhar em `RefreshIndicator(onRefresh: () => cubit.refresh(), child: ...)` e garantir `physics: const AlwaysScrollableScrollPhysics()` (D2).
- **`.../content_panel/refresh_button.dart`** (novo) — `IconButton` com tooltip "Atualizar", desabilitado durante `isRefreshing`, mostrando um `CircularProgressIndicator` pequeno no lugar do ícone enquanto atualiza. Widget próprio (Gate 1/3), no padrão do `SortControl`.
- **`.../content_panel/content_panel.dart`** — o botão no header, ao lado do `ViewModeToggle`/`SortControl`.
- **A faixa de "dados salvos" do item 17** — passa a mostrar também o resultado da última tentativa de refresh.

**Aceite:** puxar com poucos itens **funciona** (o teste da D2); o botão funciona; durante o refresh o restante da tela continua interativo; leitor de tela anuncia o estado (`Semantics` no botão).

### F3 — Testes
`content_list_cubit_test.dart` (+ refresh: sucesso regrava, falha preserva, reentrância bloqueada, cursor resetado) e widget test do painel (indicador aparece e some; botão desabilita durante).

## 5. Mapa de paralelismo

```
F1 ──► F2 ──► F3
```
Item pequeno; a ordem é natural e o paralelismo não compensa.

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 17 — dependência direta.** O `forceRefresh` é uma extensão do decorator criado lá; **nada** do 17 precisa mudar (o parâmetro tem default `false`). Confirmado.
- **Item 16 (scroll infinito)** — coexistência verificada na D2, mas a mudança de `physics` **é** um toque em código do item 16. Rodar o teste de scroll infinito existente como regressão.
- **Item 24 (publicação)** — depois do refresh, o selo "No ar/Rascunho" é atualizado junto (vem no mesmo payload). Nenhum trabalho extra.
- **Item 19 (componentes)** — o refresh vale para a aba ativa; a chave da consulta já inclui `kind`. Nenhum trabalho extra.

## 7. Perguntas para o humano

1. **A árvore de categorias também atualiza no mesmo gesto?** Os contadores por nó ficam velhos junto com a lista. Recomendo **sim** (o `CategoryTreeCubit` recarrega em paralelo) — custa pouco e evita a incoerência de "a lista tem 3, a árvore diz 2".
2. **Refresh automático ao voltar o foco da janela?** Barato de implementar (`AppLifecycleListener`) e agradável em web, onde a aba fica aberta o dia todo. Fica para depois?
3. **Mostrar "atualizado agora" por alguns segundos após o sucesso?** Assumido: sim, discreto, sumindo sozinho.
