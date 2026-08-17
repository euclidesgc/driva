# CISO review — item 46, F1 (apresentação)

**Gate:** revisão de fase (junto ao QA), branch `bugfix/46-projectid-na-rota-do-editor`,
commits `ab5f304` (apresentação) + `3e1b7e6` (E2E) + `33e7f0d` (docs). Repo consolidado,
sem staged/unstaged pendente.

**Calibragem.** Tela interna do editor (uso autenticado só por quem já opera o produto,
sem cadastro de usuário externo), mas mexe em roteamento de escopo de tenant — não é
fluxo de publicação/serving. Apliquei cadência **moderada**: li o diff completo das três
frentes (`editor_routes.dart`, `editor_page.dart`, `editor_load_failure_view.dart` novo,
`project_detail_page.dart`, `canvas_area.dart` via `cubit.projectId`), e cruzei contra o
backend (`projects.controller.ts`/`.service.ts`, `contents.controller.ts`/`.service.ts`)
para confirmar escopo real, não só o que o front assume. Não fiz auditoria completa do
modelo de auth — isso é o item 26, já registrado.

## Achados

Nenhum bloqueante. Um achado informativo, sem ação nesta fase.

**INFO — a tela de falha do editor passa a nomear o projeto num 404 cross-tenant, mas
não abre porta nova.** `EditorLoadFailureView._notFoundDisplayFor` (linhas 115–140 de
`editor_load_failure_view.dart`) cruza o `NotFoundFailure` do conteúdo com o
`projectFuture` e, quando o projeto existe mas o conteúdo não está nele, mostra
`Não encontramos este conteúdo no projeto "${project.title}"` — antes a mensagem era
genérica (`Conteúdo não encontrado.`). Verifiquei se isso é superfície nova:

- `GET /v1/projects/:id` (`projects.controller.ts:63-66` → `projects.service.ts:106-113`)
  **não tem nenhum escopo por tenant** — devolve título de qualquer projeto para
  qualquer chamador, sem checar `x-project-id`. Isso já é assim hoje, e já era chamado
  por este mesmo `GetProjectUseCase` antes da F1 (o `projectFuture` já existia,
  consumido pelo `EditorWorkspace`; a F1 só trocou a origem do `projectId` que o
  alimenta, não introduziu a chamada).
- `GET /v1/projects` (list, `projects.service.ts:52-59`) também é global — ignora o
  `x-project-id` recebido e devolve todos os projetos. Ou seja, o título de qualquer
  projeto já está a um clique (ou a um `curl`) de distância, com ou sem esta fase.
- O `ProjectDetailPage` já navega com `projectId` na URL (`pathParameters: {'id': ...}`,
  `getIt<ProjectScope>().projectId = id` na linha 51) desde antes do item 46 — o oráculo
  "projeto existe vs. não existe" já era alcançável ali.

Ou seja: a mudança **não abre** superfície — ela só reflete, na tela de erro do editor,
uma leitura que já era 100% pública em duas rotas existentes. A causa raiz (projeto sem
qualquer escopo de acesso, `x-project-id` como única "credencial" e forjável por
qualquer cliente) é exatamente o débito do item 26 — não repito o registro, só confirmo
que a F1 não o piora nem cria um caminho novo até ele.

Sobre o oráculo de conteúdo entre tenants (a pergunta específica do ângulo 2): **não
existe.** `findContentOrThrow` no backend (`contents.service.ts`, usado por `find`,
`update`, `remove`, `publish` etc.) sempre filtra por `{ id, projectId }` — um
`contentId` que existe em outro projeto responde `404` idêntico a um `contentId` que não
existe em lugar nenhum. A tela de falha do editor não teria como diferenciar os dois
casos mesmo se quisesse; ela só decide a mensagem a partir do resultado do
`projectFuture` (existe/não existe o *projeto*), nunca do conteúdo.

## Ângulo 3 — link de preview (`canvas_area.dart`)

Sem regressão. `canvas_area.dart` não foi tocado no diff — ele monta a URL com
`cubit.projectId` (linha 82), e `cubit.projectId` vem do `projectId` local do
`pageBuilder`, que agora é `state.pathParameters['projectId']` em vez do singleton
`ProjectScope`. A correção do bug de rota propaga para o link compartilhável
automaticamente, sem precisar editar `canvas_area.dart`: o link de preview sai com o
mesmo `projectId` que efetivamente carregou o conteúdo (o mesmo usado para escopar a
consulta no backend), nunca com `'default'` nem com um projeto para o qual o usuário não
navegou.

## Ângulo 1 — resposta direta

**Não abre superfície nova; torna explícito um acesso que já era possível.** Antes, o
`x-project-id` vinha de um singleton em memória que só ficava "certo" enquanto a SPA não
recarregava — o valor era tão forjável quanto agora (bastava editar o header via
devtools/curl, ou, dentro da própria SPA, navegar para o projeto alvo primeiro, já que
`GET /v1/projects` lista tudo sem escopo). O item 46 troca a fonte do `projectId` de "o
que sobrou na memória" para "o que está na URL" — mesma ausência de autorização real dos
dois lados, só que agora visível e não mais um bug de UX. Nenhuma checagem de posse foi
removida (não havia nenhuma para remover).

## Outras checagens da régua (sem achado)

- Sem log de dado sensível: nenhum `print`/`debugPrint`/logger novo nos arquivos do diff.
- Sem segredo hardcoded, sem mudança em `--dart-define`/config.
- Sem mudança de CORS ou de escopo de backend (backend/src sem diff nesta fase).
- Sem dependência nova em pubspec.yaml.
- Sem instrumentação de teste no código de produção — os arquivos tocados por `3e1b7e6`
  são só `docs/**/e2e*.sh`/`.mjs` (ferramental de E2E, não compilado no app).
- `EditorPage.pageBuilder`: guarda de `projectId`/`id` vazios/nulos antes de tocar
  `ProjectScope` ou montar o cubit (`InvalidContentScreen`) — sem mutação de estado
  global no caminho inválido.

## Veredito

**Gate liberado.** Conferi: escopo de tenant do novo roteamento, as três saídas da tela
de falha contra vazamento cross-tenant (incluindo checagem direta do `contents.service.ts`
para o oráculo de existência), e o link de preview em `canvas_area.dart`. Nenhuma
correção obrigatória antes do PR. O achado INFO fica registrado aqui só como
rastreabilidade — não é ação nova, é reafirmação de que o item 26 continua sendo o
dono do gap.
