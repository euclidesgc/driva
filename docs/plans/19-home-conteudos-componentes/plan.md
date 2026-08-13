# plan.md — Item 19: Conteúdos e Componentes lado a lado na tela do projeto

> Documento de planejamento. Dono na execução: **tech-lead**. Base: `docs/roadmap.md` › Marco 8.
> Regra do "pronto": **`flutter analyze` verde + `pnpm build` verde + testes existentes passando**.
> **Este plano estabelece a decisão arquitetural que os itens 20, 21 e 22 herdam** (D1). Ler antes deles.

## 1. Objetivo e recorte

O Marco 8 introduz **Componente**: um pedaço de UI montado uma vez e reutilizado em vários conteúdos. Este primeiro item é o menor passo com valor próprio: **o lugar onde componentes vivem passa a existir**, com a lista, o CRUD e a navegação — mesmo antes de existir construtor próprio (item 20) ou uso dentro de conteúdo (item 21).

**Entra:**
1. O discriminador `kind` (`content` | `component`) atravessando kernel, backend e editor.
2. `GET /v1/contents?kind=component` e a criação com `kind`.
3. Na tela do projeto (`/projects/:id`), uma divisão de topo **Conteúdos | Componentes**, com o painel e a árvore de categorias reagindo à aba.

**Fica fora:** construtor específico de componente (item 20), instanciar componente dentro de conteúdo (item 21), ícone/imagem de componente (item 22).

## 2. Decisão arquitetural central (herdada pelos itens 20–22)

**D1 — Componente é um `Content` com `kind = 'component'`, não uma tabela nova.**

Ganhos, todos verificados no código atual:
- **Backend:** `ContentsService` já tem lista com cursor keyset, busca acento-insensível, ordenação, `categoryId`, unicidade de slug por projeto com sugestão em conflito (`freeSlug`), e — depois do item 24 — rascunho, versões, publicação e rollback. Um componente precisa de **exatamente as mesmas coisas**. Uma tabela `Component` significaria duplicar `contents.service.ts` inteiro (326 linhas hoje) e depois manter as duas em sincronia para sempre.
- **Editor:** `contents_module` (models zard, repositório, cubits de lista, painel, cards, mover entre categorias, scroll infinito) e `editor_module` (o construtor) funcionam sem reescrita.
- **Kernel:** `ContentSpec` já carrega `kind` no envelope — hoje travado em `z.$enum(['content'])` (`content_schema.dart:11`). Abrir para dois valores é **uma linha**.

Custo aceito: um `Content` com `kind='component'` não é "conteúdo" no sentido de produto, e toda query de listagem precisa filtrar por `kind` — esquecer o filtro faz componente aparecer na lista de conteúdos. Mitigação: o filtro é **obrigatório** no DTO (sem default implícito no service; o default fica no controller, explícito).

**D2 — `kind` no spec **e** na coluna.**
A coluna `Content.kind` (indexada) é o que a query filtra; `ContentSpec.kind` é o que o kernel valida. Os dois precisam concordar, e o service confere na escrita (`spec.kind !== row.kind` → 400). Redundância deliberada: sem a coluna, filtrar exigiria varrer JSONB; sem o campo no spec, o kernel não saberia validar o que é raiz de componente.

**D3 — Componentes têm categorias, como conteúdos.**
Reusa a árvore que já existe (`Category`), inclusive a "Geral". Não há segunda árvore. Consequência visível: a árvore de categorias é a mesma nas duas abas, e o contador por nó muda conforme a aba selecionada.

## 3. Precedências (levantado em 2026-08-13)

