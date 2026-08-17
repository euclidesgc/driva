# Specs — O `projectId` entra na rota do editor

> **Item 46 do roadmap** (Track contínuo). Bug pré-existente, descoberto pela validação do
> E2E do item 24 contra homologação em **2026-08-17** e registrado ali como fora de escopo.
>
> **Status desta spec: decisões A1–A4 travadas pelo humano em 2026-08-17.** Ver
> [Decisões do humano](#decisões-do-humano-que-sustentam-esta-spec) no fim do documento.
> Pronta para o `tech-lead` escrever o `plan.md`.

---

## O achado, como ele apareceu

Recarregar a página do editor — F5, colar a URL numa aba nova, abrir um link salvo — num
projeto que **não** é o `default` mostra **"Conteúdo não encontrado."**. O conteúdo existe.
A mensagem mente.

Quem tropeçou primeiro foi um driver de E2E: o roteiro do item 24 fazia `Page.navigate`
direto para a URL do editor, o app reiniciava, e o `GET` saía com o tenant errado. O
humano reproduz o mesmo bug sem driver nenhum: basta apertar F5.

**Só o projeto `default` escapa** — por coincidência, é ele o valor de fallback.

---

## Estado atual, levantado no código (2026-08-17)

### O `ProjectScope` inteiro cabe em dez linhas

`apps/driva_editor/lib/core/network/project_scope.dart` — um singleton **mutável, só em
memória**, com `projectId` público e um `reset()`. Sem `localStorage`, sem query param, sem
nada que sobreviva a um reload da aba.

**Registrado no DI** (`apps/driva_editor/lib/injection.dart`) como singleton, semeado com
`config.defaultProjectId` (`'default'` em dev/hml), e injetado no `createDio`.

**Quem escreve** (3 lugares):

| Onde | Quando | Sobrevive a reload? |
|---|---|---|
| `injection.dart` | no boot, com `AppConfig.defaultProjectId` | é o fallback — sempre roda |
| `contents_module/.../project_detail_page.dart:51` (`pageBuilder`) | ao abrir `/projects/:id` | sim, o `:id` está na URL |
| `editor_module/.../preview/preview_page.dart:38` (`pageBuilder`) | ao abrir `/preview/:projectId/:id` | sim, o `:projectId` está na URL |

**Quem lê** (2 lugares):

| Onde | Camada | Para quê |
|---|---|---|
| `core/network/dio_client.dart` (`createDio`) | infra | carimba o header `x-project-id` em **toda** requisição do editor |
| | | _O interceptor lê o `scope` **a cada request**, não na criação do client — por isso escrever o escopo no `pageBuilder`, antes de disparar a carga, basta. **Não há race a resolver**: é o que o `/preview` já faz._ |
| `editor_module/.../editor/editor_page.dart:72` (`pageBuilder`) | presentation | passa `projectId` ao `EditorCubit` e ao `GetProjectUseCase` |

### As rotas do app, e quais aguentam um reload

`apps/driva_editor/lib/app_router.dart` — rotas **planas**, duas irmãs do `ShellRoute`
(preview) e quatro dentro dele. **Não há `redirect` global hoje**; há um
`onException` que joga qualquer URL desconhecida na home de projetos.

| Rota | Escopo vem de | Reload-safe? |
|---|---|---|
| `/` (`projects`) | não usa escopo de projeto | sim |
| `/projects/archived` | idem | sim |
| `/projects/:id` (`project-detail`) | **escreve** o scope do path | sim |
| `/preview/:projectId/:id` | **escreve** o scope do path (D18 do item 41) | sim |
| `/contents/:id/edit` (`editor`) | **lê** o scope que outra tela escreveu | **NÃO — é o bug** |

**A rota do editor é o único buraco.** Não há segunda tela com a mesma doença.

### O precedente: como o `/preview` resolveu (item 41, F2)

Duas decisões travadas no `docs/17-ergonomia-editor/plan.md`:

- **D3** — o `projectId` vai no path (`/preview/:projectId/:id`), e a rota nasce **irmã** do
  `ShellRoute`, porque o preview não tem chrome.
- **D18** — _"o `projectId` no path sozinho **não basta**"_: o header `x-project-id` sai do
  interceptor do Dio, que lê o `ProjectScope`. Então o `pageBuilder` **carimba o
  `ProjectScope` com o path param antes de montar o cubit**, para a primeira requisição já
  sair certa. E o aceite disso _"não é ler o `pageBuilder`"_ — é o print tirado num aparelho
  que nunca abriu o editor.

O código de `preview_page.dart` faz exatamente isso: valida os dois path params (tela
`InvalidPreviewScreen` quando falta um), escreve `getIt<ProjectScope>().projectId`, e só
então monta o `BlocProvider`. **É o padrão a replicar, não a reinventar.**

### A limitação já estava escrita — como fora de escopo

A **D24** do item 41 registrou o problema com todas as letras e o deixou de fora:

> _"um **deep link do editor aberto frio** (alguém compartilha `/contents/:id/edit` e o
> aparelho nunca passou pela tela do projeto) cai no `DEFAULT_PROJECT_ID` do build (…)
> **Isso já é verdade hoje** (…) É a família da D18 e do item 26, e está fora (§12)."_

