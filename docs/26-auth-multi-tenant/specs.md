# Specs — Item 26: Autenticação e multi-tenant real

> Discovery do PM, 2026-08-27. Base: `docs/roadmap.md` › Marco 6 (linha 205),
> plano de gaveta `docs/plans/26-auth-multi-tenant/plan.md` (2026-08-13) e
> varredura do código em `develop` (commit `f8a03f3`).
>
> **Status: levantamento fechado; as ambiguidades da §7 aguardam decisão do
> dev (via tech-manager) antes de o plano técnico ser revisado.**
>
> **Gate CISO é dono da feature, não revisor de fim de fase** — regra herdada
> do plano de gaveta, reafirmada aqui: nenhuma fase mergeia sem parecer.

## 1. O problema, hoje, no código

O "auth" do driva é esta função, **triplicada** em três controllers:

```ts
const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';
```

Quem manda o header `x-project-id` manda no projeto: lê, edita, publica,
arquiva, apaga — e, desde o item 25, pega a `publishableKey`. Não há usuário,
não há sessão, não há dono. O débito foi aceito em 2026-07-09
(`docs/09-crud-projeto/variance_report.md` › _Auth_) com o limite registrado:
**auth entra antes de abrir para usuários reais** — e o item 25 (entrega ao
app cliente) acabou de fechar, então o limite chegou.

## 2. Estado atual, levantado no código (2026-08-27)

### 2.1 Backend (`backend/src/`)

**Onde o `projectOf` mora e quantas rotas cobre:**

| Arquivo | Rotas sob o header | Observação |
| --- | --- | --- |
| `contents/contents.controller.ts:21` | **12** (list, create, find, update, remove, publish, unpublish, versions ×2, restore, checkpoints ×2) | Cresceu desde o plano de gaveta: os itens 50/53 adicionaram versões e checkpoints. |
| `categories/categories.controller.ts:16` | 4 (list, create, update, remove) | Igual ao plano. |
| `projects/projects.controller.ts:27` | **só a `list()`** (linha 41) | Ver o furo abaixo. |

**O furo que o plano de gaveta descreve menor do que é:** em
`projects.controller.ts`, as rotas `find`/`update`/`remove`/`archive`/
`unarchive`/`getImage` operam pelo `:id` da URL **sem tenant check nenhum —
nem o header elas leem** (linhas 63–115). O `ProjectMemberGuard` desenhado na
D3 do plano lê só `x-project-id`; para essas rotas ele precisa validar o
**param `:id`**, senão o guard global protege contra anônimo mas qualquer
usuário logado continua alcançando projeto alheio por URL.

**O que não existe** (grep em 2026-08-27, zero ocorrências):
- Tabelas/módulos de auth: nenhum `User`, `Membership`, `Session` no
  `prisma/schema.prisma`; nenhum guard, nenhuma dependência de JWT/argon2/
  cookie-parser no `package.json`.
- `POST /v1/projects/:id/rotate-key`: **nunca foi implementado**. Foi
  desenhado na D1 do plano do 25 e a tabela de vigilâncias do roadmap o
  reatribui ao 26. `projects/publishable-key.ts` só gera a chave
  (`pk_` + 32 bytes base64url) na criação do projeto.

**O que já existe e o 26 aproveita:**
- `configure-app.ts` (o bootstrap extraído, pós-plano): `trust proxy 1` (rate
  limit por IP real atrás do Traefik), `ValidationPipe` global, prefixo `v1`,
  CORS em duas camadas — `*` **só** no prefixo `/v1/public`
  (linhas 43–56) e lista `CORS_ORIGINS` + **regex `localhost` sempre
  permitida** para o resto (linhas 58–66, `allowedHeaders:
  ['content-type','x-project-id']`, sem `credentials`).
