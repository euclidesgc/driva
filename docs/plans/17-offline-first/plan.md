# plan.md — Item 17: Offline-first na lista de conteúdos

> Documento de planejamento. Dono na execução: **especialista-dados**. Base: `docs/roadmap.md` › Marco 9.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**. **Não toca backend.**
> Precedências satisfeitas: itens 13–16 entregues (filtro, busca, ordenação, paginação) e item 3 entregue (`shared_preferences` no `bootstrap`).

## 1. Objetivo e recorte

Abrir a tela de um projeto hoje sempre mostra spinner e espera a rede — mesmo quando os mesmos 20 conteúdos foram carregados 30 segundos atrás. Com rede ruim ou API fora do ar, a tela fica vazia.

**Entra:**
1. Cache local da **primeira página** de cada consulta, com escrita ao carregar e leitura imediata ao abrir.
2. Padrão *stale-while-revalidate*: mostra o cache na hora, busca em segundo plano, troca se mudou.
3. Indicação honesta de que o que está na tela veio do cache (e de quando).
4. Comportamento definido para falha total: cache vira o conteúdo da tela, com aviso — não erro.

**Fica fora:** cache de páginas seguintes (só a primeira — ver D2), edição offline com fila de sincronização (é outra feature, muito maior), cache do spec no editor (o construtor continua exigindo rede), e pull-to-refresh (item 18, que se apoia neste).

## 2. Precedências

| O que | Onde | Uso |
| --- | --- | --- |
| `ContentListCubit` com `_categoryId`, `_query`, `_sort`, `_order` privados e `load()`/`loadMore()`/`changeSort()` | `contents_module/presentation/content_list/cubit/content_list_cubit.dart` | **Os quatro campos privados formam a chave do cache** (D1). O `load()` é o único ponto a mudar. |
| `ContentListState` (`Loading`/`Loaded{contents,nextCursor,isLoadingMore}`/`Empty`/`Error`) | `.../content_list_state.dart` | Ganha o carimbo de cache. |
| `ContentsPage {items, nextCursor}` (domain) e `ContentSummaryModel` (zard, com `tryParse`) | `contents_module/{domain/entities,data/models}/` | O model **já sabe** ir de JSON para entidade — o cache guarda o **mesmo JSON** e reusa o parse. Zero serialização nova. |
| `PreferencesRepositoryImpl` — gabarito de repositório sobre `SharedPreferences`, com try/catch traduzindo para `Failure` | `preferences_module/data/repositories/preferences_repository_impl.dart` | Gabarito exato do repositório de cache. |
| `SharedPreferences` já carregado antes do primeiro frame e injetado | `lib/bootstrap.dart:39`, `lib/injection.dart` | Sem trabalho de infra. |
| `GetContentsUseCase` | `contents_module/domain/use_cases/` | O cache entra **atrás** dele, no repositório — a presentation não muda de contrato. |

## 3. Decisões

**D1 — A chave do cache é a consulta inteira.**
`contents:v1:<projectId>:<kind?>:<categoryId ?? "all">:<sort>:<order>:<q ?? "">`
Motivo: a lista com filtro de categoria A não é a mesma lista de B, e trocar a ordenação muda o conteúdo. Cachear "a lista do projeto" sem a consulta produziria a tela errada — o pior tipo de bug de cache, porque parece funcionar.
O `v1` no prefixo permite invalidar tudo mudando uma constante quando o formato mudar.
> **Item 19 (componentes)** acrescenta `kind` à consulta. A chave já o prevê — **se o 19 vier antes, incluir; se vier depois, ele é obrigado a incluir.** Anotado nos dois planos.

**D2 — Só a primeira página é cacheada.**
Guardar as páginas seguintes exigiria reconstruir a sequência de cursores e lidar com invalidação parcial, para um ganho pequeno (quem rolou até a página 4 está online). O cache guarda os itens da primeira página **e** o `nextCursor` dela — assim, ao abrir offline, o scroll infinito tenta carregar mais e falha graciosamente (o `loadMore` já mantém lista e cursor em caso de falha — **comportamento existente, verificado**).

