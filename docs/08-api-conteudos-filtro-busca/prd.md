# PRD — API de conteúdos: filtro, busca, ordenação e paginação

> Documento vivo. Dono: PM. Contrato do "pronto" desta feature (item **10** do roadmap). Decisões travadas com o humano em 2026-07-09. Descreve o que a feature **é**; ao divergir na implementação (com aprovação), este PRD é corrigido para refletir a realidade.
> Escopo em uma frase: `GET /v1/contents` passa a **filtrar por categoria, buscar por termo, ordenar e paginar**, com a **fundação de dados de categoria** (tabela + relação) criada já agora, **sem UI**.

## Problema

`GET /v1/contents` devolve **todos** os conteúdos do projeto de uma vez, como **array puro** ordenado por `updatedAt desc`. Não escala com o volume, e o editor não tem como filtrar por categoria (conceito inexistente na stack), buscar, escolher ordenação ou paginar (necessário para a listagem infinita do item 16).

## Objetivo

1. Evoluir o contrato de `GET /v1/contents` para aceitar **filtro por categoria, busca (`q`), ordenação e paginação por cursor**.
2. Criar a **fundação de dados de categoria** (tabela `Category` em árvore + `Content.categoryId` obrigatória + categoria raiz "Geral" semeada) de modo que os itens 11–16 sejam só frontend/CRUD, **sem re-migrar** o schema.
3. Atualizar a camada `data`/`domain` do `contents_module` do editor para consumir o novo contrato — **sem UI nova**.

## Escopo

**Dentro:**
- Novos query params em `GET /v1/contents`: `categoryId`, `q`, `sort`, `order`, `cursor`, `limit`.
- Novo **envelope de resposta**: `{ data: ContentSummary[], nextCursor: string | null }`.
- **Modelo Prisma**: tabela `Category` (auto-relação `parentId`) + `Content.categoryId` (**obrigatória**) + coluna `Content.nameNormalized` + índice composto. Categoria raiz **"Geral"** por seed. Banco recriado do zero (sem backfill de dados legados).
- **Editor** (`contents_module`): `ContentSummary`, `ContentsRepository`, `GetContentsUseCase`, `ContentSummaryModel` (zard), `ContentsRepositoryImpl` adaptados ao envelope + params (backend e editor **na mesma PR**).

**Fora (não-escopo):**
- **UI de categorias** — árvore na home, "Todos", clique-filtra, atribuir conteúdo (itens 11–14). Aqui só a infra de dados/contrato.
- **CRUD de categoria** via API (criar/renomear/mover/excluir) — chega no item 11. Nesta feature `Category` nasce como tabela **+ a categoria raiz "Geral" por seed**; o filtro aceita um `categoryId` que já exista.
- **Herança de descendentes** no filtro por categoria — nesta feature o filtro é por **nó exato**.
- Busca por `slug`/`description`; busca acento-insensível via extensão Postgres.
- Offline-first/cache (item 17), multi-projeto real, serving por slug.

## Contrato REST — `GET /v1/contents`

Tenant continua por header `x-project-id` (default `default`), inalterado.

### Query params (todos opcionais)

| Param | Tipo | Default | Regras |
|---|---|---|---|
| `categoryId` | string | — | **Filtro de leitura.** Filtra por **nó exato** (`where categoryId = X`). Sem herança de subcategorias. Categoria inexistente → lista vazia (não é erro). Valor especial futuro "Todos" = ausência do param. |
| `q` | string | — | Termo de busca sobre `name` (via `nameNormalized`), **case- e acento-insensível**. `q` vazio/só espaços = sem filtro. Trim aplicado. |
| `sort` | enum | `updatedAt` | Um de `updatedAt` \| `createdAt` \| `name`. Valor fora do enum → **400**. |
| `order` | enum | `desc` | `asc` \| `desc`. Fora do enum → **400**. |
| `cursor` | string | — | Cursor keyset opaco da página anterior. Ausente = primeira página. Inválido/malformado → **400**. |
| `limit` | int | `20` | 1–100. Fora da faixa ou não-inteiro → **400 Bad Request** (validação de DTO no Nest). Sem clamp silencioso. |

### Resposta `200`

```json
{
  "data": [
    { "id": "...", "name": "...", "slug": "...", "description": "...", "categoryId": "cat_geral", "updatedAt": "2026-07-09T12:00:00.000Z" }
  ],
  "nextCursor": "opaque-cursor-string-or-null"
}
```

