# Plano — O `projectId` entra na rota do editor

> **Item 46 do roadmap.** Bug pré-existente, achado pela validação do E2E do item 24 contra
> homologação em 2026-08-17. Docs irmãs: [`specs.md`](specs.md) · [`prd.md`](prd.md).
>
> **Decisões A1–A4 travadas pelo humano em 2026-08-17** — este plano as executa, não as
> reabre. Divergência só entra por `variance_report.md` aprovado pelo dev.

---

## Estado

| Fase | O que entrega | Situação |
| --- | --- | --- |
| **F1** | A URL do editor passa a bastar (rota + escopo + navegação + tela de falha) | `[ ]` não iniciada — **1 PR** |
| **F2** | E2E manual em homologação, executado e **atestado pelo dev humano** | `[ ]` bloqueada por F1 |
| **F3** | Bateria automatizada + docs vivas | `[ ]` bloqueada por F2 |

**Última atualização:** 2026-08-17 (nascimento do plano).

---

## 1. Objetivo e recorte

**A URL do editor passa a carregar o projeto.** Hoje ela carrega só o conteúdo, e o tenant
vem de um singleton em memória que morre a cada reload. O resultado é uma mensagem que mente
("Conteúdo não encontrado.") e — pior — um **link compartilhável errado gerado em silêncio**.

Entra:

1. A rota vira `/projects/:projectId/contents/:id/edit`, e o `pageBuilder` carimba o
   `ProjectScope` antes de montar o cubit (padrão D18, o mesmo do `/preview`).
2. Os dois pontos de navegação da tela do projeto passam o `projectId` que já têm em mãos.
3. A rota antiga **some** — cai no `onException` que já existe (A2›B).
4. A tela de falha para de mentir: separa "o projeto da URL não existe" de "este conteúdo não
   existe **neste** projeto", **sem request novo e sem tocar no backend** (A3›B).

Não entra: matar o singleton `ProjectScope` (A4›A — débito vivo apontando para o item 26),
auth, mudança no 404 do backend, e nada em `packages/` ou `backend/`.

**O recorte de PR segue a A4: uma fase de código, um PR.** O PRD propunha F1 e F2 separadas;
o tech-lead as funde num PR só porque o diff inteiro é de cinco arquivos e a tela de falha
**é o que torna o E2E provável** — separá-la deixaria o primeiro PR sem os dois modos de
falha visualmente distintos que o DoD exige. Registrado na §9.

---

## 2. O que está quebrado hoje, medido no código

### 2.1 A causa, em quatro linhas

`editor_routes.dart:5` — `static const String editor = '/contents/:id/edit'`. Sem projeto.

`editor_page.dart:72` — `final projectId = getIt<ProjectScope>().projectId;` — o valor vem de
um singleton **mutável, só em memória** (`core/network/project_scope.dart`, dez linhas,
`reset()` para `'default'`), semeado no boot com `AppConfig.defaultProjectId`.

Quem **escreve** o escopo hoje: `injection.dart` (semente), `project_detail_page.dart`
(`pageBuilder` de `/projects/:id`) e `preview_page.dart:38` (`pageBuilder` de
`/preview/:projectId/:id`). Quem **lê**: o interceptor do `createDio` (carimba
`x-project-id` **a cada request**, não na criação do client) e o próprio `pageBuilder` do
editor.

Conclusão: **a rota do editor é a única do app que lê um escopo que outra tela escreveu.**
Reload, aba nova ou link colado = escopo `default` = 404 em qualquer projeto que não seja ele.

### 2.2 O modo silencioso — o pior dos sintomas

`canvas_area.dart:76-86` monta a URL compartilhável do preview com `cubit.projectId`:

```dart
final location = GoRouter.of(context).namedLocation(
  EditorRoutes.previewName,
  pathParameters: {'projectId': cubit.projectId, 'id': state.document.id},
);
```

Depois de um reload frio, `cubit.projectId` é `'default'` e o diálogo "ver no celular"
entrega `https://…/preview/default/<id>` — **sem erro nenhum na tela**. O usuário copia um
link quebrado e o erro aparece do outro lado. É o caso que a evidência de hoje não cobre, e
o que faz este item ser "o editor produz dado errado sem avisar", não "o editor mostra a
mensagem errada".

### 2.3 Cinco leitores do valor contaminado — nenhum muda de código

Todos chegam ao valor por `EditorCubit.projectId`, e todos passam a receber o valor certo de
graça quando a rota o entrega:

| Onde | O que faz com ele |
| --- | --- |
| `editor_page.dart:139-145` | o botão "Voltar para o projeto" da **própria tela de erro** |
| `editor_top_registrar.dart:97-101` | o `Crumb` do projeto no breadcrumb |
| `editor_viewport_gate.dart:29` → `small_viewport_notice.dart:75` | botão "Ver conteúdo" do portão mobile (vai para o `/preview`) |
| idem → `small_viewport_notice.dart:93` | botão "Voltar aos conteúdos" do portão mobile |
| `canvas_area.dart:82` | o link/QR do "ver no celular" — **o modo silencioso** |

**Nenhum destes cinco arquivos é editado nesta fase.** Se algum aparecer no diff sem
justificativa, é desvio.

### 2.4 O que a suíte não protege

Varredura em `apps/driva_editor/test/**` (70 arquivos) por
`EditorRoutes|appRoutes|ProjectScope|/contents/|editorName`: **zero ocorrências**. Nenhum
teste monta o `GoRouter`; **o `ProjectScope` não tem cobertura nenhuma**.

**Suíte verde não prova nada aqui** — é o R1, e é por isso que a varredura de call sites vira
gate de máquina (§11.1›6) e o teste de navegação vira item da F3.

**Os dois call sites de navegação para o editor são exatamente estes** (inventário de
2026-08-17, confirmado por varredura completa de `lib/` — não há `pushNamed`, nem
`context.go('/contents…`):

| # | Onde | Contexto |
| --- | --- | --- |
| 1 | `project_detail_page.dart:169-172` | `onOpenContent:` — clique num conteúdo da lista |
| 2 | `project_detail_page.dart:387-390` | dentro de `_openContentForm`, **só no ramo `if (editing == null)`** — conteúdo recém-criado cai no editor |

### 2.5 A cerca herdada que não se pode derrubar