**D3 — Busca (`q`) não é cacheada.**
Digitar gera uma chave nova por consulta, enchendo o storage de entradas mortas. `q != null && q.isNotEmpty` → passa direto pela rede. Registrado como limitação consciente.

**D4 — O cache tem validade, mas nunca é a razão de uma tela vazia.**
TTL de **24h** para considerar "fresco" (não mostra aviso). Passado disso, ainda é mostrado, mas com o aviso de "atualizado há X". Só é descartado por: mudança do `v1`, escrita nova na mesma chave, ou limpeza explícita.

**D5 — O cache mora numa camada nova entre o use case e o repositório remoto, não dentro do repositório existente.**
`ContentsRepositoryImpl` continua sendo só rede (é o "único lugar com try/catch" e traduz `DioException` — misturar cache ali confunde as responsabilidades). Entra um `CachedContentsRepository` que **implementa a mesma interface** e recebe o remoto + o cache local por construtor. A troca acontece no `contents_injection.dart`, numa linha. É o padrão decorator, e mantém o teste do repositório remoto intacto.

**D6 — `SharedPreferences`, não banco local.**
Volume esperado: dezenas de listas × ~20 itens de JSON pequeno. `sqflite`/`drift` seriam uma dependência e um build_runner (proibido) para nada. Se o volume crescer, o `LocalContentsCache` é a única classe a trocar — a interface protege.

## 4. Fases

### F1 — A camada de cache (data)

**Arquivos a criar em `contents_module/data/`:**
- **`cache/local_contents_cache.dart`** — `abstract interface class LocalContentsCache` com:
  ```dart
  Future<Either<Failure, CachedContentsPage?>> read(String key);
  Future<Either<Failure, Unit>> write(String key, ContentsPage page);
  Future<Either<Failure, Unit>> clear(String prefix);
  ```
- **`cache/prefs_contents_cache.dart`** — implementação com `SharedPreferences`, no gabarito do `PreferencesRepositoryImpl` (try/catch → `UnexpectedFailure`). Grava `{"savedAt": <iso>, "items": [<json de cada item>], "nextCursor": ...}`.
  > **Reaproveitamento obrigatório:** os itens são gravados no **mesmo formato JSON que a API devolve**, e lidos de volta por `ContentSummaryModel.tryParse`. Nada de um segundo mapeamento — se o formato mudar, muda num lugar só. Item que não parseia é **descartado silenciosamente** (cache é best-effort), e se sobrar zero itens, trata-se como cache ausente.
- **`cache/cached_contents_page.dart`** — `class CachedContentsPage {final ContentsPage page; final DateTime savedAt;}`.
- **`cache/contents_cache_key.dart`** — a função pura que monta a chave da D1. Isolada para ser testável e para ter **um** lugar onde a chave é decidida.
- **`repositories/cached_contents_repository.dart`** — o decorator da D5.

**Arquivos a modificar:**
- **`contents_module/contents_injection.dart`** — registrar o cache e embrulhar o repositório remoto. **Só quando não é `useFakeData`** (o fake não precisa de cache e o teste ficaria não-determinístico).

**Aceite:** `flutter analyze` verde; nenhum comportamento visível muda ainda (o decorator pode nascer com o cache desligado por uma flag interna, para o PR ser 100% seguro).

### F2 — Comportamento *stale-while-revalidate* no cubit

**Arquivos a modificar:**
- **`.../content_list_state.dart`** — `ContentListLoaded` ganha `final DateTime? fromCacheAt;` (null = veio da rede) e `final bool isRevalidating;`, ambos no `copyWith` e no `props`.
- **`.../content_list_cubit.dart`** — `load()` passa a:
  1. ler o cache (rápido); havendo dados, emitir `ContentListLoaded(fromCacheAt: ..., isRevalidating: true)` **em vez** de `ContentListLoading()`;
  2. disparar a busca de rede;
  3. sucesso → emitir `Loaded(fromCacheAt: null)` **só se o conteúdo for diferente** (evita repintar a lista à toa — `ContentSummary` é `Equatable`, então `listEquals` resolve);
  4. falha **com** cache → manter a lista e emitir `isRevalidating: false` + um sinal de "offline" (reusar o padrão de `EditorNotice`? Aqui não existe — usar um campo `staleReason` no estado, mais simples);
  5. falha **sem** cache → `ContentListError`, como hoje.
  > **Guardar `isClosed` depois de cada `await`** — regra do projeto, e aqui há dois awaits em sequência.
