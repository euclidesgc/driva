# plan.md — Item 21: Aba "Componentes" no editor e instância dentro do conteúdo

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 8.
> **Precedência dura: itens 19 e 20.** Este é o item que faz o componente **valer** — até aqui ele existe, mas ninguém o usa.
> Regra do "pronto": **`flutter analyze` verde + `pnpm build` verde + testes existentes passando**.

## 1. Objetivo e recorte

Fechar o ciclo do componente: montado (item 20), ele aparece numa **terceira aba** do painel esquerdo do editor — ao lado de Widgets e Árvore — e pode ser arrastado para dentro de um conteúdo como qualquer primitivo. O conteúdo passa a ter um nó que **referencia** o componente; o app cliente recebe a árvore já resolvida.

**Entra:**
1. Nó `component` no catálogo, com a referência ao componente e (quando existirem) os valores dos parâmetros.
2. Aba "Componentes" no painel esquerdo, com arraste para canvas e árvore reusando o mecanismo que já existe.
3. Renderização da instância **no editor** (resolvendo a referência contra os componentes do projeto).
4. **Expansão na publicação** (D2) — a decisão central deste item.
5. "Onde é usado" + republicação dos dependentes.

**Fica fora:** ícone/vitrine bonita do componente (item 22), edição do componente a partir da instância (atalho "editar componente" pode entrar como polimento), override de estilo por instância.

## 2. Decisões travadas

**D1 — A instância é um nó comum: `{type: 'component', props: {ref, params}}`.**
```json
{ "id": "nd_x", "type": "component",
  "props": { "ref": "cabecalho-padrao", "params": { "titulo": "Ofertas" } } }
```
`ref` é o **slug** do componente (não o id): legível no JSON, estável em export/import entre ambientes, e coerente com o resto do produto, onde slug é a referência técnica. Renomear um componente que já é usado passa a ser uma operação com consequência — tratado em §6.
A referência mora em `properties` (e **não** no `id` do nó) de propósito: assim `cloneWithNewIds` (item 23) duplica instâncias sem quebrar nada.

**D2 — Rascunho guarda referência; publicação guarda árvore expandida.**
Ao publicar um **conteúdo** (item 24), cada nó `component` é substituído pela árvore do componente **na sua versão publicada**, com os parâmetros aplicados. A versão publicada não contém nós `component`.

Por quê:
- **O runtime fica trivial** — o `driva_client` não precisa buscar N componentes, não precisa de cache por componente, não precisa de resolução de ciclo. Um request, uma árvore. Isso importa muito num app de celular.
- **Previsibilidade** — publicar um componente **não** muda apps no ar. O que está em produção só muda quando alguém publica o conteúdo. Sem isso, editar um componente compartilhado seria capaz de alterar dezenas de telas em produção sem revisão.
- **O custo** é ter que republicar os dependentes para propagar. Isso é uma **feature**, não um bug — e ganha ferramenta na F4.

Onde a expansão acontece: **no editor, no momento do publish** (o backend não interpreta spec — regra do projeto). O `PublishContentUseCase` expande antes de enviar. Consequência: o backend continua ignorante, como deve ser.

**D3 — Ciclo é erro, e o editor barra.**
`A` usa `B` que usa `A` → detecção na inserção (recusa com recado no rodapé, reusando o `EditorNotice`) **e** na expansão do publish (erro que bloqueia). Profundidade máxima: 5 níveis (número escolhido para caber em qualquer caso real e limitar a explosão de nós; ajustável no kernel, num só lugar).

**D4 — Componente ausente ou não publicado não quebra a tela.**
No editor: a instância desenha um placeholder claro ("componente `x` não encontrado") e o rodapé lista como **erro** (portanto bloqueia publicar, item 24 D5). No publish: erro explícito, com o nome do componente. Nunca publicar árvore com buraco.

## 3. Precedências

| O que | Onde | Uso |
| --- | --- | --- |
| `WidgetDescriptor`/`descriptorFor`/`defaultNode` e a paleta 100% derivada do catálogo | `sdui_core/lib/src/catalog/widget_catalog.dart` | O nó `component` entra como descriptor — **mas com um detalhe**, ver F1. |
| `LeftPanel` com Widgets e Árvore; `DragPayload`; `resolveDrop` como regra única de encaixe | `editor_module/.../page/left_panel.dart`, `.../widgets/drag_payload.dart`, `sdui_core/.../drop_ops.dart` | A terceira aba reusa **tudo**: mesmo payload, mesmo drop. |
| `SduiRegistry` (`type → builder`) e `_UnknownTypeBox` para tipo desconhecido | `sdui_flutter/lib/src/registry.dart`, `renderer.dart:67` | O editor registra um builder próprio para `component`; o runtime **não precisa de nenhum** (D2). |
| `cloneWithNewIds` (item 23 F3a) | `sdui_core/.../tree_ops.dart` | Usado na expansão para gerar ids únicos dos nós vindos do componente. **Dependência real do item 23** — se ele não tiver entrado, esta função nasce aqui. |
| `ContentParam` + `BindingContext` + `SduiBinding.resolveAll` (item 29) | `sdui_core` | A aplicação dos parâmetros na expansão é **exatamente** uma resolução de binding com `param.*`. Se o 29 não existir, os componentes são estáticos e a expansão é uma cópia simples. |
| `GetContentsUseCase` com `kind` (item 19) | `contents_module` | Carrega a lista de componentes do projeto. |

