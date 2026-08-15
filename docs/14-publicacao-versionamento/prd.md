# PRD — Publicação e versionamento do conteúdo

_Item **24** do `docs/roadmap.md` (Marco 5). Plano de execução:
`docs/plans/24-publicacao-versionamento/plan.md` (fases P1–P5, decisões técnicas
D1–D7). Comportamento de produto: `specs.md` ao lado._

> **O PRD aprovado é o contrato do "pronto".** As decisões técnicas D1–D7 do
> plano são premissas deste documento, não estão em discussão aqui.

## Problema

Salvar é publicar. O `Content` tem **um** campo de spec, e desde 2026-08-15 esse
campo é servido a um app de verdade pelo endpoint público que a fatia 1 do item
25 subiu. Consequências, hoje, em homologação:

- Um rascunho quebrado vai ao ar no próximo refresh do app.
- Não existe "voltar para a versão de ontem".
- Não existe "tirar do ar".
- O `ETag` da API pública é `(id, updatedAt)` — muda a cada save, então o cache
  do cliente é invalidado por edição de rascunho que ninguém pediu para ver.

Isso está registrado como `VR-13-01` com a recomendação explícita de **não abrir
para nenhum cliente real antes deste item**. O item 24 é precedência dura da
fatia 2 do item 25 (`driva_client`).

## Objetivo

Um conteúdo passa a ter ciclo de vida: **rascunho**, **versões publicadas
imutáveis**, **rollback** e **fora do ar** — visível no editor, honesto na API
pública, e sem perder nada pelo caminho.

Sucesso é medido assim: **editar no editor deixa de mexer no app do cliente**,
e um erro publicado é revertido em dois cliques sem sair do editor.

## Escopo

### Dentro

| # | Entrega | Fase |
| --- | --- | --- |
| 1 | `Content.spec` → `draftSpec`; tabela `content_versions`; `publishedVersionId`/`publishedAt` | P1 |
| 2 | `POST /contents/:id/publish` (com nota opcional, ≤200) e `POST /contents/:id/unpublish` | P1 |
| 3 | `GET /contents/:id/versions` (paginado, sem specs) e `GET /contents/:id/versions/:version` | P1 |
| 4 | `POST /contents/:id/versions/:version/restore` | P1 |
| 5 | `GET /contents/:id` e `toSummary` carregam o estado de publicação, **incluindo `latestVersion`** | P1 |
| 6 | `/v1/public` inteiro vira vitrine do publicado: detalhe serve a versão publicada (`404` sem ela, `ETag` `(contentId, version)`), listagem filtra por publicado, `updatedAt` vira `publishedAt` e a ordenação segue esse campo | P1 |
| 7 | Entidades, use cases, models zard e repositório no editor (+ fake) | P2 |
| 8 | **`AppShellSlot` passa a aceitar dois chips de status** (código compartilhado — ver o recorte abaixo) | P3 |
| 9 | Botão Publicar real, gate de diagnósticos, chip de publicação no topo, "Tirar do ar" no menu | P3 |
| 10 | Diálogo de histórico de versões com restaurar; selo de estado na lista de conteúdos | P4 |
| 11 | Copies do app demo (catálogo vazio e conteúdo não encontrado) | P4 |
| 12 | Bateria automatizada + E2E de contrato e de UI | P5 |
| 13 | Publicar à mão os conteúdos de homologação, após o deploy | P5 |

### Fora

- Agendamento de publicação e janelas de deploy.
- Aprovação por papéis / workflow — depende do item 26 (usuário) e do 37.
- Diff visual entre versões.
- Publicação em lote ("release" do projeto).
- Autor da publicação preenchido: `createdBy` nasce `null` e só ganha valor no
  item 26. Nasce agora para evitar uma segunda migração destrutiva depois.
- Poda/retenção de versões — decisão do humano: guardar todas, para sempre.
- Rotação/revogação da chave publicável (`VR-13-03`) e rate limit na rota
  pública (`VR-13-04`) — seguem no item 26/37.
- **Descobrir a chave publicável pela UI do editor** — ver decisão registrada
  **P4**. Vira item próprio no roadmap.
- **Paginação da listagem pública** (hoje `take: 100` sem cursor) — ver **P5**.
- Expansão de componentes na publicação — obrigação do item 21. O
  `PublishContentUseCase` nasce como **transformador** do documento (não como
  passa-fica) para receber isso sem reescrita.

## Modelo conceitual

**Rascunho** é o que o editor abre e salva. Existe sempre, é mutável, é privado.

**Versão** é um retrato imutável do rascunho no instante da publicação:
numerada sequencialmente por conteúdo (1, 2, 3…), datada, com nota opcional.
Nunca é editada nem apagada — nem por despublicar, nem por restaurar.