Oito testes constroem `EditorCubit` passando `projectId: 'p1'` — continuam válidos. Quatro
montam **`EditorPage` sem DI**, com o harness
`MaterialApp > MultiBlocProvider > EditorPage(...)` e **sem `GoRouter` nenhum**:
`editor_page_layout_controller_test.dart:77-82`, `page/editor_workspace_test.dart:102-107`,
`widgets/canvas_panel_golden_test.dart:93-97`, `editor_perf_test.dart:75-79`.

**A mudança de rota, por si, não toca em nenhum deles** — hoje o único parâmetro `required`
de `EditorPage` é `projectFuture`. O que os derruba é **um parâmetro `required` novo**, e é
por isso que a cerca é sobre a assinatura da página, não sobre a rota. É o tropeço do
`VR-16-02`, protegido pela D19 do item 41 e reafirmado aqui na **D3**.

### 2.6 Piora sozinho

`DEFAULT_PROJECT_ID: "default"` está nos **quatro** flavors, produção incluída. Enquanto
existir um projeto chamado `default` na instalação, o estrago fica contido a quem sai dele.
No dia em que não existir (item 26), **todo reload do editor vira 404 para todo mundo**. O
custo de consertar é o mesmo hoje e depois; o de conviver, não.

---

## 3. O que já existe e vamos reusar

- **O padrão inteiro**, validado em produção: `preview_page.dart:25-53` — valida os dois path
  params, devolve tela de rota inválida se faltar um, escreve
  `getIt<ProjectScope>().projectId = projectId` **antes** do `BlocProvider`, monta o cubit.
  A F1 replica essa forma; não inventa nenhuma.
- **A rota já é registrada pelo caminho certo:** `app_router.dart:32` instala
  `EditorRoutes.route` dentro do `ShellRoute`. Mudar o `path` na constante basta —
  **`app_router.dart` não recebe uma linha** (gate de máquina, §11.1›5).
- **`InvalidContentScreen`** (`presentation/editor/page/invalid_content_screen.dart`) já é a
  tela de rota inválida do editor, irmã da `InvalidPreviewScreen`.
- **O `projectFuture` já é buscado e já resolve o nome do projeto**: `pageBuilder` cria
  `getIt<GetProjectUseCase>()(projectId)`, e `editor_top_registrar.dart:43-49` já o consome
  num `FutureBuilder` para o breadcrumb. O branch de falha do `EditorPage` **ignora** esse
  mesmo `Future` hoje — a F1b só liga um ao outro (é o que torna a A3 barata).
- **`onException`** (`app_router.dart:36`) já manda toda URL desconhecida para a home. É todo
  o "código" que a A2›B pede.
- **Infra: nada a mudar.** `deploy/nginx.conf` faz `try_files … /index.html` genérico,
  `bootstrap.dart` usa `usePathUrlStrategy()`, e o seletor de manifest do `web/index.html`
  chaveia por `startsWith('/preview')` — uma rota sob `/projects/…` continua no escopo `/`.

---

## 4. Decisões travadas

### D1 — A rota nasce **plana**, com o path completo, **dentro** do `ShellRoute` — **[tech-lead, A1]**

`GoRoute(path: '/projects/:projectId/contents/:id/edit')` continua na lista de `routes:` do
`ShellRoute`, ao lado de `ContentsRoutes.route`. **Não** é aninhada sob `/projects/:id`.

Aninhar faria o go_router montar a pilha inteira — `ProjectDetailPage` construído por baixo
do editor a cada abertura, disparando `CategoryTreeCubit.load()` + `ContentListCubit.load()`
de graça — e colidiria o nome do param (`:id` já é o projeto lá). Não há conflito de
ordenação: cinco segmentos não casam com `/projects/:id` nem com `/projects/archived`.

**Consequência que o E2E cobra:** "voltar" e breadcrumb **não mudam uma linha** — já navegam
por `goNamed(projectDetailName, {'id': cubit.projectId})`; o que muda é o valor passar a
estar certo (passo 5 do roteiro).

### D2 — O `pageBuilder` carimba o `ProjectScope` **antes** de montar o cubit — **[herdada, D18 do item 41]**

O path param sozinho não basta: o header `x-project-id` sai do interceptor do Dio, que lê o
`ProjectScope` a cada request. Escrever o escopo no `pageBuilder`, antes de disparar a carga,
é o que faz a **primeira** requisição sair certa. Não há race a resolver — é o que o
`/preview` já faz desde o item 41.

**O aceite disto não é ler o `pageBuilder`**: é o header observado na aba Network de uma aba
que nunca abriu a tela do projeto (§10›passo 3).

### D3 — O `projectId` **não** entra no construtor de `EditorPage` — **[cerca, D19 do item 41 / `VR-16-02`]**

Ele vem do path, é carimbado no escopo, é passado ao **`EditorCubit`** e ao
`GetProjectUseCase` — e a página continua alcançando-o por `context.read<EditorCubit>()`,
como os cinco leitores da §2.3 já fazem.

Promover `projectId` a parâmetro obrigatório de `EditorPage` "porque ficou mais limpo"
derruba os quatro testes da §2.5. **Se alguém achar que precisa, é `variance_report.md`, não
julgamento local.**

### D4 — A rota antiga não é registrada, e **nenhum código novo** trata dela — **[humano, A2›B — contra a recomendação]**

`/contents/:id/edit` simplesmente deixa de existir. O `onException` manda para a home, calada.

**Registrado como decisão contra a recomendação:** PM e tech-lead recomendaram avisar antes
de mandar para a home (_remover a rota reproduz o pecado do próprio bug: falhar sem
explicar_). O dev escolheu a opção mais barata porque o inventário de links antigos salvos é
~zero (um usuário, uma hml). **Não reabrir** — se o custo aparecer, aparece como item novo.

O passo 8 do E2E prova o comportamento; ele não prova que ele é bom.

### D5 — O guard de path param vazio fica, e **não** gera aceite visual — **[tech-lead]**

O `pageBuilder` valida os dois params e devolve `InvalidContentScreen`, espelhando
`PreviewPage`. Na prática, uma URL com segmento vazio **não casa com a rota** e cai na home
pelo `onException` — o guard é cinto e suspensório para quem construir a rota por
`goNamed` com string vazia.

**Consequência:** ninguém procura print de "tela de rota inválida" na rodada. Esse caso é
teste de widget (F3›item 13), não passo de E2E. Escrito aqui para o QA não caçar um estado
inalcançável pela URL.