## 4. Fases

### F1 — Kernel: o tipo `component` e a expansão

**Arquivos a criar/modificar em `packages/sdui_core/`:**
- **`catalog/widget_catalog.dart`** — descriptor de `component`: `slot: SlotKind.none`, campos `ref` (string, obrigatório) e `params` (mapa — **não há `FieldKind` para mapa hoje**; ver nota).
  > **Nota importante:** os parâmetros de uma instância são dinâmicos (dependem do componente referenciado), então **não** cabem como `PropField` fixo no descriptor. O Inspector da instância monta os editores a partir dos `params` **do componente referenciado** (F3). O descriptor declara só `ref`; `params` é gravado no nó mas não descrito no catálogo. **Isso é uma exceção consciente à regra "tudo deriva do catálogo"** — precisa de aprovação na `revisar-fase`, com esta justificativa.
  > A alternativa (um `FieldKind.componentParams`) só empurraria a dinamicidade para dentro do kernel sem ganho.
- **`ops/expand_component_ops.dart`** (novo) — função pura:
  ```dart
  Either<ExpansionError, SduiNode?> expandComponents(
    SduiNode? root,
    Map<String, ContentSpec> componentsBySlug,
    String Function() nextId, {int maxDepth = 5});
  ```
  Percorre a árvore; em cada nó `component`: busca o slug, erro se ausente (D4), clona a raiz do componente com ids novos (`cloneWithNewIds`), aplica os parâmetros (via `BindingContext` com `params`, se o item 29 existir), recursa respeitando `maxDepth` e detectando ciclo por pilha de slugs.
- **`ops/expansion_error.dart`** — `sealed class ExpansionError` com `MissingComponent(slug)`, `ComponentCycle(path)`, `MaxDepthExceeded(slug)`. Mensagens em pt-BR, prontas para a UI.
- **`diagnostics/diagnose_ops.dart`** — códigos `unknownComponentRef` (erro) e `componentCycle` (erro). Usa o mesmo mecanismo de contexto discutido nos itens 28/29 (`diagnoseTree` recebendo o spec + o conjunto de slugs conhecidos). **Terceiro cliente da mesma mudança de assinatura** — mais um motivo para fazê-la de uma vez.

**Aceite:** testes puros em `sdui_core/test/ops/expand_component_ops_test.dart` — expansão simples, com parâmetro, aninhada 2 níveis, ciclo detectado, profundidade estourada, slug ausente. Sem Flutter, sem mock.

### F2 — Editor: a aba e o arraste  **[∥ com F1 depois do formato do nó congelado]**

- **`.../presentation/editor/cubit/component_library_cubit.dart`** + `component_library_state.dart` — cubit **escopado ao painel esquerdo**, carrega os componentes publicados do projeto (`GetContentsUseCase` com `kind: component`). Escopado, não global: carregar a biblioteca não pode reconstruir canvas/inspector.
  > **Fronteira de módulo:** o `editor_module` vai precisar de um use case do `contents_module`. Isso é permitido **só pelo barrel público** (`contents_module.dart`). **Verificar o que o barrel exporta hoje** — se não exporta `GetContentsUseCase`, ou se exporta (e aí está tudo certo), ou a saída é um use case próprio do `editor_module` batendo no mesmo endpoint. **Levantar antes de estimar** — mesma incógnita apontada no item 28 F4.
- **`.../page/left_panel.dart`** — terceira aba, reusando o `CenterTabLabel`/padrão de abas já existente.
- **`.../widgets/component_library/component_list.dart`**, **`component_tile.dart`** — a lista arrastável. `ComponentTile` produz o **mesmo** `DragPayload` que `PaletteTile`, com o tipo `component` e o `ref` embutido.
- **`.../widgets/drag_payload.dart`** — o payload ganha o campo opcional `componentRef`.
- **`.../cubit/editor_cubit.dart`** — `addNode` ganha um caminho para `component` (grava `props.ref`), reusando **inteiro** o `resolveDrop`. Recusa se criar ciclo (D3), com `EditorNoticeKind.componentCycle` novo.

### F3 — Editor: renderizar e inspecionar a instância

- **`.../widgets/canvas/component_instance_builder.dart`** (novo) — o builder de `component` **do editor** (registrado num registry estendido que o canvas monta: `SduiRegistry({...defaultRegistry, 'component': ...})`). Resolve o slug contra a biblioteca carregada e renderiza a árvore do componente; sem resolver, desenha o placeholder da D4.
  > **Verificar** como o canvas monta o registry hoje (`canvas_panel.dart` / `preview_surface.dart` usam `defaultRegistry`?). Se hoje usa o default direto, esta fase introduz o registry estendido — mudança pequena e localizada.