**Publicado** é um ponteiro do conteúdo para **uma** de suas versões. Publicar
move o ponteiro para uma versão nova; despublicar zera o ponteiro; restaurar
**não toca no ponteiro** — mexe no rascunho.

Os quatro estados derivados (nunca publicado / no ar / alterações não publicadas
/ fora do ar) e o que o usuário vê em cada um estão em `specs.md`.

## Contrato REST

### Editor — `/v1/contents` (escopado por `x-project-id`, como todo o resto)

`GET /v1/contents/:id` — a chave `spec` **continua existindo** e passa a ser o
rascunho (D6). Campos novos entram **ao lado**:

```json
{
  "id": "…", "name": "…", "slug": "…", "spec": { … },
  "publishedVersion": { "version": 3, "publishedAt": "2026-08-14T…" },
  "latestVersion": 3,
  "hasUnpublishedChanges": true
}
```

`publishedVersion` é `null` quando não há publicação. **`latestVersion`** é a
maior versão já criada, ou `null` se nunca houve publicação — é o campo que
separa **"nunca publicado"** (`latestVersion == null`) de **"fora do ar"**
(`latestVersion != null && publishedVersion == null`). Sem ele o botão
Despublicar entrega a ação sem entregar o feedback dela.

`POST /v1/contents/:id/publish` — body `{ "note"?: string ≤200 }`. O spec
publicado é **sempre o rascunho corrente do servidor**, nunca vem do cliente —
isso impede publicar algo que não passou pelo save. Idempotente: sem alterações
desde a última publicação, devolve `200` com a versão atual **sem criar
registro** (D3).

`POST /v1/contents/:id/unpublish` — `200`. Zera o ponteiro. **Não apaga
versões.**

`GET /v1/contents/:id/versions?cursor&limit` — keyset por `version desc`,
reusando `encodeCursor`/`decodeCursor`. **Sem o campo `spec`** — a lista carrega
metadados, não JSON.

`GET /v1/contents/:id/versions/:version` — o spec daquela versão.

`POST /v1/contents/:id/versions/:version/restore` — copia o spec da versão para
o rascunho e devolve o conteúdo no mesmo shape do `GET :id`. **O que está no ar
não muda** (D4).

`GET /v1/contents` — `toSummary` ganha `publishedAt`, `hasUnpublishedChanges` e
**`latestVersion`**, para a lista mostrar os **quatro** estados **sem request
extra**.

### App cliente — `/v1/public`

**Todo o prefixo vira a vitrine da versão publicada** (decisão 6), não só a rota
de detalhe:

`GET /v1/public/contents/:slug` — passa a servir `publishedVersion.spec`.
Conteúdo sem publicação → **`404`**, o mesmo `404` genérico de chave inválida e
slug inexistente. `ETag` passa a `(contentId, version)`.

`GET /v1/public/contents` — passa a **filtrar `publishedVersionId != null`**.
Conteúdo nunca publicado nunca aparece; conteúdo despublicado **some da lista**.
Ordenação passa de `updatedAt desc` para **`publishedAt desc`**.

`updatedAt` (nos dois corpos públicos) — **mesmo nome, novo significado**: passa
a carregar o `publishedAt`. Não pode sumir: o `PublishedContentModel` do app
demo valida o envelope com zard, e mexer na **forma** quebra o parse em runtime.
Mudar o **significado** é seguro e é o que torna o campo honesto — antes ele
vazava a hora da última edição de rascunho.

A chave **`spec` continua obrigatória** nos dois contratos, pelo mesmo motivo.

> **Este é o contrato que o item 25 herda.** A fatia 2 (`driva_client`: cache em
> disco, *stale-while-revalidate*, fallback embarcado) será construída em cima
> destas semânticas — `ETag` imutável e `updatedAt` como data de publicação são
> exatamente o que tornam o cache viável. **A partir daqui, mexer neste contrato
> custa versionar a API**, porque haverá apps publicados na loja consumindo-o e
> app na loja não se atualiza sob demanda.

> **Ponto técnico em aberto, a confirmar com o tech-lead no P1 — não bloqueia
> este PRD.** O `VR-13-01` descreve a mudança como "ler
> `content.publishedVersion.spec`", mas isso **não é implementável sob a D1 como
> escrita**: a própria D1 define `publishedVersionId` como FK **solta, sem
> `@relation`**, e sem relação não há navegação no Prisma (`include` não é
> opção). Restam dois caminhos — **duas queries** com join explícito no service
> (o que a D1 previa em texto), ou **dar `@relation` à D1** e reexaminar a
> justificativa do ciclo de dependência. A escolha é do tech-lead; o que este
> PRD exige é só que o resultado observável seja o descrito acima.