### D6 — A tela de falha **espera** o `projectFuture` resolver — **[tech-lead]**

Enquanto o `Future` do projeto não resolve, a tela de falha mostra o mesmo indicador de
carga, **nunca** uma mensagem provisória. Sem isto a tela pisca "não existe" e volta atrás —
e o print do E2E capturaria um estado que o produto não afirma.

### D7 — São **três** saídas, e a terceira não inventa culpado — **[tech-lead, A3]**

Cruzando a falha do conteúdo com o resultado do `projectFuture` (que **já está em mãos**):

| Falha do conteúdo | `projectFuture` | Mensagem | Saída |
| --- | --- | --- | --- |
| `NotFoundFailure` | `Right(project)` | "Não encontramos este conteúdo no projeto **_\<Nome\>_**." | "Voltar para o projeto" (`project-detail`, `{'id': projectId}`) |
| `NotFoundFailure` | `Left(NotFoundFailure)` | "Este link aponta para um projeto que não existe." | **"Ver meus projetos"** (home) — "voltar para o projeto" seria um beco |
| `NotFoundFailure` | `Left(Network/Unexpected)` | "Não encontramos este conteúdo." (sem nomear nada) | "Ver meus projetos" (home) |
| `Network` / `Validation` / `Conflict` / `Unexpected` | irrelevante | **inalteradas** | "Voltar para o projeto", como hoje |

**Nenhuma das mensagens afirma nem sugere que o conteúdo existe em outro projeto** — a
fronteira que o 404 do backend protege fica intacta (é o que o gate do CISO vai cobrar).

A terceira linha existe porque ela é real: se a rede caiu, o app **não sabe** se o projeto
existe. Dizer "o projeto não existe" ali seria repetir o pecado do bug em escala menor.

### D8 — Os dois modos de falha se distinguem por **texto + ícone**, não por cor — **[tech-lead, acessibilidade]**

Regra do projeto (cor nunca é o único sinal) **e** requisito de prova: o DoD exige telas
visualmente distintas, e distinção só por matiz não sobrevive a um print em escala de cinza
nem a quem não distingue as duas cores.

### D9 — Um `projectFuture` só — a tela de falha **reusa**, não cria um segundo request — **[tech-lead]**

O `Future` nasce no `pageBuilder` e desce por construtor. Um `Future` do Dart admite vários
ouvintes; criar outro `GetProjectUseCase(projectId)` dentro da tela de falha duplicaria a
chamada de rede numa tela que já está em erro.

**Gate:** `GetProjectUseCase` invocado em **exatamente um** lugar de `editor_module`
(§11.1›8).

### D10 — A cerca da A4: **toda rota nova que dependa de escopo de projeto carrega o `projectId` no path** — **[humano, A4]**

O singleton `ProjectScope` continua vivo (matá-lo é o item 26). A cerca é o que impede a
próxima rota de repetir o erro, e é **cobrada na `revisar-fase`**: rota nova que leia
`getIt<ProjectScope>()` sem ter o `projectId` no próprio path reprova.

Depois desta fase, os únicos lugares que **escrevem** o escopo são `injection.dart` (semente
do flavor) e os **três** `pageBuilder` que têm o projeto no path (`project_detail`,
`preview`, `editor`). Qualquer quarto escritor é desvio.

### D11 — Os scripts de E2E **vivos** se atualizam nesta rodada; `evidencias/` não se toca — **[tech-lead, R2]**

Os scripts em `docs/NN-*/` são ferramenta viva e passariam a cair na home em vez de abrir o
editor — deixá-los quebrados é uma armadilha de uma hora para quem reexecutar qualquer um
deles. O diff é uma linha de montagem de URL em cada.

**São oito arquivos, não cinco.** O inventário de 2026-08-17 achou três `.sh` que o discovery
não tinha listado:

| Arquivo | Onde | O que é |
| --- | --- | --- |
| `docs/24-publicacao-versionamento/e2e_drive.mjs` | `:300` (helper `editorUrl()`), usado em `:347`, `:387`, `:453` | URL real |
| `docs/15-destravar-construtor/e2e_drive.mjs` | `:231` (helper), **8 chamadas** (`:277`, `:346`, `:355`, `:363`, `:370`, `:381`, `:432`, `:452`) | URL real |
| `docs/16-image-url-e-props/e2e_drive.mjs` | `:229` (helper), usado em `:232` | URL real |
| `docs/04-foco-inspector/e2e_drive_foco.mjs` | `:71` (inline, sem helper) | URL real |
| `docs/02-conteudos/e2e_drive.mjs` | `:89` (inline, sem helper) | URL real |
| `docs/02-conteudos/e2e_shots.sh` | `:107` e **`:111`** | **URL real** — e o `:111` é `/contents/nao-existe/edit` |
| `docs/02-conteudos/e2e.sh` | `:163` | texto do roteiro manual impresso |
| `docs/04-foco-inspector/e2e_foco.sh` | `:95` | legenda do README gerado |

⚠️ **A armadilha silenciosa do `e2e_shots.sh:111`:** aquele print (`04_notfound`) existe para
provar "NotFound tratado". Com a rota antiga removida, a URL passa a cair **na home** e o
script continua "passando" — tirando um print da home com legenda de tela de erro. É o mesmo
tipo de falha silenciosa que este item conserta, reproduzido na ferramenta. A URL vira
`/projects/<projeto>/contents/nao-existe/edit`.

### D11b — No script do item 24 **nenhuma** linha sai: as três são navegação, não aquecimento — **[tech-lead, corrige o discovery · revista em 2026-08-17 pela conferência da frente B]**

O discovery (e o PRD, R2) diz que os `goto(projectUrl())` das linhas **339 / 378 / 508** de
`docs/24-publicacao-versionamento/e2e_drive.mjs` ficam obsoletos. A primeira redação desta
decisão salvou só a 508. A conferência passo a passo da frente B mostrou que as **três** têm
a mesma forma e o mesmo papel — e a conferência está certa:

```
step('1',  …);  await goto(projectUrl());  check(…, await cardBadge());  await shot('01_lista_selo_rascunho.png', …);
step('5',  …);  await goto(projectUrl());  check(…, await cardBadge());  await shot('05_lista_selo_no_ar.png', …);
step('15', …);  await goto(projectUrl());  check(…, await cardBadge());  await shot('18_lista_volta_rascunho.png', …);
```