- **`.../project_detail/widgets/content_panel/content_panel.dart`** (ou onde o painel constrói o estado `Loaded`) — mostrar uma faixa discreta "Mostrando dados salvos · atualizado há 2h" quando `fromCacheAt != null`. **Ícone + texto**, nunca só cor.

**Aceite:**
- Segunda visita à mesma consulta **não** mostra spinner.
- Com a API desligada, a lista aparece com a faixa de cache.
- Conteúdo idêntico não causa repintura (verificável contando emissões no `bloc_test`).

### F3 — Invalidação nas escritas

**Por quê.** Cache que não invalida é a origem do "apaguei e o item continua lá".

**Arquivos a modificar:**
- **`.../content_list_cubit.dart`** — depois de criar/excluir/mover conteúdo (os caminhos já existentes, incluindo o **delete otimista** do item 2 e o **mover** do item 14), invalidar o prefixo `contents:v1:<projectId>:` inteiro.
  > **Prefixo inteiro, não a chave corrente:** mover um conteúdo de categoria muda **duas** listas (a de origem e a de destino) e a de "todos". Invalidar só a corrente deixaria as outras mentindo. Custo: uma revalidação a mais. Aceito.
- **`editor_module`** — salvar um conteúdo muda o `updatedAt`, que é a ordenação default. O editor **também** precisa invalidar.
  > **Fronteira de módulo:** `editor_module` não pode importar o interno de `contents_module`. Saída: o `LocalContentsCache` (ou um `CacheInvalidator` mínimo) vive em **`core/cache/`**, e os dois módulos dependem do core. **Decidir isso na F1**, senão a F3 empaca. **Recomendação: nascer no `core/cache/` desde a F1.**

### F4 — Testes
`contents_cache_key_test.dart` (chaves distintas para consultas distintas), `prefs_contents_cache_test.dart` (round-trip, item corrompido descartado), `cached_contents_repository_test.dart` (rede ok grava; rede falha lê), `content_list_cubit_test.dart` (+ os 5 casos da F2 e a invalidação da F3).

## 5. Mapa de paralelismo

```
F1 ──► F2 ──► F3 ──► F4
```
Serial de verdade — cada fase depende da anterior. Compensa: as fases são pequenas.

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 19 (componentes)** — a chave do cache precisa incluir `kind` (D1). Anotado lá.
- **Item 24 (publicação)** — o selo "No ar / Rascunho" entra no `ContentSummary` (P4 de lá). Como o cache guarda o **JSON da API**, o campo novo entra sozinho; itens cacheados **antes** da mudança não terão o campo → o `tryParse` precisa de default tolerante (o plano 24 já pede `z.boolean()` com default seguro). **Se não tiver default, o cache antigo derruba a lista inteira.** Registrado nos dois.
- **Item 26 (auth)** — cache é **por usuário**. Um segundo usuário na mesma máquina veria a lista do primeiro. **A chave precisa ganhar o id do usuário, e o logout precisa limpar o cache.** Anotado no plano 26 e aqui: se o 26 vier primeiro, a chave da D1 já nasce com `<userId>`; se vier depois, é obrigação dele.
- **Itens 13–16** — nada quebra: o cache é transparente para o cubit fora do `load()`.

## 7. Perguntas para o humano

1. **TTL de 24h (D4) faz sentido?** Para um editor usado todo dia, sim. Para uso esporádico, talvez incomode ver "atualizado há 3 dias" antes da revalidação terminar.
2. **Cachear a busca (D3)?** Assumido que não.
3. **Limpar o cache ao trocar de projeto?** Assumido que **não** (a chave já separa por projeto, e manter acelera o vai-e-vem entre projetos).