### Erros

| Situação | Código |
| --- | --- |
| Conteúdo inexistente ou de outro projeto | `404` (nunca `403` — não revela existência) |
| Versão inexistente | `404` |
| `note` acima de 200 caracteres ou campo não declarado no body | `400` (`ValidationPipe` global) |
| `specVersion` do rascunho fora do suportado | `400`, a mesma checagem que o `update()` já faz |
| Corrida de publicação (dois publish simultâneos) | `409` — o `@@unique([contentId, version])` transforma corrida em P2002 traduzido |
| Conteúdo público sem versão publicada | `404` |

## Caminho feliz

1. Usuário edita um conteúdo já no ar (v3). Topo: "Alterações não publicadas".
2. Clica em **Publicar** → confirmação mostra "Publicar como v4", campo de nota
   opcional e a contagem de avisos.
3. Confirma. O editor salva o rascunho pendente e publica.
4. Topo: "No ar (v4)". Selo na lista: "No ar".
5. O app cliente, no próximo fetch, recebe o spec da v4 com `ETag` novo.

## Exceções e casos de borda

| Caso | Comportamento |
| --- | --- |
| Documento com diagnóstico de **erro** | Publicar desabilitado, com tooltip dizendo o motivo. Avisos não bloqueiam. |
| Rascunho sujo ao publicar | Salva primeiro, depois publica. Se o save falhar, **não** publica. |
| Publicar sem alteração desde a última publicação | Botão desabilitado ("Tudo publicado (v3)"); a API, se chamada, devolve a v3 sem criar versão. |
| Falha de rede no publish | `publishFailed` visível; o estado de publicação exibido **não muda**. |
| Duplo clique / corrida de publicação | `409` traduzido em mensagem de recarregar. Nenhuma versão duplicada é criada. |
| Restaurar a versão que já está no ar | Permitido. O rascunho passa a ser idêntico ao publicado, mas o estado vira "Alterações não publicadas" — `hasUnpublishedChanges` é derivado de timestamp, não de diff de JSON (D7). Publicar depois **cria uma versão nova** idêntica à anterior. Aceito: comparar dois JSONB a cada `GET` custa mais do que vale. |
| Restaurar com rascunho sujo | Confirmação explícita; o rascunho atual é substituído. Desfazível com `Ctrl+Z` (item 23). |
| Despublicar | Nada é apagado. Estado vira "Fora do ar" (`latestVersion` intacto); o app passa a receber `404` **e o conteúdo some do catálogo público**. Não é instantâneo: até 60s de cache — a confirmação avisa. |
| Publicar de novo depois de despublicar | Cria versão nova se o rascunho mudou; senão republica a última. O conteúdo **volta ao catálogo público**. |
| Conteúdo sem `root` (página vazia) | **Publicar é permitido.** Página vazia não é diagnóstico de erro, e o app cliente já mostra estado-vazio explicativo em vez de tela branca (entregue na fatia 1). O diálogo de publicação avisa: "Este conteúdo está vazio." |
| Renomear o **slug** de um conteúdo no ar | Quebra silenciosamente os apps que o consomem pelo slug antigo. Ver _Registrada, mas não perguntada_, ao fim deste documento. |
| Excluir o conteúdo | Versões vão junto (`onDelete: Cascade`) — não pode travar a exclusão de projeto do item 9e. |
| Lista de conteúdos vinda de cache antigo (item 17) | Os campos novos precisam de **default tolerante** no zard, senão a home inteira some no primeiro deploy. |

## Critérios de aceite por fase

### P1 — Backend (gate CISO)

- [ ] Criar conteúdo → `GET :id` devolve `publishedVersion: null`,
      `hasUnpublishedChanges: true`.
- [ ] `PUT` com spec → `publish` → `publishedVersion.version == 1`; `GET :id` →
      `hasUnpublishedChanges: false`.
- [ ] Publicar de novo sem mudar nada → **mesma** versão 1; `GET :id/versions`
      continua com 1 item.
- [ ] `PUT` novo spec → publish → versão 2; `GET :id/versions` devolve 2 itens,
      mais nova primeiro, **sem** o campo `spec`.
- [ ] `restore` da versão 1 → `GET :id` traz o spec da 1 como rascunho e
      `publishedVersion.version` continua **2**.
- [ ] `unpublish` → `publishedVersion: null`; `GET :id/versions` continua com 2.
- [ ] Cross-tenant: qualquer rota nova com `x-project-id` de outro projeto →
      **404**.
- [ ] `DELETE` do conteúdo apaga as versões; o E2E do item 9e (exclusão de
      projeto) volta a passar.
- [ ] Renomear nome/slug **não** liga `hasUnpublishedChanges`.

