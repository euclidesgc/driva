# plan.md — Item 29: Contexto de dados e binding com contrato

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 7.
> Regra do "pronto": **`flutter analyze` verde + testes existentes passando**.
> **Precedência dura: itens 25 e 28.** Este item resolve binding **em runtime** — precisa do runtime (25) e reaproveita o catálogo de ações (28).
> **Aviso de tamanho, dito na cara:** este é o maior item aberto do roadmap. O plano está dividido em **duas fatias** (§4) que podem virar dois itens (29a/29b) se a execução preferir entregas menores. A fatia 1 sozinha já tem valor de ponta a ponta.

## 1. Objetivo e recorte

O item 9b entregou o binding como **edição**: toda prop `isBindable` alterna entre valor fixo e expressão, `SduiBinding` reconhece/extrai/embrulha `{{...}}`, e o diálogo mostra o tipo esperado. O que falta é tudo o que dá **sentido** a isso:

- **Nada define o que existe para bindar.** O campo é texto livre: `{{qualquercoisa}}` é aceito e ninguém sabe se aponta para algo.
- **Ninguém resolve.** O renderer entrega a string `"{{user.name}}"` para o builder, que a desenha literalmente. No canvas o usuário vê as chaves; no app cliente também veria.
- **Não há de onde os dados virem.** Não existe conceito de parâmetro de página nem de fonte de dados.

**Entra (fatia 1):**
1. **Parâmetros da página** — o conteúdo declara o que recebe de quem o abre (`DrivaContent(slug:, params: {...})`).
2. **Fontes de dados** — o conteúdo declara de onde busca dados (REST, por ora), resolvidos pelo runtime antes de desenhar.
3. **Resolução do binding** no kernel + no renderer, com caminho por ponto (`{{param.id}}`, `{{data.perfil.nome}}`).
4. **Valores de exemplo** para o canvas do editor mostrar conteúdo de verdade em vez de `{{...}}`.
5. **Diálogo de binding com sugestões** — o editor oferece as chaves disponíveis em vez de texto livre.

**Entra (fatia 2):**
6. **Listas com template** — `listView`/`gridView` repetindo um filho por item de uma coleção (`{{item.*}}`).
7. **Ação `callApi` e eventos de valor** (`onChanged`) — o que o item 28 recortou de propósito.

**Fica fora:** expressões com operadores/condicionais (`{{a || b}}`, `{{if …}}`), transformações (formatação de data/moeda no binding), GraphQL, WebSocket/tempo real, e escrita de dados (mutação) — tudo registrado em §9.

## 2. Precedências

| O que já existe | Onde | Uso |
| --- | --- | --- |
| `SduiBinding.isBinding/expressionOf/wrap` — regex `^\{\{\s*(\S(?:.*\S)?)\s*\}\}$` | `sdui_core/lib/src/model/sdui_binding.dart` | **A gramática está travada aqui.** A resolução é acrescentada ao lado, sem mudar o reconhecimento. |
| `PropField.isBindable` (default `true`) e o par `PropBindingButton`/`PropBindingDialog`/`PropBindingEditor` | `sdui_core/.../prop_field.dart`, `editor_module/.../prop_field/` | O diálogo ganha sugestões; o resto da UI de binding **não muda**. |
| `ContentSpec {specVersion, id, name, slug, description, root?, safeArea}` + `copyWith` + `toJson` que **omite chave vazia** | `sdui_core/lib/src/model/content_spec.dart` | Gabarito exato de como `params`/`dataSources` entram sem quebrar spec antigo (o `safeArea` do item 8f fez a mesma coisa: `if (safeArea.isNotEmpty)`). |
| `parseContentSpec` lendo campos fora do envelope zard com checagem manual (`rawSafeArea is! Map`) | `sdui_core/lib/src/schema/content_schema.dart:36` | Mesmo padrão para os campos novos. |
| `SduiRenderer.render` → `_SduiNodeView(key: ValueKey(node.id))` — **um `StatelessWidget` por nó** | `sdui_flutter/lib/src/renderer.dart:18,50` | É exatamente onde a resolução de props entra, com isolamento de rebuild por nó já pronto. |
| `SduiView(node:, registry:, onAction:, nodeWrapper:, safeArea:)` | `sdui_flutter/lib/src/sdui_view.dart` | Ganha o contexto de dados. |
| `packages/driva_client` (item 25): `Driva.init`, `DrivaContent(slug:)`, cache, fallback | item 25 | Ganha `params:` e a busca das fontes. |
| `ActionDescriptor`/`actionCatalog` (item 28) | `sdui_core/lib/src/catalog/action_catalog.dart` | `callApi` entra **como mais um descriptor**, não como mecanismo novo. |
| `InspectorPanel` no modo Página (sem nó selecionado, edita `safeArea`) — item 8f | `.../widgets/inspector_panel.dart:34` | É o lugar natural da aba "Dados" da página. |