- `@nestjs/throttler` com o padrão `@Throttle` por handler — e a lição da
  fatia 2 do 25: `ThrottlerModule` é `@Global()` e múltiplos `forRoot`
  disputam o token; o rate limit do login deve seguir o padrão por handler,
  não um `forRoot` novo.
- Rota pública do 25: `public/public.controller.ts`, autenticada por
  **`x-driva-key`** (chave publicável), throttle 120/min, `ETag`/304.
- Proxy de mídia (item 39/44, pós-plano): `media/media.controller.ts` —
  `GET /v1/media/proxy?url=…`, sem auth, com throttle e anti-SSRF
  (`url-guard.ts`); o `media.service.ts` documenta que **nenhum header do
  chamador é repassado**.
- Schema: `ContentVersion.createdBy` **e** `ContentCheckpoint.createdBy`
  (este, novo, do item 53) — ambos nullable, **nunca escritos**
  (`contents.service.ts:317` e `:235` não os setam), mas **já lidos e
  devolvidos** nas listagens de histórico (`:400–478`). O 26 tem **dois**
  pontos de escrita a preencher, não um.
- Sem `@nestjs/config` — env é `process.env` direto; o segredo de sessão
  obrigatório-que-derruba-o-boot precisa ser feito à mão.

### 2.2 Editor (`apps/driva_editor/`)

- **`core/network/project_scope.dart`** — o singleton de 10 linhas, default
  `'default'`, vivo. O item 46 pôs o `projectId` na rota
  (`/projects/:projectId/contents/:id/edit`) e os `pageBuilder`s o estampam
  (`project_detail_page.dart:51`, `editor_page.dart:103`,
  `preview_page.dart:38`) — mas o singleton continua sendo o transporte até o
  `Dio`. **Débito herdado do 46 (roadmap, linha 205): matá-lo** —
  `projectId` explícito em repositório/use case — **e junto o
  `DEFAULT_PROJECT_ID` compilado** (`core/config/app_config.dart:18–21`,
  semeado em `injection.dart:18`).
- **`core/network/dio_client.dart`** — único ponto que estampa o header
  (interceptor `onRequest`, linha 24). Ordem atual: projeto → retry → log.
  O `RetryInterceptor` **não retenta 401** (só falha de conexão e
  502/503/504) — não conflita com um refresh automático, mas a ordem
  auth×retry precisa de decisão técnica (pergunta T2, §8).
- **`app_router.dart`** — go_router com `rootNavigatorKey`, `ShellRoute`, e
  as rotas de preview **fora** do shell (gabarito pronto para a rota de
  login sem chrome). `onException` manda para a home. **Não há `redirect`
  global hoje.**
- **`bootstrap.dart`** — `runZonedGuarded`, `SharedPreferences` antes do
  `setupInjection`; é onde a sessão seria restaurada antes do primeiro frame.
- **Módulos**: `projects_module` (novo, pós-plano), `contents_module`,
  `editor_module`, `preferences_module` (o gabarito de módulo pequeno que o
  plano cita continua valendo).
- **`useFakeData` default `true`** sem dart-define: dev local sem servidor
  roda com fakes. O fluxo de dev com auth é a ambiguidade A6.
- **Capa de projeto**: `imageUrl` aponta para `GET /v1/projects/:id/image`
  (`projects.service.ts:228`) e é renderizada com `Image.network`
  (`projects_module/presentation/widgets/project_cover.dart:41`,
  `.../project_form/cover_preview.dart:25`) — **`Image.network` não manda
  `Authorization`**. Ver §5 (colisão viva).

### 2.3 Infra (Coolify/VPS)

- Editor hml: `hml.driva.duckdns.org` · API hml: `api-hml.driva.duckdns.org`
  · prod: `driva.duckdns.org` / `api.driva.duckdns.org`. **Cross-origin,
  mas mesmo "site"** (subdomínios de `driva.duckdns.org`) — se `duckdns.org`
  estiver na Public Suffix List, `SameSite=Lax` funciona para XHR entre eles
  sem virar `None`. É a pergunta T1 (§8); responde a pergunta 1 do §8 do
  plano de gaveta, que era "o item que mais atrasa se descoberto tarde".