**Os três estados de `latestVersion` (decisão 8):**

- [ ] Conteúdo recém-criado → `latestVersion: null` e `publishedVersion: null`
      ("nunca publicado").
- [ ] Depois de publicar → `latestVersion == publishedVersion.version`
      ("no ar").
- [ ] Depois de `unpublish` → `latestVersion` **continua 2** e
      `publishedVersion: null` ("fora do ar"). É o caso que prova que
      despublicar não apagou o histórico.
- [ ] `latestVersion` aparece também no `GET /v1/contents` (lista), com os
      mesmos três estados — sem request extra.

**A vitrine pública (decisão 6):**

- [ ] `/v1/public/contents/:slug` de conteúdo nunca publicado → `404`; de
      publicado → o spec da versão; `ETag` estável entre dois GETs com o
      rascunho editado no meio.
- [ ] `/v1/public/contents/:slug` de conteúdo **despublicado** → `404`.
- [ ] **Listagem pública: conteúdo nunca publicado nunca aparece.** Criar dois
      conteúdos, publicar um → a lista devolve **um**.
- [ ] **Listagem pública: conteúdo despublicado some da lista.** Publicar dois,
      despublicar um → a lista devolve **um**; republicar → volta a devolver
      dois.
- [ ] `updatedAt` do corpo público é o `publishedAt`: editar o rascunho de um
      conteúdo publicado **não** altera o `updatedAt` que o app recebe (nem na
      lista, nem no detalhe).
- [ ] A listagem pública vem ordenada por `publishedAt desc` — publicar um
      conteúdo antigo o traz para o topo da lista.
- [ ] Migração aplicada em hml com `migrate status` limpo e **contagem de specs
      idêntica antes e depois** (o rename é `RENAME COLUMN`, nunca drop).
- [ ] `pnpm build` + `pnpm lint` verdes.

### P2 — Editor: domain + data

- [ ] `flutter analyze` verde; nenhum widget mudou.
- [ ] O modo `useFakeData` publica, despublica, lista versões e restaura em
      memória — sem isso a maioria dos widget tests quebra.
- [ ] `save_draft_use_case_test.dart` continua passando.

### P3 — Editor: publicar de verdade

- [ ] Com um `expanded` fora de flex, Publicar fica **desabilitado** e o tooltip
      diz o motivo.
- [ ] Publicar com rascunho sujo salva antes; o topo passa a "No ar (v1)".
- [ ] Falha de rede no publish deixa o erro visível e **não** altera o estado de
      publicação exibido.
- [ ] "Tirar do ar" está no menu de excesso do topo, com confirmação que explica
      que nada é apagado, e só aparece quando há publicação.
      > **Escopo que o plano não previu:** hoje **não existe menu nenhum** no
      > topo — não há `PopupMenuButton`/`MenuAnchor` em `core/widgets/` nem no
      > `editor_module`. A decisão 2 do humano ("escondido no menu do topo")
      > implica **criar** o menu de excesso, com `AppBarAction` ganhando o tipo
      > correspondente. É trabalho novo no `core/widgets/app_shell/`, não uma
      > entrada a mais numa lista existente.
**O slot de dois chips (decisão 7) — o único ponto deste item que toca código
de outras telas:**

- [ ] `AppShellSlot` aceita **dois chips**; salvamento e publicação aparecem
      juntos, e nenhum some. "Não salvo" + "No ar (v3)" convivem.
- [ ] O chip de publicação distingue os **quatro** estados com **ícone +
      texto**, nunca só cor.
      > `AppBarStatusTone` tem hoje `success`, `neutral` e `danger`. "Alterações
      > não publicadas" não é nenhum dos três com honestidade — precisa de um
      > tom de **atenção**. Os tokens `warning` já existem em `EditorColors`
      > (light e dark), entregues na barra de problemas do item 8e.
- [ ] **Nenhuma tela que consome o slot hoje regride.** O P3 lista
      explicitamente as telas que usam `AppShellSlot` e confirma cada uma —
      um chip só continua renderizando como antes.
- [ ] **O shell continua sem ler cubit**: a página publica os chips como
      **dados**, no padrão do item 16c. Se o shell precisar saber o que é
      publicação, o recorte está errado.

### P4 — Histórico e selo

- [ ] Abrir o histórico **não pisca o canvas** (cubit escopado ao diálogo).
- [ ] A lista pagina, mostra número/data/nota e marca qual versão está no ar.
- [ ] Restaurar fecha o diálogo, o canvas mostra a versão restaurada como
      rascunho sujo, e `Ctrl+Z` volta ao rascunho anterior.
- [ ] A lista de conteúdos mostra o selo certo **sem request extra**, nos
      **quatro** estados — incluindo "Fora do ar", que só é possível por causa
      do `latestVersion`.