## 3. Decisões travadas

**D1 — Forma no spec (aditiva, chave omitida quando vazia):**
```json
{
  "specVersion": 1, "kind": "content", "id": "...", "slug": "perfil",
  "params": [
    {"key": "userId", "type": "string", "required": true, "previewValue": "u_123"}
  ],
  "dataSources": [
    {"id": "perfil", "type": "rest", "method": "GET",
     "url": "https://api.exemplo.com/users/{{param.userId}}",
     "previewValue": {"nome": "Maria", "plano": "Pro"}}
  ],
  "root": { ... }
}
```
- `params` e `dataSources` só aparecem no JSON quando **não vazios** — spec antigo continua válido sem migração, exatamente como o `safeArea` do item 8f.
- **`previewValue` fica no spec e o runtime o ignora.** Alternativa considerada e descartada: guardar preview fora do spec (numa tabela do editor) — obrigaria mais uma tabela, mais um endpoint, e perderia o valor ao exportar/importar o spec. Custo aceito: alguns bytes a mais no payload público. **Nunca colocar segredo em `previewValue`** — é público. Escrever isso no `helpText` do campo.

**D2 — Namespaces do contexto, fechados:**
| Prefixo | Origem | Exemplo |
| --- | --- | --- |
| `param.` | o que o app passou em `DrivaContent(params:)` | `{{param.userId}}` |
| `data.<sourceId>.` | resposta de uma fonte | `{{data.perfil.nome}}` |
| `item.` | item corrente dentro de um template de lista (fatia 2) | `{{item.titulo}}` |
Qualquer outro prefixo é **desconhecido** → diagnóstico de aviso no editor, e no runtime resolve para `null`.

**D3 — Resolução é acesso por caminho, não expressão.**
`{{data.perfil.endereco.cidade}}` navega mapas e listas (índice numérico: `data.itens.0.nome`). **Sem** operadores, sem função, sem condicional. Motivo: uma linguagem de expressão é um projeto próprio (parser, precedência, erros, segurança) e o SDUI não precisa dela para 90% dos casos. Registrado em §9 como evolução — e a gramática atual não impede acrescentá-la depois.

**D4 — Onde a resolução acontece: no renderer, por nó, uma vez.**
`_SduiNodeView.build` resolve as props do **seu** nó contra o contexto obtido de um `SduiDataScope` (`InheritedWidget`) antes de chamar o builder. Motivo: mantém os 24 builders existentes **intocados** (eles continuam lendo `node.properties` já resolvido) e preserva o isolamento de rebuild por nó que o item 3b construiu — só os nós que dependem do dado mudado reconstroem.
Alternativa descartada: resolver a árvore inteira antes de renderizar (mais simples de escrever, mas refaz toda a árvore a cada mudança de dado — exatamente o que o item 3b matou).