- HTTPS nos dois lados, Traefik na frente (`trust proxy 1` já conta com ele).

### 2.4 App cliente (fora da mudança)

`driva_client` autentica por `publishableKey` (`x-driva-key`) e **não entra
em sessão** — confirmado no aviso do plano 25 §6: quando o `x-project-id`
virar sessão, a rota pública não entra; `backend/src/public/` fica fora do
guard global, com `@Public()` explícito.

## 3. O que envelheceu no plano de gaveta (auditoria de 2026-08-27)

O núcleo do plano **continua de pé**: D2 (guard global + `@Public()`
explícito), D3 (membership validada na borda, services intactos), D4 (lista
de projetos por membership), D6 (sem cadastro público, seed idempotente),
D7 (argon2id), D8 (migração: admin adota os projetos existentes), o mapa de
fases P1→P5 com a restrição dura "P2 e P4 deployam juntos". O que mudou:

1. **D3 está incompleta** — as seis rotas de `projects/:id` não usam header
   (§2.1); o guard precisa validar o param, não só o `x-project-id`.
2. **Rotas órfãs do guard** que o plano não conheceu: `GET /v1/media/proxy`
   (item 39/44) precisa de destino declarado (`@Public()` com throttle +
   anti-SSRF, ou morrer sob sessão — decisão A7/T6); as 4 rotas de
   checkpoint (item 53) entram no pacote do `ProjectMemberGuard`.
3. **`createdBy` dobrou**: `ContentCheckpoint.createdBy` (item 53) é o
   segundo ponto de escrita; o plano só conhecia o do `ContentVersion`.
4. **`rotate-key` mudou de natureza**: o plano dizia "proteger o rotate-key
   por papel" como se a rota existisse — ela nunca foi implementada. O 26
   **cria** a rota e já a cria protegida (reatribuição registrada na tabela
   de vigilâncias do roadmap).
5. **Conflito com o débito do 46**: a tabela do §2 do plano diz que o
   `ProjectScope` "continua existindo; passa a ser preenchido pelo login" —
   mas o roadmap manda o 26 **matar o singleton** e o `DEFAULT_PROJECT_ID`
   compilado. O plano precisa ser reescrito nesse ponto (é decisão herdada,
   não reaberta — ver §7, "decisões herdadas").
6. **A colisão da capa (§6 do plano × item 27) continua viva** — ver §5. O
   27 não entregou a rota `/v1/media/:key`; o `media/proxy` atual é outra
   coisa (proxy de URL externa). Como o 26 vai primeiro, a saída da capa é
   pré-requisito do guard global e mora **neste** item.
7. **P5 (E2E) morreu como estava escrito**: E2E está suspenso no repositório
   inteiro (política de 2026-08-20). A fase de testes vira pirâmide
   unit/widget escrita junto de cada fase + registro do que sobrar em
   _Validações de campo pendentes_ do roadmap. O `e2e_hml.sh` do 9g não
   será adaptado enquanto a suspensão valer.
8. **A pergunta 1 do §8 do plano (domínios/cookie) está praticamente
   respondida** pelo mapa de infra (§2.3) — falta só a confirmação da PSL
   (T1).
9. **CORS mudou de endereço**: mora em `configure-app.ts`, não em `main.ts`;
   e a regex `localhost` sempre permitida passa a ser tema de segurança
   quando `credentials: true` entrar (T5).
10. **D1 (JWT em memória + refresh em cookie) merece reabrir** — não por
    estar errada, mas porque duas coisas descobertas depois pesam contra o
    custo dela: o `ProjectMemberGuard` consulta o banco **em toda request de
    qualquer jeito** (o "stateless" do JWT não economiza nada), e a sessão
    por cookie dissolve a colisão da capa (§5). É a ambiguidade **A1**, a
    primeira da fila.