- `data`: array de resumos (mesmos campos de hoje **+ `categoryId`**, sempre presente — todo conteúdo tem categoria). `description` omitido quando nulo (padrão atual do service).
- `nextCursor`: string opaca para buscar a próxima página; **`null`** quando não há mais páginas (última página).
- **Sem** `total`/`count` (decisão travada).

### Paginação (keyset cursor)

- Ordenação real é sempre **`(campo_sort, id)`** — o `id` é o desempate estável.
- `cursor` codifica o par `(valor_do_campo_sort, id)` do último item retornado. O backend continua **após** esse par na mesma ordenação.
- **Trocar `sort`/`order`/`q`/`categoryId` invalida o cursor**: o cliente recomeça do início (`cursor` ausente). O editor trata isso resetando a lista ao mudar qualquer filtro/ordenação.
- `nextCursor` é `null` quando a página devolvida tem menos itens que `limit` (fim da lista).

### Busca (`q`)

- Backend mantém `Content.nameNormalized` = `name` em **lowercase + sem acentos**, normalizado **em Node** na escrita (create/update). Não usa extensão Postgres.
- `q` é normalizado do mesmo jeito e comparado por **`ILIKE '%q%'`** sobre `nameNormalized`.
- Só o campo `name` é pesquisável nesta feature.

### Erros

| Situação | HTTP |
|---|---|
| `sort`/`order`/`limit`/`cursor` inválidos | 400 |
| `categoryId` na escrita referencia categoria inexistente/de outro projeto | 400 |
| Sucesso (mesmo lista vazia) | 200 |

### Escrita — `POST` / `PUT /v1/contents(/:id)`

O CRUD existente e o fluxo de `409` de slug permanecem **inalterados**, com duas adições nesta feature:

- `POST`/`PUT` **gravam `nameNormalized`** (derivado do `name` em Node) a cada escrita de `name`.
- `POST`/`PUT` **aceitam `categoryId`** no corpo, **opcional**:
  - **omitido** → o conteúdo cai na categoria raiz **"Geral"** do projeto (semeada pela migração). O editor continua criando conteúdo **sem tocar em categoria** — o item 14 só pluga o seletor de UI.
  - **presente** → validado (a categoria existe **e** é do mesmo projeto); inválido → **400**.
  - `PUT` com `categoryId` **move** o conteúdo de categoria; omitir `categoryId` no `PUT` **preserva** a categoria atual (não força "Geral").

## Modelo de dados / migração (Prisma)

```prisma
model Category {
  id        String     @id @default(cuid(2))
  projectId String     @default("default") @map("project_id")
  name      String
  slug      String
  parentId  String?    @map("parent_id")
  parent    Category?  @relation("CategoryTree", fields: [parentId], references: [id], onDelete: SetNull)
  children  Category[] @relation("CategoryTree")
  contents  Content[]
  createdAt DateTime   @default(now()) @map("created_at")
  updatedAt DateTime   @updatedAt @map("updated_at")

  @@unique([projectId, slug])
  @@index([projectId, parentId])
  @@map("categories")
}

model Content {
  // ... campos atuais ...
  categoryId     String    @map("category_id")
  category       Category  @relation(fields: [categoryId], references: [id], onDelete: Restrict)
  nameNormalized String    @map("name_normalized")

  @@unique([projectId, slug])
  @@index([projectId])
  @@index([projectId, updatedAt(sort: Desc), id])
  @@map("contents")
}
```

- **`Content.categoryId` é obrigatória (NOT NULL):** todo conteúdo pertence a exatamente uma categoria.
- **`onDelete: Restrict` em `Content → Category`:** **não** é permitido apagar uma `Category` que tenha conteúdos — o usuário move/apaga os conteúdos antes (UX de mover fica para o item 14). Na auto-relação `Category → parent`, apagar um pai **zera `parentId`** dos filhos (`SetNull`) — a subárvore não cascateia exclusão.
- **Banco recriado do zero (sem dados de produção):** nenhum dado é preservado; **sem migração de backfill de dados legados**. O schema é recriado limpo com `categoryId NOT NULL` e `nameNormalized NOT NULL` desde o início; conteúdos nascem já com ambos preenchidos (via seed + criação normal). Dado de dev, se houver, é descartável.
- **Seed obrigatório:** a migração/seed cria uma **categoria raiz default "Geral"** (`parentId = null`) por projeto. É o alvo default de `POST`/`PUT` sem `categoryId`. É o mínimo que garante que todo conteúdo tenha categoria sem UI.
- **Índice do cursor**: `(projectId, updatedAt desc, id)` cobre a ordenação default. Ordenar por `name`/`createdAt` funciona sem índice dedicado no volume atual (aceitável; índice extra fica para quando doer).

