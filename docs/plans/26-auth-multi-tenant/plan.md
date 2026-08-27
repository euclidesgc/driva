# plan.md — Item 26: Autenticação e multi-tenant real (revisado em 2026-08-27)

> Documento de planejamento vivo. Dono na execução: **tech-lead**. Substitui o plano de
> gaveta de 2026-08-13 (preservado no histórico do git; o que dele sobrevive está citado
> por decisão). Base: **PRD aprovado em 2026-08-27** (`docs/26-auth-multi-tenant/prd.md`,
> commit `2d54377`) + `docs/26-auth-multi-tenant/specs.md` (§7 A1–A8 decididas; §8 T1–T3
> respondidas).
>
> Regra do "pronto": `pnpm build`/`pnpm lint`/`pnpm test`/`pnpm test:e2e` verdes no
> backend + `flutter analyze` e suíte verdes no editor + `bash scripts/gates_guard.sh`.
> **Gate CISO é condição de merge por fase, não revisão final** — pareceres em
> `docs/26-auth-multi-tenant/pareceres/`.
>
> **Restrição dura de deploy (PRD):** guards do backend (F2) e editor com login (F4)
> saem **num único evento** — a mudança de URL (header → param) é breaking. O token do
> QR vai no mesmo evento. A pilha de PRs abaixo (§5) codifica isso: **a F2 só mergeia
> escolhendo o topo da pilha**, nunca sozinha.

## 1. Objetivo e recorte

Fechar a porta: ninguém sem sessão acessa a API do editor; ninguém com sessão acessa
projeto alheio; o tenant sai do header `x-project-id` (que o cliente escolhe) e passa a
ser **param de path validado no servidor** — sem quebrar o app cliente (`x-driva-key`),
o QR do item 51 (token de visualização, A7) nem o dev local (`useFakeData`, A6).

Escopo e não-escopo são os do PRD (aprovado — não repetidos aqui). Fica registrado o que
o PRD delegou a este plano: a forma final da rota (ponto 1), a decisão T4 (ponto 8) e a
reescrita de D1/D3/D5/P5 do plano de gaveta (pontos 2, 6, 7).

## 2. O que mudou desde o plano de gaveta

A auditoria completa está em `docs/26-auth-multi-tenant/specs.md` §3. O que muda o
desenho:

- **D1 (JWT + refresh) morreu** → sessão server-side por cookie (A1). Somem:
  `AuthTokenStore`, interceptor de refresh, fila de refresh, rotação de refresh token,
  `@nestjs/jwt`. O bug clássico da fila deixa de existir por desenho.
- **D3 (header validado) morreu** → tenant no path (T3). A tabela do §2 do plano de
  gaveta dizia que o `ProjectScope` "continua existindo; passa a ser preenchido pelo
  login" — **mentira a partir de agora**: o débito do item 46 o mata na F4, junto com o
  `DEFAULT_PROJECT_ID` compilado.
- **D5 (RBAC completo) encolheu** → `role` no schema com enforcement mínimo (A4): todo
  membro opera tudo no seu projeto; só o destrutivo/sensível exige `owner`.
- **§6 do plano de gaveta (colisão da capa) sai como estava** — mas ver a D26.4 abaixo:
  a dissolução prometida pela A1 é verdadeira no protocolo e **falsa no engine** do
  Flutter Web; o conserto é pequeno e muda de lugar (editor, não backend).
- **P5 (E2E) morreu** → pirâmide unit/widget/contrato escrita **junto de cada fase**
  (política de 2026-08-20); o que só o campo prova vai para _Validações de campo
  pendentes_ do roadmap (§7 deste plano).
- **P2 cresceu**: 4 rotas de checkpoint (item 53), segundo `createdBy`
  (`ContentCheckpoint`), `rotate-key` é **criação** (nunca existiu), `POST /v1/users`
  (A8) e a rota de resolução do token de visualização (A7).