O item 46 é o item que traz isso para dentro. Não é regressão de nada: é dívida datada
sendo paga.

### De onde vem a mensagem enganosa

`editor_module/.../editor/editor_page.dart:175` mapeia `NotFoundFailure()` →
`'Conteúdo não encontrado.'`.

E a `NotFoundFailure` **não distingue** os dois casos — o `ERROR_LOGS.md` já documenta isso
como comportamento pretendido: _"404 (conteúdo inexistente **ou de outro tenant**)"_. O
backend responde 404 para conteúdo de outro projeto **de propósito** (não vazar existência
entre tenants), e isso **não se toca**: pedir ao backend que diferencie seria regressão de
segurança, reprovada no gate do CISO.

Consequência para o produto: mesmo com a rota corrigida, um `projectId` errado **na própria
URL** (link de colega de outro tenant, projeto arquivado, id editado à mão) continuará
produzindo 404. O que o editor pode fazer é **dizer com que escopo tentou** — nunca afirmar
qual dos dois motivos foi.

### Quem aponta para a rota do editor hoje

- **Navegação no app** — `contents_module/.../project_detail/project_detail_page.dart`,
  duas chamadas `context.goNamed(EditorRoutes.editorName, …)` (abrir conteúdo da lista;
  criar conteúdo e cair no editor). São os dois pontos que passam a precisar do
  `projectId` no `pathParameters` — e os dois já o têm em mãos (é a tela do projeto).
- **Nenhum teste da suíte.** `apps/driva_editor/test/**` não referencia `EditorRoutes`,
  `appRoutes`, `ProjectScope` nem `/contents/` — zero ocorrências. **A suíte verde não prova
  nada aqui**, e é por isso que o teste de navegação entra como item de aceite.
- **Cerca herdada (D19 do item 41):** os 8 testes que constroem `EditorCubit` já passam
  `projectId: 'p1'` pelo construtor e continuam passando — **desde que o `projectId` não vire
  parâmetro obrigatório de `EditorPage`**. Se virar, caem quatro
  (`editor_page_layout_controller_test.dart`, `editor_perf_test.dart`,
  `page/editor_workspace_test.dart`, `widgets/canvas_panel_golden_test.dart`), exatamente os
  que a D19 protegeu e o `VR-16-02` já derrubou uma vez. **O `projectId` fica no cubit.**