`cardBadge()` (`:230`) lê a **árvore semântica da página aberta** num laço de 12 s procurando o
card por `SLUG`+`NAME` — **não consulta a API**. Sem o `goto`, o passo 1 leria o selo de
`about:blank` e o passo 5 o leria da tela do editor: os dois dariam FAIL, e os prints
`01_lista_selo_rascunho.png` e `05_lista_selo_no_ar.png` fotografariam a tela errada. É
exatamente o dano que o **R2f** nomeia para a 508.

O que a redação anterior enxergou foi o **efeito colateral**: visitar `/projects/:id` carimbava
o `ProjectScope`, e por isso o `goto(editorUrl())` seguinte funcionava. Depois da F1 esse
aquecimento fica **desnecessário** — mas a navegação continua sendo o passo. Aquecimento
desnecessário não é linha morta quando ela também é a única coisa que abre a tela que o passo
fotografa.

- **339**, **378** e **508** — **ficam.** Só a URL do `editorUrl()` (`:300`) muda no arquivo.
- **453** é um `goto(editorUrl())` (`step('12')`, o modo de falha do publish). Também só troca
  de URL.

Nenhuma remoção neste arquivo. Se alguém quiser tirar uma dessas linhas, é
`variance_report.md` com aprovação do dev — e precisa explicar como o passo continua vendo a
lista.

As cópias em `docs/*/evidencias/rodada_NN/` são **histórico congelado**: não se reescrevem,
nem para "consertar".

### D12 — O aceite roda em **hml**, com backend real, em projeto **≠ `default`** — **[herdada, lição do item 9g]**

Duas armadilhas mascaram este bug por completo:

1. **`USE_FAKE_DATA: true`** — o `FakeContentsStore` não é escopado por projeto
   (`core/dev/fake_contents_store.dart:30-36`); com fake, o bug **desaparece**.
2. **O projeto `default`** — é o valor de fallback; nele o bug é invisível **por construção**.

Uma rodada que caia em qualquer uma das duas **não prova nada** e é reprovada de saída.

---

## 5. Fases

### F1 — A URL do editor passa a bastar · **[0-dep]** · **1 PR** · **[frente A: `especialista-apresentacao` · frente B: `qa`]**

Duas frentes de arquivos **disjuntos**, tocáveis ao mesmo tempo (worktree separado cada uma);
dentro de cada frente, as tarefas são sequenciais de propósito.

> **Nota de custo:** não vale quebrar a frente A em mais de um agente. São cinco arquivos do
> mesmo módulo, com dependência real entre eles (a constante da rota antes do `pageBuilder`,
> o `pageBuilder` antes da tela de falha) — paralelizar aí paga merge de worktree para
> economizar nada.

**Frente A — o código** · `especialista-apresentacao`

1. **[paralela: não — primeira]** `editor_routes.dart`: `editor` passa a
   `'/projects/:projectId/contents/:id/edit'`. `editorName` **não muda** (é o que mantém os
   `goNamed` compilando). Comentário de porquê só se explicar a **razão** de a rota ser plana
   (D1) — nada de descrever o que a linha faz.
2. **[paralela: não — dep. 1]** `editor_page.dart` › `pageBuilder`: lê `projectId` **e** `id`
   de `state.pathParameters`, guard dos dois (D5) → `InvalidContentScreen`, escreve
   `getIt<ProjectScope>().projectId = projectId` **antes** do `BlocProvider` (D2), e passa
   esse `projectId` ao `EditorCubit` e ao `GetProjectUseCase`. **A assinatura de `EditorPage`
   não muda** (D3).
3. **[paralela: não — dep. 1]** `project_detail_page.dart`: as **duas** chamadas
   `context.goNamed(EditorRoutes.editorName, …)` — `:169-172` (abrir conteúdo da lista) e
   `:387-390` (dentro de `_openContentForm`, ramo `if (editing == null)`: conteúdo
   recém-criado) — passam `pathParameters: {'projectId': …, 'id': content.id}`. O
   `projectId` já está em mãos na tela (é o `:id` da própria rota, e é o que ela já usa para
   carimbar o escopo em `:51`) — **não inventar fonte nova**, e em especial não ler o
   `ProjectScope` aqui.
4. **[paralela: não — dep. 2]** **A tela de falha (A3).** Widget novo em arquivo próprio,
   `presentation/editor/page/editor_load_failure_view.dart` (Gate 1 e Gate 3): recebe
   `failure` e `projectFuture` por construtor (D9), resolve o `Future` num `FutureBuilder`
   com indicador de carga enquanto pendente (D6), e aplica a matriz da **D7** — texto **e**
   ícone distintos (D8), espaçamento/cor/tipografia **só por token** (Gate 4). O
   `_messageFor` sai de `editor_page.dart` e passa a viver nesse arquivo. O branch
   `EditorLoadFailure` do `EditorPage.build` vira uma linha que monta o widget novo.
5. **[paralela: não — dep. 1-4]** **Varredura de call sites**, à mão e registrada na
   descrição do PR: `grep -rn "editorName\|'/contents/" apps/driva_editor/lib`. Todo hit ou
   passa os dois `pathParameters`, ou é a própria constante. **Isto não é opcional** — o
   compilador não ajuda (o nome da rota não mudou) e a suíte não cobre (§2.4).
6. **[paralela: não — por último]** `CHANGELOG.md` › `Unreleased`: a URL do editor mudou, o
   link antigo deixou de existir, a tela de falha passa a nomear o projeto. **No mesmo PR da
   mudança** (regra do projeto). `ERROR_LOGS.md`: a linha de `NotFoundFailure` registra que a
   UX passou a citar o escopo — **a semântica da falha não muda** (404 = inexistente **ou** de
   outro tenant).

**Frente B — ferramental e docs de gaveta** · `qa` · **[paralela: sim — arquivos disjuntos da frente A]**

7. **[paralela: sim]** Os **oito** arquivos de E2E vivos da tabela da **D11** passam a montar
   `/projects/<projectId>/contents/<id>/edit`. Nos três `.mjs` com helper, o diff é a linha do
   `editorUrl()`; nos dois inline (`04`, `02`) é a própria chamada; nos `.sh`, as URLs de
   `e2e_shots.sh:107,111` e os textos de `e2e.sh:163` e `e2e_foco.sh:95`.
   **O `e2e_shots.sh:111` (`/contents/nao-existe/edit`) é o crítico** — sem ele, aquele print
   passa a fotografar a home com legenda de tela de erro (D11).