## 4. O que o item entrega — e a fronteira com o 37

### Entra no 26

1. **Usuário e sessão**: login, logout, expiração/renovação, `GET /me`.
2. **Vínculo usuário↔projeto** persistido no banco (forma exata: A2/A3) e
   **validado no servidor** em toda rota escopada — o tenant deixa de ser
   confiança cega no cliente.
3. **Guard global**: tudo nasce protegido; `@Public()` explícito e auditável
   em: `health`, `src/public/*` (chave publicável — aviso do plano 25 §6) e
   as rotas de auth. O destino de `media/proxy` e da capa entra na lista
   conforme A1/A7.
4. **Editor**: tela de login, restauração de sessão no F5, redirect de rota
   (deep link volta à URL pedida após login), logout no shell, tratamento de
   sessão expirada sem loop.
5. **Débito do 46**: fim do singleton `ProjectScope` e do
   `DEFAULT_PROJECT_ID` compilado nos flavors.
6. **`rotate-key`**: a rota nasce, restrita ao dono do projeto.
7. **`createdBy` preenchido** nos dois pontos (versão publicada e
   checkpoint) — fecha o nullable-sem-uso dos itens 24/53.
8. **Migração**: projetos existentes de hml/prod ganham dono (A5).
9. **Seed do primeiro usuário** por ambiente (sem cadastro público).

### Fica no 37 (SaaS) — não entra aqui

- **Organizações** e qualquer coisa acima de projeto.
- **Convite por e-mail** e self-service signup (não há provedor de e-mail na
  infra; o 26 não o introduz).
- **UI de administração** (gestão de membros, papéis, chaves). No 26 a
  criação de usuário é operação de dono via API, sem tela.
- **Gestão de chaves além do rotate**: revogação com janela, chave por
  ambiente, múltiplas chaves.
- **Webhooks**, auditoria completa de ações, SSO/OAuth corporativo, 2FA,
  papéis finos (permissão por conteúdo/categoria, "salva mas não publica").
- Recuperação de senha por e-mail (no 26: reset administrativo).

A régua da fronteira: **o 26 fecha a porta** (ninguém sem sessão mexe em
nada; ninguém com sessão mexe em projeto que não é seu); **o 37 gerencia
quem tem a chave** (organizações, papéis operáveis por UI, ciclo de vida de
credenciais). Tudo que exige provedor de e-mail ou UI administrativa é 37.

## 5. A colisão que não pode ser descoberta em produção: a capa de projeto

`GET /v1/projects/:id/image` é consumida como URL simples por
`Image.network` (§2.2), que não manda `Authorization`. No instante em que o
guard global entrar, **toda capa de projeto quebra** (401 na imagem, card sem
capa em todas as telas), a menos que uma das saídas entre **junto** do guard:

- **(a)** Se a sessão for por **cookie** (A1, opção B): o navegador manda o
  cookie sozinho em `<img>` same-site — a capa continua funcionando **sem
  código novo**. É o argumento de produto mais forte da opção B.
- **(b)** Se a sessão for por **JWT no header** (A1, opção A): a rota
  `/v1/media/:key` (D3 do plano 27 — key de storage não-enumerável,
  `@Public()`, `nosniff`, cache) precisa nascer **no 26**, como pré-requisito
  do guard. Não marcar `/projects/:id/image` como `@Public()` — o `:id`
  vaza em toda URL do editor.

Registro do plano 27 mantido: nenhum dos dois planos pode assumir que o
outro resolveu; como o 26 vai primeiro, a obrigação é daqui.

## 6. Personas, fluxos e requisitos não-funcionais

### Personas

- **Dono do driva (admin do seed)** — hoje, o único usuário real. Loga no
  editor, vê todos os projetos que adotou na migração, opera tudo.
