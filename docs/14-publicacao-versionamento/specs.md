# Specs — Publicação e versionamento do conteúdo

_Roadmap: item **24** (Marco 5 — Ciclo de vida do conteúdo). Plano de gaveta:
`docs/plans/24-publicacao-versionamento/plan.md` — as decisões técnicas D1–D7
vivem lá e **não são reabertas aqui**. Este documento descreve o **comportamento
de produto**._

## O problema

Um `Content` tem **um** campo de spec. Salvar é publicar.

Isso era abstrato enquanto ninguém consumia. Deixou de ser em 2026-08-15, quando
a fatia 1 do item 25 subiu: existe hoje, em homologação, um endpoint público
(`GET /v1/public/contents/:slug`) e um app (`apps/driva_demo_app`) que renderiza
o que vem dele. **Esse endpoint serve o rascunho.** Cada tecla salva no editor
vai para a tela de quem estiver com o app aberto, e não há como voltar atrás —
é o desvio `VR-13-01` de `docs/13-loop-sdui/variance_report.md`, registrado com a
recomendação de não abrir para nenhum cliente real antes deste item.

O que falta não é um botão. É o conceito de **"o que está no ar"** existir
separado de **"o que estou mexendo"**, com histórico do que já esteve no ar e
caminho de volta.

## Objetivo

Dar ao conteúdo um ciclo de vida explícito, visível e reversível:

1. **Rascunho × publicado** — salvar mexe no rascunho e nunca no que está no ar.
2. **Versões imutáveis** — publicar carimba uma versão numerada, datada, com uma
   nota opcional de quem publicou.
3. **Rollback** — restaurar uma versão antiga **para o rascunho**, revisar no
   canvas e republicar.
4. **Despublicar** — tirar do ar sem apagar nada.
5. **O editor e a lista mostram o estado**, sempre, sem o usuário ter que
   adivinhar.
6. **Fechar o VR-13-01** — a API pública passa a servir a versão publicada.

## Escopo

**Dentro:**

- Separação rascunho × publicado no modelo e na API (`/v1/contents`).
- Histórico imutável de versões, com paginação.
- Publicar, despublicar e restaurar — API **e** interface no editor.
- Indicador de estado no topo do editor e selo na lista de conteúdos.
- Bloqueio de publicação quando o documento tem diagnóstico de **erro**.
- `/v1/public` passa a servir a **versão publicada**; sem publicação → `404`.

**Fora (deliberadamente):**

- **Agendamento** de publicação e janelas de deploy.
- **Aprovação por papéis / workflow** — depende do item 26 (usuário) e do 37.
- **Diff visual** entre duas versões — reaproveitaria o `json_highlighter` do
  item 8; fica registrado como evolução.
- **Publicar vários conteúdos de uma vez** ("release" do projeto).
- **Autor da publicação** — a coluna `createdBy` nasce, mas fica `null` até o
  item 26 existir. Sem usuário não há autor honesto para gravar.
- **Poda de versões** — decisão do humano: guardar todas, para sempre.
- **Expansão de componentes na publicação** — obrigação do item 21; o use case de
  publicar nasce como um **transformador** do documento justamente para receber
  isso depois sem reescrita.

## Estado atual (levantado no código, 2026-08-15, pós-PR #118)

**Backend.** `Content` tem **um** campo `spec` (e um `updatedAt`), e é ele que
todo mundo lê. `backend/src/public/` tem três arquivos e **nenhum teste**:
`GET /v1/public/contents[/:slug]`, autenticado pelo header `x-driva-key`
(`Project.publishableKey`, `@unique`). O `findBySlug` lê **`Content.spec` cru**
— o rascunho —, responde `ETag: "<id>-<updatedAt em ms>"`,
`Cache-Control: public, max-age=60, must-revalidate` e `200`/`304`/`404` (nunca
`401`). **A listagem pública não filtra nada:** devolve todos os conteúdos do
projeto, `take: 100` fixo, sem cursor e sem `ETag`.

As quatro precedências que este item reaproveita continuam intactas:
`@@unique([projectId, slug])`, a checagem de `specVersion` no `update()` (400),
o `toSummary(row)` como forma única do item de lista, e o `cursor.ts`
(`encodeCursor`/`decodeCursor` + keyset `take: limit+1`).