8. **[paralela: não — dep. 7]** No `docs/24-…/e2e_drive.mjs`, **conferir passo a passo e não
   remover nada** (D11b): as linhas **339**, **378** e **508** abrem a lista que o próprio passo
   lê pelo `cardBadge()` e fotografa. A **453** também só troca de URL. O diff deste arquivo é
   a linha do `editorUrl()` (`:300`) e mais nada.
9. **[paralela: sim]** Os dois planos de gaveta que passam a mentir:
   `docs/plans/20-componente-construtor/plan.md:38` ("a rota **não muda**" — passa a ser
   falso) e `docs/plans/26-auth-multi-tenant/plan.md:228` (deep link do editor no fluxo de
   login). Ajuste de texto, nada de reescrever o plano.

**Aceites da F1** (o QA cobra na `revisar-fase`, antes do E2E):

| # | Critério |
| --- | --- |
| 1 | `EditorRoutes.editor == '/projects/:projectId/contents/:id/edit'`; `editorName` inalterado |
| 2 | O `pageBuilder` escreve o `ProjectScope` **antes** do `BlocProvider` (D2) — e a prova é o header da **primeira** requisição, não a leitura do código |
| 3 | As **duas** navegações de `project_detail_page.dart` passam os dois `pathParameters` |
| 4 | `app_router.dart` **não** recebe uma linha (D1: a rota já está registrada onde precisa) |
| 5 | `EditorPage` **não** ganhou parâmetro `projectId` (D3) — e os quatro testes da §2.5 continuam verdes |
| 6 | Nenhum dos **cinco leitores** da §2.3 aparece no diff |
| 7 | A tela de falha implementa a matriz da **D7** inteira, incluindo a terceira linha |
| 8 | A varredura de call sites (tarefa 5) está **na descrição do PR**, com o comando e a saída |
| 9 | `flutter analyze` verde; suíte existente passando |

---

### F2 — E2E manual em homologação, executado e atestado · **[dep. F1 mergeada em `develop`]** · **[`qa` instrumenta · dev humano atesta]**

Roteiro completo na **§10**. O QA automatiza o que der (skill `instrumentar-e2e`) num script
idempotente e auto-limpante; o que exige olho — as três telas serem **visualmente distintas**,
o link do diálogo "ver no celular" — fica para o humano.

Gate do CISO **antes** de instrumentar (a fase mexe em rota e em mensagem de erro: o que se
cobra ali é que nenhuma das mensagens novas vaze existência entre tenants — D7).

**A F2 é item do DoD, não apêndice.** Sem ela atestada, a feature não fecha e a F3 não começa.

---

### F3 — Bateria automatizada + docs vivas · **[dep. F2 atestada]** · **[`qa`]**

Por último, depois do E2E atestado (cap. 22 do livro). Testes:

| # | Teste | Prova |
| --- | --- | --- |
| 10 | Widget: montar a rota nova e inspecionar o **header da primeira requisição** | o item 2 dos aceites — o `ProjectScope` foi carimbado antes da carga (D2) |
| 11 | Widget: path param faltando → `InvalidContentScreen` | D5 (o caso que **não** vira passo de E2E) |
| 12 | Widget: `NotFoundFailure` + projeto resolvido → mensagem **cita o nome**; projeto não resolvido → a **outra** mensagem; projeto com falha de rede → a **terceira** | a matriz da D7 inteira |
| 13 | Navegação: os dois `goNamed` de `project_detail_page.dart` produzem a URL nova | o buraco do R1 (nada na suíte referencia a rota hoje) |
| 14 | Regressão: os quatro testes que montam `EditorPage` sem DI continuam passando | a cerca da D3 / `VR-16-02` |

Docs vivas (skill `manter-docs-vivas`): `final_report.md` do item 46 com o atestado do
humano e a data; varredura de texto nas docs que citam a rota antiga (`docs/08-…/plan.md`,
`docs/17-ergonomia-editor/plan.md`, `docs/24-…/final_report.md`) — **evidências de rodadas
passadas não se reescrevem**.

---

## 6. Ordem de PRs e precedências

```
F1  (1 PR, branch bugfix/46-projectid-na-rota-do-editor)
 └─> merge em develop  ->  auto-deploy em hml
      └─> F2  (E2E manual em hml, atestado pelo humano)
           └─> F3  (bateria + docs vivas, 1 PR)
```

- É **bugfix**, não feature: o bug está em desenvolvimento/hml, não publicado — branch de
  `develop`, PR para `develop` (skill `iniciar-bugfix`, `docs/GITFLOW.md`).
- **Não abrir F3 antes do atestado.** Escrever teste contra comportamento que o humano ainda
  não viu é o erro que o cap. 22 nomeia.
- Se um segundo PR ficar aberto ao mesmo tempo (a feature de appBar em curso), a regra é
  **pilha**, nunca dois PRs soltos contra `develop` (`docs/GITFLOW.md` §6).

---

## 7. Riscos