- **Usuário convidado (criado pelo dono via API)** — segundo usuário de um
  projeto; existe para provar o multi-tenant (A não vê projeto de B). Sem
  UI de gestão neste item.
- **App cliente (não-persona de sessão)** — continua com `publishableKey`;
  nada muda para ele.

### Fluxos (o detalhe vira caminho feliz/exceções no PRD)

1. **Login**: `/login` fora do shell → e-mail+senha → sessão criada →
   redirect à URL originalmente pedida (deep link preservado).
2. **Sessão**: F5 não desloga; expiração renova sem o usuário perceber
   (mecânica conforme A1); renovação concorrente não pode gerar logout em
   loop (o bug clássico da fila de refresh, se A1 = JWT).
3. **Vínculo usuário↔projeto**: lista de projetos = memberships do usuário
   (D4); acesso a projeto sem vínculo = **404, não 403** (não revelar que o
   projeto existe); criar projeto = criador vira dono na mesma transação.
4. **Logout**: revoga a sessão no servidor, limpa estado local e volta ao
   login. (Quando o item 17 trouxer cache local, o logout limpa o cache —
   obrigação registrada lá, não aqui, porque o 17 ainda não existe.)
5. **Expiração/revogação**: sessão morta no meio do uso → uma tentativa de
   renovar → falhou, volta ao login com mensagem, sem loop.

### Requisitos não-funcionais — segurança é o coração

- **Gate CISO obrigatório por fase** (herdado do plano; reafirmado): schema/
  sessão, guards, e o par CORS+cookie são os três pareceres mínimos.
- Senha com **argon2id** (`@node-rs/argon2` — lição do PR #47: dependência
  nativa × pnpm estrito do Dockerfile).
- Segredo de sessão ausente **derruba o boot** — nunca default silencioso.
- Token/cookie **nunca** em `localStorage`/`shared_preferences`.
- Rate limit no login (padrão `@Throttle` por handler já existente).
- Mensagem de erro de login **não distingue** "e-mail não existe" de "senha
  errada".
- CORS com `credentials` exige lista explícita de origens; a regex
  `localhost` em produção vira decisão consciente do CISO (T5).
- Sem-membership = 404 (não-enumeração de projetos).
- Rotação/reuso de credencial de renovação detectado → sessão morta (se A1
  = JWT+refresh; se cookie server-side, revogação é imediata por natureza).

## 7. Ambiguidades — para o dev decidir (via tech-manager)

> Formato: opções com impacto/custo, e a recomendação do PM. **A A1 destrava
> A6 e A7 e muda o tamanho de P4 — é a primeira da fila.**

### A1 — Formato de sessão: JWT (access em memória + refresh em cookie) × sessão server-side com cookie httpOnly

**A que destrava as outras.** Define se a colisão da capa (§5) exige rota
nova, o tamanho do interceptor do editor e o fluxo de dev local.

- **Opção A — como o plano travou (D1)**: access JWT 15 min só em memória;
  refresh opaco rotativo em cookie httpOnly.
  - _Custo_: interceptor com fila de refresh no editor (o bug clássico dos N
    refreshes paralelos, que o próprio plano marca como "precisa de teste");
    a capa de projeto **quebra** sob o guard e a rota `/v1/media/:key`
    (plano 27 D3) vira pré-requisito dentro do 26; mais código nos dois
    lados.
  - _Ganho_: validação de token sem banco… **que o `ProjectMemberGuard`
    anula** — ele consulta membership no banco em toda request de qualquer
    jeito. O stateless não compra nada na escala atual (VPS 2 vCPU, um
    usuário real).