| O que | Onde | Uso |
| --- | --- | --- |
| `_contentEnvelope` zard com `'kind': z.$enum(['content'])` | `sdui_core/lib/src/schema/content_schema.dart:11` | Abre para `['content','component']`. |
| `ContentSpec` sem campo `kind` (é fixo no `toJson`, linha 53) | `sdui_core/lib/src/model/content_spec.dart` | Ganha `final ContentKind kind`. |
| `model Content` + índices `(projectId, updatedAt desc, id)` | `backend/prisma/schema.prisma:62` | Ganha `kind` + índice composto. |
| `ContentsService.list/create/update` + `toSummary` | `backend/src/contents/contents.service.ts` | Ganham `kind`. |
| `ListContentsQueryDto` (cursor, limit, q, sort, order, categoryId) | `backend/src/contents/dto/list-contents.query.dto.ts` | Ganha `kind`. |
| `ProjectDetailPage` (árvore à esquerda + painel à direita) e `ContentListCubit` (`changeSort`, `loadMore`, delete otimista) | `contents_module/presentation/project_detail/`, `.../content_list/cubit/` | A aba entra acima do painel; o cubit ganha `changeKind`. |
| `AppShell` + breadcrumb por slot (item 16c) | `core/widgets/app_shell/` | O breadcrumb pode refletir a aba. |

## 4. Fases

### F1 — Kernel: `ContentKind`  **[∥ com nada; é a base]**

- **Criar `sdui_core/lib/src/model/content_kind.dart`** — `enum ContentKind {content, component}` com `String get wireName` e `static ContentKind? fromWire(String)`.
- **`content_spec.dart`** — `final ContentKind kind;` com default `ContentKind.content` (spec antigo continua parseando), no `copyWith`, `props` e `toJson` (`'kind': kind.wireName` no lugar do literal `'content'`).
- **`content_schema.dart`** — `z.$enum(['content','component'])` e leitura do valor para o `build`.
- **`sdui_core.dart`** — export.

**Aceite:** spec antigo (`kind: 'content'`) parseia igual; spec com `kind: 'component'` parseia; `kind: 'outro'` → `Left` com mensagem clara. Rodar `content_schema_test.dart` existente sem alteração.

### F2 — Backend: coluna, filtro e validação cruzada

- **`schema.prisma`** — `kind String @default("content")` em `Content` + `@@index([projectId, kind, updatedAt(sort: Desc), id])`.
  > O índice do item 10 (`projectId, updatedAt desc, id`) deixa de servir para a query nova, que passa a filtrar por `kind`. **Criar o índice novo; avaliar remover o antigo** (só se nenhuma query restante o usar — conferir).
- **Migração** — `ADD COLUMN kind TEXT NOT NULL DEFAULT 'content'` + índice. Sem backfill (o default resolve). Migração barata e reversível.
- **`dto/list-contents.query.dto.ts`** — `kind?: 'content'|'component'` (`@IsIn`).
- **`dto/create-content.dto.ts`** — `kind?` idem.
- **`contents.service.ts`** — `list()` inclui `where.kind`; `create()` grava `kind` e o injeta no spec inicial; `update()` valida D2 (`dto.spec.kind` ≠ `row.kind` → 400); `toSummary()` devolve `kind`; **todos os quatro `select`** ganham o campo.
- **`contents.controller.ts`** — o controller escolhe o default (`kind = query.kind ?? 'content'`) e repassa; o service **exige** o valor.

**Aceite (E2E de contrato):** criar componente → aparece só em `?kind=component`; a lista sem `kind` devolve só conteúdos; `PUT` com spec de `kind` divergente → 400; slug de componente pode colidir com slug de conteúdo? **Não** — o `@@unique([projectId, slug])` é global. Decidir em §6.

### F3 — Editor: `kind` em data/domain  **[∥ com F4]**

- `contents_module/domain/entities/content_summary.dart` — `+ final ContentKind kind;`
- `.../data/models/content_summary_model.dart` — `'kind': z.string()` com fallback `'content'` se ausente.
- `.../domain/repositories/contents_repository.dart` + `contents_repository_impl.dart` + `..._fake.dart` — `getContents(..., ContentKind kind)`.
- `.../domain/use_cases/get_contents_use_case.dart`, `create_content_use_case.dart` — repassam `kind`.
- `core/dev/fake_contents_store.dart` — guarda o `kind` por conteúdo (`Map<String, ContentKind>`), como já faz com `categoryId`.