| # | Risco | Mitigação |
| --- | --- | --- |
| R1 | **Um call site de navegação passa despercebido e quebra em runtime.** `editorName` não muda → o compilador não ajuda; nenhum teste da suíte referencia a rota → a suíte verde não prova nada | Varredura obrigatória (F1›tarefa 5), com a saída **colada na descrição do PR**; gate de máquina §11.1›6; teste de navegação na F3›13 |
| R2 | **Os oito arquivos de E2E vivos passam a cair na home** e alguém perde uma hora achando que quebrou o app | D11 — atualizados na frente B, no mesmo PR. Registrado no CHANGELOG |
| R2e | **O `04_notfound` do `docs/02-conteudos/e2e_shots.sh:111` vira um print da home com legenda de tela de erro** — e o script continua "passando" | D11. É a mesma falha silenciosa que este item conserta, reproduzida na ferramenta; por isso está nomeado, não deixado para quem tropeçar |
| R2f | **Remover qualquer um dos `goto(projectUrl())` (339 / 378 / 508) do script do item 24** seguindo a lista do PRD e quebrar os passos 1, 5 e 15 daquele roteiro — os prints passariam a fotografar `about:blank` ou o editor | D11b (revista) — a lista do discovery está errada; a frente B conferiu passo a passo e **não removeu nada**. `cardBadge()` lê a tela, não a API |
| R2b | **Validar com `USE_FAKE_DATA: true`** e concluir que está tudo bem | D12, escrito no roteiro (§10›preparar) e cobrado no DoD §11.3›21 |
| R2c | **Validar no projeto `default`** e concluir que está tudo bem — ele esconde o bug por construção | D12; o roteiro exige o nome do projeto visível no print |
| R2d | Criar o conteúdo de teste em hml **sem categoria** e travar na criação (o projeto default de hml não tem a categoria "Geral") | §10›preparar: usar projeto ≠ `default` **e** escolher uma categoria existente ao criar |
| R3 | **`projectId` vira parâmetro obrigatório de `EditorPage`** "porque ficou mais limpo" e derruba quatro testes | D3 + aceite 5. É desvio, não julgamento local |
| R4 | A tela de falha **duplica o request** do projeto | D9 + gate §11.1›8 |
| R5 | A tela de falha **pisca** a mensagem errada antes de o projeto resolver, e o print mente | D6 + o print do passo 6/7 tirado com a tela estabilizada |
| R6 | **Docs passam a mentir** sobre a rota (dois planos de gaveta, `docs/08`, `docs/17`, `docs/24`, CHANGELOG) | Frente B›9 no PR; varredura de fechamento na F3 |
| R7 | **O singleton continua vivo e a próxima rota repete o erro** (A4›A é pontual) | D10 — cerca escrita e cobrada na `revisar-fase`. Débito estrutural apontado para o item 26 (§12) |
| R8 | O link antigo sumir sem aviso incomodar mais do que o previsto (A2›B foi contra a recomendação) | Fica registrado como decisão do dev (D4). Se doer, volta como item novo — **não** se corrige por conta própria dentro desta fase |

---

## 8. O que ainda precisa do humano

1. **Atestar o E2E da F2** — ninguém mais atesta E2E. Prints conferidos, atestado escrito no
   `final_report.md` com data.
2. **Aprovar qualquer desvio** das D1–D12 antes de ele existir no código, com registro em
   `variance_report.md` (`VR-46-NN`: como estava / por que mudou / o que mudou). O arquivo
   ainda não existe — nasce no primeiro desvio.

---

## 9. Divergências em relação ao recorte do PRD

| # | O PRD dizia | O plano faz | Por quê |
| --- | --- | --- | --- |
| 1 | F1 (rota) e F2 (tela de falha) como fases separadas | **uma fase, um PR** | A4 travou 1 PR, e a tela de falha é o que torna o E2E provável: sem ela, o primeiro PR não tem os dois modos de falha visualmente distintos que o DoD exige. O PRD já previa a fusão na nota do §"Recorte proposto" |
| 2 | A tela de falha com **duas** saídas (projeto existe / não existe) | **três** (D7) | A terceira é real: com o `projectFuture` falhando por rede, o app **não sabe** se o projeto existe. Afirmar que não existe seria repetir o bug |
| 3 | **Cinco** scripts de E2E vivos | **oito arquivos** (D11) | O inventário achou três `.sh` que a varredura do discovery não pegou — incluindo o `e2e_shots.sh:111`, que quebra em silêncio |
| 4 | Os `goto(projectUrl())` das linhas **339 / 378 / 508** ficam obsoletos (PRD›R2) | **nenhuma sai** (D11b, revista) | As três abrem os `step('1')`, `step('5')` e `step('15')` do roteiro do item 24. `cardBadge()` (`:230`) lê a árvore semântica da tela aberta, não a API — sem o `goto`, o passo leria `about:blank` ou o editor, daria FAIL e o print fotografaria a tela errada. O aquecimento do `ProjectScope` que elas faziam de quebra vira desnecessário depois da F1; a navegação, não |

Nenhuma delas altera decisão travada pelo humano — são detalhamento técnico, e ficam aqui
para o QA não acusar desvio.

---

## 10. Roteiro de E2E manual

**Em homologação** (`https://hml.driva.duckdns.org`), **nunca em `localhost`** — lição
permanente do item 9g. Tudo marcado **[olho]** é do humano.

> ⚠️ **Dois avisos que invalidam a rodada inteira se ignorados (D12).**
> 1. **Modo fake mascara o bug por completo.** Confirme na aba Network que há chamada real à
>    API antes do passo 1. Com `USE_FAKE_DATA: true` **todos** os passos passam e nada foi
>    provado.
> 2. **O projeto `default` esconde o bug por construção.** A rodada roda num projeto que não
>    é ele, e o nome do projeto tem de estar **legível no print**.

**Preparar:**

| Rótulo | O que | Para quê |
| --- | --- | --- |
| `PROJ_A` | Um projeto em hml que **não** é o `default` (criar se não houver) | todos os passos |
| `PROJ_B` | Um **segundo** projeto ≠ `default` e ≠ `PROJ_A` | passos 6 e 9 |
| `CT_A` | Um conteúdo dentro de `PROJ_A`, com **categoria existente** escolhida na criação | passos 1 a 6 |
| `CT_B` | Um conteúdo dentro de `PROJ_B` | passos 6 e 9 |
| `ID_FANTASMA` | Um `projectId` que não existe (ex.: `nao-existe-46`) | passo 7 |
| `ANONIMO` | Aba anônima — um navegador que **nunca** abriu a tela de projeto | passos 3 e 4 |

**Executar:**