- **`.../widgets/inspector/component/component_params_editor.dart`** (novo) — o Inspector da instância: lê os `ContentParam` do componente referenciado e monta um `PropFieldEditor` por parâmetro (reaproveitamento total, como no item 28 D3). Sem o item 29, mostra "este componente não tem parâmetros".
- **`.../widgets/inspector_panel.dart`** — despacha para o editor de parâmetros quando `node.type == 'component'`.

### F4 — Publicação: expansão, "onde é usado" e republicar dependentes

- **`editor_module/domain/use_cases/publish_content_use_case.dart`** (do item 24) — antes de publicar, carrega os componentes referenciados, chama `expandComponents` e envia a árvore expandida. Erro de expansão → falha com mensagem específica, **sem** publicar.
  > Consequência: o `PUT` de rascunho continua enviando a árvore **com** referências; só o publish envia expandido. **Isso exige que o backend aceite `spec` diferente entre rascunho e versão** — e aceita: são campos distintos (`draftSpec` vs `ContentVersion.spec`, item 24 D1). **Verificado, sem mudança de backend.**
- **Backend — "onde é usado":** `GET /v1/contents?usesComponent=<slug>` exigiria varrer JSONB (caro e frágil). **Alternativa recomendada:** tabela de arestas `ContentComponentUsage(contentId, componentSlug)` atualizada no `PUT` de rascunho pelo... backend? Não — o backend não interpreta spec.
  **Saída limpa:** o **editor** envia a lista de slugs referenciados junto do save (`PUT ... {spec, componentRefs: [...]}`), e o backend só persiste o que recebeu. O backend continua sem interpretar; quem interpreta é o kernel Dart, como sempre. Nova coluna/tabela + campo no DTO.
- **UI:** na tela do componente (ou num diálogo no editor dele), "usado em N conteúdos" com a lista e um botão **"Republicar todos"** (sequencial, com progresso e relatório de falhas).

**Aceite:** editar e publicar um componente **não** muda o app; clicar em "Republicar todos" muda; um conteúdo com componente ausente **não** publica e diz qual falta.

### F5 — Testes

Kernel (F1) + widget test da aba e do arraste + teste do `PublishContentUseCase` expandindo + E2E completo: montar componente → publicar → usar em conteúdo → publicar conteúdo → showcase (item 25) mostra a árvore expandida, **sem** nó `component`.

## 5. Mapa de paralelismo

```
F1 (kernel) ──┬─► F3 (render/inspector) ──► F4 (publish) ──► F5
              └─► F2 (aba/arraste) ───────┘
```

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 24 (publicação) — dependência forte e uma obrigação nova:** o publish deixa de ser "manda o rascunho" e passa a ser "expande e manda". O plano 24 P3 diz que `publish()` salva antes se estiver sujo e chama o use case — **isso continua verdade**, só que o use case faz a expansão. **Anotar no plano 24.**
- **Item 25 (entrega) — simplificação preservada:** graças à D2, o `driva_client` **não muda nada** para suportar componentes. Se algum dia a decisão virar "resolver em runtime", o item 25 ganha trabalho grande — por isso a D2 está registrada com o porquê.
- **Item 23 (histórico) — dependência real:** `cloneWithNewIds` (F3a de lá) é usado na expansão. Se o 23 não tiver entrado, a função nasce **aqui** e o plano 23 depois só a encontra pronta. **Anotado nos dois.**
- **Item 29 (dados) — dependência opcional:** parâmetros de componente = `ContentParam` + resolução de binding. Sem o 29, componentes são estáticos e a F1 faz cópia simples.
- **Item 28 (eventos)** — instância de componente carrega os eventos definidos **dentro** do componente; a expansão os copia junto. Nada a fazer.
- **Item 22 (metadados) — afinação futura, não obrigação:** o `ComponentMeta` (ícone, rótulo, capa) viaja dentro do spec do componente e, portanto, seria copiado para a árvore expandida na publicação. É inofensivo (o runtime ignora), mas são bytes inúteis no payload público. **Se o tamanho incomodar**, a expansão pode descartar `meta` ao copiar. Não fazer isso agora — é otimização sem problema medido.
- **Item 30 (breakpoints)** — se o override por breakpoint existir, a expansão precisa preservá-lo nos nós copiados. **Anotado no plano 30.**

## 7. Perguntas para o humano

1. **Referência por slug (D1) ou por id?** Slug é legível e portável entre ambientes; id é imune a rename. O plano assume slug + tratamento de rename (bloquear rename de componente em uso, ou reescrever as referências — **decidir**).
2. **Expansão no publish (D2) — confirma?** É a decisão mais consequente deste marco. A alternativa (resolver em runtime) propaga na hora, mas complica o SDK e tira previsibilidade de produção.
3. **"Republicar todos" pode publicar conteúdo que estava com rascunho sujo?** Assumido **não** — só republica quem estiver limpo; os sujos entram no relatório para revisão manual.