- **Cinco scripts de E2E ativos** montam a URL na unha:
  `docs/24-publicacao-versionamento/e2e_drive.mjs:300` (o que expôs o bug — e os
  `goto(projectUrl())` das linhas 339/378/508, que existiam só para reaquecer o escopo,
  ficam obsoletos), `docs/15-destravar-construtor/e2e_drive.mjs:231`,
  `docs/16-image-url-e-props/e2e_drive.mjs:229`, `docs/04-foco-inspector/e2e_drive_foco.mjs:71`
  (+ `e2e_foco.sh:95`), `docs/02-conteudos/e2e_drive.mjs:89` (+ `e2e_shots.sh`, `e2e.sh`).
  As cópias em `evidencias/rodada_NN/` são histórico congelado e **não** se reescrevem. Os
  `e2e_hml.sh` usam só `$API_BASE` — sem impacto.
- **Infra: nada a mudar.** `deploy/nginx.conf` já faz `try_files … /index.html` genérico,
  `bootstrap.dart` usa `usePathUrlStrategy()`, e o seletor de manifest do `web/index.html`
  chaveia por `startsWith('/preview')` — uma rota sob `/projects/…` continua no escopo `/`.
- **Planos de gaveta que citam a rota antiga** e vão precisar de um ajuste de texto:
  `docs/plans/20-componente-construtor/plan.md:38` (afirma _"a rota **não muda**"_ — passa a
  ser falso) e `docs/plans/26-auth-multi-tenant/plan.md:228` (o deep link que volta depois
  do login).
- **Bookmarks e histórico do navegador do próprio dev** — não inventariáveis, tratados pela
  decisão **A2**.

### O bug é maior do que o relato: há um modo **silencioso**

O relato do roadmap fala de uma mensagem enganosa. O discovery técnico achou o mesmo defeito
produzindo **nenhuma** mensagem:

> **`canvas_area.dart:82` monta a URL compartilhável do preview** com o `cubit.projectId` —
> o valor contaminado. Depois de um reload frio, o diálogo "ver no celular" entrega
> `/preview/default/<id>`. **A tela não acusa nada.** O usuário copia o link, manda para o
> celular ou para outra pessoa, e o erro só aparece do outro lado.

Isso reclassifica o item: não é "o editor mostra a mensagem errada", é **"o editor produz
dado errado sem avisar"** — e é o caso que o E2E precisa provar, porque é o que a evidência
atual não cobre.

### Ganho colateral que a correção traz de graça

Com o `projectId` na URL, o `projectFuture` do `EditorPage` (`GetProjectUseCase(projectId)`)
passa a resolver o projeto **certo** num reload — hoje ele resolve o `default`.

Isso conserta de carona **três sintomas do mesmo bug** que ninguém tinha ligado a ele:

- **A migalha do projeto no topo do editor.** `editor_top_registrar.dart:97-101` monta o
  `Crumb` com `pathParameters: {'id': cubit.projectId}` — o valor que veio do `ProjectScope`.
  Num reload, hoje, essa migalha mostra e **navega para o projeto errado**.
- **O botão de escape da própria tela de erro.** `editor_page.dart:139-145` monta
  _"Voltar para o projeto"_ com `pathParameters: {'id': cubit.projectId}` — o mesmo valor
  contaminado. Hoje, no reload, o usuário lê uma mensagem falsa **e** o único botão da tela
  o joga no projeto errado. É o buraco mais fundo do bug, e some junto com a causa.
- **Os dois botões do portão mobile** (F1b do item 41), pela mesma razão — exatamente o que
  a D24 previu e deixou fora.

Ao todo são **cinco leitores indiretos** do valor contaminado, todos via `EditorCubit.projectId`:
`editor_page.dart:142`, `editor_top_registrar.dart:100`, `editor_viewport_gate.dart:29`
(→ `small_viewport_notice.dart:75,93`) e `canvas_area.dart:82`. Nenhum deles muda de código
com a correção — todos passam a receber o valor certo.

### Duas armadilhas de validação (o E2E precisa saber disto)

- **`FakeContentsStore` não é escopado por projeto** (`core/dev/fake_contents_store.dart:30-36`).
  Com `useFakeData: true`, o bug **desaparece**. Validar só com fake é validar nada.