**D5 — Valor não resolvido nunca vira `{{...}}` na tela.**
Se a chave não existe: a prop se comporta como **ausente** (o builder aplica o `defaultValue` do `PropField`, que já é o contrato do catálogo). Motivo: mostrar `{{user.name}}` para o usuário final de um app é o pior modo de falha possível. No **editor**, o comportamento é o oposto: mostra o `previewValue` e, faltando, um marcador visual claro (é lá que o erro deve gritar).

**D6 — Fontes de dados são buscadas pelo runtime, não pelo backend do driva.**
O `driva_client` faz a requisição direto da API do cliente. O backend do driva **não** é proxy. Motivo: proxy significaria o driva ver (e poder vazar) dados do cliente, exigir credenciais dele e virar gargalo. Consequência: cabeçalhos de autenticação da API do cliente são responsabilidade do app — `Driva.init(dataHeaders: ...)` ou um `onPrepareRequest` injetável. **Nunca** guardar segredo do cliente no spec (que é público via item 25).

**D7 — Preview no editor não faz rede.**
O canvas usa `previewValue`. O editor **nunca** chama a API do cliente — evita CORS, credencial e efeito colateral em API real durante a edição. Botão futuro "buscar dados de exemplo" fica em §9.

## 4. Fases

### FATIA 1 — o contexto e a resolução

---

#### F1 — Kernel: modelo, schema e resolvedor  **[base de tudo]**

**Arquivos a criar em `packages/sdui_core/lib/src/model/`:**
- **`content_param.dart`** — `class ContentParam extends Equatable {final String key; final ParamType type; final bool required; final Object? previewValue;}` + `toJson`.
- **`param_type.dart`** — `enum ParamType {string, number, boolean, object, list}` (arquivo próprio; enums agrupados são permitidos, mas este é um só).
- **`content_data_source.dart`** — `class ContentDataSource extends Equatable {final String id; final DataSourceType type; final String method; final String url; final Map<String,String> headers; final Object? previewValue;}` + `toJson`. `enum DataSourceType {rest}` — um valor só hoje, mas o enum evita `String` mágica quando chegar `graphql`.
- **`binding_context.dart`** — `class BindingContext {final Map<String,dynamic> params; final Map<String,dynamic> data; final Map<String,dynamic>? item;}` com `Object? read(String path)` implementando a D3 (split por `.`, navegando `Map`/`List`, devolvendo `null` em qualquer falha — **nunca lança**).

**Arquivos a modificar:**
- **`model/content_spec.dart`** — `+ final List<ContentParam> params;` e `+ final List<ContentDataSource> dataSources;`, ambos `const []` por default, no `copyWith`, no `props` e no `toJson` **com `if (params.isNotEmpty)`** (D1).
- **`model/sdui_binding.dart`** — método novo `static Object? resolve(Object? value, BindingContext context)`: se não é binding, devolve o próprio valor; se é, `context.read(expressionOf(value)!)`.
  E `static Map<String, dynamic> resolveAll(Map<String, dynamic> properties, BindingContext context)` — devolve **o mesmo mapa por referência** quando nenhuma prop é binding (otimização que evita alocar por nó a cada frame; verificação barata com um loop de `isBinding`).
- **`schema/content_schema.dart`** — parse dos dois campos novos no mesmo estilo do `safeArea` (checagem manual de tipo, erro claro). Validar: `params[].key` não vazio e único; `dataSources[].id` não vazio, único e sem ponto (senão quebra o caminho `data.<id>.campo`).
- **`sdui_core.dart`** — exports novos.

**Critério de aceite:** `parseContentSpec` de um spec **sem** os campos continua funcionando (regressão); com campos malformados devolve `Left` com mensagem legível; `BindingContext.read` navega `a.b.0.c` e devolve `null` para caminho inexistente sem lançar.

---

#### F2 — Renderer: escopo de dados e resolução por nó

**Arquivos a criar em `packages/sdui_flutter/lib/src/`:**
- **`data/sdui_data_scope.dart`** — `class SduiDataScope extends InheritedWidget` carregando o `BindingContext`; `static BindingContext of(BuildContext)` com fallback para um contexto vazio (`const BindingContext.empty()`), para que renderizar sem escopo continue funcionando.
  > O fallback é o que mantém **toda** a base atual funcionando sem mudança — inclusive o `renderer_golden_test.dart` existente.