### F4 — Editor: a divisão na tela do projeto

- **`.../content_list/cubit/content_list_cubit.dart`** — `void changeKind(ContentKind)`: reseta cursor e recarrega **do servidor** (mesmo caminho de `changeSort`, item 15 — imitar exatamente, inclusive o espelho local).
- **`.../content_list/cubit/content_list_state.dart`** — `kind` no `ContentListLoaded`.
- **`.../project_detail/widgets/kind_tabs.dart`** (novo) — as duas abas, acima do painel. Widget de tier **feature**.
- **`.../project_detail/project_detail_page.dart`** — monta as abas; o texto do estado vazio e o rótulo do botão "Novo" mudam conforme a aba ("Novo conteúdo" / "Novo componente").
- **`.../widgets/content_form_dialog.dart`** — recebe o `kind` e o repassa na criação.
- **`.../category_tree/cubit/category_tree_cubit.dart`** — o contador por nó passa a considerar o `kind` ativo. **Verificar como o contador é obtido hoje** (`_count` do backend, item 10 P3): se vier do servidor, o endpoint de categorias precisa aceitar `kind`; se for derivado no cliente, é filtro local. **Esta é a incógnita da fase** — levantar antes de estimar.

**Aceite:** trocar de aba recarrega a lista; a busca e a ordenação continuam funcionando dentro da aba; criar na aba Componentes cria com `kind=component`; o breadcrumb continua correto.

### F5 — Testes (por último)
`content_list_cubit_test.dart` (+`changeKind` reseta cursor e recarrega), `content_summary_model_test.dart` (fallback de `kind` ausente), widget test das abas, e o E2E de contrato da F2.

## 5. Mapa de paralelismo

```
F1 ──► F2 ──► F3 ──► F4 ──► F5
        └──────┘  (F3 pode começar assim que o contrato da F2 estiver congelado)
```
Pouco paralelismo real: é uma fatia vertical estreita. **Isso é bom** — o item inteiro cabe em 2–3 PRs.

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 24 (publicação) — herança direta e boa:** componente ganha rascunho/versão/publicação **de graça**, porque é um `Content`. Nenhuma mudança no plano 24.
- **Item 25 (entrega ao app) — atenção:** `GET /v1/public/contents/:slug` passa a poder devolver um **componente** se alguém pedir o slug dele. Isso não é erro grave (o spec é válido e renderizável), mas provavelmente não é desejado. **Ação: a rota pública deve filtrar `kind='content'`** — anotar no plano 25 §P1. Componente é peça de montagem, não tela.
- **Item 17 (offline-first)** — o cache local passa a ter duas listas (por `kind`). A chave de cache **precisa** incluir o `kind`, senão a aba Componentes serve a lista cacheada de Conteúdos (bug que parece funcionar). A D1 do plano 17 já reserva o lugar na chave; **se o 17 vier antes, o campo já existe; se vier depois, ele lê esta obrigação aqui.** Anotado nos dois.
- **Itens 20/21/22** — todos assumem D1/D2/D3 daqui.
- **Conflito a decidir (§7):** slug único por projeto é **compartilhado** entre conteúdos e componentes hoje (`@@unique([projectId, slug])`). Se quisermos `home` como conteúdo **e** `home` como componente, a unicidade precisa virar `@@unique([projectId, kind, slug])` — **migração adicional, decidir nesta fase e não depois**.

## 7. Perguntas para o humano

1. **Slug pode repetir entre conteúdo e componente?** Recomendo **sim** (`@@unique([projectId, kind, slug])`) — são espaços de nome diferentes na cabeça do usuário. Mas isso muda a migração e o `freeSlug`. **Decidir antes da F2.**
2. **Componente aparece na busca global junto com conteúdo?** Assumido: não (a busca é por aba).
3. **Abas ou dois itens no menu lateral?** Assumido: abas no topo do painel, mantendo a árvore de categorias compartilhada (D3).