- [ ] A confirmação de despublicar cita a **contagem de versões** guardadas
      ("as 3 versões continuam guardadas"), e não um genérico.
- [ ] O catálogo vazio do app demo fala em **publicar**, não em criar; o erro de
      conteúdo não encontrado não sugere mais que o conteúdo existe.
- [ ] Payload sem os campos novos (cache antigo) não quebra a lista.
      > **Restrições de layout levantadas no código.** O card da grade tem
      > **altura fixa** (`mainAxisExtent: 182`): o selo cabe **na mesma linha**
      > da data (o `Spacer` absorve, virando `spaceBetween`), mas **não** cabe
      > uma linha nova empilhada sem mexer na grade. Logo: badge compacto, não
      > bloco próprio. E o modo **row** não mostra categoria nem id — o selo tem
      > **dois encaixes diferentes**, um por modo. O `SlugBadge` existente serve
      > de molde visual, mas está **hardcoded na cor `primary`**: o selo de
      > estado precisa de tom variável, então é **widget novo tokenizado**
      > (Gate 4), não reuso direto.

### P5 — Testes

- [ ] `docs/14-publicacao-versionamento/e2e_hml.sh` — contrato contra o hml real,
      auto-limpante, cobrindo os casos do P1.
- [ ] **Conteúdos de homologação publicados à mão** depois do deploy, e as
      evidências do PR #118 voltando a reproduzir. Sem isso o item não fecha —
      é a contrapartida combinada da D2 sem backfill.
- [ ] E2E de UI: publicar, ver o selo mudar, abrir histórico, restaurar,
      despublicar.
- [ ] `editor_cubit_test.dart`, `content_version_model_test.dart`,
      `publication_state_model_test.dart`, widget test do diálogo de publicação
      e do selo no card.
- [ ] `packages/sdui_core` **não muda** neste item — registrado de propósito, é
      sinal de bom recorte.

## Analytics (a instrumentar)

- `content_published` — conteúdo, versão criada, se tinha nota, contagem de
  avisos ignorados, se houve save antes.
- `content_publish_blocked` — quantidade e códigos dos diagnósticos de erro que
  bloquearam. Mede se o gate ajuda ou atrapalha.
- `content_unpublished` — conteúdo e última versão que estava no ar.
- `content_version_restored` — versão restaurada e a distância dela para a
  publicada (quantas versões para trás).
- `version_history_opened` — e se o usuário restaurou depois de abrir.

_Detalhamento no `ANALYTICS.md` no fechamento._

## Erros monitorados

- Falha ao publicar por rede/timeout — separar de falha por validação.
- `409` de publicação concorrente — se aparecer sem usuários simultâneos, é bug
  de duplo submit.
- `400` de `specVersion` incompatível no publish — indica editor desatualizado
  contra backend novo.
- Parse zard falhando em `ContentVersionModel`/`PublicationStateModel` →
  `ValidationFailure` logada (contrato divergindo entre backend e editor).
- `404` na rota pública **com chave válida** — o sinal de "app pedindo conteúdo
  que ninguém publicou". Deve subir logo após o deploy (D2) e cair conforme o
  time publica; se não cair, alguém esqueceu de publicar.
- Falha na migração / `migrate status` sujo no start.

## Riscos

- **[DADO] O rename `spec` → `draft_spec` é destrutivo se errado.** Mitigação:
  `RENAME COLUMN` (nunca drop/create), `prisma migrate diff` contra o hml antes,
  e conferência de contagem de specs antes/depois.
- **[PRODUTO] Sem backfill, tudo em hml vira "nunca publicado" e o app demo
  para de mostrar conteúdo até alguém publicar.** Aceito conscientemente pelo
  humano. O custo real é maior do que o plano assumia: **as evidências de E2E do
  PR #118 deixam de reproduzir**. Mitigação obrigatória, não opcional —
  **publicar à mão em homologação é passo explícito do plano e do PR**, e a
  `Unreleased` do CHANGELOG diz que conteúdo existente nasce despublicado.
- **[SEGURANÇA — o mais grave deste item] Sem auth, "qualquer um publica".**
  O `x-project-id` é escolhido pelo cliente e o `PUT /v1/contents/:id` não tem
  barreira nenhuma. Até aqui isso significava "qualquer um edita um rascunho".
  Depois deste item significa **qualquer um coloca conteúdo no ar dentro do app
  de um cliente** — o risco muda de categoria, não de tamanho. A D5 tratava isso
  como risco residual do item 26; **deixou de ser teórico** e sobe para aviso
  visível. Gate CISO obrigatório no P1.