**Arquivos a modificar:**
- **`src/renderer.dart`** — em `_SduiNodeView.build`, antes de chamar o builder:
  ```
  final context0 = SduiDataScope.of(context);
  final resolved = SduiBinding.resolveAll(node.properties, context0);
  final effective = identical(resolved, node.properties) ? node : node.copyWith(properties: resolved);
  ```
  e passar `effective` ao builder. O `identical` evita `copyWith` quando não há binding — o caso comum.
  > **Não** resolver `events` aqui: os params de ação são resolvidos **na hora do dispatch** (o valor pode ter mudado). Ajustar `dispatch` para receber o contexto e resolver `params` de cada `SduiAction` antes de entregar ao handler.
- **`src/sdui_view.dart`** — `SduiView` ganha `final BindingContext? dataContext;` e embrulha em `SduiDataScope` quando não-nulo. `SduiView.content(spec)` ganha o parâmetro opcional correspondente.

**Critério de aceite:** `renderer_golden_test.dart` e `sdui_view_test.dart` existentes passam **sem alteração** (prova de que a mudança é aditiva); teste novo: `text` com `content: "{{param.nome}}"` desenha "Maria" com contexto e desenha **o default do catálogo** sem contexto (D5).

---

#### F3 — Editor: aba "Dados" da página + preview no canvas

**Precedência:** F1 e F2.

**Arquivos a criar em `.../presentation/editor/widgets/inspector/data/`:**
- `page_data_panel.dart` — o corpo da aba: duas seções (Parâmetros, Fontes de dados).
- `param_list.dart`, `param_row.dart`, `param_form_dialog.dart` — CRUD de parâmetro (key, tipo, obrigatório, valor de exemplo).
- `data_source_list.dart`, `data_source_row.dart`, `data_source_form_dialog.dart` — CRUD de fonte (id, método, URL com binding permitido, headers, JSON de exemplo).
- `preview_json_field.dart` — campo de `previewValue` com validação de JSON (reaproveitar o `json_highlighter` do item 8 para exibição, se couber sem esforço).

**Arquivos a modificar:**
- **`.../widgets/inspector_panel.dart`** — no modo Página (sem nó selecionado), o painel passa a ter abas: "Área segura" (o que já existe) e "Dados".
  > **Atenção ao item 28:** aquele plano coloca abas no modo **nó** (Propriedades/Eventos). Aqui é o modo **página**. São dois `TabBar` diferentes no mesmo widget — **extrair um `InspectorTabs` reutilizável** em vez de duplicar. Quem chegar segundo faz a extração.
- **`.../cubit/editor_cubit.dart`** — `void updateParams(List<ContentParam>)`, `void updateDataSources(List<ContentDataSource>)`, ambos emitindo documento novo **pelo `_emitDocument`** (contrato do item 23) — o `_emitDocument` hoje só troca `root`; vai precisar aceitar um `ContentSpec` inteiro, ou ganhar variantes. **Refatorar `_emitDocument` para receber o `ContentSpec` novo** é a saída limpa; o `updateSafeAreaProps` (que hoje emite fora do funil) passa a usá-la também — **fecha aquele buraco de histórico de uma vez**.
- **`.../cubit/editor_state.dart`** — `EditorReady` ganha `BindingContext get previewContext` **derivado** do documento (monta `params`/`data` a partir dos `previewValue`). Derivado, não guardado — mesma disciplina do `selectedNode`/`diagnostics`.
- **`.../widgets/canvas/preview_surface.dart`** (ou onde o `SduiView` é montado no canvas — **confirmar o arquivo**) — passar `dataContext: state.previewContext`.

