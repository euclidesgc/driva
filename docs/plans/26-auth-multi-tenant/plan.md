# plan.md — Item 26: Autenticação e multi-tenant real

> Documento de planejamento. Dono na execução: **tech-lead** + **especialista-infra**. Base: `docs/roadmap.md` › Marco 6.
> Regra do "pronto": **`flutter analyze` verde + `pnpm build`/`pnpm lint` verdes + testes existentes passando**.
> **Gate CISO é o dono desta feature**, não um revisor de fim de fase. Nenhuma fase mergeia sem ele.
> Origem: débito aceito por decisão do humano em 2026-07-09 (`docs/09-crud-projeto/variance_report.md` › _Auth_), com o limite registrado: **"auth entra como feature antes de abrir para usuários reais em produção"**.

## 1. Objetivo e recorte

Hoje o "auth" do driva é isto, repetido em cada controller:

```ts
const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';
```

Ou seja: **quem manda o header manda no projeto**. Qualquer pessoa com a URL da API e um id de projeto lê, edita, arquiva e apaga tudo — e, depois do item 25, também pega a chave publicável. Não há usuário, não há dono, não há registro de quem fez o quê (o `ContentVersion.createdBy` do item 24 nasceu nullable esperando esta feature).

**Entra:**
1. `User` + `Membership` (usuário ↔ projeto, com papel).
2. Login/refresh/logout/me, com **access token curto em memória** e **refresh em cookie httpOnly**.
3. Guard global no backend: tudo protegido por default; `@Public()` explícito para health e para a rota pública do item 25.
4. O tenant deixa de ser confiança cega no header: `x-project-id` continua **selecionando** o projeto, mas o guard **valida a membership** antes de qualquer service rodar.
5. `auth_module` no editor: tela de login, store de token, interceptor com refresh automático, redirect de rota.
6. Preenchimento do `createdBy` das versões (item 24) e proteção do `rotate-key` (item 25) por papel.

**Fica fora:** cadastro público/self-service, convite por e-mail, SSO/OAuth, recuperação de senha por e-mail (fica um reset administrativo), auditoria completa (só o `createdBy` das versões) e permissão por conteúdo (o papel é por projeto).

## 2. Precedências e mapa do estrago (levantado em 2026-08-13)

**O `projectOf` aparece em três controllers** — todos mudam:
- `backend/src/contents/contents.controller.ts` (linhas 18–19) — 5 rotas.
- `backend/src/categories/categories.controller.ts` (linha 48 e vizinhas) — 4 rotas.
- `backend/src/projects/projects.controller.ts` (linhas 27–28) — lista/CRUD/arquivar/upload.

**O editor manda o header em um lugar só** — `apps/driva_editor/lib/core/network/dio_client.dart:23`, via interceptor que lê o `ProjectScope`. Isso é sorte boa: o token entra no **mesmo** interceptor, e nenhum repositório precisa saber de auth.

| O que já existe | Onde | Uso aqui |
| --- | --- | --- |
| `ProjectScope { String projectId; reset() }` singleton | `core/network/project_scope.dart` | Continua existindo; passa a ser **preenchido pelo login** e validado pelo servidor. |
| `createDio(config, scope)` com `InterceptorsWrapper.onRequest` | `core/network/dio_client.dart` | Ganha `Authorization` + o interceptor de refresh (`onError`). |
| `setupInjection(config, prefs)` registrando `AppConfig`, `ProjectScope`, `Dio` e os módulos | `lib/injection.dart` | Registra o `auth_module` **antes** dos demais (o `Dio` passa a depender do token store). |
| `bootstrap(config)` com `SharedPreferences` pré-carregado e `runZonedGuarded` | `lib/bootstrap.dart` | Onde a sessão é restaurada antes do primeiro frame. |
| `appRoutes` (go_router) com `ShellRoute` e `rootNavigatorKey` | `lib/app_router.dart` | Ganha `redirect` para `/login` e a rota de login **fora** do `ShellRoute`. |
| `@nestjs/throttler` já instalado e usado (`ProjectsController`) | `backend/src/projects/projects.controller.ts:20` | Rate limit no `/auth/login` sai de graça — **não instalar nada**. |
| `preferences_module` (padrão de módulo com persistência local) | `modules/preferences_module/` | Gabarito do módulo pequeno com `data/repositories` + `shared_preferences`. |
| `ContentVersion.createdBy String?` (item 24) | schema | Passa a ser preenchido. |
| `Project.publishableKey` + `rotate-key` (item 25) | schema/controller | Passa a exigir papel `owner`. |