- **[SEGURANÇA] O backend não valida o spec** (regra do projeto: quem valida é o
  kernel Dart). O gate de diagnósticos vive no **editor**, então um cliente HTTP
  fora dele pode publicar spec inválido. Mitigação em duas frentes futuras: item
  26 (credencial) e item 25/fatia 2 (o runtime do app não pode quebrar a tela do
  cliente com spec ruim).
- **[COMPATIBILIDADE] `toSummary` muda e afeta a lista de conteúdos.** Campos
  **adicionados** não quebram o zard do `ContentSummaryModel` (ele só devolve as
  chaves declaradas), então P1 pode ir sozinha. Ainda assim P1 e P2 devem
  mergear na mesma janela.
- **[COMPATIBILIDADE] Item 17 (offline-first).** Se ele já estiver entregue,
  existirão listas cacheadas em disco sem os campos novos; um `z.boolean()` sem
  default derruba a home inteira no primeiro deploy. Default tolerante é
  requisito, não preciosismo.
- **[RAIO DE IMPACTO] O slot de dois chips sai do editor e entra em código de
  todas as telas.** `core/widgets/app_shell/` é consumido por telas que nada têm
  a ver com publicação, e este é o **único** ponto do item 24 assim. Um erro ali
  não quebra a feature — quebra o topo de todo o app. Mitigação: o P3 enumera as
  telas que consomem o slot e confirma cada uma; o shell segue recebendo os
  chips como **dados** (item 16c), nunca lendo cubit; e **CISO/QA revisam além
  do `editor_module`**. É o candidato natural a virar tarefa própria dentro do
  P3 — ver a nota de recorte abaixo.
- **[SCHEMA] `onDelete: Cascade` nas versões é desvio consciente do padrão
  `Restrict` do resto do schema.** Justificativa: versão não é entidade de
  negócio independente, e sem cascade a exclusão de projeto do item 9e volta a
  travar. Precisa de aprovação explícita no gate.

## Decisões travadas

### Do humano, nesta sessão (2026-08-15)

1. **Retenção: todas as versões, para sempre.** Sem poda. Podar depois é
   migração — e migração que apaga histórico é decisão própria.
2. **Despublicar entra nesta fatia, com API e botão**, o botão escondido no menu
   de excesso do topo (não no botão principal), com confirmação.
3. **A nota da publicação é opcional**, máximo 200 caracteres.
4. **O `VR-13-01` fecha dentro deste item.** `PublicService.findBySlug` passa a
   ler `content.publishedVersion.spec` e a devolver `404` quando não houver
   publicação; o `ETag` passa de `(id, updatedAt)` para `(contentId, version)`,
   que é imutável. O contrato visto pelo app não muda.
5. **Sem backfill na migração (D2 mantido).** Todo conteúdo existente vira
   "nunca publicado" e o app demo em homologação recebe `404` até alguém clicar
   em Publicar.

_As três seguintes fecharam as ambiguidades levantadas neste discovery — o
raciocínio completo está ao fim do documento:_

6. **Todo o `/v1/public` vira a vitrine da versão publicada.** A listagem filtra
   por publicado, o `updatedAt` do corpo público passa a carregar o
   `publishedAt`, e a ordenação segue esse campo. **É o contrato que o item 25
   herda** — daqui em diante, mexer nele custa versionar a API.
7. **Dois chips de status no topo do editor.** Salvamento e publicação convivem
   em `AppShellSlot`, cada um no seu chip. Toca `core/widgets/app_shell/`,
   código compartilhado por todas as telas — o P3 confirma que nenhuma regride,
   e o shell continua sem ler cubit.
8. **`latestVersion: int | null`** entra no `GET /v1/contents/:id` e no
   `toSummary`, separando "nunca publicado" de "fora do ar". Reflete-se na copy
   do topo, no selo da lista e na confirmação de despublicar.

### Registradas por mim (PM), abertas a veto do humano

Decisões pequenas o bastante para não gastarem uma pergunta, mas grandes o
bastante para não ficarem implícitas:

- **P1. Despublicar leva até 60 segundos, e a UI diz isso.** O `max-age=60` da
  rota pública fica como está; a confirmação avisa que apps já carregados podem
  continuar exibindo por até um minuto. Baixar o cache encarece toda leitura de
  todo app para acelerar uma ação rara. Se despublicar virar remoção de
  emergência, o caminho certo é invalidação explícita — registrado como
  evolução, fora deste item.
- **P2. As copies do app demo entram no escopo.** O catálogo vazio passa de
  "Crie um conteúdo…" para **"Publique um conteúdo…"**, e o erro de conteúdo não
  encontrado para de sugerir que o conteúdo existe. São duas strings, e sem elas
  o app passa a mentir.