- **O projeto `default` esconde o bug por construção.** O roteiro tem de rodar num projeto
  que não seja ele, em **hml** — a mesma lição do item 9g.

### O que o backend faz com o header (mais estreito do que parece)

| Endpoint | Usa o `x-project-id`? |
|---|---|
| `/v1/contents/*` | **Sim** — `findContentOrThrow({id, projectId})` → 404 |
| `/v1/categories/*` | **Sim** |
| `/v1/projects` (lista) | **Não** — o service recebe e ignora |
| `/v1/projects/:id` | **Não** — resolve por path |

Duas consequências: a home é reload-safe por acidente feliz (não porque alguém cuidou), e
**dá para saber se o projeto da URL existe sem inventar endpoint** — o que muda a A3.

---

## O que **não** se reabre nesta spec

- **O 404 do backend continua indistinguível entre tenants.** É controle de segurança, não
  defeito. Nada aqui pede mudança em `backend/`.
- **O `x-project-id` como mecanismo de tenant** é débito conhecido e vira o **item 26**
  (auth). Esta spec não antecipa auth.
- **O padrão do `pageBuilder` carimbar o `ProjectScope`** (D18) está validado em produção e
  é o alicerce da correção.

---

## Decisões do humano

### A1 — Qual é o formato da rota nova? → **Decidido: opção A**

| Opção | Rota | O que ganha | O que custa |
|---|---|---|---|
| **A** _(recomendada)_ | `/projects/:projectId/contents/:id/edit` | Hierarquia que já existe no app (`/projects/:id` é a tela-mãe do conteúdo); a URL conta a verdade do recurso; casa com o breadcrumb | URL longa; é o maior diff nos scripts de E2E |
| **B** | `/editor/:projectId/:id` | Simetria literal com `/preview/:projectId/:id`; URL curta; um só nível | Abandona o vocabulário `/contents/…` que a API e a UI usam; "editor" vira substantivo de rota sem par no resto do app |
| **C** | `/contents/:id/edit?project=<id>` | Link antigo continua **abrindo** (degrada para o comportamento de hoje); menor diff | Query param é dado acessório, não identidade — o padrão do projeto (D3) é path; some se alguém aparar a URL; mantém a armadilha viva para quem copiar a URL sem a query |
| **D** | Rota inalterada + `projectId` em `localStorage` | Diff mínimo; F5 no mesmo navegador funciona | **Não conserta o link compartilhado** (a máquina do outro tem outro `localStorage`); cria segunda fonte de verdade; duas abas em projetos diferentes brigam pelo mesmo valor. **Descartar** — está aqui só para não voltar como sugestão |

**Decidido: A.** A URL do editor passa a ser a mesma verdade que a do preview: quem abre o
link abre o conteúdo certo, venha de onde vier. É também a única opção que sobrevive ao
item 26 sem retrabalho (a auth vai querer autorizar por projeto, e o projeto precisa estar
na URL antes do login).

_Nota técnica, já resolvida pelo tech-lead — **não é decisão do dev**:_ a rota nasce **plana,
com o path completo, dentro do `ShellRoute`** (o mesmo desenho do `/preview/:projectId/:id`),
**não** aninhada sob `/projects/:id`. Aninhar faria o go_router montar a pilha inteira — o
`ProjectDetailPage` construído por baixo do editor a cada abertura, disparando
`CategoryTreeCubit.load()` + `ContentListCubit.load()` de graça — e colidiria o nome do param
(`:id` já é o projeto lá). Não há conflito de ordenação: cinco segmentos não casam com
`/projects/:id` nem com `/projects/archived`. **"Voltar" e breadcrumb não mudam uma linha** —
já navegam por `goNamed(projectDetailName, {'id': cubit.projectId})`; o que muda é o valor
passar a estar certo.

### A2 — O que acontece com os links antigos (`/contents/:id/edit`)? → **Decidido: opção B**