**Editor.** O botão continua o placeholder literal:
`AppBarAction.outlined(label: 'Publish', tooltip: 'Publicação chega no
incremento I4')` — **sem `onPressed`**. Três fatos que moldam o desenho:

- **Não existe menu de excesso no topo.** Não há `PopupMenuButton` nem
  `MenuAnchor` em `core/widgets/` ou no `editor_module`. O "Tirar do ar"
  escondido no menu (decisão 2) implica **criar** esse menu.
- **O slot de status do topo já está ocupado.** `AppShellSlot` tem **um**
  `status:`, hoje alimentado por `_statusFor(SaveStatus)`. Passa a aceitar
  **dois chips** (decisão 7) — e isso é `core/widgets/`, código de todas as
  telas.
- **`ContentSummary` não tem campo de status.** O selo na lista não é só UI:
  exige campo novo na entidade, no model zard e no `toSummary` do backend.

**O gate de publicação já existe pronto.** `EditorReady.diagnostics` entrega
`SpecDiagnostic {nodeId, nodeType, code, severity, message}`, e
`DiagnosticSeverity` tem `error`/`warning`. Hoje **um único código é erro**:
`flexOnlyOutsideFlex` (`expanded`/`spacer` cujo pai não é `row`/`column`).
Como o diagnóstico carrega o `nodeId`, o bloqueio pode apontar **qual nó** está
errado, não só dizer "há erro".

**O histórico do editor já está entregue** (item 23): `_emitDocument` é o funil
de mutação e empilha o passo anterior. Restaurar uma versão passando por ele
vira **automaticamente** uma entrada de desfazer — é isso que torna aceitável
substituir o rascunho.

