# Roadmap — driva

Rastreamento vivo do que está **feito**, **em andamento** e **por fazer**. A lista está ordenada **por dependência**: o que vem antes destrava o que vem depois. Cada item traz, entre parênteses, o número original em `docs/03-melhorias/` para rastreabilidade.

**Legenda:** `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída.

> **Documento vivo.** Mantido atualizado pela IA a cada fechamento de trabalho (junto da faxina de branches): marca o item entregue como `[x]`, o item da vez como `[-]`, e — quando surgem features novas — reescreve o texto para dar clareza e **reordena** para o ponto de precedência correto. Ver `CLAUDE.md` › _Método de trabalho_.

## Base já entregue

- `[x]` **Fundação I1 — Conteúdos (rename página→conteúdo + identidade slug/CUID2).** No ar em homologação; renderer SDUI, editor de 3 painéis, catálogo com 14 widgets, backend `/v1/contents`. É o alicerce sobre o qual todo o resto abaixo é construído.

---

## Marco 0 — Fundação e correções que destravam tudo

_Sem dependências entre si; vêm primeiro porque tornam todo o resto viável ou agradável de construir._

- `[x]` **1. Corrigir o bug de foco no Inspector (0-dep).** _(item 16)_ Ao digitar em qualquer campo de propriedade (ex.: elevação do card), o editor perde o foco após cada tecla e exige reclicar. Causa: a `ValueKey` do `TextFormField` inclui o valor, então cada `onChanged` recria o campo. **Precede o item 9 (catálogo)** — sem isso, editar propriedades é inviável.
- `[x]` **2. Enxugar loadings e rebuilds da navegação.** _(item 10)_ Remover o loading desnecessário ao criar conteúdo (ele pisca antes de ir ao construtor) e cortar rebuilds à toa nas telas de carregamento. A transição em si já está boa — o alvo é o flash de load. **Entregue:** create navega direto ao editor (sem `await load()`/spinner) e exclusão otimista (card some na hora, reconcilia em falha). Docs em `docs/05-loadings-navegacao/`.
- `[x]` **3. Tema light + dark com persistência.** _(item 0)_ Hoje só existe `AppTheme.light`. Adicionar o dark e persistir a opção ao sair (introduz a camada de preferências local que o **item 15 (offline-first)** reaproveita).
- `[x]` **3b. Aliviar o peso do editor ao digitar/arrastar (escopo de rebuilds).** _(perf; surgiu do uso)_ Um único `BlocBuilder` no topo reconstrói o editor inteiro (paleta + árvore + canvas + inspector) a cada tecla/tick de drag, e o canvas re-executa o renderer real do Flutter toda vez. Escopar rebuilds por painel (`BlocSelector`/`buildWhen`), isolar o canvas (`RepaintBoundary`) e **throttlar só o preview caro** (mantendo campo e estado instantâneos). Sem dependências; destrava a sensação de leveza de tudo depois (inclusive o item 9).

## Marco 1 — Polimento do construtor (canvas)

_Depende só do editor atual; independente de backend e de categorias._

- `[x]` **4. Altura máxima do mock do dispositivo.** _(item 12)_ ~~Limitar a altura do mock para não rolar a tela em monitores grandes.~~ **Revertido:** o teto encolhia o dispositivo em janelas baixas (indesejado); o **zoom** (80%) já resolve o encaixe. O `_DeviceFrame` volta a usar `device.height` natural; o usuário controla o encaixe por zoom + rolagem do canvas.
- `[x]` **5. Feedback visual ao soltar um componente no mock + realce no hover.** _(item 11)_ Componente solto no dispositivo mostra borda tracejada + uma tag pequena com o nome, para o usuário perceber que há algo ali. Passar o mouse por cima realça o nó com um contorno leve (estilo FlutterFlow), estado efêmero e local do canvas.
- `[x]` **6. Molduras de dispositivo realistas.** _(item 13)_ Trocar as 3 caixas de tamanho por molduras críveis de Android, iPhone e Tablet (aproximar do device real, como no app de exemplo).
- `[x]` **7. Painel de preview do JSON em tempo real.** _(item 14)_ Exibir o JSON do spec sendo gerado, numa aba/janela destacável — lado a lado com o mock ou alternando entre eles (estilo painéis do VS Code). **Precede o item 8.**
- `[x]` **8. JSON somente-leitura, copiável e com syntax highlight.** _(item 15)_ Depende do painel do item 7.
- `[ ]` **8b. Legibilidade avançada do JSON.** _(polimento; surgiu do review)_ Números de linha já entregues; falta destacar a **chave-pai** e casar `{`/`}` (abre/fecha) quando o cursor está próximo, e permitir **dobrar seções**. Baixa prioridade.
- `[x]` **8c. Raiz livre (página nasce vazia; 1º widget vira a raiz).** _(surgiu do produto; estilo FlutterFlow)_ O kernel deixa de impor uma `column` fixa: `ContentSpec.root` vira opcional (`SduiNode? root`), `parseContentSpec` aceita `root` ausente/null e valida qualquer tipo do catálogo como raiz. Conteúdo novo (backend + fake store) nasce **sem `root`**; o editor mostra um estado-vazio (drop tracejado) e o primeiro widget adicionado — de qualquer tipo — vira a raiz selecionada. Renderer desenha vazio com `root == null`.
- `[ ]` **8d. Raiz folha mostra o estado-vazio em vez de renderizar.** _(bug menor; surgiu do teste da 8c)_ Quando a raiz é um widget **folha** (ex.: um `textField` sozinho, sem slot de filhos), o canvas exibe o placeholder de estado-vazio ("Arraste um widget…") em vez de renderizar o próprio widget. A condição de empty-state deve considerar só `root == null` (e slots de container vazios), não um root folha já preenchido. Baixa prioridade.

## Marco 2 — Catálogo de widgets (track contínuo)

- `[-]` **9. Ampliar o catálogo usando o FlutterFlow como referência.** _(item -1)_ Guiar-se pelo FlutterFlow para decidir quais widgets teremos e como suas propriedades são modeladas/editadas. Track contínuo que alimenta paleta e Inspector. **Depende do item 1** (edição de propriedade precisa funcionar).
  - **Incremento 1 (controles de formulário):** `textField`, `switch`, `checkbox` — três novos descriptors + builders + fixture, preview estático. Paleta/Inspector derivam do catálogo, sem código por tipo no editor.
  - **Incremento 2 (`textField` abrangente):** props do `textField` ampliadas à la FlutterFlow — `filled` (bool) vira `borderStyle` (enum `outline`/`underline`/`filled`); adiciona `keyboardType` (enum), `maxLength` (int) e `prefixIcon` (iconName). Só descriptor + builder + fixture; o Inspector já deriva os editores do `FieldKind`.
- `[ ]` **9b. Editores de propriedade avançados no Inspector (estados + binding).** _(baixa/média prioridade)_ A componentização do editor de propriedade **por tipo** (`FieldKind`→editor) já existe; falta a camada de **estados e binding** que o FlutterFlow tem: (a) **estados múltiplos** por propriedade — forma expandida detalhada ↔ contraída com presets (ex.: `padding` com 4 lados individuais vs. atalho "todos"); (b) **"set from variable" / binding** por propriedade — alternar entre **valor fixo** e **expressão `{{binding}}`** (o binding já é dado no spec; o app cliente o executa, o editor só o edita). **Depende do item 1** e alimenta todo o track do catálogo.

## Marco 3 — Hierarquia Projeto → Categoria → Conteúdo (o fluxo do protótipo)

_Track interdependente que exige mudança de backend antes do frontend. **Projeto** e **Categoria** são conceitos **novos** que passam a ancorar os conteúdos. O **fluxo inteiro do protótipo** (Projetos → tela do projeto com árvore de categorias + painel de conteúdos → Construtor) é entregue neste marco: item 9d (Projeto), item 10 (API), itens 11–14 (a tela do projeto), itens 15–16 (busca/ordenação/paginação da lista)._

- `[-]` **9d. CRUD de Projeto — novo topo da hierarquia (Projeto → Categoria → Conteúdo).** _(feature nova; docs/09)_ Home de **cards** de projeto (imagem/título/descrição), **upload seguro de imagem** (pipeline CISO) e `Content.projectId` vira **FK NOT NULL → Project** (`onDelete: Restrict`, seed do projeto `default`). Backend `/v1/projects` + `projects_module` (domain/data) **entregues**; a **UI da home de cards** (F5) e os **contadores nos cards** ficam no fecho do fluxo. **É pré-requisito do item 10** (categoria e conteúdo agora vivem dentro de um projeto). Docs vivas em `docs/09-crud-projeto/`.
- `[ ]` **10. API de conteúdos com filtro, busca, ordenação e paginação + fundação de Categoria.** _(item 7)_ `GET /v1/contents` passa a **envelope `{data,nextCursor}`** com **cursor keyset**, filtro por `categoryId`, busca acento-insensível (`q`), ordenação (`updatedAt`/`createdAt`/`name`) e `limit`; nasce a tabela **`Category`** (árvore `parentId`, **por projeto**, FK NOT NULL → Project) + o **CRUD de categoria** + a **"Geral" por projeto**; o `contents_module` do editor é adaptado ao envelope **na mesma fatia** (restrição dura). **Depende do item 9d** (Project como topo). **Fundação do backend — precede os itens 11 a 16.** Docs vivas em `docs/08-api-conteudos-filtro-busca/` (PRD, specs, **plan.md do fluxo inteiro**).
- `[ ]` **11. Árvore de categorias/subcategorias na tela do projeto (lado esquerdo).** _(item 1)_ **UI** — recursiva por `parentId`, com "Não categorizados"/raiz e editar/excluir no hover. A camada de dados sai do item 10. Depende dos itens 9d e 10.
- `[ ]` **12. "Não categorizados"/raiz como entrada de topo, selecionada por padrão.** _(item 6)_ **UI** — a seleção default mostra tudo (ou os sem categoria). Depende do item 11.
- `[ ]` **13. Selecionar categoria filtra o painel de conteúdos à direita.** _(item 3)_ **UI** — clicar num nó dispara request com `categoryId`. A API já existe no item 10. Depende dos itens 11 e 10.
- `[ ]` **14. Atribuir/mover conteúdo entre categorias.** _(item 2)_ **UI** — pelo formulário de conteúdo (seletor de categoria) **ou** arrastando o conteúdo para a categoria; o `PUT` com `categoryId` já existe no item 10. Depende dos itens 11 e 10.
- `[ ]` **15. Busca e ordenação de conteúdos no painel.** _(item 4)_ **UI** — caixa de busca (`q`) + toggle de ordenação; a API já existe no item 10. Depende do item 10.
- `[ ]` **16. Listagem infinita (paginação por cursor).** _(item 5)_ **UI** — consome o `nextCursor` do envelope do item 10. Depende do item 10.

> **Cobertura do "fluxo inteiro do protótipo".** O plano em `docs/08-api-conteudos-filtro-busca/plan.md` entrega este fluxo em 3 fatias: **P1** = item 10 (backend + editor data/domain); **P2** = a **tela do projeto** (árvore + painel + forms) — cobre a UI dos itens 11–15 num só esforço, **parcialmente bloqueada por design** (o `.dc.html` da tela não chegou; estrutura/fluxo definidos, pixel-perfect refina depois); **P3** = integrações finais (mover conteúdo fim-a-fim + contadores nos cards da home via `_count`). A home de cards (item 9d/F5) + P2 + o Construtor (já existe) fecham Projetos → Categorias → Conteúdos → Construtor.
- `[ ]` **17. Offline-first na tela de conteúdos.** _(item 8)_ Cache local; atualiza apenas ao salvar. Depende da lista já com filtro/busca/paginação (itens 13–16) e reaproveita a persistência do item 3.
- `[ ]` **18. Pull-to-refresh que refaz o cache.** _(item 9)_ Puxar para atualizar força a ida à API e reconstrói o cache local. Depende do item 17.

## Marco 4 — Componentes (widgets reutilizáveis)

_A maior frente; depende do construtor maduro (Marcos 1–2) e das categorias (Marco 3)._

- `[ ]` **19. Home passa a exibir Conteúdos e Componentes.** _(item 17)_ Divisão de nível superior entre as duas coisas. Depende da lista de conteúdos madura.
- `[ ]` **20. Componente como widget reutilizável, com construtor próprio.** _(item 18)_ Mesma premissa de Conteúdo; um componente é um widget que poderá ser usado como conteúdo. Depende do item 19.
- `[ ]` **21. Diferenciar construtor de Componente e de Conteúdo; nova aba "Componentes" no editor.** _(item 19)_ Componentes criados pelo usuário aparecem numa aba "Componentes", ao lado de Widgets e Árvore, prontos para uso no construtor de conteúdo. Depende do item 20 e das abas do editor.
- `[ ]` **22. Lista de componentes no padrão da lista de Widgets.** _(item 20)_ Ao salvar um componente, escolher/criar categoria e definir ícone ou imagem, para ele aparecer bonito na lista como os widgets. Depende do item 20 e da infra de categorias (itens 11/14).