| # | Passo | O que tem de acontecer | Print |
| --- | --- | --- | --- |
| 1 | Home → `PROJ_A` → abrir `CT_A` | a URL mostra **os dois ids**: `/projects/<PROJ_A>/contents/<CT_A>/edit` | `01_url_com_dois_ids.png` — barra de endereços legível |
| 2 | **F5** na mesma aba | o **mesmo conteúdo** volta; breadcrumb com o nome de `PROJ_A` | `02_reload_mesmo_conteudo.png` |
| 3 | Copiar a URL, colar em `ANONIMO` | abre o conteúdo **sem** passar pela tela do projeto; na aba Network, o `GET /v1/contents/<CT_A>` sai com `x-project-id: <PROJ_A>` **na primeira requisição** (D2) | `03_aba_anonima.png` + `03b_header_primeira_requisicao.png` |
| 4 | Na aba recarregada do passo 2, abrir **"ver no celular"** | o link/QR aponta para `/preview/<PROJ_A>/<CT_A>` — **hoje sairia `/preview/default/…` sem erro nenhum na tela** | `04_link_preview_projeto_certo.png` — a URL do diálogo legível **[olho]** |
| 4b | Abrir esse link no celular | o conteúdo aparece, não um 404 | `04b_preview_no_aparelho.jpg` |
| 5 | Ainda na aba recarregada: conferir o **breadcrumb** e clicar em **"Voltar para o projeto"** | os dois levam a `PROJ_A` — não ao `default` | `05_breadcrumb_e_volta.png` |
| 6 | Trocar o `:projectId` da URL de `CT_A` para `PROJ_B` (projeto **válido**) | mensagem **nomeando `PROJ_B`** ("não encontramos este conteúdo no projeto _\<PROJ_B\>_"), com saída | `06_falha_conteudo_fora_do_projeto.png` |
| 7 | Trocar o `:projectId` por `ID_FANTASMA` | mensagem **diferente** da do passo 6 ("este link aponta para um projeto que não existe"), com saída para a home | `07_falha_projeto_inexistente.png` |
| 8 | Abrir `https://hml…/contents/<CT_A>/edit` (formato antigo) | home de projetos, **sem** aviso dedicado (D4) | `08_link_antigo_home.png` |
| 9 | Na mesma aba: abrir `CT_A`, depois `CT_B`, e voltar pelo **histórico** do navegador | os **dois** carregam certo — o escopo é recarimbado a cada rota | `09a_ct_a.png`, `09b_ct_b.png`, `09c_volta_ct_a.png` |

**Os passos 6, 7 e 8 são os modos de falha** e precisam produzir telas **visualmente
distintas** entre si, da tela de carregamento e da tela de conteúdo carregado. **O passo 4 é
o modo silencioso** — o único que a evidência de hoje não cobriria, e onde o bug se esconde.

Evidência em `docs/46-projectid-na-rota-do-editor/evidencias/rodada_01/`, com um `README.md`
dizendo qual linha do DoD cada print prova.

---

## 11. Definition of Done

**A feature não está pronta enquanto o roteiro da §10 não tiver sido executado e atestado
pelo dev humano.** As três subseções abaixo são cumulativas: máquina, fase, E2E.

### 11.1 Cancela de máquina