**Sobrevivem do plano de gaveta:** D2 (guard global + `@Public()` explícito), D4 (lista
por membership), D6 (seed, sem cadastro público), D7 (argon2id via `@node-rs/argon2` —
lição do PR #47: dependência nativa × pnpm estrito), D8 (admin adota os projetos), o
esqueleto do schema (ajustado abaixo) e a restrição dura P2+P4.

## 3. Decisões técnicas deste plano

**D26.1 — Forma final da rota: aninhada, não query param.**
`/v1/projects/:projectId/contents…` e `/v1/projects/:projectId/categories…`. Motivos:
o guard extrai o tenant de um lugar só (`params.projectId ?? params.id`, helper único);
a URL é auditável em log (o T3 do specs §8 já registrou que cache/proxy chaveiam por
URL, não por header); e o editor já carrega `projectId` no path das próprias rotas
(`/projects/:projectId/contents/:id/edit` desde o item 46) — a simetria elimina uma
tradução. Query param teria guard bifurcado (param × query) e URL menos declarativa.

**D26.2 — T4 decidida: `process.env` manual com `requireEnv`, sem `@nestjs/config`.**
Padrão do repositório mantido (zero dependência nova). Nasce
`backend/src/require-env.ts`: `requireEnv('ADMIN_EMAIL')` lança na inicialização se
ausente/vazio — chamado no bootstrap para `ADMIN_EMAIL` e `ADMIN_PASSWORD` (o seed
depende deles em todo ambiente, A6 inclusive: dev local tem `.env`). **Consequência da
A1=B que o PRD herda sem nomear: não existe mais segredo de assinatura** — o token de
sessão é opaco (32 bytes aleatórios) e guardado como **SHA-256 puro** em repouso; com
256 bits de entropia, pré-imagem é impraticável e pepper não compra segurança real. A
exigência do PRD "segredo ausente derruba o boot" é satisfeita pelo `requireEnv` das
credenciais do seed. **O CISO valida (ou endurece com pepper) no gate da F1.**

**D26.3 — Números da sessão (proposta ao gate da F1).**
Cookie `driva_session`, valor = token opaco; `Path=/; HttpOnly; Secure; SameSite=Lax;
Max-Age=604800` — **sem atributo `Domain`** (host-only; achado da T1: os quatro hosts
são o mesmo site). TTL **deslizante de 7 dias**: `expiresAt` avança a cada request
autenticada, com gravação no máximo 1×/hora (não escrever no banco a cada request);
**teto absoluto de 30 dias** contado de `createdAt`, verificado em código (sem coluna).
Logout/revogação = delete da linha, vale imediatamente.

**D26.4 — A capa de projeto exige um provider autenticado no editor (correção de
mecânica do PRD; o requisito não muda).**
O PRD assume "o cookie viaja no `<img>` same-site, sem código novo". Verificado no
engine (Flutter 3.38.6,
`~/.puro/envs/3.38.6/flutter/packages/flutter/lib/src/painting/_network_image_web.dart:184-198`):
no CanvasKit, `Image.network` busca bytes por `XMLHttpRequest` **sem `withCredentials`**
— cookie não viaja em request cross-origin, mesmo same-site; o caminho `<img>`
(`loadViaImgElement`) só roda sob `WebHtmlElementStrategy.prefer/fallback`, que o repo
já rejeitou no item 39 (platform view quebra golden). Logo, sob o guard, a capa
(`GET /v1/projects/:id/image`, consumida em
`apps/driva_editor/lib/modules/projects_module/presentation/widgets/project_cover.dart:41`
e `.../project_form/cover_preview.dart:25`) quebraria com 401. **Conserto (T4.5):**
`SessionImageProvider` — `ImageProvider` pequeno que busca os bytes pelo `Dio`
compartilhado (que tem `withCredentials`) e decodifica — nos dois call sites. Continua
**proibido** `@Public()` na rota da capa (`:id` enumerável — regra do PRD). O requisito
do PRD ("capas continuam aparecendo") fica; a frase "sem código novo" vira entrada de
`variance_report.md` na execução, com aprovação do dev (§8 deste plano).

**D26.5 — Defesa CSRF em camadas (a postura que o CISO avalia no gate da F2).**
(1) `SameSite=Lax` — cross-site só manda cookie em navegação GET de topo; (2) CORS com
`credentials: true` e lista explícita (o destino da regex `localhost` é a T5, do gate);
(3) **checagem de `Origin` nas mutações**: middleware/guard que recusa
POST/PUT/DELETE cujo header `Origin` presente não esteja na allowlist — cobre inclusive
o multipart do upload de capa, que a exigência de `Content-Type: application/json` não
alcança (formulário HTML submete multipart cross-site sem CORS).

**D26.6 — Base de branch e pilha (o estado do repo em 2026-08-27).**
A pilha do item 25 (PRs #225/#226) **ainda não está em `develop`**. As branches do 26
**não nascem dela**: nascem empilhadas em `docs/26-discovery-auth` (que contém
PRD/specs/este plano e vira a base da pilha do 26 contra `develop`). Superfícies de
código são disjuntas (`backend/` + `apps/driva_editor/` × `packages/driva_client/` +
`apps/driva_demo_app/`); o conflito previsto é só `CHANGELOG.md` e `docs/roadmap.md`,
resolvido por rebase da pilha do 26 quando a do 25 mergear (ela vai primeiro). Pilha do
26, de baixo para cima: `docs/26-discovery-auth` → F1 → F3 → F2 → F4 → F5. **Mergear
até a F3 é seguro a qualquer momento** (F1 não protege nada; F3 não muda
comportamento); **F2/F4/F5 mergeiam numa operação só** escolhendo o PR do topo — um
merge, um deploy, a restrição dura satisfeita pela mecânica da pilha (GITFLOW §6).

**D26.7 — `GET /v1/media/proxy` assumido `@Public()` até o parecer (T6).**
Com throttle + anti-SSRF existentes. Motivo técnico novo a levar ao gate: pelo mesmo
achado da D26.4, as imagens do canvas passam pelo proxy via `Image.network` — sob
sessão, **todas** quebrariam sem provider autenticado. `@Public()` mantém o canvas como
está; se o CISO exigir sessão, o `SessionImageProvider` da T4.5 cobre também o resolver
do proxy (`apps/driva_editor/lib/core/network/media_proxy_image_url_resolver.dart`) —
custo registrado, decisão do gate.

## 3b. Contrato congelado (o que F3/F4 podem assumir antes de F1/F2 terminarem)

**Schema (F1):**

```prisma
model User {
  id           String   @id @default(cuid(2))
  email        String   @unique
  passwordHash String   @map("password_hash")
  name         String
  isActive     Boolean  @default(true) @map("is_active")
  createdAt    DateTime @default(now()) @map("created_at")
  @@map("users")
}
model Membership {
  userId    String  @map("user_id")
  projectId String  @map("project_id")
  role      String  // 'owner' | 'editor' | 'viewer' — enforcement mínimo (A4)
  @@unique([userId, projectId])  @@index([projectId])  @@map("memberships")
}
model Session {
  id        String    @id @default(cuid(2))
  userId    String    @map("user_id")
  tokenHash String    @unique @map("token_hash")   // SHA-256 do token opaco
  expiresAt DateTime  @map("expires_at")            // deslizante (D26.3)
  revokedAt DateTime? @map("revoked_at")
  createdAt DateTime  @default(now()) @map("created_at")
  @@index([userId])  @@map("sessions")
}
model PreviewToken {
  id          String    @id @default(cuid(2))
  tokenHash   String    @unique @map("token_hash")
  contentId   String    @map("content_id")
  projectId   String    @map("project_id")
  createdById String    @map("created_by_id")
  expiresAt   DateTime  @map("expires_at")           // +15 min (A7)
  revokedAt   DateTime? @map("revoked_at")
  createdAt   DateTime  @default(now()) @map("created_at")
  @@index([createdById])  @@map("preview_tokens")
}
```

(Relações `user`/`project`/`content` com `onDelete: Cascade` — membership/sessão/token
não são entidades independentes; mesma justificativa do `ContentVersion` no item 24.)

**Rotas (F1 + F2):**

```
POST /v1/auth/login    {email, password} → 200 {user} + Set-Cookie driva_session
POST /v1/auth/logout   → 204, revoga sessão + preview tokens vivos do usuário
GET  /v1/auth/me       → 200 {user, memberships}

GET  /v1/projects                      → memberships do usuário (sem header)
GET/PUT/DELETE /v1/projects/:id        → guard valida :id; DELETE/archive = owner
POST /v1/projects/:id/rotate-key       → owner; nasce nesta fase
POST /v1/users                         → owner de ≥1 projeto (A8)

/v1/projects/:projectId/contents…      → as 12 rotas atuais de /v1/contents
/v1/projects/:projectId/categories…    → as 4 rotas atuais de /v1/categories

POST /v1/projects/:projectId/contents/:id/preview-token → {token, expiresAt}
GET  /v1/preview/:token                → @Public + throttle; 200 {name, spec(draft)}
                                         ou 404 indistinguível (A7)
```

**Editor (F3/F4):** contrato de repositório
`AuthRepository { login(email, password), logout(), me() }` devolvendo
`Future<Either<Failure, AuthenticatedUser>>`; `AuthenticatedUser {id, email, name,
memberships: List<ProjectMembership {projectId, role}>}`; `UnauthorizedFailure` entra no
`sealed Failure` de `apps/driva_editor/lib/core/error/failure.dart`. URL do QR:
`/preview/t/:token` (fora do shell, como as rotas de preview atuais).

## 4. Fases e tarefas

> Backend = **especialista-infra**; editor domain = **especialista-dominio**; editor
> data/rede = **especialista-dados**; editor UI = **especialista-apresentacao**. Bateria
> escrita **junto de cada tarefa** (política de 2026-08-20). Tarefa textual não lança
> supervisor — cobrada no lote da fase pelo QA.

### F1 — Identidade e sessão no backend, nada protegido ainda **(1 PR)** **[gate CISO #1]**

Branch `feature/26-f1-sessao-identidade`, empilhada em `docs/26-discovery-auth`.
Racional herdado do plano de gaveta: emitir sessão em hml **com a API ainda aberta**
valida o login sem risco de trancar o editor.

#### T1.1 — Schema e migration das quatro tabelas **[paralela: não — base da fase]** **[sub-agente: especialista-infra]**

`backend/prisma/schema.prisma` ganha os quatro models do §3b (com as relações em
`User`/`Project`/`Content`) e a migration nova. Sem backfill (o seed da T1.3 cuida —
depende de id criado em runtime).

**DoD**
- `backend/prisma/schema.prisma` contém os models `User`, `Membership`, `Session` e `PreviewToken` com os campos e mapeamentos (`@@map("users")`, `"memberships"`, `"sessions"`, `"preview_tokens"`) e as constraints `@@unique([userId, projectId])` em `Membership` e `tokenHash @unique` em `Session` e `PreviewToken`.
- Existe exatamente uma migration nova em `backend/prisma/migrations/*_add_auth/migration.sql` criando as quatro tabelas, sem `UPDATE`/backfill dentro.
- `cd backend && npx prisma validate` sai sem erro e `pnpm build` verde.
- Nenhum arquivo fora de `backend/prisma/` foi modificado nesta tarefa.

#### T1.2 — Núcleo de auth: senha, sessão e as três rotas **[paralela: não — dep. T1.1]** **[sub-agente: especialista-infra]**

`backend/src/auth/`: `auth.module.ts`, `auth.controller.ts` (`login`/`logout`/`me`),
`auth.service.ts`, `password.util.ts` (argon2id via `@node-rs/argon2` — em
`dependencies`, não `devDependencies`; lição do PR #47), `session.service.ts` (criar/
validar/revogar; TTL deslizante 7d gravado no máx 1×/hora; teto 30d de `createdAt`;
hash SHA-256), `dto/login.dto.ts`. Cookie na forma final da D26.3. Throttle no login
(padrão `@Throttle` por handler — nunca `forRoot` novo, lição da fatia 2 do 25).
Mensagem única para e-mail/senha errados. `configure-app.ts` ganha `cookie-parser` e
`credentials: true` com a lista `CORS_ORIGINS` (a regex `localhost` fica como está até o
parecer T5 — mudança dela é do gate, não desta tarefa). Unit tests junto.

**DoD**
- `POST /v1/auth/login` com credencial válida responde 200 com o usuário e um `Set-Cookie` cujo valor literal contém `HttpOnly`, `Secure`, `SameSite=Lax`, `Path=/` e **não contém** `Domain=` — provado por teste em `backend/src/auth/` ou `backend/test/` que asserta a string do header.
- Credencial inválida (e-mail inexistente × senha errada) responde 401 com **a mesma** mensagem nos dois casos — teste compara os dois corpos e exige igualdade.
- `GET /v1/auth/me` com cookie válido devolve o usuário; sem cookie devolve 401; após `POST /v1/auth/logout`, o mesmo cookie devolve 401 — os três casos em teste.
- O hash guardado em `sessions.token_hash` não é o token: teste cria sessão e asserta que o valor no banco difere do token e tem 64 hex chars (SHA-256).
- `backend/package.json` tem `@node-rs/argon2` e `cookie-parser` em `dependencies`; `cd backend && pnpm build && pnpm lint && pnpm test` verdes.

#### T1.3 — `requireEnv`, seed idempotente e docs de deploy **[paralela: sim — ∥ T1.4; arquivos disjuntos]** **[sub-agente: especialista-infra]** _(dep. T1.2)_

`backend/src/require-env.ts` (D26.2) chamado no bootstrap para `ADMIN_EMAIL`/
`ADMIN_PASSWORD`. `backend/src/auth/admin.seed.ts` idempotente: cria o admin se não
existe; garante `Membership(owner)` dele em **todos** os projetos existentes (A5); loga
a contagem `projetos × memberships criadas` (é o que audita a migração no deploy).
Atualizar `backend/.env.example` e `docs/deploy/coolify.md` (variáveis novas; nota do
runbook: senha do admin perdida = trocar env no Coolify + redeploy).

**DoD**
- `backend/src/require-env.ts` existe e um teste prova que a ausência de `ADMIN_EMAIL` faz o bootstrap lançar antes de o Nest subir (mensagem nomeando a variável).
- Teste de idempotência: rodar o seed duas vezes não duplica usuário nem membership (contagens iguais entre a 1ª e a 2ª execução), e projetos pré-existentes sem dono terminam todos com `Membership(owner)` do admin.
- O seed emite log com a contagem de projetos adotados — asserção sobre o logger no teste.
- `backend/.env.example` lista `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `CORS_ORIGINS`; `docs/deploy/coolify.md` documenta as três e o runbook de reset administrativo.
- `cd backend && pnpm test` verde.

#### T1.4 — Contrato Jest da F1 **[paralela: sim — ∥ T1.3; arquivos disjuntos]** **[sub-agente: especialista-infra]** _(dep. T1.2)_

`backend/test/auth.e2e-spec.ts`: o ciclo completo contra o app real (supertest), no
padrão de `backend/test/public-rate-limit.e2e-spec.ts`. Inclui a **regressão da API
aberta**: nesta fase, nenhuma rota existente muda de comportamento.

**DoD**
- `backend/test/auth.e2e-spec.ts` existe e cobre: login bom (200 + cookie), login ruim (401, mensagem única), throttle do login (requisições acima do limite → 429), `me` com/sem cookie, logout matando a sessão, e TTL deslizante (request autenticada avança `expiresAt` — asserção via leitura do banco de teste).
- O mesmo spec prova a regressão: `GET /v1/contents` e `GET /v1/projects` **sem sessão** respondem **200** nesta fase (nada protegido na F1) — asserção de status e de corpo não-vazio, não comparação com estado anterior.
- `cd backend && pnpm test:e2e` verde, incluindo os specs pré-existentes (`media-proxy.e2e-spec.ts`, `public-rate-limit.e2e-spec.ts`) sem alteração.

#### T1.5 — Textual: CHANGELOG + parecer CISO da F1 **[paralela: sim]** **[textual — sem supervisor, lote da fase]**

Entrada em `Unreleased` do `CHANGELOG.md` (mesmo PR). Parecer do CISO anexado em
`docs/26-auth-multi-tenant/pareceres/parecer_f1.md` — pontos nomeados: schema das
quatro tabelas e cascades; forma do cookie (D26.3); **SHA-256 sem pepper** (D26.2 —
validar ou endurecer); TTL 7d/30d; parâmetros do argon2id; mensagem única; throttle do
login; `requireEnv`; seed e log de adoção. **Sem parecer, a F1 não mergeia.**

**DoD**
- `CHANGELOG.md` (`Unreleased`) cita a F1 (sessão server-side, seed, nada protegido ainda).
- `docs/26-auth-multi-tenant/pareceres/parecer_f1.md` existe com veredito explícito (aprovado/aprovado-com-ressalvas) e nomeia, um a um: schema das quatro tabelas, forma do cookie (host-only/`Lax`/`Secure`), hash SHA-256 sem pepper, TTLs 7d/30d, parâmetros do argon2id, mensagem única de login, throttle do login, conjunto do `requireEnv` e seed idempotente com log de adoção.

### F3 — Editor: `auth_module` domain/data, sem UI e sem mudança de comportamento **(1 PR)**

Branch `feature/26-f3-auth-module-editor`, empilhada na F1 (arquivos 100% disjuntos —
rebase trivial). **∥ com a F1 inteira** — codifica contra o contrato congelado do §3b.
Gabarito: `preferences_module` (o módulo pequeno do repo).

#### T3.1 — Domain do auth_module **[paralela: sim — ∥ F1]** **[sub-agente: especialista-dominio]**

`apps/driva_editor/lib/modules/auth_module/domain/`: entidades
`authenticated_user.dart` e `project_membership.dart` (Equatable, imutáveis), contrato
`auth_repository.dart` (`abstract interface class`, três métodos do §3b), use cases
`login_use_case.dart`, `logout_use_case.dart`, `get_current_user_use_case.dart` (um
`call()` por operação). Testes unitários junto.

**DoD**
- Os arquivos acima existem sob `apps/driva_editor/lib/modules/auth_module/domain/` com `test/` espelhando (`apps/driva_editor/test/modules/auth_module/domain/...`), e nenhum deles importa `package:flutter` nem nada de `data/`.
- `AuthRepository` declara exatamente `login`, `logout` e `me`, todos devolvendo `Future<Either<Failure, ...>>` (fpdart).
- `cd apps/driva_editor && flutter analyze && flutter test -r compact test/modules/auth_module` verdes.

> **DoD verificado e aprovado em 2026-08-27** (supervisor cego). Registro do veredito
> para leitura futura: a linha do espelho lê-se como **espelho de layout**
> (`CLAUDE.md:46`) — os testes moram sob
> `apps/driva_editor/test/modules/auth_module/domain/`, e **não** há um `_test.dart`
> por arquivo de produção; o contrato `abstract interface class`, sem comportamento,
> não ganha teste próprio.

#### T3.2 — Data + fake + `UnauthorizedFailure` no sealed **[paralela: não — dep. T3.1]** **[sub-agente: especialista-dados]**

`data/models/authenticated_user_model.dart` (zard `safeParse`, gabarito
`content_summary_model.dart`), `data/repositories/auth_repository_impl.dart` (único
try/catch; `DioException` → `Failure`), `auth_repository_fake.dart` **com sessão
embutida** (A6: `useFakeData` abre o editor logado, sem tela). `UnauthorizedFailure`
entra no `sealed Failure` de `apps/driva_editor/lib/core/error/failure.dart` — o switch
exaustivo lista os call sites a tratar (mensagem genérica basta nesta fase; o
comportamento de navegação é da F4). `auth_injection.dart` + barrel `auth_module.dart`
registrando só repositório e use cases.

**DoD**
- `apps/driva_editor/lib/core/error/failure.dart` contém `final class UnauthorizedFailure extends Failure` e `cd apps/driva_editor && flutter analyze` sai verde — ou seja, todos os `switch` sobre `Failure` do app foram atualizados.
- `auth_repository_impl.dart` traduz `DioException` com status 401 em `UnauthorizedFailure` — provado por teste com adapter/cliente fake.
- `auth_repository_fake.dart` devolve usuário logado sem rede — teste prova que `me()` no fake resolve `Right` imediato.
- O model valida com zard: payload sem `email` → `Left(ValidationFailure)` em teste.
- `cd apps/driva_editor && flutter test -r compact` verde; e o `git diff --name-only` da tarefa só contém arquivos sob `apps/driva_editor/lib/modules/auth_module/`, `apps/driva_editor/test/`, o `apps/driva_editor/lib/core/error/failure.dart` e arquivos cujo diff se resume a um `case` novo em `switch` sobre `Failure` — nenhuma rota, página ou cubit ganhou/perdeu outra linha.

### F2 — Guard global, tenant no path e as superfícies novas (backend) **(1 PR)** **[gate CISO #2 — a fase perigosa]**

Branch `feature/26-f2-guard-tenant`, empilhada na F3. **Não mergeia sozinha** (D26.6).

#### T2.1 — Guards, decorators e a checagem de Origin **[paralela: não — base da fase]** **[sub-agente: especialista-infra]**

`backend/src/auth/guards/session-auth.guard.ts` (global via `APP_GUARD` no
`app.module.ts`; resolve cookie → sessão → `request.user`),
`decorators/public.decorator.ts`, `decorators/current-user.decorator.ts`,
`guards/project-member.guard.ts` (helper único: `params.projectId ?? params.id` →
`Membership(userId, projectId)`; ausente → **404**),
`guards/owner.decorator.ts`+enforcement mínimo (A4: `@RequireOwner()`), e o guard de
Origin nas mutações (D26.5). Unit tests de cada guard com contexto fake.

**DoD**
- `backend/src/app.module.ts` registra o guard de sessão como `APP_GUARD`, e um teste prova: rota sem `@Public()` sem cookie → 401; com `@Public()` → passa sem sessão.
- `project-member.guard.ts` tem teste provando: com `params.projectId` usa ele; sem, usa `params.id`; membership ausente → 404 (não 403); presente → `request` segue com o projeto validado.
- O guard de Origin tem teste: POST com header `Origin` fora da allowlist → 403; sem header `Origin` (curl/supertest) → passa; GET nunca é bloqueado por ele.
- `@RequireOwner()` tem teste: membro `editor` → 403; `owner` → passa.
- `cd backend && pnpm build && pnpm test` verdes.

#### T2.2 — Rotas aninhadas + projetos por membership **[paralela: não — dep. T2.1]** **[sub-agente: especialista-infra]**

`backend/src/contents/contents.controller.ts` → `@Controller('projects/:projectId/contents')`
(12 rotas; some o `projectOf` da linha 21; `projectId` vem do param validado pelo
guard); `backend/src/categories/categories.controller.ts` → idem (4 rotas);
`backend/src/projects/`: `list()` vira `listForUser(userId, status)` (join por
membership — método novo no service, único que muda de assinatura), `create()` grava
`Membership(owner)` do criador **na mesma `$transaction`** do projeto + "Geral",
`remove`/`archive` ganham `@RequireOwner()`. `@Public()` em `health`, `src/public/*` e
`auth`; `GET /v1/media/proxy` fica `@Public()` (D26.7 — pendente do parecer T6).
`configure-app.ts`: `allowedHeaders` perde `x-project-id`. Specs Jest existentes
atualizados para as URLs novas. **Services de contents/categories intactos.**

**DoD**
- `rtk proxy grep -rn "x-project-id" backend/src/` devolve zero ocorrências fora de comentário, e `backend/src/configure-app.ts` tem `allowedHeaders` sem `x-project-id` e com `credentials: true`.
- As 12 rotas de conteúdo e as 4 de categoria respondem sob `/v1/projects/:projectId/...` — teste de contrato cobre uma leitura e uma escrita de cada controller com membership válida (200) e com projeto alheio (404).
- `GET /v1/projects` com sessão de usuário B devolve só os projetos com membership de B — teste com dois usuários.
- Criar projeto autenticado deixa o criador com `Membership(owner)` na mesma transação — teste força falha após o insert do projeto e prova rollback conjunto.
- `cd backend && pnpm test && pnpm test:e2e` verdes — incluindo os specs pré-existentes de `backend/test/` (`media-proxy.e2e-spec.ts`, `public-rate-limit.e2e-spec.ts`, `auth.e2e-spec.ts`), ajustados onde citavam as URLs antigas, sem caso removido (contagem de `it(` por arquivo ≥ a de antes da tarefa).

#### T2.3 — `rotate-key`, `POST /v1/users` e os dois `createdBy` **[paralela: sim — ∥ T2.4; arquivos distintos]** **[sub-agente: especialista-infra]** _(dep. T2.1)_

`POST /v1/projects/:id/rotate-key` nasce (`@RequireOwner()`; regenera via
`backend/src/projects/publishable-key.ts`; a antiga morre no mesmo update).
`POST /v1/users` (A8: exige `owner` de ≥1 projeto; DTO com e-mail+senha+nome; argon2id;
sem UI). `backend/src/contents/contents.service.ts` passa a gravar `createdBy` na
publicação (linha ~317) e no checkpoint (linha ~235) com o id do usuário da sessão.

**DoD**
- Teste do rotate: `owner` troca a chave; a chave antiga passa a responder 404 na rota pública (`GET /v1/public/contents/:slug` com o header `x-driva-key` antigo) e a nova responde 200; membro não-owner → 403.
- Teste do `POST /v1/users`: owner cria usuário e o novo loga; usuário sem nenhuma membership `owner` → 403; e-mail duplicado → 409.
- Publicar e criar checkpoint com sessão gravam `created_by` ≠ null — teste lê as linhas de `content_versions` e `content_checkpoints` e compara com o id do usuário logado.
- `cd backend && pnpm test && pnpm test:e2e` verdes.

#### T2.4 — Token de visualização do QR (A7) **[paralela: sim — ∥ T2.3]** **[sub-agente: especialista-infra]** _(dep. T2.1)_

`backend/src/preview-tokens/` (módulo próprio):
`POST /v1/projects/:projectId/contents/:id/preview-token` (sessão + membership; gera 32
bytes base64url, guarda SHA-256, `expiresAt = now + 15min`) e `GET /v1/preview/:token`
(`@Public()` + `@Throttle` por handler; resolve hash → devolve `{name, spec}` do
**rascunho** do conteúdo; expirado/revogado/inexistente → **404 indistinguível**).
Logout revoga os tokens vivos do criador (hook no `auth.service.ts` da F1).

**DoD**
- Teste do ciclo: gerar token autenticado → `GET /v1/preview/:token` sem sessão responde 200 com o `spec` do rascunho; o corpo não contém `projectId` nem ids além do necessário à renderização.
- Testes dos quatro 404: token expirado (relógio avançado), revogado, inexistente e malformado devolvem **status e corpo idênticos** — asserção de igualdade entre as quatro respostas.
- Teste do logout: `POST /v1/auth/logout` do criador → token vivo dele passa a responder o mesmo 404.
- A rota de resolução tem rate limit próprio — teste prova 429 acima do limite.
- `cd backend && pnpm test:e2e` verde.

#### T2.5 — Varredura automatizada de rotas e regressão do item 25 **[paralela: não — dep. T2.2/T2.3/T2.4]** **[sub-agente: especialista-infra]**

`backend/test/route-sweep.e2e-spec.ts`: itera **todas** as rotas registradas no router
do Nest e exige 401 sem sessão, exceto a allowlist declarada por `@Public()` (a lista
esperada é literal no teste: health, `public/*`, auth, `media/proxy`,
`preview/:token`). Mais a regressão do contrato do 25: a rota pública com `x-driva-key`
intocada.

**DoD**
- `backend/test/route-sweep.e2e-spec.ts` enumera as rotas em runtime (não lista de memória), asserta que o total varrido é **≥ 25** (prova de que a enumeração não veio vazia) e falha se qualquer rota fora da allowlist responder ≠ 401 sem sessão.
- O mesmo arquivo registra um controller-fixture de teste **sem** `@Public()` e prova que a varredura o acusa — a garantia de que o sweep pega violação, sem depender de mutação manual do código de produção.
- A allowlist literal no teste tem exatamente: `GET /health`, `GET /v1/public/contents`, `GET /v1/public/contents/:slug`, `POST /v1/auth/login`, `GET /v1/media/proxy`, `GET /v1/preview/:token` (logout/me exigem sessão).
- O spec de contrato do item 25 (`backend/test/public-rate-limit.e2e-spec.ts`) segue verde **sem modificação nesta fase**.
- `cd backend && pnpm test:e2e` verde.

#### T2.6 — Textual: CHANGELOG + parecer CISO da F2 **[paralela: sim]** **[textual — lote da fase]**

Parecer em `docs/26-auth-multi-tenant/pareceres/parecer_f2.md` — pontos: guard global e
allowlist; helper único do tenant; postura CSRF (D26.5); T5 (regex `localhost` ×
`credentials`); T6 (destino do `media/proxy` — decide a D26.7); T8 (token do QR — TTL,
hash, escopo, 404 indistinguível, revogação). **Sem parecer, F2 não mergeia** (e como
ela só mergeia com F4, o parecer trava o evento de deploy inteiro).

**DoD**
- `CHANGELOG.md` (`Unreleased`) cita a F2 (guard global, tenant no path, rotate-key, users, token do QR).
- `docs/26-auth-multi-tenant/pareceres/parecer_f2.md` existe com veredito explícito sobre três pontos nomeados: a regex `localhost` no CORS com `credentials: true` inclusive em produção (T5), o destino de `GET /v1/media/proxy` sob o guard (T6) e o token de visualização do QR — TTL, hash, escopo, 404 indistinguível, revogação (T8). Se o veredito do proxy for "exige sessão", há entrada nova em `docs/plans/26-auth-multi-tenant/variance_report.md` e a D26.7 deste plano está revisada antes do merge.

### F4 — Editor: login, sessão, tenant explícito e QR **(1 PR — mergeia junto com a F2)**

Branch `feature/26-f4-editor-login`, empilhada na F2.

#### T4.1 — SessionCubit, restauração no boot, redirect global e logout no shell **[paralela: não — base da fase]** **[sub-agente: especialista-apresentacao]**

`modules/auth_module/presentation/session/session_cubit.dart` + estados `sealed`
(`SessionUnknown`/`SessionAuthenticated`/`SessionAnonymous`), provido acima do
`MaterialApp.router` em `apps/driva_editor/lib/app_widget.dart`;
`apps/driva_editor/lib/bootstrap.dart` tenta `me()` antes do primeiro frame (o cookie
httpOnly sobrevive ao F5); `apps/driva_editor/lib/app_router.dart` ganha `redirect`
global (desconhecida → aguarda; anônima e rota ≠ login → `/login?from=<url>`;
autenticada em `/login` → `/projects`) com `refreshListenable` no cubit — **exceção: as
rotas `/preview/t/:token` não exigem sessão** (A7). Botão `Sair` na faixa do shell (slot
de ações existente do `AppShellController`), que chama logout e volta ao login. Com
`useFakeData`, o fake da F3 responde `me()` logado — o editor abre sem tela de login,
sem caso especial no router.

**DoD**
- Widget test prova o deep link: abrir `/projects/p1/contents/c1/edit` anônimo cai em `/login` e, após login (fake), navega de volta à URL original — asserção sobre a rota final do `GoRouter`.
- Widget test prova o F5: com `me()` resolvendo usuário, abrir qualquer rota **não** passa pelo `/login`.
- Widget test prova o fake (A6): `useFakeData` abre a home sem tela de login.
- A rota `/preview/t/abc` renderiza sem sessão (redirect não a intercepta) — teste dedicado.
- `apps/driva_editor/test/app_router_test.dart` existe (nasce nesta tarefa, se ainda não existir) e `cd apps/driva_editor && flutter analyze && flutter test -r compact test/modules/auth_module test/app_router_test.dart` saem verdes.

#### T4.2 — LoginPage fora do shell **[paralela: sim — ∥ T4.3; arquivos disjuntos]** **[sub-agente: especialista-apresentacao]** _(dep. T4.1)_

`modules/auth_module/presentation/login/`: `login_page.dart` (`static Widget
pageBuilder` — único ponto com `getIt`), `cubit/login_cubit.dart` + `login_state.dart`
(`part of`, `sealed`), `widgets/login_form.dart` e banner de erro (reusar
`core/widgets/feedback/` se servir). Rota fora do `ShellRoute` (gabarito: rotas de
preview). Mensagem de erro única (não distingue e-mail de senha). Tokens do tema
(gates 1 e 4 valem).

**DoD**
- `apps/driva_editor/lib/modules/auth_module/presentation/login/login_page.dart` existe com `static Widget pageBuilder`, e a rota `/login` está registrada **fora** do `ShellRoute` em `apps/driva_editor/lib/app_router.dart`.
- `bloc_test` do `LoginCubit`: sucesso emite estado autenticando→sucesso; `UnauthorizedFailure` emite erro com a mensagem única — a mesma para e-mail inexistente e senha errada (asserção de igualdade).
- Widget test do form: submeter com campo vazio não chama o use case; erro mostra o banner com ícone + texto (cor nunca é o único sinal).
- Da raiz, `bash scripts/gates_guard.sh` verde; `cd apps/driva_editor && flutter test -r compact test/modules/auth_module` verde.

#### T4.3 — Rede: `withCredentials`, interceptor de 401 e `createDio` limpo **[paralela: sim — ∥ T4.2]** **[sub-agente: especialista-dados]** _(dep. T4.1)_

`apps/driva_editor/lib/core/network/dio_client.dart`: no web, adapter com
`withCredentials = true` (import condicional — os testes em VM ficam no adapter
default); **sai o wrapper de `x-project-id`** (linhas 21–28 atuais); entra
`session_expiry_interceptor.dart` **depois** do `RetryInterceptor` (T2 do specs: o
retry repassa 401 intocado), que em 401 fora das rotas de auth invoca o callback
`onUnauthorized` injetado (fiado ao `SessionCubit` no `injection.dart`) — uma ida ao
login, sem loop (401 do próprio `/auth/login` não dispara).

**DoD**
- `apps/driva_editor/lib/core/network/dio_client.dart` não contém `x-project-id` e a ordem literal dos interceptors é: `RetryInterceptor`, interceptor de sessão, `LogInterceptor` (este só fora de release).
- Teste do interceptor com adapter fake: 401 numa rota qualquer chama `onUnauthorized` exatamente uma vez, mesmo com 3 requests paralelos falhando (sem loop); 401 vindo de `/v1/auth/login` **não** chama.
- No web, o adapter tem `withCredentials` verdadeiro — teste compila o par condicional e asserta a flag na variante web (ou, se inviável em VM, o arquivo da variante web contém a atribuição literal e o `flutter build web` do editor sai verde: `cd apps/driva_editor && flutter build web --target lib/main_dev.dart`).
- `cd apps/driva_editor && flutter analyze && flutter test -r compact test/core/network` verdes.

#### T4.4 — `projectId` explícito fim-a-fim: morte do `ProjectScope` e as URLs aninhadas **[paralela: não — dep. T4.3]** **[sub-agente: especialista-dados]**

O débito do item 46 executado: `apps/driva_editor/lib/core/network/project_scope.dart`
**apagado**; `DEFAULT_PROJECT_ID` sai de `core/config/app_config.dart` e de
`injection.dart`; os contratos de repositório de `contents_module` e `editor_module`
passam a receber `projectId` explícito, os use cases e cubits o repassam, e os
`pageBuilder`s o leem da rota (já o fazem — `project_detail_page.dart:51`,
`editor_page.dart:103`, `preview_page.dart:38` deixam de estampar o singleton). As URLs
dos 17 call sites migram para `/v1/projects/:projectId/...`
(`editor_repository_impl.dart` 9, `contents_repository_impl.dart` 4,
`categories_repository_impl.dart` 4). O teste de elo (lição do item 53): montar a
árvore real a partir da rota e provar que o `projectId` chega ao repositório.

**DoD**
- `apps/driva_editor/lib/core/network/project_scope.dart` não existe; `rtk proxy grep -rn "ProjectScope\|DEFAULT_PROJECT_ID" apps/driva_editor/lib/` devolve zero.
- `rtk proxy grep -rn "'/v1/contents\|'/v1/categories" apps/driva_editor/lib/` devolve zero — todas as URLs de dados carregam `/v1/projects/$projectId/`.
- Teste de elo: montar `EditorPage` pela rota `/projects/p1/contents/c1/edit` com repositório fake e assertar que o fake recebeu `projectId == 'p1'` (mesmo padrão do teste de elo do item 53).
- Os fakes (`useFakeData`) seguem funcionando sem `DEFAULT_PROJECT_ID` — teste abre a lista de projetos em modo fake.
- `cd apps/driva_editor && flutter analyze && flutter test -r compact` verdes (suíte inteira — a mudança atravessa módulos).

#### T4.5 — Capa autenticada: `SessionImageProvider` **[paralela: sim — ∥ T4.4; arquivos disjuntos]** **[sub-agente: especialista-apresentacao]** _(dep. T4.3)_

D26.4: `apps/driva_editor/lib/core/network/session_image_provider.dart` —
`ImageProvider` que busca bytes pelo `Dio` compartilhado (que tem `withCredentials`) e
decodifica; substitui `Image.network` nos dois call sites da capa
(`project_cover.dart:41`, `cover_preview.dart:25`). O erro mantém o placeholder atual
da capa (sem tela vermelha).

**DoD**
- `apps/driva_editor/lib/core/network/session_image_provider.dart` existe e os dois arquivos `apps/driva_editor/lib/modules/projects_module/presentation/widgets/project_cover.dart` e `.../project_form/cover_preview.dart` não contêm mais `Image.network`.
- Teste de widget com Dio fake: bytes válidos renderizam a imagem; resposta 401/erro mostra o placeholder existente e `tester.takeException()` é `null`.
- O provider deduplica por URL (mesma URL não dispara dois GETs simultâneos) — teste com contador no fake.
- `cd apps/driva_editor && flutter test -r compact test/modules/projects_module` verde.

#### T4.6 — QR por token: geração no diálogo e rota `/preview/t/:token` **[paralela: sim — ∥ T4.4/T4.5]** **[sub-agente: especialista-apresentacao]** _(dep. T4.3)_

Use case + método de repositório para
`POST /v1/projects/:projectId/contents/:id/preview-token`; quem abre o
`PreviewShareDialog` (o `url` que ele recebe) passa a gerar token novo por abertura e
montar `https://<editor>/preview/t/<token>`; rota `/preview/t/:token` fora do shell
renderiza o preview resolvendo `GET /v1/preview/:token` (sem sessão); token
expirado/revogado (404) mostra a tela dedicada **"Este link de visualização expirou —
gere um novo QR no editor"** — sem formulário de login, sem nome de projeto/conteúdo.

**DoD**
- Abrir o diálogo "Ver no celular" duas vezes gera dois tokens distintos — teste com repositório fake contando chamadas e assertando a URL `/preview/t/` no `PreviewShareDialog.url`.
- Widget test da rota `/preview/t/abc`: resolução com sucesso renderiza o spec (via fake); 404 mostra a tela de expirado, cujo texto contém "gere um novo QR" e **não** contém o nome do conteúdo/projeto do fake.
- A tela de expirado tem ícone + texto (não só cor) e não tem campo de senha/e-mail — asserções por finder.
- `cd apps/driva_editor && flutter analyze && flutter test -r compact test/modules/editor_module` verdes.

#### T4.7 — Textual: CHANGELOG da F4 **[paralela: sim]** **[textual — lote da fase]**

**DoD**
- `CHANGELOG.md` (`Unreleased`) cita: login/logout no editor, morte do `ProjectScope`/`DEFAULT_PROJECT_ID`, URLs aninhadas, capa via provider autenticado e o QR por token.
- `docs/26-auth-multi-tenant/prd.md` corrigido conforme a **VR-26-01** (`docs/plans/26-auth-multi-tenant/variance_report.md`): o caminho feliz nº 5 e a linha "Capa de projeto sob o guard" da tabela de exceções passam a citar o `SessionImageProvider` no lugar de "sem código novo", com referência à VR-26-01 — é a obrigação de fechamento da F4 registrada na própria entrada.

### F5 — Encerramento **(1 PR, topo da pilha — é o PR cujo merge leva F2+F4+F5 juntas)**

Branch `feature/26-f5-encerramento`, empilhada na F4.

#### T5.1 — Comentários mentirosos e limpeza **[paralela: sim — ∥ T5.2]** **[sub-agente: especialista-dados]**

O comentário `multi-tenant real chega no I4` em
`apps/driva_editor/lib/core/config/app_config.dart:34` e o comentário desatualizado do
`model Content` em `backend/prisma/schema.prisma` descrevem esta feature — somem (regra
do repo: comentário que virou mentira é pior que ausência).

**DoD**
- `rtk proxy grep -rn "I4\|multi-tenant real" apps/driva_editor/lib backend/prisma/schema.prisma` devolve zero ocorrências.
- `cd apps/driva_editor && flutter analyze` e `cd backend && pnpm build` verdes.

#### T5.2 — Textual: roadmap, débito de 2026-07-09, relatórios **[paralela: sim]** **[textual — lote da fase]**

`docs/roadmap.md`: item 26 `[x]`; tabela de vigilâncias — a linha "Chave publicável sem
rotação" fecha (rotate-key entregue) e a linha "Auth por `x-project-id`" fecha apontando
para cá; _Validações de campo pendentes_ ganha a linha do 26 (ver §7). Nota de
fechamento do débito em `docs/09-crud-projeto/variance_report.md` apontando para este
item. `docs/26-auth-multi-tenant/final_report.md` + `variance_report.md` (mínimo: a
correção de mecânica da capa, D26.4 — com o OK do dev registrado). Marcas de progresso
neste `plan.md`.

**DoD**
- `docs/roadmap.md` com o 26 `[x]`, as duas linhas de vigilância fechadas e a linha nova em _Validações de campo pendentes_ nomeando: QR em Android físico, cookie/sessão em Safari/iOS, contagem da migração no log de deploy do hml.
- `docs/09-crud-projeto/variance_report.md` tem a nota de fechamento do débito de 2026-07-09 apontando para `docs/26-auth-multi-tenant/`.
- `docs/26-auth-multi-tenant/final_report.md` existe, citando as cinco fases e os dois pareceres; `docs/plans/26-auth-multi-tenant/variance_report.md` (criado em 2026-08-27 com a VR-26-01) contém os desvios da execução; e o PRD já está corrigido conforme a VR-26-01 — conferência do que a T4.7 fez, não trabalho novo desta tarefa.

## 5. Ordem de despacho

```
docs/26-discovery-auth (base da pilha)
  └► F1: T1.1 ─► T1.2 ─┬► T1.3 ∥ T1.4 ─► T1.5 + gate CISO #1
        (∥ com F1 inteira) F3: T3.1 ─► T3.2
  F1+F3 podem mergear quando verdes (nada protegido, nada muda no app)
        F2: T2.1 ─► T2.2 ─► (T2.3 ∥ T2.4) ─► T2.5 ─► T2.6 + gate CISO #2
        F4: T4.1 ─► (T4.2 ∥ T4.3) ─► (T4.4 ∥ T4.5 ∥ T4.6) ─► T4.7
        F5: T5.1 ∥ T5.2
  F2+F4+F5 mergeiam numa operação: escolher o PR da F5 no topo (um deploy)
```

1. **T1.1 → T1.2** sequenciais (base do backend); **T3.1 em paralelo desde o minuto
   zero** (worktree própria, contrato congelado do §3b).
2. **T1.3 ∥ T1.4** (arquivos disjuntos, mesmo especialista retomado ou dois agentes);
   **T3.2** segue a T3.1 no mesmo agente.
3. F2 é sequencial no início (T2.1 → T2.2) e abre em **T2.3 ∥ T2.4** (módulos
   distintos); T2.5 consolida.
4. F4: **T4.1** primeiro; depois **T4.2 ∥ T4.3**; depois **T4.4 ∥ T4.5 ∥ T4.6** (três
   worktrees — data × projects_module × editor_module, arquivos disjuntos).
5. **F4 pode começar (T4.1/T4.2 com fakes) assim que a F3 estiver verde** — só T4.3+
   dependem do contrato real da F2 estar na base da branch.
6. Consolidação antes de publicar a pilha: suíte completa nos dois alvos +
   `bash scripts/gates_guard.sh` + rebase sobre `develop` (a pilha do 25 já terá
   mergeado; conflito esperado só em `CHANGELOG.md`/`docs/roadmap.md`).

## 6. Gate CISO — o que vai em cada parecer

- **Gate #1 (F1, trava o merge da F1):** schema das quatro tabelas (cascades, unique de
  `tokenHash`); forma do cookie (D26.3 — host-only sem `Domain`, `Lax`, `Secure`,
  `Max-Age`); **hash SHA-256 sem pepper** (D26.2 — validar ou endurecer); TTL 7d
  deslizante/teto 30d; parâmetros do argon2id; mensagem única de login; throttle do
  login; `requireEnv` (quais variáveis derrubam o boot); seed idempotente + log de
  adoção; `credentials: true` no CORS (a regex `localhost` fica para o gate #2/T5).
- **Gate #2 (F2, trava o evento de deploy):** guard global + allowlist da varredura
  (T2.5); helper único do tenant e o 404 de não-enumeração; postura CSRF em camadas
  (D26.5); **T5** (regex `localhost` × `credentials`, inclusive produção); **T6**
  (destino do `media/proxy` — decide a D26.7; se sair "sessão", o custo é o
  `SessionImageProvider` cobrir o resolver do proxy, já dimensionado na D26.7); **T8**
  (token do QR: TTL 15 min, hash em repouso, escopo de um conteúdo, 404 indistinguível,
  revogação no logout, throttle da resolução).

## 7. Definition of Done do item

- [ ] `cd backend && pnpm build && pnpm lint && pnpm test && pnpm test:e2e` verdes.
- [ ] `cd apps/driva_editor && flutter analyze && flutter test -r compact` verdes; `bash scripts/gates_guard.sh` verde na branch integrada.
- [ ] A varredura de rotas (`backend/test/route-sweep.e2e-spec.ts`) verde com a allowlist literal de seis rotas públicas — nenhuma rota fora dela responde sem sessão.
- [ ] Isolamento provado com dois usuários: B cria projeto; A recebe 404 no projeto de B e não o vê em `GET /v1/projects` (teste da T2.2).
- [ ] `rtk proxy grep -rn "x-project-id" backend/src apps/driva_editor/lib` → zero; `ProjectScope`/`DEFAULT_PROJECT_ID` → zero.
- [ ] Deep link → login → volta à URL pedida; F5 não desloga; 401 no meio do uso → login sem loop (testes da T4.1/T4.3).
- [ ] QR: gerar token → abrir `/preview/t/:token` sem sessão renderiza; expirado mostra a tela dedicada (testes T2.4/T4.6).
- [ ] Capas de projeto renderizam sob o guard via `SessionImageProvider` (teste T4.5).
- [ ] Boot sem `ADMIN_EMAIL` falha com mensagem nomeando a variável (teste T1.3).
- [ ] Pareceres do CISO das duas fases em `docs/26-auth-multi-tenant/pareceres/`, com veredito.
- [ ] `CHANGELOG.md` atualizado por fase; `docs/roadmap.md` com o 26 `[x]`, vigilâncias fechadas e a linha nova de _Validações de campo pendentes_: **QR num Android físico** (câmera real → rascunho), **cookie/sessão em Safari/iOS** (ITP e `SameSite` em WebKit real), **contagem da migração no log de deploy do hml** — com o item 26 como origem.

## 8. O que ainda precisa do dev

1. **D26.4 (capa) — resolvido em 2026-08-27:** o dev aprovou o registro; a entrada é a
   **VR-26-01** (`docs/plans/26-auth-multi-tenant/variance_report.md`). O requisito do
   PRD fica intacto (capas continuam; `@Public()` proibido); a mecânica é o
   `SessionImageProvider` da T4.5. **O fechamento da F4 inclui corrigir a linha do PRD**
   (caminho feliz nº 5 + tabela de exceções) citando a VR-26-01 — não antes da entrega
   da T4.5, porque a mecânica final é a que a implementação provar. Quem fechar a F4
   confere isso junto do DoD da fase.

Nada mais pende do dev: T4 decidida (D26.2), forma da rota decidida (D26.1), números de
sessão e destino do proxy são do gate CISO (D26.3/D26.7).