O ponto de partida honesto: **hoje esse link já está quebrado** para todo projeto que não
seja o `default` — é literalmente o bug. A pergunta é o que ele passa a fazer.

| Opção | Comportamento | O que ganha | O que custa |
|---|---|---|---|
| **A** _(recomendada)_ | Rota legada mantida, redireciona para a **home de projetos** com um aviso explícito ("este link é de um formato antigo e não diz de que projeto é o conteúdo — escolha o projeto") | Nunca abre a tela errada nem mente; zero backend; o usuário tem um caminho de saída | Uma tela/aviso a construir e a provar no E2E |
| **B** | Rota removida — cai no `onException` e vai para a home **sem explicação** | Diff mínimo | O usuário vê a home sem entender por quê; indistinguível de um clique errado |
| **C** | Rota legada mantida com o comportamento de hoje (fallback ao `ProjectScope`) | Link antigo abre quando o scope está quente | **Preserva o bug** para o caso que originou o item |
| **D** | Redirect resolvido no servidor (endpoint que descobre o projeto de um `contentId`) | Link antigo funciona de verdade | **Não existe endpoint assim, e criá-lo é o oposto do que o backend protege**: `findContentOrThrow` exige `projectId`, e devolver "este conteúdo mora no projeto X" é exatamente o dado cross-tenant que o 404 esconde. Gate do CISO garantido, e provavelmente reprovado |

**Um redirect de verdade é tecnicamente impossível** (A2›D): o cliente não tem como
descobrir o projeto a partir do id do conteúdo. Sobram avisar (A) ou sumir (B).

**Decidido: B**, contra a recomendação do PM/tech-lead (que era **A**, avisar antes de
mandar para a home — _remover a rota reproduz o pecado do próprio bug: falhar sem
explicar_). O dev escolheu a opção mais barata: o inventário de links antigos salvos é
~zero (produto com um usuário e uma hml). A rota antiga simplesmente **não é registrada**
no novo formato — cai no `onException` já existente, que manda para a home. Nenhum código
novo de aviso.

### A3 — O item conserta só a rota, ou também a tela de falha? → **Decidido: opção B**

Mesmo com a rota certa, `projectId` errado **na URL** continua dando 404 com "Conteúdo não
encontrado." — e o 404 do backend segue indistinguível de propósito.

**O que o discovery mudou nesta pergunta:** dá para separar os dois casos **sem request novo
e sem tocar no backend**. O `pageBuilder` já busca o projeto (`editor_page.dart:88`) por um
endpoint que **não** é escopado pelo header, e hoje o branch de falha simplesmente ignora
esse resultado. Ligando um ao outro:

- projeto da URL **não existe** → "este link aponta para um projeto que não existe";
- projeto existe, conteúdo 404 → "este conteúdo não existe **no projeto _<Nome>_**".

Nenhuma das duas afirma nada sobre outros tenants — a fronteira de segurança fica intacta.

| Opção | Escopo | O que ganha | O que custa |
|---|---|---|---|
| **A** | Só a rota | O menor diff possível; fecha o bug relatado | O modo de falha continua mentindo quando a URL está errada; o E2E do DoD prova pouco |
| **B** _(recomendada)_ | Rota + a tela de falha usa o `projectFuture` que **já é buscado** para dar as duas mensagens acima + botão de saída | O erro para de mentir; dois modos de falha **visualmente distintos** para o E2E provar (regra do DoD para feature que corrige falha silenciosa); custo baixo porque o dado já está na mão | Alguns widgets a mais no mesmo PR |
| **C** | B + tratamento distinto para projeto **arquivado** | Cobertura completa | Puxa comportamento de projeto arquivado, que é assunto do item 9e; escopo crescendo sem relato que o justifique |

**Decidido: B.** É o mínimo que transforma "mensagem enganosa" — as palavras do próprio item
no roadmap — em algo verdadeiro, e o discovery mostrou que custa menos do que parecia. **A**
conserta a causa e deixa o sintoma.