- **Opção B — sessão server-side**: cookie httpOnly + Secure + SameSite=Lax
  com id opaco (hash no banco), TTL deslizante; sem token no cliente.
  - _Custo_: uma consulta de sessão por request (que se soma à de membership
    que já vai existir — pode ser o mesmo round-trip); CSRF passa a existir
    de verdade e precisa de defesa declarada (SameSite=Lax + CORS estrito +
    exigir `Content-Type: application/json`/header custom nas mutações —
    parecer do CISO); depende de `hml.driva`/`api-hml.driva` serem same-site
    (T1) — se `duckdns.org` não estiver na PSL, `SameSite` vira `None` e a
    defesa CSRF precisa ser mais forte.
  - _Ganho_: **sem** token store, **sem** interceptor de refresh, **sem** a
    fila e o bug clássico dela; F5 funciona de graça; logout/revogação é
    imediata (apagar a linha); e a capa de projeto **continua funcionando
    sem código novo** (o cookie viaja no `<img>` same-site) — a §5 se
    dissolve.
- **Recomendação do PM: opção B**, condicionada ao T1 (PSL) confirmado pelo
  tech-lead. A D1 do plano foi desenhada antes de duas descobertas que
  invertem a conta: o guard de membership já toca o banco em toda request, e
  a capa quebra com header-auth. A opção B remove as duas maiores fontes de
  bug do P4 e encolhe o item. Se o T1 desmentir o same-site, a recomendação
  cai para a opção A com `/v1/media/:key` no escopo.

### A2 — Onde mora o vínculo usuário↔projeto: tabela própria × claim na credencial

- **Opção A — tabela `Membership` (plano, D5)**: `userId+projectId+role`,
  única fonte de verdade, consultada pelo guard.
  - _Custo_: consulta por request (já paga — ver A1); migração nova.
  - _Ganho_: revogar acesso vale **imediatamente**; é a fundação que o item
    37 (organizações) estende sem refazer.
- **Opção B — claim dentro do token/sessão** (lista de projetos embutida).
  - _Custo_: revogação só na renovação (janela de acesso indevido); credencial
    cresce com o número de projetos; o 37 refaz tudo.
  - _Ganho_: zero consulta extra — irrelevante, pelo mesmo motivo da A1.
- **Recomendação do PM: opção A.** Sem concorrente real; a B só faria
  sentido num mundo stateless que a A1 já descarta.

### A3 — Provedor de identidade: e-mail+senha próprio × OAuth Google × magic link

- **Opção A — e-mail+senha + seed (plano, D6/D7)**: primeiro usuário por
  `ADMIN_EMAIL`/`ADMIN_PASSWORD` no Coolify; seguintes criados pelo dono.
  - _Custo_: guardar hash de senha (argon2id mitiga); reset administrativo
    (sem fluxo por e-mail).
  - _Ganho_: zero dependência externa; dev local e testes triviais; nada a
    registrar em console de terceiro.
- **Opção B — OAuth Google**: sem senha armazenada.
  - _Custo_: registro de app + callback + client id por ambiente; allowlist
    de e-mails para não virar cadastro aberto; dev local e bateria de teste
    acoplados a serviço externo; exclui usuário sem conta Google.
  - _Ganho_: menos superfície de senha — relevante quando houver dezenas de
    usuários, não um.
- **Opção C — magic link**: exige provedor de e-mail que a infra não tem;
  é o mesmo pré-requisito que o roadmap já empurrou para o 37 (convites).
  - _Custo_: infra nova + entregabilidade de e-mail; atrasa o item inteiro.
- **Recomendação do PM: opção A.** OAuth/SSO já está declarado como escopo
  do 37 no plano (§1 "fica fora"); antecipá-lo agora acopla o item à infra
  externa sem usuário que o justifique.

### A4 — Papéis agora ou só a fundação: `owner/editor/viewer` com guards × `role` no schema com enforcement mínimo

A pergunta 2 do §8 do plano ("quantos usuários no primeiro momento?") nunca
foi respondida pelo dono — na prática, hoje é **um**.