| # | Item | Como se prova |
| --- | --- | --- |
| 1 | `flutter analyze` verde no workspace | saída do comando, zero issues, colada no PR |
| 2 | Suíte existente passando (`flutter test -r compact`) em `sdui_core`, `sdui_flutter` e `driva_editor` | saída no PR |
| 3 | **Zero linha em `packages/`** | `git diff --stat origin/develop -- packages/` = vazio |
| 4 | **Zero linha em `backend/`** | `git diff --stat origin/develop -- backend/` = vazio. _O 404 indistinguível é controle de segurança; nada aqui pede que ele mude_ |
| 5 | **Zero linha em `app_router.dart`** (D1) | `git diff --stat origin/develop -- apps/driva_editor/lib/app_router.dart` = vazio |
| 6 | **Nenhum call site da rota do editor ficou para trás** (R1) | `grep -rn "editorName\|'/contents/" apps/driva_editor/lib` — todo hit passa os dois `pathParameters` ou é a própria constante. Saída colada no PR |
| 7 | **A string da rota antiga não sobrevive em `lib/`** | `grep -rn "/contents/:id/edit" apps/driva_editor/lib` = **zero** |
| 8 | **Um `projectFuture` só** (D9) | `grep -rn "GetProjectUseCase" apps/driva_editor/lib/modules/editor_module` — exatamente **uma** invocação, no `pageBuilder` |
| 9 | **Só quatro escritores do `ProjectScope`** (D10) | `grep -rn "ProjectScope>().projectId =" apps/driva_editor/lib` → `injection.dart` + os `pageBuilder` de `project_detail`, `preview` e `editor`. Um quinto é desvio |
| 10 | **`EditorPage` não ganhou `projectId`** (D3) | leitura do diff: o construtor não mudou; e os quatro testes da §2.5 passam **sem DI** |
| 11 | **Os cinco leitores da §2.3 não aparecem no diff** | `git diff --stat` do PR: `editor_top_registrar.dart`, `editor_viewport_gate.dart`, `small_viewport_notice.dart` e `canvas_area.dart` ausentes |
| 12 | **Gate 1** — nenhuma função/método novo que retorna `Widget` | leitura do diff: a tela de falha é um `StatelessWidget` em arquivo próprio, não um `Widget _buildFailure(...)` |
| 13 | **Gate 3** — o widget novo mora em arquivo `snake_case` próprio | `presentation/editor/page/editor_load_failure_view.dart` existe |
| 14 | **Gate 4** — zero cor/espaçamento/tipografia crua nos arquivos tocados | `grep -nE "Color\(0x\|EdgeInsets\.\w+\(\s*[0-9]\|fontSize:" nos arquivos do diff = zero |
| 15 | **Zero comentário que descreve mecânica** nos arquivos tocados | leitura do diff: o que sobrar de comentário explica **porquê** (D1, D2, D3), não o que a linha faz |
| 16 | `CHANGELOG.md` › `Unreleased` atualizado **no mesmo PR** | seção presente no diff da F1 |
| 17 | CI verde — a mesma régua do humano | checks do GitHub |

### 11.2 Aceite por fase

| # | Item | Como se prova |
| --- | --- | --- |
| 18 | Os **9 critérios da F1** atestados | `revisar-fase` do QA no PR da F1 |
| 19 | Gate do CISO da F1 passado **antes** de instrumentar o E2E | parecer do CISO no PR — foco: nenhuma mensagem nova afirma ou sugere existência de conteúdo em outro tenant (D7) |
| 20 | Os **5 testes da F3** (itens 10 a 14 da §5›F3) escritos e verdes | saída da suíte no PR da F3 |
| 21 | Nenhum desvio das **D1–D12** sem `variance_report.md` aprovado **pelo humano** | desvios numerados `VR-46-NN`, com "como estava / por que mudou / o que mudou" |

### 11.3 E2E — faz parte do DoD, não é apêndice

| # | Item | Como se prova |
| --- | --- | --- |
| 22 | O roteiro da §10 executado **em homologação**, UI real | a URL `hml.driva.duckdns.org` aparece nos prints |
| 23 | A rodada correu **contra o backend real**, não em modo fake (D12›1) | a aba Network mostra chamada real à API no print `03b` |
| 24 | A rodada correu num projeto **≠ `default`** (D12›2) | o nome de `PROJ_A` está legível no breadcrumb dos prints 1, 2 e 5 |
| 25 | **QA instrumenta** o que der (skill `instrumentar-e2e`); o que exige olho fica para o humano | script em `docs/46-projectid-na-rota-do-editor/`, copiado para dentro da rodada |
| 26 | **O dev humano confere os prints e atesta** — ninguém mais atesta E2E | atestado escrito no `final_report.md`, com data |
| 27 | Evidência em `evidencias/rodada_01/`, prints nomeados como na §10, com `README.md` ligando print → linha do DoD | a pasta existe e nenhum print fica sem aceite associado |
| 28 | E2E reprovado → o tech-lead conserta e o QA abre `rodada_02`; a anterior **não é apagada** | histórico de rodadas |

### 11.4 A matriz que prova o que a feature promete — **não o caminho feliz**

Esta feature corrige uma falha que **mente** e uma que **não avisa**. Um E2E que só percorra
o caminho feliz não prova nada aqui.

| # | O que a feature promete | Print exigido | **Reprova se** |
| --- | --- | --- | --- |
| 29 | F5 no editor recarrega o mesmo conteúdo, em projeto ≠ `default` | `02` | qualquer mensagem de erro; ou o breadcrumb mostrar outro projeto |
| 30 | O link colado numa aba que nunca viu o app abre o conteúdo certo | `03` + `03b` | a home; a tela de erro; ou o header `x-project-id` sair `default` na **primeira** requisição |
| 31 | **O link "ver no celular" gerado após reload aponta para o projeto certo** _(o modo silencioso)_ | `04` (URL do diálogo legível) + `04b` (abre no aparelho) | a URL conter `/preview/default/`. **Este é o aceite que a evidência de hoje não cobre — sem ele, o item não fecha** |
| 32 | Breadcrumb e "Voltar para o projeto" levam ao projeto certo após reload | `05` | cair no `default` ou na home |
| 33 | Conteúdo inexistente **naquele** projeto → mensagem que **nomeia o projeto** | `06` | a mensagem seca "Conteúdo não encontrado."; ou a ausência do nome do projeto |
| 34 | Projeto inexistente → mensagem **diferente** da anterior | `07` | `07` e `06` mostrarem a **mesma** tela. _É a prova de que os dois modos de falha são distinguíveis — o coração da A3_ |
| 35 | As duas telas de falha se distinguem por **texto e ícone**, não só por cor (D8) | `06` e `07` lado a lado | a única diferença ser a matiz |
| 36 | Nenhuma das duas afirma ou sugere que o conteúdo existe em outro projeto | leitura de `06` e `07` **[olho]** + parecer do CISO | qualquer frase que insinue "achamos em outro lugar" |
| 37 | Link antigo → home, sem aviso dedicado (D4) | `08` | abrir o editor; tela em branco; ou uma tela de aviso que ninguém pediu |
| 38 | Alternar entre conteúdos de **dois projetos** na mesma aba funciona nos dois sentidos | `09a`, `09b`, `09c` | qualquer um dos três dar erro — seria o escopo não sendo recarimbado |

### 11.5 Fechamento

| # | Item | Como se prova |
| --- | --- | --- |
| 39 | `final_report.md` do item 46 escrito, com o atestado do humano e a data | o arquivo existe |
| 40 | Docs que citavam a rota antiga varridas — **`evidencias/` intocadas** | As 12 linhas do inventário: `docs/plans/20-…/plan.md:38`, `docs/plans/26-…/plan.md:228`, `docs/17-ergonomia-editor/plan.md:432,881,889,2854`, `docs/08-…/plan.md:22,91`, `docs/24-…/final_report.md:90`, `docs/02-conteudos/{plan.md:64, specs.md:28, prd.md:41, test_plan.md:59}`. Cada uma ou passa a citar a rota nova, ou fica marcada como registro histórico datado. **`CHANGELOG.md:161` não se reescreve** (é a entrega 02) — a mudança entra como linha nova em `Unreleased` |
| 41 | Os **oito** arquivos de E2E vivos atualizados (D11 + D11b) | `grep -rn "/contents/[^ )\`]*/edit" docs --include=*.mjs --include=*.sh` fora de `evidencias/` = **zero**; e `grep -c "goto(projectUrl())" docs/24-publicacao-versionamento/e2e_drive.mjs` = **3** (as linhas 339, 378 e 508 continuam lá) |
| 42 | `ERROR_LOGS.md` com a linha de `NotFoundFailure` registrando a UX nova | o arquivo mostra a mudança de apresentação, e **não** mudança de semântica |
| 43 | O item 46 marcado `[x]` no `docs/roadmap.md`, e o débito da A4 registrado apontando para o item 26 | linha do roadmap. _Nesta rodada o `roadmap.md` está sob edição de outro agente — a marcação entra no fechamento, não agora_ |
| 44 | Faxina de branches feita e **sessão nova recomendada** ao humano, com prompt de retomada | mensagem de fechamento |

---

## 12. Fora de escopo — débitos registrados

- **Matar o singleton `ProjectScope`** (A4›B): `projectId` como parâmetro explícito de
  repositório/use case, header saindo de valor passado adiante. Toca `data` e `domain` de
  todos os módulos, e o **item 26** (auth) vai remexer nessa camada de qualquer jeito — feito
  agora, é retrabalho garantido. **Débito vivo apontando para o item 26.**
- **`DEFAULT_PROJECT_ID` compilado no binário** (nos quatro flavors, produção incluída):
  "projeto padrão compilado" deixa de fazer sentido quando a auth chegar. Anotado para o
  item 26 — este item não o remove, só deixa de depender dele na rota do editor.
- **Auth / multi-tenant de verdade** — item 26. O `x-project-id` continua sendo o mecanismo
  (débito aceito no `VR-09`).
- **Mudança no 404 do backend** — controle de segurança, não defeito.
- **Persistir o último projeto visitado** (`localStorage`) — descartado na A1›D. Se voltar,
  volta como conveniência ("abrir onde parei"), nunca como fonte do escopo de uma rota.
- **Tratamento distinto para projeto arquivado** na URL (A3›C) — é assunto do item 9e. Se o
  comportamento divergir do herdado durante a rodada, é achado novo e vai para
  `variance_report.md`.
- **Reescrever evidências de rodadas passadas** — histórico não se reescreve (D11).
