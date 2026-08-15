# Specs — Loop SDUI fechado (API pública de consumo + app de demonstração)

_Roadmap: item **25** (Entrega ao app cliente), fatia "API pública + app de
exemplo". Plano de gaveta: `docs/plans/25-entrega-app-cliente/plan.md`._

## O problema

O driva se descreve como plataforma de **Server-Driven UI**, mas até aqui só o
lado do **editor** foi provado. O spec nasce no editor, é salvo no Postgres e é
desenhado no mock do canvas — tudo dentro do **mesmo** app Flutter Web. O
renderer (`sdui_flutter`) nunca desenhou um spec **vindo da API** dentro de um
app de cliente. As duas pontas soltas estavam explícitas no código: o botão
`Publish` do editor é um `tooltip`, `DrivaContent` lança `UnimplementedError` e
o `ContentsController` só expõe o CRUD do editor.

## Escopo

**Dentro:**

1. `GET /v1/public/contents/:slug` — leitura para **consumo**, autenticada por
   **chave publicável** do projeto, com `ETag`/`304`.
2. `GET /v1/public/contents` — listagem dos conteúdos do projeto da chave. Sem
   ela o app não teria navegação nem haveria como escolher o que abrir.
3. `Project.publishableKey` — a chave que o app embarca (D1 do plano do item 25).
4. `apps/driva_demo_app` — app Flutter que consome os dois endpoints e renderiza
   com `SduiView`.
5. Relatório do que o consumo real revelou.

**Fora (deliberadamente):**

- **Rascunho × publicado e versionamento → item 24.** Sem ele, o endpoint serve
  o único spec que existe: o que está salvo. Ver `variance_report.md` — é o
  desvio mais importante desta entrega.
- Package `driva_client` com cache em disco e fallback embarcado → item 25 (o
  resto dele). Este app faz o fetch direto; é o embrião, não o SDK.
- Executar as ações do spec → item 28. O app apenas **exibe** que a ação chegou.
- Rotação de chave, rate limit → ficam para o item 25 completo.

## Contrato da API pública

Prefixo `/v1/public`, controller e service próprios — o `ContentsController` é
escopado pelo header `x-project-id` **sem verificação**, e misturar a rota
pública ali seria o caminho curto para vazar rascunho num refactor futuro.

Autenticação: header **`x-driva-key`** com a `publishableKey` do projeto. Ela é
pública por natureza (vai embarcada no binário do app do cliente) e por isso só
lê conteúdo — nunca escreve, nunca lista projetos.

`GET /v1/public/contents`

```json
{ "data": [{ "id": "…", "name": "…", "slug": "…", "updatedAt": "…" }] }
```

Até 100 itens, mais recentes primeiro.

`GET /v1/public/contents/:slug`

```json
{ "id": "…", "name": "…", "slug": "…", "updatedAt": "…", "spec": { … } }
```

- `ETag: "<id>-<updatedAt em ms>"` + `Cache-Control: public, max-age=60,
  must-revalidate`; `If-None-Match` casando → `304` sem corpo.
- **Chave ausente, inválida ou de projeto arquivado → `404`**, nunca `401`: a
  resposta não distingue "chave errada" de "conteúdo inexistente" para quem
  sonda de fora.
- `Access-Control-Allow-Origin: *` apenas neste prefixo — a lista de
  `CORS_ORIGINS` existe para o editor; conteúdo publicado é lido de qualquer
  origem.

## O app de demonstração

Duas telas, sem regra de negócio:

- **Catálogo** (`/`): lista os conteúdos do projeto da chave, com a origem dos
  dados visível no topo (URL da API + prefixo da chave). Sem chave configurada,
  explica como obtê-la em vez de dar erro de rede.
- **Conteúdo** (`/c/:slug`): busca o spec, valida pelo kernel e renderiza.
  Rodapé mostra a procedência (data do spec + ETag). Conteúdo sem `root` mostra
  estado-vazio explicativo em vez de tela branca. Ação disparada por um widget
  vira um aviso na tela, provando que `events` chega ao app como dado.

Configuração por flavor: `API_BASE_URL` e `PUBLISHABLE_KEY`.

## Critérios de aceite

1. `GET` público com chave válida devolve o spec de um conteúdo criado no editor.
2. Sem chave, com chave inválida ou com slug inexistente → `404`.
3. Revalidação com `If-None-Match` → `304`.
4. O app lista os conteúdos e renderiza um que exercite o catálogo (layout,
   texto, ícone, card, divisor, botão com evento e os três controles de forma).
5. Conteúdo sem `root` não vira tela branca.
6. `flutter analyze` verde, `pnpm build` verde e as baterias existentes passando.