**O app demo já trata `404`**: mostra `Icons.search_off`, "Conteúdo não
encontrado." e "Tentar de novo". Sem crash. O estrago do D2 sem backfill é
menor do que parecia — mas a copy de catálogo vazio ("Crie um conteúdo no editor
do driva e ele aparece aqui") fica **factualmente errada** depois deste item, e
precisa passar a falar de publicação.

## Os quatro estados de um conteúdo

O estado é a primeira coisa que o usuário precisa ler na tela — no topo do
editor e no card da lista. Ele é derivado, nunca digitado:

Os quatro estados saem de **dois campos** do contrato — `latestVersion`
(a maior versão já criada, ou `null`) e `publishedVersion` (a que está no ar,
ou `null`) — mais o `hasUnpublishedChanges`:

| Estado | Como é derivado | No topo do editor | Selo na lista |
| --- | --- | --- | --- |
| **Nunca publicado** | `latestVersion == null` | "Nunca publicado" | "Rascunho" |
| **No ar** | `publishedVersion != null` e `!hasUnpublishedChanges` | "No ar (v3)" | "No ar" |
| **Alterações não publicadas** | `publishedVersion != null` e `hasUnpublishedChanges` | "Alterações não publicadas (no ar: v3)" | "No ar · alterações" |
| **Fora do ar** | `latestVersion != null` e `publishedVersion == null` | "Fora do ar (última: v3)" | "Fora do ar" |

Duas regras que sustentam a tabela:

- **"Mudou" é o rascunho, não o registro.** Renomear o conteúdo ou trocar o slug
  **não** transforma "No ar" em "Alterações não publicadas" — só a edição do
  spec conta (D7 do plano).
- **"Fora do ar" não é "nunca publicado".** Depois de despublicar, o histórico
  continua ali e o usuário precisa ver isso — senão o botão Despublicar parece
  ter apagado o trabalho. É exatamente para isso que o `latestVersion` existe
  (decisão 8).

**Acessibilidade:** cada estado é **ícone + texto**, nunca só cor. O selo da
lista tem `Semantics`/tooltip com o texto longo ("No ar desde 14/08, versão 3").
No topo, publicação e salvamento são **dois chips distintos** — ver a seção
seguinte.

## O topo do editor: dois chips, dois assuntos

Salvamento e publicação são **eixos ortogonais**. "Não salvo" e "No ar (v3)" são
verdade ao mesmo tempo, e é justamente aí que o usuário mais precisa dos dois:
ele acabou de mexer, ainda não salvou, e o que está no ar continua sendo a v3.

Por isso o topo passa a exibir **dois chips lado a lado** (decisão 7):

- **Chip de salvamento** — o que já existe: "Salvo" / "Não salvo" / "Salvando…" /
  "Falha ao salvar". Fala sobre o **rascunho**.
- **Chip de publicação** — os quatro estados da tabela acima. Fala sobre **o que
  está no ar**.

Nenhum dos dois substitui o outro, e nenhum deles some. O chip de publicação
precisa de um tom de **atenção** para "Alterações não publicadas" — não é
sucesso nem perigo; os tokens `warning` já existem em `EditorColors` desde o
item 8e.

> **Isto toca código compartilhado.** O slot de status mora em
> `core/widgets/app_shell/`, usado por **todas** as telas, não só pelo editor. O
> contrato do shell permanece o do item 16c: **o shell nunca lê cubit** — a
> página publica os chips como **dados**. Ver o recorte no `prd.md`.

## Fluxo — publicar

**Caminho feliz.**

1. O usuário edita, o rascunho fica sujo, o topo mostra "Alterações não
   publicadas".
2. Clica em **Publicar**.
3. Abre a confirmação, que mostra: **a versão que será criada** ("Publicar como
   v4"), o campo **Nota (opcional, até 200 caracteres)** e, se houver, a
   **contagem de avisos não bloqueantes** ("2 avisos — publicar mesmo assim").
4. Confirma. Se o rascunho estiver sujo, **o editor salva antes** — publicar o
   que está na tela e não o que está no servidor seria mentira.
5. O topo passa a "No ar (v4)"; o selo na lista acompanha.

**O gate de qualidade.** Publicar fica **bloqueado** enquanto houver diagnóstico
de severidade **erro** no documento (a lista do item 8e). Avisos **não**
bloqueiam. O botão desabilitado carrega tooltip dizendo **o porquê** ("1 erro no
conteúdo — corrija na barra de problemas para publicar"), porque estado
desabilitado sem explicação é um beco sem saída.

**Publicar sem nada novo.** Quando não há alteração desde a última publicação, o
botão fica desabilitado com tooltip "Tudo publicado (v3)". A API, mesmo assim, é
**idempotente** (D3): se a chamada chegar — duplo clique, corrida, cliente fora
do editor —, ela devolve a versão atual **sem criar uma versão nova**. A UI
previne; a API garante.

## Fluxo — despublicar

Ação **secundária**, escondida no menu de excesso do topo (nunca no botão
principal), disponível apenas quando o conteúdo está no ar.

1. O usuário abre o menu do topo e escolhe **Tirar do ar**.
2. Confirmação explícita, que diz **o que acontece de verdade**: "O conteúdo sai
   do ar para os apps que o consomem. O rascunho e as 3 versões do histórico
   continuam guardados. Você pode publicar de novo quando quiser."
3. Confirma. O topo passa a "Fora do ar (última: v3)" — e é "fora do ar", não
   "nunca publicado", porque o `latestVersion` continua valendo 3 (decisão 8).
4. **A partir daí, o app cliente recebe `404` naquele slug — e o conteúdo
   também some do catálogo público** (decisão 6). A confirmação diz as duas
   coisas: "Ele sai do ar e deixa de aparecer na lista dos apps."

Despublicar **não apaga nada**: nem versões, nem rascunho.

**Não é instantâneo, e a tela diz isso.** A rota pública responde
`Cache-Control: public, max-age=60, must-revalidate`, então um app que buscou o
conteúdo há menos de um minuto continua exibindo o que tinha em cache. A
confirmação acrescenta, sem eufemismo: _"Apps que já carregaram o conteúdo podem
continuar exibindo por até 1 minuto."_

**Decisão registrada:** manter os 60 segundos e **ser honesto na UI**, em vez de
derrubar o `max-age`. Baixar o cache encarece toda leitura de todo app para
acelerar uma ação rara. Se despublicar virar ferramenta de remoção de
emergência — conteúdo ofensivo, vazamento —, aí o caminho é invalidação
explícita, não cache curto; fica registrado como evolução.

## Fluxo — restaurar uma versão

1. O usuário abre o **Histórico de versões** (menu do topo ou o indicador de
   estado).
2. O diálogo lista as versões, **mais nova primeiro**, com número, data, nota e
   um selo **"no ar"** na que estiver publicada. Rola infinito (o padrão do item
   16), e a lista **não carrega os specs** — só os metadados.
3. Escolhe **Restaurar para o rascunho** numa versão.
4. Confirmação, porque **descarta o rascunho atual**: "O rascunho atual será
   substituído pelo conteúdo da v1. O que está no ar não muda."
5. O diálogo fecha, o canvas passa a mostrar a v1 como **rascunho sujo**, e o
   estado vira "Alterações não publicadas".
6. O usuário revisa e publica quando quiser — o que cria a **v4**, não
   "restaura a v1 ao ar".

**Duas etapas, de propósito** (D4). Rollback com um clique é como se derruba
produção sem querer; a segunda etapa é a chance de olhar o canvas antes.

**O restaurar é desfazível.** O item 23 já entregou a pilha de histórico do
editor: restaurar passa pelo funil de mutação do documento, então vira **uma**
entrada de desfazer — `Ctrl+Z` traz o rascunho anterior de volta. Isso é o que
torna aceitável descartar o rascunho no passo 4.

## O que muda para o app cliente (fecha o VR-13-01)

**Todo o `/v1/public` passa a ser a vitrine da versão publicada** (decisão 6) —
não só a rota de detalhe. O contrato **não muda de forma**; muda de conteúdo e
de significado:

- `GET /v1/public/contents/:slug` passa a devolver o spec da **versão
  publicada**, nunca o rascunho.
- Conteúdo **nunca publicado** ou **fora do ar** → **`404`**, o mesmo `404`
  genérico de slug inexistente. O app não tem como distinguir "não existe" de
  "existe mas não está no ar" — e não deve: isso vazaria a existência de um
  rascunho.
- **`GET /v1/public/contents` (o catálogo) passa a listar só o que está no ar.**
  Conteúdo nunca publicado nunca aparece; conteúdo despublicado **some da
  lista**. Fecha duas coisas de uma vez: o catálogo deixa de oferecer itens que
  dão `404` ao abrir, e a listagem para de expor nome e slug de rascunhos a
  qualquer portador da chave — que é uma chave embarcada em binário
  distribuído.
- **`updatedAt` deixa de ser a hora da última edição de rascunho e passa a ser
  o `publishedAt`.** O campo continua existindo com o mesmo nome (o zard do app
  o exige), mas volta a significar o que o app entende por ele: "quando isto
  mudou para mim". De quebra, some o vazamento de **atividade** — antes dava
  para inferir quando alguém mexeu no rascunho.
- **A ordenação do catálogo segue o `publishedAt`**, pelo mesmo motivo: ordenar
  por edição de rascunho é ordenar por um fato invisível e irrelevante para
  quem consome.
- O `ETag` deixa de ser `(id, updatedAt)` e passa a ser `(contentId, version)`.
  A versão é **imutável**, então o `ETag` passa a ser honesto: enquanto a versão
  no ar não muda, o cache do cliente é válido de verdade.

> **Este é o contrato que o item 25 herda.** A fatia 2 (`driva_client`, com
> cache em disco e *stale-while-revalidate*) vai ser construída em cima destas
> semânticas — `updatedAt` como data de publicação e `ETag` imutável são
> exatamente o que tornam o cache viável. **A partir daqui, mexer neste
> contrato custa versionar a API**, porque haverá apps na loja consumindo-o.

**Consequência aceita e consciente (D2, confirmada pelo humano):** a migração
**não publica nada retroativamente**. Todo conteúdo existente em homologação
vira "nunca publicado", e o app demo passa a receber `404` **até alguém abrir o
editor e clicar em Publicar**. Publicar manualmente faz parte da validação
deste item — e é **passo explícito do plano e do PR**, não algo a lembrar
depois: sem ele, as evidências de E2E do PR #118 deixam de reproduzir.

**Duas copies do app demo ficam factualmente erradas** depois deste item e
entram no escopo:

- O catálogo vazio hoje diz _"Crie um conteúdo no editor do driva e ele aparece
  aqui"_. Passa a ser **publique**, não crie — criar deixa de bastar.
- O erro de conteúdo não encontrado diz só _"Conteúdo não encontrado."_, que
  agora é ambíguo entre "slug errado" e "existe, mas não está no ar". Como a API
  devolve o mesmo `404` genérico de propósito, **o app não tem como
  distinguir** — a copy deve parar de sugerir que o conteúdo existe.

## Mensagens

Texto é parte do produto. As mensagens abaixo são o contrato de tom — direto,
sem jargão, dizendo o que aconteceu e o que fazer:

| Situação | Mensagem |
| --- | --- |
| Publicado | "No ar na v4." |
| Publicar bloqueado por erro | "1 erro no conteúdo — corrija na barra de problemas para publicar." |
| Publicar sem nada novo | "Tudo publicado (v3)." |
| Falha de rede ao publicar | "Não foi possível publicar. O que está no ar não mudou. Tente de novo." |
| Publicação concorrente (409) | "Alguém publicou este conteúdo agora mesmo. Recarregue para ver a versão atual." |
| Despublicado | "Conteúdo fora do ar. As 3 versões do histórico continuam guardadas." |
| Publicar um conteúdo que estava fora do ar | "No ar de novo, na v4." |
| Histórico vazio | "Este conteúdo nunca foi publicado. Publique para criar a primeira versão." |
| Restaurado | "Rascunho substituído pela v1. Publique para colocar no ar." |

A copy de despublicado cita **a contagem de versões**, não um genérico "o
histórico continua guardado": é o que prova, na hora, que nada foi apagado — e é
possível justamente porque o `latestVersion` passou a existir.

**Regra do erro de publicação:** falhar ao publicar **nunca** altera o estado
exibido de publicação. Se a rede caiu, o topo continua dizendo a verdade sobre o
que está no ar.

## Decisões do humano que sustentam esta spec

Tomadas na sessão de 2026-08-15, **não reabrir**:

1. **Retenção: todas as versões, para sempre.** Sem poda, sem limite. Podar
   depois é migração — e migração que apaga histórico precisa de decisão
   própria.
2. **Despublicar entra nesta fatia, com API e botão.** O botão fica escondido no
   menu de excesso do topo, não no botão principal, e pede confirmação.
3. **A nota da publicação é opcional**, com no máximo 200 caracteres.
4. **O VR-13-01 fecha aqui.** `PublicService.findBySlug` passa a ler a versão
   publicada e a devolver `404` sem publicação; o `ETag` vira `(contentId,
   version)`. O contrato visto pelo app não muda.
5. **Sem backfill na migração (D2 mantido).** Todo conteúdo existente vira
   "nunca publicado" e o demo em homologação recebe `404` até alguém publicar.
6. **Todo o `/v1/public` vira vitrine da versão publicada** — a listagem filtra
   por publicado, o `updatedAt` do corpo público passa a ser o `publishedAt`, e
   a ordenação segue esse mesmo campo. **É o contrato que o item 25 herda**;
   daqui em diante, mexer nele custa versionar a API.
7. **Dois chips no topo do editor.** Salvamento e publicação convivem, cada um
   no seu chip, em `AppShellSlot`. Toca `core/widgets/app_shell/` — código
   compartilhado por todas as telas.
8. **`latestVersion: int | null`** entra no `GET /v1/contents/:id` e no
   `toSummary`. É o que separa "nunca publicado" de "fora do ar", nos três
   lugares onde isso aparece: a copy do topo, o selo da lista e a confirmação de
   despublicar.

## Ambiguidades — todas fechadas

As três que este discovery levantou foram decididas pelo humano em 2026-08-15 e
viraram as decisões **6**, **7** e **8** da seção anterior. **Nenhuma ambiguidade
de produto segue aberta.**

Resta **um ponto técnico**, que não é decisão de produto e não bloqueia esta
spec: o `VR-13-01` descreve a mudança como ler `content.publishedVersion.spec`,
mas a D1 define `publishedVersionId` como FK **solta, sem `@relation`** — e sem
relação não há navegação no Prisma. Duas queries com join no service ou dar
`@relation` à D1: escolha do tech-lead no P1. O que esta spec exige é só o
resultado observável descrito acima.