### A4 — Correção pontual ou estrutural? → **Decidido: opção A**

| Opção | O que é | O que ganha | O que custa |
|---|---|---|---|
| **A** _(recomendada)_ | A rota carrega o `projectId`, o `pageBuilder` carimba o `ProjectScope` — padrão D18, singleton continua existindo | Barato, consistente com o precedente, uma fase | O singleton mutável continua lá; a próxima rota que alguém criar pode repetir o erro |
| **B** | Matar o singleton mutável: `projectId` vira parâmetro explícito de repositório/use case, o header sai de um valor passado adiante | A classe de bug morre de vez; testabilidade melhora | Toca `data` e `domain` de **todos** os módulos; várias fases; e o item **26** (auth) vai remexer nessa camada de qualquer jeito — feito agora, é retrabalho garantido |

**Decidido: A**, com **B registrado como débito vivo** apontando para o item 26. Junto,
uma cerca barata que evita a repetição: **toda rota nova que dependa de escopo de projeto
carrega o `projectId` no path** — regra escrita no `plan.md`, cobrada na revisão de fase.

### A5 — Confirmação de processo (não bloqueia)

A doc viva nasceu em **`docs/46-projectid-na-rota-do-editor/`**, numerada pelo **item do
roadmap**, e não pelo próximo sequencial livre (`18`). Dois motivos: o item 24 já abriu esse
precedente (`docs/24-publicacao-versionamento/`), e `18` está semanticamente **reservado**
pelo item 18 do roadmap, que existe e está aberto (`docs/plans/18-pull-to-refresh/`) — usar
`18` aqui criaria colisão na hora em que aquele item for executado. Renomear é um `git mv`
se o dev preferir o outro critério.

---

## Fora de escopo (declarado, para não voltar como surpresa)

- **Auth / multi-tenant de verdade** — item 26. O `x-project-id` continua sendo o mecanismo.
- **Mudança no 404 do backend** — controle de segurança, ver acima.
- **Persistir o último projeto visitado** (`localStorage`) — descartado na A1›D; se voltar,
  volta como conveniência ("abrir onde parei"), nunca como fonte do escopo de uma rota.
- **Editar SDUI no celular** — D20 do item 41, segue valendo.
- **Reescrever as evidências de rodadas passadas** (`docs/*/evidencias/rodada_NN/`) — são
  registro histórico do que foi executado naquele dia; não se reescreve histórico. Os
  scripts vivos que forem re-executados é que se atualizam.

---

## Decisões do humano que sustentam esta spec

| # | Decisão | Data |
|---|---|---|
| A1 | Rota `/projects/:projectId/contents/:id/edit` (opção A, recomendação seguida) | 2026-08-17 |
| A2 | Link antigo remove a rota — cai no `onException` padrão, home sem aviso dedicado (opção B, **contra** a recomendação, que era avisar) | 2026-08-17 |
| A3 | Inclui a tela de falha — distingue projeto inexistente de conteúdo inexistente no projeto (opção B, recomendação seguida) | 2026-08-17 |
| A4 | Correção pontual, 1 PR, padrão D18 (opção A, recomendação seguida); matar o singleton `ProjectScope` fica como débito vivo para o item 26 | 2026-08-17 |

## Decisões herdadas (não reabertas)

| # | De onde | O que diz |
|---|---|---|
| D3 (item 41) | `docs/17-ergonomia-editor/plan.md` | `projectId` vai no **path**, não em estado de memória |
| D18 (item 41) | idem | o `pageBuilder` carimba o `ProjectScope` a partir do path param, **antes** de montar o cubit |
| D24 (item 41) | idem | o deep link frio do editor é limitação conhecida, herdada, fora daquele escopo — **este item a paga** |
| VR-09 / débito auth | `docs/09-crud-projeto/variance_report.md` | `x-project-id` é aceito até o item 26 |