## Adendo pós-feature-09 (Project virou entidade real)

> **Contexto.** Este PRD foi escrito **antes** da feature 09 (docs/09, `feature/crud-projeto`) existir. A 09 criou a entidade `Project` real: `Content.projectId` agora é **FK NOT NULL → Project** (`onDelete: Restrict`), com **seed do projeto `default`** e banco recriado do zero. O adendo abaixo ajusta o modelo de `Category` a esse novo topo de hierarquia. **Os exemplos e o contrato REST acima permanecem válidos** — nada no `GET /v1/contents`/escrita muda; apenas a modelagem de `Category` ganha o vínculo com `Project` e a criação da "Geral" passa a ser por projeto.

1. **`Category.projectId` é FK NOT NULL → `Project`** (não mais `String @default("default")`). Uma categoria **vive dentro de um projeto**, espelhando `Content.projectId`. Relação `Category → Project` com **`onDelete: Restrict`** — coerente com `Content → Project` (09) e `Content → Category` (esta feature): não se apaga um `Project` que ainda tem categorias; o usuário esvazia/move antes (UX no fluxo do protótipo). O `x-project-id` (default `default`) continua sendo o tenant/escopo, agora resolvendo para um `Project` real semeado pela 09.

2. **A categoria seed "Geral" nasce por projeto** (não uma única global). Como `Content.categoryId` é NOT NULL e o default de escrita é a "Geral", **todo projeto precisa ter a sua "Geral"** antes de qualquer `POST` de conteúdo. Cobertura mínima: a migração desta feature semeia a "Geral" no projeto `default` já criado pela 09.

3. **Criação da "Geral" em projeto novo → no service de create do projeto, na mesma transação** (recomendação adotada — o mais simples). Quando a 09/o fluxo criar um `Project` novo, o `ProjectsService.create` insere a categoria "Geral" (`parentId = null`) **na mesma `$transaction`** do insert do projeto. Descartadas: **trigger de banco** (lógica escondida no schema, difícil de testar/versionar, fora do padrão Nest+Prisma do repo) e **seed só na migração** (só cobre projetos que existem na hora da migração, não os criados em runtime). Consequência operacional: a implementação da "Geral-por-projeto" **encosta no `projects.service.ts` da 09** — registrado como dependência de código entre as features (a P1 empilha sobre `feature/crud-projeto`; ver `plan.md`).

4. **Índice `(projectId, parentId)`** da `Category` continua válido; nada muda nos exemplos de resposta/contrato de `GET /v1/contents` — `categoryId` segue apontando para uma categoria que agora, por transitividade, pertence a um projeto.

## Decisões travadas (humano, 2026-07-09)

1. **Escopo:** modelo de categoria entra **já** no item 10 (tabela + `categoryId` + param de filtro + escrita), **sem UI**.
2. **Modelo:** **1:N com árvore** — `Category.parentId` (auto-relação nullable). **`Content.categoryId` é obrigatória (NOT NULL)**; `onDelete: Restrict` (não se apaga categoria com conteúdos). Filtro de leitura por **nó exato**.
3. **Categoria default "Geral":** a migração faz **seed** de uma categoria raiz "Geral" por projeto. `POST`/`PUT` **sem** `categoryId` caem na "Geral"; **com** `categoryId` válido (existe e é do projeto), respeitam. O editor cria conteúdo sem tocar em categoria; o item 14 pluga o seletor.
4. **Banco do zero:** nenhum dado é de produção — **não** há backup nem migração de backfill de dados legados. O schema é recriado limpo; `categoryId`/`nameNormalized` nascem preenchidos. Dado de dev é descartável.
5. **Paginação:** **keyset cursor** `(campo, id)`, envelope `{ data, nextCursor }`, **sem total/count**; trocar ordenação/filtro reinicia a lista.
6. **Busca:** coluna `nameNormalized` (lowercase + sem acento, normalizada em Node) + `ILIKE`; **sem extensão Postgres**; só `name`.
7. **Ordenação:** `updatedAt` (default `desc`), `createdAt`, `name`; índice `(projectId, updatedAt desc, id)`.
8. **`limit`** default `20`, faixa 1–100; fora da faixa ou não-inteiro → **400** (validação de DTO no Nest), sem clamp silencioso.