## 3. Decisões de design travadas

**D1 — Access token em memória, refresh em cookie httpOnly.**
- Access JWT, TTL 15 min, guardado **só em memória** no editor (`AuthTokenStore`, um singleton com um `String?`). **Nunca** em `localStorage`/`shared_preferences` — é a diferença entre "XSS incomoda" e "XSS rouba a conta".
- Refresh token opaco (random 32 bytes, hash no banco), TTL 30 dias, em **cookie httpOnly + Secure + SameSite=Lax**, emitido por `/v1/auth/login` e trocado em `/v1/auth/refresh`.
- Consequência obrigatória: `enableCors({credentials: true, origin: [...lista explícita...]})` — **`origin: '*'` deixa de ser possível** junto com credentials. A lista `CORS_ORIGINS` já existe no `main.ts` e passa a ser obrigatória em produção.
- Consequência 2: rotação de refresh a cada uso (o antigo é invalidado) — detecta roubo por reuso.

**D2 — Guard global, `@Public()` explícito.**
`APP_GUARD` com `JwtAuthGuard`. Tudo nasce protegido; abrir é ato deliberado com decorator. O contrário (proteger rota a rota) é como se esquece uma. **`@Public()` vai em exatamente três lugares:** `health.controller.ts`, `src/public/*` (item 25) e `auth.controller.ts` (login/refresh).

**D3 — O tenant continua vindo do header, mas agora é verificado.**
Um `ProjectMemberGuard` roda depois do `JwtAuthGuard` nas rotas escopadas: lê `x-project-id`, procura `Membership(userId, projectId)`; sem membership → **404** (não 403 — não revelamos que o projeto existe). Os **services não mudam**: continuam recebendo `projectId: string` como primeiro parâmetro.
> Este é o ponto que faz a feature caber: sem ele, `ContentsService`, `CategoriesService` e `ProjectsService` teriam que ser reescritos. Com ele, mudam só os controllers.

**D4 — `GET /v1/projects` deixa de ser escopado por header e passa a listar as memberships do usuário.**
Hoje `ProjectsController.list` recebe `projectOf(header)` — o que nunca fez sentido para uma **lista de projetos**. Passa a ser "os projetos em que eu sou membro". É a única mudança de semântica de endpoint existente, e é a correta.

**D5 — Papéis: `owner`, `editor`, `viewer`.**
- `owner`: tudo, incluindo arquivar/excluir projeto, gerenciar membros e `rotate-key`.
- `editor`: CRUD de conteúdo/categoria, salvar, **publicar**.
- `viewer`: leitura.
Guard `@Roles('owner')` por rota, no mesmo estilo do `@Public()`. Papel mais fino (ex.: "pode salvar mas não publicar") **não** entra agora — registrado em §9.

**D6 — Sem cadastro público.**
O primeiro usuário nasce por **seed idempotente** no start, lendo `ADMIN_EMAIL` e `ADMIN_PASSWORD` do ambiente (Coolify). Usuários seguintes: `POST /v1/users` restrito a `owner`. Motivo: o driva ainda não é um SaaS aberto; cadastro livre criaria superfície sem necessidade.