- **Opção A — RBAC completo (plano, D5)**: três papéis, `@Roles` em publicar/
  arquivar/rotate/gerir usuário.
  - _Custo_: matriz de permissão inteira escrita e testada **sem uso real**
    (não existe segundo usuário); o 37 vai redesenhar papéis por organização
    e pode invalidar a matriz.
- **Opção B — fundação sem matriz**: a coluna `role` nasce no schema (custo
  de migração agora ≈ zero), todo membro opera tudo no seu projeto, e
  apenas as operações destrutivas/sensíveis (`rotate-key`, delete/archive de
  projeto, criar usuário) exigem `owner`.
  - _Custo_: se o segundo usuário real precisar de "só leitura" antes do 37,
    o guard fino é retrofit — pequeno, porque a coluna já existe.
- **Recomendação do PM: opção B.** Código de permissão não exercitado é o
  pior tipo de código de segurança: parece proteger e ninguém nunca o viu
  negar nada. O 26 fecha a porta; a matriz fina é exatamente o produto do 37.

### A5 — Migração dos projetos existentes (hml e prod sem dono)

- **Opção A — o admin do seed adota tudo (plano, D8)**: seed idempotente
  cria `Membership(owner)` do admin para todos os projetos existentes.
  - _Custo_: nenhum relevante — todos os projetos de hml/demo são do dono.
  - _Ganho_: nenhum projeto órfão; o admin loga e vê tudo; contagem
    antes/depois audita a migração.
- **Opção B — adoção manual por lista**: só projetos listados ganham dono.
  - _Custo_: projeto esquecido vira inacessível para sempre (sem UI de
    reatribuição até o 37); trabalho manual sem ganho, dado que só existe um
    usuário.
- **Recomendação do PM: opção A.**

### A6 — Fluxo de dev local: como se trabalha com auth ligado

- **Opção A — fakes = sessão embutida; backend local = login real**:
  `useFakeData` continua abrindo o editor sem login (sessão fake no
  repositório fake); contra backend local, login de verdade com o seed do
  `.env` local.
  - _Custo_: o repositório fake de auth precisa existir (o plano já o previa:
    `auth_repository_fake.dart`); quem roda contra backend local digita
    login uma vez por sessão.
- **Opção B — flag `AUTH_DISABLED` no backend para dev**.
  - _Custo_: uma flag que desliga autenticação é o buraco clássico — um dia
    ela vaza para hml/prod. **Não recomendar nem como opção de conveniência**;
    se o dev a quiser, o CISO precisa vetar ou cercar.
- **Recomendação do PM: opção A.** Mantém o contrato "produção e dev rodam o
  mesmo código de segurança" e o hábito de `useFakeData` intacto.

### A7 — O QR "ver no celular" e o preview sob sessão

Caso de borda **de produto** que nenhum plano registrou: o
`/preview/:projectId/:id` é rota do editor e consome a API autenticada. Com
o guard ligado, abrir o QR no celular vai **pedir login no celular**.

- **Opção A — pede login mesmo**: rascunho é dado privado; quem quer ver no
  celular loga no celular.
  - _Custo_: fricção real no fluxo "ver no celular" (digitar senha no
    aparelho); o QR deixa de ser "aponte e veja".
- **Opção B — link de preview assinado** (token curto, escopo só-leitura de
  um conteúdo, expira em minutos).
  - _Custo_: superfície nova de credencial em URL (histórico do navegador,
    logs de proxy — CISO); mais uma fase no item.
- **Recomendação do PM: opção A no 26**, com o custo de fricção **medido**
  (é o mesmo racional da saída (c) do item 51: aceitar o atrito com aviso,
  registrar o refinamento). O link assinado fica registrado como candidato a
  item futuro se o atrito doer — não engordar o 26 com uma credencial nova.

### A8 — Gestão mínima de usuário no 26: rota de owner sem UI × nada além do seed