**Critério de aceite:**
- Declarar `param.nome` com exemplo "Maria", bindar o `content` de um `text` a `{{param.nome}}` → **o canvas mostra "Maria"**, não as chaves.
- Remover o parâmetro → o canvas volta ao default do catálogo e o binding vira aviso no rodapé de problemas (F4).
- Editar um `previewValue` não reconstrói a árvore inteira (rebuild escopado — validar com o teste de perf existente `editor_perf_test.dart`).

---

#### F4 — Editor: binding com sugestões + diagnóstico  **[∥ com F5]**

**Arquivos a modificar:**
- **`.../widgets/prop_field/prop_binding_dialog.dart`** — recebe as chaves disponíveis (derivadas do `previewContext`) e as lista para clicar, com busca. Texto livre continua permitido (o usuário pode bindar algo que só existirá em runtime), mas o caminho conhecido vira um clique.
- **`sdui_core/lib/src/diagnostics/diagnose_ops.dart`** — `DiagnosticCode.unknownBindingPath`, severidade **aviso**, emitido quando a expressão usa um prefixo válido (`param.`/`data.`) e a chave não existe no que o documento declara. Prefixo desconhecido → mesmo aviso, mensagem diferente.
  > Como no item 28 (F4), `diagnoseTree` precisa do contexto para julgar: passar o `ContentSpec` inteiro em vez de só o `root`. **Isso muda a assinatura de `diagnoseTree`** — hoje `diagnoseTree(document.root)`. Mudar para `diagnoseTree(spec)` e ajustar `EditorReady.diagnostics`. Encaixa bem com a mudança do item 28 F4, que também queria mais contexto — **fazer a mudança de assinatura uma vez só**, no item que chegar primeiro.

---

#### F5 — Runtime: params e fontes no `driva_client`  **[∥ com F4]**

**Precedência dura:** item 25 (o package existe).

**Arquivos a modificar/criar em `packages/driva_client/lib/src/`:**
- `driva_content.dart` — `DrivaContent` ganha `final Map<String, dynamic> params;`.
- `data/data_source_loader.dart` (novo) — dado o `ContentSpec` resolvido, para cada `ContentDataSource`: resolve a URL contra o contexto de params, faz a requisição com o `Client` injetado, decodifica JSON, monta `data[sourceId]`. Falha de uma fonte **não derruba a tela**: aquela chave fica `null` e as props que dependiam dela caem no default (D5) — coerente com "o runtime nunca derruba a tela do cliente" (D5 do item 25).
- `driva_config.dart` — `dataHeaders` ou `onPrepareRequest` (D6).
- `driva_content.dart` — o `build` monta `BindingContext(params: widget.params, data: loaded)` e passa para `SduiView(dataContext:)`.
- **Cache das fontes:** TTL curto e separado do cache de spec (spec muda por publicação; dado muda o tempo todo). Default: sem cache de dados na primeira versão — buscar a cada montagem. Registrar como ponto de evolução.

**Critério de aceite:** showcase abre um conteúdo com `param.userId` e uma fonte REST pública; a tela mostra dado real; derrubando a rede da fonte, a tela **ainda desenha** (com defaults).

---

### FATIA 2 — repetição e escrita _(pode virar o item 29b)_

#### F6 — Listas com template
`listView`/`gridView` ganham as props `items` (bindable, espera lista) e passam a repetir **o primeiro filho** como template, com `SduiDataScope` aninhado por item (`item.*`). Ids dos nós repetidos precisam ser derivados (`<id>#<índice>`) para o `ValueKey` do renderer não colidir. O editor mostra N cópias no canvas conforme o `previewValue`. **É a fase mais complexa do plano** — merece PR próprio e possivelmente item próprio.

#### F7 — `callApi` e eventos de valor
Fecha o recorte do item 28: `ActionDescriptor` novo `callApi` (url, method, body) e os eventos `onChanged`/`onSubmitted` dos widgets de formulário, com o valor corrente disponível como `{{value}}`. Exige estado de formulário no runtime (um `SduiFormScope`) — **é uma feature em si**.