- **P3. Publicar página vazia (`root` nulo) é permitido.** Não é diagnóstico de
  erro, e o app já mostra estado-vazio explicativo. O diálogo de publicação
  avisa que o conteúdo está vazio.
- **P4. Descobrir a chave publicável pela UI do editor fica FORA deste item.**
  `publishableKey` tem zero ocorrências em `apps/driva_editor/lib` — hoje ela só
  sai por `GET /v1/projects/:id`. É lacuna real ("como eu ligo meu app?"), mas é
  sobre **acesso**, não sobre ciclo de vida do conteúdo, e o item 24 já é
  grande. Vai para o roadmap como item próprio, vizinho do 26/37 (rotação e
  revogação de chave).
- **P5. O teto de 100 da listagem pública, sem cursor, permanece.** É débito
  pré-existente da fatia 1 (o 101º conteúdo some em silêncio). Filtrar por
  publicado **reduz** a chance de bater no teto, então este item não piora nada.
  Paginar a rota pública fica com a fatia 2 do item 25, que é quem vai consumir
  a listagem de verdade.

### Herdadas do plano de gaveta (premissas, não reabertas)

- **D1** — `spec` vira `draftSpec`; versões em tabela própria com
  `@@unique([contentId, version])` e `onDelete: Cascade`.
- **D2** — a migração não publica nada retroativamente.
- **D3** — publicar é idempotente por conteúdo.
- **D4** — restaurar traz para o rascunho; nunca republica direto.
- **D5** — quem valida o spec é o kernel Dart; o gate de publicação é o
  diagnóstico de erro no editor.
- **D6** — o contrato de leitura do editor mantém a chave `spec` (que passa a
  ser o rascunho).
- **D7** — `hasUnpublishedChanges` é derivado de timestamps, não de diff de
  JSON; renomear nome/slug não conta como alteração.

## Nota de recorte para o tech-lead (leitura de produto, não decisão)

**Quem decide o recorte final é o tech-lead no plano vivo.** O que o PM tem a
dizer é sobre o risco.

O slot de dois chips (decisão 7) é a **única** entrega do item 24 que muda
código de outras telas. Isso o torna diferente de tudo o mais aqui em três
aspectos: quem o revisa é outro perfil (não basta olhar `editor_module`), quem
o quebra derruba telas que não têm nada a ver com publicação, e ele **não
depende de nada do item 24** — não precisa do backend do P1 nem dos use cases
do P2, porque é uma mudança de API de widget.

**Leitura do PM: vale isolar — e a independência é o argumento mais forte.**
Preferência, em ordem:

1. **Fase curta antes do P3** (um "P2b", paralelo ao P1/P2): `AppShellSlot`
   passa a aceitar dois chips, as telas existentes são conferidas, e o editor
   continua publicando **um** chip só. É refactor puro, sem feature junto —
   PR pequeno, revisável em minutos, e um `flutter analyze` verde mais as telas
   conferidas já são a prova. Como não depende do P1 nem do P2, **não alonga o
   caminho crítico**: roda em paralelo. Quando o P3 chegar, ele só acrescenta o
   segundo chip, e qualquer regressão de topo que apareça no P3 já estará
   descartada como causa.
2. **Tarefa própria dentro do P3**, se o tech-lead achar que uma fase a mais tem
   custo de cerimônia maior que o benefício. Aceitável, com uma condição:
   **commit separado**, para o refactor do shell não se misturar com a lógica de
   publicação no mesmo diff. Um PR que muda `core/widgets/` **e** estreia
   publicação é um PR em que o revisor não consegue separar o que é risco de
   quê.

O que o PM **não** recomenda é deixá-lo diluído nos arquivos do P3 sem fronteira
nenhuma. O gate do item 24 é publicar com segurança; misturar a isso uma mudança
de componente compartilhado é o jeito de descobrir tarde que a regressão estava
no topo, não na publicação.

## Dependências

- **Item 8e (barra de problemas)** — entregue. É a fonte do gate de publicação.
- **Item 23 (histórico do editor)** — entregue. Restaurar passa pelo funil de
  mutação e vira uma entrada de desfazer. O `EditorReady` ganha campos novos, que
  precisam entrar nos `copyWith`/`props` existentes.
- **Item 25 fatia 1 (API pública + demo)** — entregue. É o que este item
  conserta.
- **Item 9e (exclusão de projeto)** — o E2E dele precisa ser re-executado.
- **Bloqueia:** item 25 fatia 2 (`driva_client`) e o item 21 (componentes, que
  vai pendurar a expansão no `PublishContentUseCase`).

## Ambiguidades — levantadas e fechadas