- **Opção A — `POST /v1/users` restrito a owner (plano, D6)**: dá para criar
  o segundo usuário e provar multi-tenant de verdade (A não vê projeto de B)
  sem tela.
  - _Custo_: uma rota + DTO + teste; reset de senha administrativo junto.
- **Opção B — só o admin do seed até o 37.**
  - _Custo_: o multi-tenant fecha sem nunca ter sido exercitado com dois
    usuários reais — o critério de aceite do plano ("B cria projeto; A não
    vê") viraria teste de integração apenas.
- **Recomendação do PM: opção A.** É barata e é o que permite ao dono
  **demonstrar** o isolamento — o argumento de venda do item.

## 8. Perguntas técnicas abertas (para o tech-lead, não travam o discovery)

- **T1** — `duckdns.org` está na Public Suffix List? Define se
  `hml.driva.duckdns.org` × `api-hml.driva.duckdns.org` são same-site
  (SameSite=Lax suficiente) ou cross-site (`SameSite=None` + defesa CSRF
  reforçada). **Condiciona a recomendação da A1.**
- **T2** — Ordem dos interceptors no `Dio` (auth × `RetryInterceptor` × log)
  e o comportamento do retry durante renovação de sessão; hoje o retry não
  retenta 401 — confirmar que continua assim.
- **T3** — Com o débito do 46 executado (projectId explícito em
  repositório/use case), o tenant continua viajando como header
  `x-project-id` validado pelo guard, ou muda para path param nas rotas? O
  plano assume header; trocar rota é custo de API + driva_client não é
  afetado (rota pública é outra) — mas os 3 controllers e todos os
  repositórios do editor sim.
- **T4** — Entra `@nestjs/config` ou o "segredo ausente derruba o boot"
  continua em `process.env` manual? (Padrão do repo hoje: manual.)
- **T5** — [CISO] A regex `localhost` no CORS (`configure-app.ts:62`) pode
  continuar quando `credentials: true` entrar — inclusive em produção?
- **T6** — [CISO] `GET /v1/media/proxy` fica `@Public()` (throttle +
  anti-SSRF existentes bastam?) ou passa a exigir sessão — sabendo que
  `Image.network` não manda header e, na opção B da A1, o cookie resolve?
- **T7** — Divergência de registro: a fatia 2 do 25 foi dada como fechada em
  2026-08-27, mas `packages/driva_client/pubspec.yaml` está em `0.1.0` e o
  roadmap ainda mostra a F5 aberta. Nada disso muda o 26 (o app cliente não
  entra em sessão); confirmar com o tech-manager se há registro pendente de
  merge antes de o plano revisado citar versões.

## 9. Decisões herdadas (não reabertas aqui)

- **Guard global com `@Public()` explícito** (D2 do plano) — proteger por
  default é a única postura defensável; não há opção concorrente séria.
- **404 (não 403) para projeto sem vínculo** (D3) — não-enumeração.
- **`src/public/` fora do guard** — aviso registrado no plano 25 §6.
- **Matar o `ProjectScope` + `DEFAULT_PROJECT_ID`** — decisão do dono na A4
  do item 46 (2026-08-17): "correção pontual agora, o estrutural é do 26".
  O 26 é o "depois"; não se adia duas vezes.
- **Sem cadastro público no 26** — fronteira com o 37, registrada no roadmap.
- **argon2id para senha** (D7), se a A3 sair como recomendado.
- **P2 (guards) e P4 (editor) deployam juntos** — a restrição dura do plano
  continua verdadeira em qualquer variante das ambiguidades.

## 10. Fora de escopo (declarado, para não voltar como surpresa)

Tudo da lista "fica no 37" (§4) e, além dela: expiração por inatividade
configurável, limite de sessões simultâneas, histórico de logins, política
de senha além de tamanho mínimo, lockout progressivo por tentativas (o rate
limit por IP cobre o primeiro momento — registrar reavaliação no 37).