#### F8 — Testes de tudo (por último)

## 5. Mapa de paralelismo

```
F1 ──► F2 ──► F3 ──┬─► F4
                   └─► F5     (F4 e F5 são independentes)
                        │
                        └──► F6 ──► F7 ──► F8   (fatia 2)
```

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 23 (histórico) — duas costuras:**
  1. A F3 **refatora o `_emitDocument`** para receber `ContentSpec` em vez de `SduiNode?`. Isso **melhora** o plano 23 (fecha o buraco do `updateSafeAreaProps`, que lá era tratado como caso especial). Se o 23 já estiver entregue, é refactor com teste de regressão; se não, o plano 23 pode já nascer com a assinatura melhor — **anotar no plano 23**.
  2. A `coalesceKey` precisa de um namespace novo para os campos de dados (`data:param:<key>`), sem colidir com `props:`/`event:`.
- **Item 28 (eventos) — três costuras:**
  1. `dispatch` passa a resolver os `params` da ação contra o contexto (F2). O plano 28 entrega `dispatch` sem isso; **é uma mudança aditiva**, não quebra o que ele fez.
  2. O `TabBar` do Inspector: o 28 coloca abas no modo nó, o 29 no modo página. **Extrair `InspectorTabs` comum** — quem chegar segundo faz.
  3. A assinatura de `diagnoseTree` muda nos dois planos (28 F4 quer `knownSlugs`, 29 F4 quer o spec inteiro). **Resolver de uma vez:** `diagnoseTree(ContentSpec spec, {Set<String> knownSlugs = const {}})`. Anotado nos dois.
- **Item 24 (publicação) — atenção nova:** `previewValue` vai para a versão publicada e fica **público** via item 25. O `helpText` do campo precisa avisar; e o gate CISO do 24 deve incluir "spec publicado não contém segredo" na checklist.
- **Item 25 (entrega) — compatível:** `DrivaContent` ganha `params` (aditivo, com default `const {}`), sem breaking change no package.
- **Item 30 (breakpoints) — conflito de mecanismo a evitar:** breakpoint também quer "props que variam". Se os dois inventarem mecanismos separados de resolução de prop, o renderer ganha duas camadas concorrentes. **Anotado no plano 30:** a resolução por breakpoint deve acontecer **antes** da resolução de binding, na mesma passagem do `_SduiNodeView`.

## 7. Definition of Done (fatia 1)

- [ ] `flutter analyze` verde; suítes existentes de `sdui_core`/`sdui_flutter`/editor passando **sem alteração** (prova de aditividade).
- [ ] Spec antigo (sem `params`/`dataSources`) abre, edita, salva e publica normalmente.
- [ ] Canvas mostra valores de exemplo; app mostra valores reais.
- [ ] Fonte de dados fora do ar não derruba a tela do app.
- [ ] Nenhum segredo exigido no spec (validado no gate CISO).
- [ ] `docs/29-contexto-de-dados/final_report.md`; `docs/roadmap.md` atualizado.

## 8. Perguntas para o humano (bloqueiam a F1)

1. **Fatiar em 29a (contexto) e 29b (listas/formulário)?** Recomendo **sim** — a fatia 1 entrega valor sozinha e a fatia 2 é do tamanho de uma feature inteira.
2. **`previewValue` no spec (D1) é aceitável?** Ele viaja para produção e é público. A alternativa (tabela separada no editor) custa backend novo.
3. **Autenticação das fontes de dados do cliente (D6):** o app injeta headers, certo? Se algum cliente quiser que o driva guarde a credencial e faça proxy, isso muda a arquitetura inteira e precisa virar decisão explícita — e provavelmente um "não".

## 9. Deixado de fora (registro)

Operadores e condicionais na expressão · formatação (data/moeda) no binding · GraphQL · tempo real · mutação de dados · botão "buscar exemplo real" no editor · cache configurável por fonte · paginação dentro de lista bindada.