## Critérios de aceite

**Backend**
- [ ] `GET /v1/contents` sem params devolve `{ data, nextCursor }` com os conteúdos do projeto, `sort=updatedAt`, `order=desc`, `limit=20`; `nextCursor` correto (null na última página).
- [ ] `categoryId` filtra por nó exato; categoria inexistente → `{ data: [], nextCursor: null }`, status 200.
- [ ] `q` encontra por `name` case- e acento-insensível (ex.: `q=cabecalho` acha "Cabeçalho"); `q` vazio = sem filtro.
- [ ] `sort` aceita `updatedAt|createdAt|name`, `order` `asc|desc`; inválido → 400.
- [ ] Paginação por cursor é estável sob inserção concorrente; percorrer todas as páginas retorna cada item **uma vez**, sem buracos nem repetição.
- [ ] `POST` **sem** `categoryId` associa o conteúdo à categoria "Geral"; **com** `categoryId` inexistente/de outro projeto → 400; com válido, respeita.
- [ ] `PUT` com `categoryId` move o conteúdo de categoria; `PUT` sem `categoryId` preserva a categoria atual.
- [ ] `POST`/`PUT` gravam `nameNormalized` coerente com o `name`.
- [ ] Migração + seed criam a categoria raiz "Geral"; tentar apagar uma categoria com conteúdos é **rejeitado** (`Restrict`); apagar categoria-pai zera `parentId` dos filhos.
- [ ] `flutter analyze`/build backend verdes; migração recria o schema limpo do zero e aplica em hml (não há dado a preservar).

**Editor (data/domain)**
- [ ] `ContentsRepository.getContents` aceita filtros/ordenação/cursor e devolve a página + próximo cursor tipados.
- [ ] `ContentSummaryModel` (zard) valida o **envelope** e o novo campo `categoryId` (obrigatório); payload inválido → `ValidationFailure` descritiva.
- [ ] `GetContentsUseCase` **não** reordena mais no cliente (a ordenação é do servidor).
- [ ] A home continua carregando a lista (nenhuma regressão visível) — a fatia vertical não quebra o parse.
- [ ] `flutter analyze` verde.

**E2E (por script, rodadas)**
- [ ] `e2e.sh` cobre por API: lista paginada, filtro por `categoryId`, busca acento-insensível, ordenações, 400s, e o percurso completo de cursor sem repetição.

## Analytics (a instrumentar)
- Uso de filtro por categoria, busca (com/sem resultado), troca de ordenação, profundidade de paginação (quantas páginas o usuário puxa). *Sinais que orientam os itens 13–16; detalhamento no `ANALYTICS.md` no fechamento.*

## Erros monitorados
- Payload de listagem que falha o parse zard no editor (envelope inesperado) → `ValidationFailure` logada.
- `POST`/`PUT` com `categoryId` inválido (400) — sinaliza dessincronia entre categorias conhecidas pelo cliente e o backend.
- Cursor inválido em volume (indício de bug de codificação/decodificação).

## Riscos

- **[CRÍTICO] Contrato quebrado (fatia vertical):** o envelope `{ data, nextCursor }` quebra o parse atual do editor (array puro) **em runtime**. Backend + editor **na MESMA PR**; **nunca** mergear backend sozinho — auto-deploy em hml derrubaria a home. Registrar como restrição dura no `plan.md` (não fatiar por camada).
- **Seed da "Geral" é pré-condição dura:** como `categoryId` é `NOT NULL` e o default de escrita é a "Geral", a categoria raiz **precisa existir antes** de qualquer `POST` de conteúdo. A migração/seed deve garanti-la por projeto; ambiente sem "Geral" quebra a criação de conteúdo. Cobrir no E2E.
- **`categoryId` de outro projeto:** a validação de escrita precisa checar **projeto + existência** (não só existência) para não vazar categoria entre tenants.
- **Ordenar por `name`/`createdAt` sem índice dedicado:** aceitável no volume atual; monitorar; índice extra fica para quando necessário.
- **`onDelete: Restrict`:** garantir que a tentativa de apagar categoria com conteúdos falha de forma tratada (não 500 cru) — traduzir para erro previsto. Cobrir no teste. *(A UX de mover conteúdos antes de apagar chega no item 14.)*