**D7 — Senha com `argon2id`.**
Dependência nova: `argon2` (ou `@node-rs/argon2`, sem build nativo — **preferir este**, porque o Dockerfile atual usa pnpm estrito e já apanhou de dependência nativa; ver a lição do PR #47 com o `express`). Nunca bcrypt custom, nunca SHA.

**D8 — Migração: todo projeto existente vira propriedade do admin do seed.**
Sem isso, depois do deploy o admin loga e não vê nenhum projeto. A migração cria a `Membership(owner)` do admin para **todos** os projetos existentes.

## 4. Fases

Fases de backend são pequenas de propósito: é a área onde um erro custa caro.

### P1 — Schema, seed e módulo de auth (sem proteger nada ainda)  **[CISO]**

**Por quê.** Introduzir as tabelas e o login **sem** ligar o guard permite validar a emissão de token em hml com o sistema ainda funcionando normalmente. Se ligássemos tudo junto e algo desse errado, o editor ficaria inacessível — e o rollback envolveria migração.

**Arquivos a criar/modificar:**
- **`backend/prisma/schema.prisma`**:
  ```
  model User {
    id           String   @id @default(cuid(2))
    email        String   @unique
    passwordHash String   @map("password_hash")
    name         String
    isActive     Boolean  @default(true) @map("is_active")
    createdAt    DateTime @default(now()) @map("created_at")
    memberships  Membership[]
    sessions     Session[]
    @@map("users")
  }
  model Membership {
    id        String   @id @default(cuid(2))
    userId    String   @map("user_id")
    projectId String   @map("project_id")
    role      String                          // 'owner' | 'editor' | 'viewer'
    user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
    project   Project  @relation(fields: [projectId], references: [id], onDelete: Cascade)
    createdAt DateTime @default(now()) @map("created_at")
    @@unique([userId, projectId])
    @@index([projectId])
    @@map("memberships")
  }
  model Session {
    id               String   @id @default(cuid(2))
    userId           String   @map("user_id")
    refreshTokenHash String   @unique @map("refresh_token_hash")
    expiresAt        DateTime @map("expires_at")
    revokedAt        DateTime? @map("revoked_at")
    createdAt        DateTime @default(now()) @map("created_at")
    user             User     @relation(fields: [userId], references: [id], onDelete: Cascade)
    @@index([userId])
    @@map("sessions")
  }
  ```
  E em `Project`: `memberships Membership[]`.
  > **`onDelete: Cascade` em `Membership.project`** é outro desvio do `Restrict` padrão do schema — mesma justificativa do `ContentVersion` (item 24): membership não é entidade independente. Apagar projeto (só arquivado, item 9e) leva as memberships.
- **`backend/prisma/migrations/<ts>_add_auth/migration.sql`** — cria as três tabelas. **Sem** backfill aqui (o seed do P1 cuida) — mas ver D8: o backfill de membership é feito pelo seed idempotente, não por SQL, porque depende do id do admin criado em runtime.
- **`backend/src/auth/`** (novo):
  - `auth.module.ts`, `auth.controller.ts`, `auth.service.ts`
  - `dto/login.dto.ts` (`email` `@IsEmail()`, `password` `@IsString() @MinLength(8)`)
  - `password.util.ts` — `hashPassword`/`verifyPassword` com argon2id (D7)
  - `token.util.ts` — geração/hash do refresh opaco
  - `jwt.strategy.ts` **ou** `jwt.service.ts` (decisão: `@nestjs/jwt` puro + guard próprio, sem passport — menos dependência, menos mágica)
  - `admin.seed.ts` — idempotente: se `ADMIN_EMAIL` não existe, cria; garante `Membership(owner)` do admin em **todos** os projetos existentes (D8). Chamado no `onModuleInit` do `AuthModule`.
  - Rotas: `POST /v1/auth/login` (seta cookie, devolve `{accessToken, user}`), `POST /v1/auth/refresh` (lê cookie, rotaciona, devolve novo access), `POST /v1/auth/logout` (revoga sessão, limpa cookie), `GET /v1/auth/me`.
  - `@UseGuards(ThrottlerGuard) @Throttle({default:{limit:10, ttl:60_000}})` no login — **padrão já usado** no upload de imagem.
- **`backend/src/main.ts`** — `cookie-parser` + `enableCors({credentials:true, origin: <lista>})`; `allowedHeaders` ganha `authorization`.
- **`backend/package.json`** — `@nestjs/jwt`, `@node-rs/argon2`, `cookie-parser` (+ `@types/cookie-parser`).
  > **Lição do PR #47 aplicada:** toda dependência importada em runtime tem que estar em `dependencies` (não `devDependencies`) e o `Dockerfile` precisa copiar os manifests antes do `pnpm install`. Conferir os dois antes de abrir o PR.
- **`backend/.env.example`** / **`docs/deploy/coolify.md`** — `JWT_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `CORS_ORIGINS` (agora obrigatório), `ACCESS_TOKEN_TTL`, `REFRESH_TOKEN_TTL`.

**Critério de aceite:** login com o admin do seed devolve access token e cookie; `/auth/me` com o token devolve o usuário; sem token devolve 401; **o resto da API continua funcionando exatamente como antes** (nada protegido ainda).

**Riscos:** segredo em log; `JWT_SECRET` fraco ou ausente (o boot deve **falhar** se não houver, nunca cair para um default); cookie sem `Secure` em produção.

---

### P2 — Guards: proteger tudo + membership  **[CISO]** — a fase perigosa

**Precedência dura:** P1 em produção/hml e **P4 (editor) pronto para mergear junto**. Ver "restrição dura" abaixo.

> **[RESTRIÇÃO DURA — fatia vertical]** No instante em que o guard global entra, **o editor sem token para de funcionar inteiro** (todas as telas). Backend P2 e editor P4 **não podem** ser deployados separados. Ou vão no mesmo PR, ou os PRs mergeiam na mesma janela com deploy coordenado. É o mesmo tipo de acoplamento que o envelope `{data,nextCursor}` teve no item 10 — e lá a regra foi escrita justamente por isso.

**Arquivos a criar:**
- `backend/src/auth/guards/jwt-auth.guard.ts` — lê `Authorization: Bearer`, valida, popula `request.user`.
- `backend/src/auth/guards/project-member.guard.ts` — D3.
- `backend/src/auth/guards/roles.guard.ts` + `decorators/roles.decorator.ts` — D5.
- `backend/src/auth/decorators/public.decorator.ts` — `SetMetadata('isPublic', true)`.
- `backend/src/auth/decorators/current-user.decorator.ts` — `@CurrentUser()`.

**Arquivos a modificar:**
- `backend/src/app.module.ts` — `{provide: APP_GUARD, useClass: JwtAuthGuard}`.
- `backend/src/health/health.controller.ts` — `@Public()`.
- `backend/src/public/public.controller.ts` (item 25) — `@Public()`. **Se o item 25 ainda não tiver entrado, esta linha não existe — e o plano 25 já registra a dependência inversa.**
- `contents.controller.ts`, `categories.controller.ts` — remover o `projectOf` local; `@UseGuards(ProjectMemberGuard)` no controller; trocar `@Headers('x-project-id') projectId?: string` por `@CurrentProject() projectId: string` (decorator novo que lê o que o guard validou). **Assinaturas dos services não mudam.**
- `projects.controller.ts` — `list()` passa a `this.projects.listForUser(user.id, status)` (D4); `create()` cria a `Membership(owner)` do criador **na mesma `$transaction`** que já cria projeto + categoria "Geral"; `archive`/`delete`/`rotate-key` ganham `@Roles('owner')`.
- `projects.service.ts` — `listForUser(userId, status)` novo (join por membership); `create` recebe `userId`.
- `contents.service.ts` — `publish()` (item 24) passa a gravar `createdBy: user.id`. **Se o item 24 já estiver entregue, esta é a linha que fecha aquele `createdBy` nullable.**

**Critério de aceite:**
- Toda rota sem token → 401. Health e rota pública → 200.
- Token válido + `x-project-id` de projeto sem membership → **404**.
- `editor` tentando arquivar projeto → 403; `owner` consegue.
- Criar projeto logado como usuário B: B vira `owner`; A (outro usuário) não vê o projeto na lista.

---

### P3 — Editor: `auth_module` (domain/data)  **[∥ com P1/P2]**

**Por quê.** Camadas puras, sem UI, sem depender do guard estar ligado. Pode ser escrita e mergeada **antes** do P2, porque não muda comportamento até a P4 plugar.

**Arquivos a criar** (gabarito: `preferences_module`, o módulo pequeno do repo):
```
modules/auth_module/
  auth_module.dart              barrel: só rota + registro de DI
  auth_routes.dart              AuthRoutes.login = '/login', loginName = 'login'
  auth_injection.dart           registerAuthModule(getIt)
  domain/entities/authenticated_user.dart     {id, email, name, memberships}
  domain/entities/project_membership.dart     {projectId, role}
  domain/repositories/auth_repository.dart    login/refresh/logout/me
  domain/use_cases/{login,logout,refresh_session,get_current_user}_use_case.dart
  data/models/authenticated_user_model.dart   zard, no padrão do ContentSummaryModel
  data/repositories/auth_repository_impl.dart único try/catch, traduz Dio→Failure
  data/repositories/auth_repository_fake.dart para useFakeData
```
**Arquivos a criar no core:**
- `core/auth/auth_token_store.dart` — `class AuthTokenStore { String? accessToken; ... }`, singleton em memória (D1). **Não** persiste. Fica em `core/` (e não no módulo) porque o `dio_client` — que é core — depende dele; módulo não pode ser dependência do core.
- `core/error/failure.dart` — acrescentar `UnauthorizedFailure` ao `sealed`. **Atenção: `switch` exaustivo** — todo lugar que faz match em `Failure` para de compilar até tratar. Isso é a lista de tarefas do compilador; os pontos conhecidos são `editor_page.dart:_messageFor`, `project_detail_page.dart` e os cubits com mensagem de erro.

**Critério de aceite:** `flutter analyze` verde; nenhum comportamento muda; `useFakeData` continua abrindo o editor sem login.

---

### P4 — Editor: login, interceptor com refresh e redirect

**Precedência dura:** P3 (módulo) + P2 (contrato do backend congelado). **Mergeia junto com P2.**

**Arquivos a criar:**
- `modules/auth_module/presentation/login/login_page.dart` (`static Widget pageBuilder`), `.../cubit/login_cubit.dart` + `login_state.dart` (`part of`, `sealed`), `.../widgets/login_form.dart`, `.../widgets/login_error_banner.dart` (reusar `core/widgets/feedback/message_banner.dart` se servir).
- `modules/auth_module/presentation/session/session_cubit.dart` + `session_state.dart` — o estado global de sessão (`SessionUnknown`/`SessionAuthenticated`/`SessionAnonymous`), provido **acima** do `MaterialApp.router` em `app_widget.dart`, para o `redirect` do go_router poder consultá-lo.
- `core/network/auth_interceptor.dart` — `Interceptor` que (a) injeta `Authorization: Bearer <accessToken>` quando há token; (b) em **401**, chama `/auth/refresh` **uma vez**, com fila de requisições pendentes para não disparar N refreshes simultâneos, e repete a original; (c) se o refresh falhar, limpa o token e sinaliza logout.
  > O ponto delicado é o (b): sem a fila, abrir o editor com 4 requests paralelos gera 4 refreshes e a rotação de refresh (D1) invalida os outros três → logout em loop. **Este é o bug clássico desta feature e precisa de teste.**

**Arquivos a modificar:**
- `core/network/dio_client.dart` — `createDio(config, scope, tokenStore, onSessionExpired)`; o interceptor de `x-project-id` continua; o de auth entra depois.
- `lib/injection.dart` — registrar `AuthTokenStore` e o `auth_module` **antes** do `Dio`; ajustar a criação do `Dio`.
- `lib/app_router.dart` — `AuthRoutes.route` **fora** do `ShellRoute` (login não tem breadcrumb nem topo) + `redirect:` global: sessão desconhecida → aguarda; anônimo e rota != login → `/login`; autenticado e rota == login → `/projects`.
- `lib/bootstrap.dart` — antes do primeiro frame, tentar `refresh()` uma vez (o cookie httpOnly sobrevive ao reload da página; sem isso, todo F5 cai no login).
- `lib/app_widget.dart` — `BlocProvider<SessionCubit>` acima do router; `refreshListenable` do go_router apontando para ele.
- `core/widgets/app_shell/app_shell.dart` — menu de usuário (nome + Sair) na faixa de ações, ao lado do `ThemeModeButton`. Publicado como **dado**, no mecanismo de slot do item 16c — o shell continua sem ler cubit de página.
- `core/network/project_scope.dart` — `projectId` deixa de ter default `'default'` quando há sessão: passa a ser setado ao entrar num projeto. Manter o default só em `useFakeData`.

**Critério de aceite:**
- Sem sessão, qualquer URL do editor cai em `/login` (inclusive deep link para `/contents/:id/edit`), e **volta para a URL pedida** depois do login.
- F5 com sessão válida **não** pede login de novo.
- Token expirado no meio do uso: a próxima ação renova sozinha, sem o usuário perceber.
- Refresh inválido → volta ao login com mensagem, sem loop.
- 4 requests paralelos com token expirado → **um** refresh.

---

### P5 — Testes e E2E (por último)

- **Backend:** e2e de contrato cobrindo os 4 casos do P2 + login/refresh/logout/rotação; incluir o caso de **reuso de refresh revogado** → 401 e sessão morta.
- **Editor:** `login_cubit_test.dart`; `auth_interceptor_test.dart` (o caso dos 4 paralelos, com `DioAdapter` fake); widget test do redirect.
- **E2E de UI no hml** (padrão 9g): login → projetos → editor → logout → deep link pedindo login.
- **Regressão obrigatória:** re-rodar `docs/09-crud-projeto/e2e_hml.sh` **adaptado ao login** — ele hoje bate direto com `x-project-id`. Adaptá-lo é parte da fase, não item separado.

## 5. Mapa de paralelismo

```
P1 (schema+auth API) ──► P2 (guards) ══╗   ← P2 e P4 mergeiam JUNTOS (restrição dura)
                                       ║
P3 (editor domain/data) ──► P4 (editor UI+interceptor) ══╝ ──► P5
```
- **P3 é totalmente paralelo a P1/P2** — arquivos disjuntos (Dart vs TypeScript), e não muda comportamento.
- **P1 pode ir para hml sozinha** com segurança (nada protegido ainda).
- **P2 e P4 são um único evento de deploy.**

## 6. Impacto nos planos anteriores (revisão cruzada)

- **Item 24 (publicação) — nenhuma contradição; duas costuras:**
  1. `ContentVersion.createdBy` sai do nullable-sem-uso e passa a ser preenchido (P2). Se o 26 vier **antes** do 24, o campo já nasce preenchido — o plano 24 não muda, só ganha um valor.
  2. `publish` fica sob `@Roles('owner','editor')`.
- **Item 25 (entrega ao app) — a costura crítica:** a rota pública **não pode** cair no guard global. Está previsto no P2 (`@Public()` em `src/public/*`), e o plano 25 §6 já registra a dependência inversa. **Se o 26 entrar antes do 25**, o plano 25 nasce com `@Public()` no controller desde a primeira linha — mais simples.
  Segunda costura: `rotate-key` vira `@Roles('owner')`, e a `publishableKey` **continua** fora do `toSummary` da lista.
- **Item 27 (storage) — COLISÃO REAL, descoberta na revisão cruzada de 2026-08-13.**
  `GET /v1/projects/:id/image` é consumido pelo editor como **URL simples** (`imageUrl` derivado no `toSummary`, `projects.service.ts:224`) e renderizado por `Image.network`/`<img>` — que **não mandam header `Authorization`**. No instante em que o `APP_GUARD` do P2 entrar, **toda capa de projeto quebra** (401 na imagem, card sem capa em todas as telas de projeto).
  **Não resolver marcando a rota como `@Public()`**: o `:id` do projeto é enumerável, e isso exporia a capa de qualquer projeto.
  **Solução (detalhada na D3 do plano 27):** rota nova `GET /v1/media/:key(*)` com `@Public()`, onde a key é a do storage (`<projectId>/midias/<uuid>.<ext>`) — não-enumerável pelo UUID —, com validação de caractere na borda, `nosniff` e cache. `imageUrl` passa a apontar para ela.
  **Quem implementa depende da ordem de execução:** se o 26 vier primeiro, a rota `/v1/media/:key` **nasce no P2 deste plano** (é pré-requisito de não quebrar a UI); se o 27 vier primeiro, ela já existe e o P2 só marca `@Public()`. **Nenhum dos dois planos pode assumir que o outro resolveu.**
- **Item 17 (offline-first) — cache é por usuário, obrigação registrada na revisão cruzada de 2026-08-13.** A chave do cache local (`contents:v1:<projectId>:…`) **não inclui usuário**. Com sessão real, dois usuários na mesma máquina/navegador veriam a lista um do outro — vazamento silencioso, sem request nenhum. **Duas obrigações:** (a) a chave ganha o id do usuário; (b) o **logout limpa o cache** (`LocalContentsCache.clear`) junto com o token. Se o 26 vier antes do 17, a chave já nasce certa lá; se vier depois, é obrigação deste plano (P4, junto do logout).
- **Item 23 (histórico) — zero contato.**
- **Contradição resolvida aqui:** o comentário `/// Tenant scope sent as x-project-id (multi-tenant real chega no I4)` em `core/config/app_config.dart:34` e o do `model Content` no schema **descrevem esta feature**. Ambos precisam ser reescritos no P2/P4 — comentários que viram mentira são pior que ausência.
- **`AppConfig.defaultProjectId`** perde o sentido com sessão real (o projeto vem da membership). Manter o campo só para `useFakeData`; marcar isso explicitamente ou remover — **decidir no P4**, não deixar ambíguo.

## 7. Definition of Done

- [ ] `pnpm build`/`pnpm lint` verdes; `flutter analyze` verde.
- [ ] Migração aplicada em hml; admin do seed com membership em **todos** os projetos pré-existentes (contar antes/depois).
- [ ] Nenhuma rota respondendo sem token, exceto health e a pública do item 25 (varredura automatizada: iterar as rotas e conferir 401).
- [ ] `JWT_SECRET` ausente **derruba o boot** (testado).
- [ ] E2E de UI no hml passando, incluindo F5 e deep link.
- [ ] E2E do item 9g adaptado e verde.
- [ ] **Capas de projeto continuam aparecendo** depois do guard (a colisão do §6 com o item 27 tratada, não descoberta em produção).
- [ ] Comentários desatualizados sobre "I4"/"multi-tenant real chega depois" removidos do código.
- [ ] `docs/26-auth-multi-tenant/final_report.md` + `variance_report.md` (o débito de 2026-07-09 é **fechado** aqui, com nota no `docs/09-crud-projeto/variance_report.md` apontando para cá).
- [ ] `docs/roadmap.md`: item 26 `[x]`; tabela de débitos vivos atualizada.

## 8. Perguntas para o humano (bloqueiam o P1)

1. **Cookie httpOnly (D1) exige mesmo domínio ou CORS com credentials + lista explícita de origens.** O editor em hml está em domínio diferente da API? Se sim, confirmar as origens exatas para o `CORS_ORIGINS` — e saber que `SameSite=Lax` pode precisar virar `None; Secure` (cross-site), o que exige HTTPS nos dois lados. **Isto é o item que mais atrasa esta feature se descoberto tarde.**
2. **Quantos usuários, na prática, no primeiro momento?** Se for só você, o P2 pode simplificar papéis para `owner` apenas e adiar `editor`/`viewer`.
3. **Reset de senha:** administrativo (owner troca a de outro) é suficiente por ora, ou precisa de fluxo por e-mail (que exige provedor de e-mail e é outra feature)?

## 9. Deixado de fora (registro)

Convite por e-mail · SSO/OAuth · 2FA · permissão por conteúdo ou por categoria · auditoria completa de ações (hoje só `ContentVersion.createdBy`) · expiração de sessão por inatividade · limite de sessões simultâneas.