Este discovery levantou três ambiguidades de produto. **Todas foram decididas
pelo humano em 2026-08-15**, nas três recomendações do PM, aceitas
integralmente. Ficam registradas aqui com o raciocínio, porque o "porquê" é o
que impede que sejam reabertas por engano mais para frente.

**Nenhuma ambiguidade de produto segue aberta.** O PRD está pronto para
aprovação.

### A1 — O que a API pública passa a expor, além do `findBySlug`? → **fechada**

A decisão 4 do humano fechou a rota de detalhe. Mas a fatia 1 do item 25
entregou mais superfície pública, e o resto ficou sem decisão: a **listagem**
devolvia todos os rascunhos do projeto sem filtro, o **`updatedAt`** do corpo
público era a hora da última edição de rascunho, e a **ordenação** seguia esse
mesmo campo.

Sem decidir, o app passaria a listar conteúdos que dão `404` ao abrir, e a
listagem continuaria expondo nome, slug e **atividade de edição** de rascunhos a
qualquer portador da chave publicável — uma chave que, por natureza, vai
embarcada no binário distribuído.

> **Decidido:** tratar **todo o `/v1/public` como a vitrine da versão
> publicada**. A listagem filtra `publishedVersionId != null`, o `updatedAt`
> passa a carregar o `publishedAt`, e a ordenação segue esse campo. O contrato
> não muda de **forma** — só de conteúdo e significado, exatamente como a
> decisão 4 prometia.

**Consequência que precisa estar explícita:** este é o contrato que o **item 25
(runtime SDK)** herda. `ETag` imutável e `updatedAt` como data de publicação são
justamente o que tornam viável o cache em disco e o *stale-while-revalidate* da
fatia 2. **A partir daqui, mexer neste contrato custa versionar a API** — haverá
apps publicados na loja consumindo-o, e app na loja não se atualiza sob demanda.

### A2 — Onde mora o estado de publicação no topo do editor? → **fechada**

O plano assumia o `status:` do `AppShellSlot` livre. **Não estava** — é
`_statusFor(SaveStatus)`. Salvar e publicar são eixos ortogonais: "Não salvo" e
"No ar (v3)" são verdade ao mesmo tempo, e é aí que o usuário mais precisa dos
dois. Trocar um pelo outro apagaria o indicador de salvamento que o item 23
acabou de refinar.

> **Decidido:** `AppShellSlot` passa a aceitar **dois chips** — um de
> salvamento, um de publicação. Nenhum substitui o outro.

**Consequência que precisa estar explícita:** o slot mora em
`core/widgets/app_shell/`, **compartilhado por todas as telas**. É o único ponto
deste item que toca código fora do editor, e por isso:

- O P3 **lista as telas que consomem o slot hoje** e confirma que nenhuma
  regride com um chip só.
- O contrato do item 16c continua valendo: **o shell nunca lê cubit** — a página
  publica os chips como **dados**. Se o shell precisar saber o que é
  "publicação", o recorte está errado.
- **CISO e QA precisam saber que o raio de impacto passou do editor.** A revisão
  de fase não pode olhar só `editor_module`.

### A3 — "Fora do ar" é distinguível de "nunca publicado"? → **fechada**

O contrato desenhado no plano expunha só `publishedVersion` (que vira `null`) e
`hasUnpublishedChanges`. Com isso, um conteúdo **despublicado** ficava
indistinguível de um **nunca publicado**: o usuário clicava em "Tirar do ar" e a
tela passava a dizer que o conteúdo nunca foi publicado — parecia que o
histórico tinha sido apagado, o oposto do que a confirmação prometia.

> **Decidido:** expor **`latestVersion: int | null`** no `GET /v1/contents/:id`
> **e** no `toSummary`. "Nunca publicado" é `latestVersion == null`; "fora do
> ar" é `latestVersion != null && publishedVersion == null`.

**Consequência que precisa estar explícita:** os três estados aparecem em
**três lugares**, e todos entram no aceite — a copy do topo do editor, o selo da
lista de conteúdos e a confirmação de despublicar (que passa a citar a contagem
de versões guardadas, em vez de um genérico "o histórico continua guardado").

### Registrada, mas não perguntada — renomear o slug de um conteúdo no ar

O slug é a **chave pública de consumo**: o app pede
`/v1/public/contents/<slug>`. Renomear o slug de um conteúdo publicado quebra
**silenciosamente** todos os apps que o usam — vira `404` sem nenhum aviso, e a
D7 até reforça que renomear "não conta como alteração".

Não vira pergunta porque a correção completa (slug histórico, redirecionamento,
ou bloqueio) é escopo próprio. Fica como **evolução registrada** e, se couber
sem custo no P3, como um aviso no diálogo de renomear: _"Apps que buscam este
conteúdo pelo slug antigo deixarão de encontrá-lo."_
