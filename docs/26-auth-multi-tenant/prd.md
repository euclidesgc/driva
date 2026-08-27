# PRD — Item 26: Autenticação e multi-tenant real

> **APROVADO — decisões do dev registradas em 2026-08-27** (via
> tech-manager). Este PRD é o contrato do "pronto" do item 26. As oito
> ambiguidades do discovery estão decididas (`specs.md` §7, cada uma com
> data e opções preservadas para registro); as respostas técnicas T1–T3 do
> tech-lead estão no `specs.md` §8.
>
> Par deste documento: [`specs.md`](specs.md) (levantamento, decisões e
> especificação do token de visualização). Plano técnico: a revisão de
> [`docs/plans/26-auth-multi-tenant/plan.md`](../plans/26-auth-multi-tenant/plan.md)
> pelo tech-lead é o próximo passo — a lista do que ele herda está na seção
> _O que o plano revisado herda_ ao final.
>
> **Gate CISO por fase é condição de merge, não revisão final.** Os pontos
> nomeados para o gate estão na seção _Gate CISO_ abaixo.

## Problema

Qualquer pessoa com a URL da API e um id de projeto lê, edita, publica,
arquiva e apaga tudo — o "auth" é o header `x-project-id`, que o próprio
cliente escolhe. O débito foi aceito em 2026-07-09 com um limite explícito:
**auth entra antes de abrir para usuários reais**. O item 25 fechou; o
driva tem app cliente de verdade; o limite venceu.

## Objetivo

Fechar a porta: ninguém sem sessão acessa a API do editor; ninguém com
sessão acessa projeto que não é seu; o escopo de tenant deixa de vir do
cliente e passa a ser validado no servidor — sem quebrar o app cliente
(chave publicável), o fluxo do QR do item 51, nem o hábito de dev local.

## Escopo

1. **Sessão server-side por cookie** (A1): sessão no Postgres; cookie
   httpOnly, **host-only** (sem atributo `Domain`), `SameSite=Lax`,
   `Secure`. Logout e revogação são delete de linha — valem imediatamente.
2. **Identidade por e-mail+senha** (A3): argon2id; primeiro usuário por
   seed idempotente (`ADMIN_EMAIL`/`ADMIN_PASSWORD` no Coolify); seguintes
   por `POST /v1/users` restrito a owner, sem UI (A8); reset administrativo.
3. **Vínculo usuário↔projeto na tabela `Membership`** (A2), com a coluna
   `role` no schema e **enforcement mínimo** (A4): todo membro opera tudo no
   seu projeto; só `rotate-key`, delete/archive de projeto e criar usuário
   exigem `owner`.
4. **Guard global** com `@Public()` explícito e auditável: `health`,
   `src/public/*` (autenticado por `x-driva-key` — aviso do plano 25 §6),
   rotas de auth, e o destino de `media/proxy` conforme o gate (T6).
5. **Tenant no path, header morto** (T3): rotas aninhadas
   `/v1/projects/:projectId/contents…` e `…/categories…`; guard valida o
   param num helper único; **`x-project-id` desaparece** do backend, do
   CORS e do editor. Services intactos.
6. **Editor**: tela de login fora do shell, sessão restaurada no F5,
   redirect com retorno à URL pedida, logout no shell, sessão expirada sem
   loop; `withCredentials` no adapter web do Dio — **sem token store, sem
   fila de refresh** (T2).
7. **Débito do item 46**: morte do singleton `ProjectScope` e do
   `DEFAULT_PROJECT_ID` compilado nos flavors.
8. **`rotate-key`** nasce, owner-only (reatribuição da tabela de
   vigilâncias).
9. **`createdBy` preenchido** nos dois pontos de escrita (versão publicada
   e checkpoint — itens 24/53).
10. **Migração**: o admin do seed adota todos os projetos existentes (A5),
    auditada por contagem antes/depois.
11. **Token de visualização do preview** (A7): o QR "ver no celular"
    continua de uma mão só — ver a seção própria abaixo.
12. **Dev local** (A6): `useFakeData` segue abrindo o editor sem login
    (sessão fake embutida); contra backend local, login real com o seed do
    `.env`. **Não existe flag `AUTH_DISABLED`** — vetada por desenho.

## Não-escopo (nomeado, para não voltar como surpresa)

- **`/v1/media/:key` NÃO entra** — a decisão A1 (cookie) dissolveu a
  colisão da capa de projeto que a exigiria; se o item 27 quiser a rota por
  outro motivo (servir mídia do Garage), a decisão é de lá.
- **OAuth NÃO entra** — registrado na A3 como evolução possível,
  explicitamente fora deste item.
- Organizações, convite por e-mail, self-service signup, UI de
  administração (membros, papéis, chaves, tokens), gestão de chaves além do
  rotate, webhooks, SSO corporativo, 2FA, papéis finos, recuperação de
  senha por e-mail → **item 37**.
- Expiração por inatividade configurável, limite de sessões simultâneas,
  histórico de logins, lockout progressivo (rate limit por IP cobre o
  primeiro momento; reavaliação registrada no 37).

## Personas

- **Dono do driva** (admin do seed): único usuário real hoje; adota todos os
  projetos na migração.
- **Usuário convidado**: criado pelo dono via API; prova o isolamento entre
  tenants (A não vê projeto de B).
- **App cliente**: fora da mudança — `x-driva-key` continua sendo a
  autenticação da rota pública.

## Caminho feliz

1. Usuária abre `https://hml.driva.duckdns.org/projects/abc/contents/x/edit`
   sem sessão → o editor redireciona para `/login` guardando a URL pedida.
2. E-mail e senha → `POST /v1/auth/login` valida (argon2id), cria a linha de
   sessão e devolve o cookie httpOnly host-only (`Secure`, `SameSite=Lax`).
3. O editor volta para a URL pedida no passo 1. `GET /v1/projects` lista as
   memberships dela.
4. Toda request seguinte viaja com o cookie (same-site — T1: `duckdns.org`
   está na PSL, o site é `driva.duckdns.org`); o guard resolve sessão →
   usuário → membership no `:projectId` do path → segue ao service.
5. As capas de projeto continuam aparecendo — o cookie viaja no `<img>`
   same-site, sem código novo.
6. F5, aba nova, voltar amanhã: a sessão persiste pelo cookie até o TTL
   deslizante; nenhuma renovação visível, nenhuma fila de refresh.
7. "Ver no celular": o diálogo gera o QR **com token de visualização**; o
   celular abre o rascunho sem login (seção abaixo).
8. `Sair` → delete da sessão no servidor, tokens de visualização vivos do
   usuário revogados, estado local limpo, volta ao `/login`.

## O token de visualização do QR (decisão A7, especificação)

_Spec completa com racional: `specs.md` §7 › A7. Resumo normativo:_

- **Forma**: token opaco (32 bytes aleatórios base64url), guardado como
  **hash**; linha com `contentId`, `projectId`, `createdBy`, `expiresAt`,
  `revokedAt` — mesma mecânica server-side da sessão.
- **Autoriza**: leitura do rascunho de **um** conteúdo, só o que a página de
  preview renderiza. Sem escrita, sem listagem, sem vizinhos.
- **URL**: carrega só o token (ex.: `/preview/t/:token`); o servidor resolve
  projeto/conteúdo — os ids saem da URL.
- **Expiração: 15 minutos** da geração; cada abertura do diálogo "Ver no
  celular" gera token novo.
- **Revogação**: delete/`revokedAt` da linha; **logout do criador revoga os
  tokens vivos dele**. Sem UI de gestão no 26.
- **Expirado/inválido/revogado**: API responde **404 indistinguível**; o
  celular vê a tela dedicada **"Este link de visualização expirou — gere um
  novo QR no editor"** — sem formulário de login, sem vazar nome de projeto
  ou conteúdo (a tela de falha não mente, lição do item 46).
- **Guardas**: rate limit por IP na rota de resolução; TTL curto + hash em
  repouso + escopo mínimo mitigam a credencial em URL.
- **É superfície nova de credencial → gate CISO (T8).**

## Exceções e casos de borda

| Caso | Comportamento esperado |
| --- | --- |
| Senha ou e-mail errados | Mensagem única ("e-mail ou senha inválidos") — não revelar qual; rate limit por IP no login. |
| Sessão expirada/revogada no meio do uso | Próxima request → 401 → interceptor (depois do retry — T2) limpa estado e manda ao `/login` preservando a URL, **sem loop**. |
| Cookie válido + projeto sem membership | **404** no guard, antes de qualquer service — não-enumeração; vale para o param `:projectId`/`:id`, que é a fonte única (T3). |
| Deep link do editor sem sessão | Login e **volta à URL pedida** — inclusive `/projects/:projectId/contents/:id/edit` (o cenário do item 46). |
| QR aberto no celular com token válido | Rascunho renderiza sem login. |
| QR com token expirado/revogado/forjado | Tela "link expirou — gere um novo QR"; API devolve 404 indistinguível. |
| Logout com QR na parede | Tokens de visualização do usuário morrem junto com a sessão. |
| Rota pública com `x-driva-key` | Continua 200 sem sessão — `@Public()` explícito; app cliente intocado. |
| `GET /health` | 200 sem sessão (monitoração do Coolify). |
| Capa de projeto sob o guard | Continua aparecendo — cookie no `<img>` same-site; **proibido** marcar `/projects/:id/image` como `@Public()`. |
| `useFakeData` (dev sem servidor) | Editor abre **sem** tela de login, com sessão fake do repositório fake. |
| Boot sem segredo de sessão | O backend **não sobe** — falha explícita, nunca default. |
| Migração com projeto órfão | Não existe: contagem projetos × memberships do admin antes/depois audita o seed idempotente. |
| Editor antigo (com header) contra API nova (param) | Impossível por construção: a mudança de URL é breaking e está coberta pela **restrição dura** — guards do backend e editor com login **deployam juntos**, e o token do QR vai no mesmo evento. |
| Dois usuários na mesma máquina | Sem cache local hoje (item 17 não existe); quando o 17 chegar, a chave de cache leva o usuário e o logout limpa o cache — obrigação registrada **lá**. |

## Analytics

Não existe infraestrutura de analytics (débito registrado no PRD do item
51). Mesmo precedente: **eventos nomeados como débito**, sem implementação —

- `login_succeeded` / `login_failed` (sem e-mail no payload)
- `session_expired` (401 levou ao login)
- `logout_clicked`
- `preview_qr_token_generated` / `preview_qr_token_expired_view` (mede se os
  15 min do token estão certos — é o dado que reabre o TTL, se doer)
- `project_access_denied` (404 por falta de membership — também vira log
  estruturado, abaixo, porque é sinal de segurança antes de ser produto)

## Erros monitorados (log estruturado no backend)

- **Tentativa de acesso sem membership** (userId, projectId, rota) — o
  rastro mínimo do multi-tenant.
- **Falhas de login por IP acima do throttle** — força bruta.
- **Resolução de token de visualização inválido/expirado em pico** — alguém
  tentando adivinhar tokens.
- **Boot abortado por segredo ausente** — precisa gritar no log do Coolify.
- **CORS recusando origem** (logar a origem recusada) — o modo silencioso de
  "login funciona local e quebra em hml".
- No editor: loop de 401 (mais de N idas ao login por minuto) via
  `AppBlocObserver`/`log` existente.

## Fases e os testes que cada uma pede

> Estrutura herdada do plano de gaveta (P1→P5), a ser revisada pelo
> tech-lead sobre as decisões; a pirâmide é unit/widget escrita **junto** da
> fase (E2E segue suspenso — o que sobrar vai para _Validações de campo
> pendentes_ do roadmap).

### F1 — Schema, seed e rotas de auth (nada protegido ainda) **[CISO]**

`User`/`Membership`/`Session` + login/logout/me + seed idempotente do admin
adotando os projetos existentes (A5). Cookie emitido já na forma final
(host-only, `Lax`, `Secure`).
**Testes:** unit do hash e do ciclo da sessão (criar/expirar/revogar); e2e
de contrato do login (credencial boa/ruim/throttle); seed duas vezes não
duplica; **o resto da API segue como hoje** (regressão).
**Aceite:** login devolve cookie + usuário; `/me` responde; API inalterada.

### F2 — Guard global, tenant no path, rotate-key, token do QR (backend) **[CISO — a fase perigosa]**

Guard global; `@Public()` em health/public/auth (+ `media/proxy` conforme
T6); rotas aninhadas por `:projectId` com o helper único do guard (T3 — o
`x-project-id` morre aqui, inclusive do `allowedHeaders`);
`GET /v1/projects` por membership; criador vira owner na mesma transação;
`rotate-key` owner-only; `createdBy` nos dois pontos; `POST /v1/users`
owner-only (A8); **rota de resolução do token de visualização** (A7).
**Testes:** varredura automatizada de rotas → 401 sem sessão (exceto
públicas declaradas); matriz de membership por param (404 alheio, 200
próprio); rotate-key troca a chave e a antiga morre; capa servida com
cookie; token do QR: válido resolve, expirado/revogado/forjado → 404
indistinguível; CSRF: mutação cross-site sem cookie Lax é recusada.
**Aceite:** os critérios do plano P2 reescritos para param + "capas
continuam aparecendo" + "QR resolve por token".

### F3 — Editor: módulo de auth (domain/data, sem UI) **[∥ F1/F2]**

Gabarito `preferences_module`; repositório real + fake (A6);
`UnauthorizedFailure` no `sealed Failure` (o compilador lista os call
sites).
**Testes:** unit de use cases e do fake; `flutter analyze` verde;
comportamento do app inalterado.

### F4 — Editor: login, sessão, redirect, QR por token — **deploya junto com F2**

Tela de login fora do shell; `withCredentials` no adapter web + interceptor
de 401 **depois** do retry (T2); redirect global com retorno à URL; logout
no shell (revoga sessão + tokens de visualização); morte do
`ProjectScope`/`DEFAULT_PROJECT_ID` e URLs por param nos 17 call sites
(T3); diálogo "Ver no celular" gera token e QR novo; tela de link expirado
no preview.
**Testes:** widget do redirect (deep link); cubit de login; 401 → login sem
loop e sem fila; URLs dos repositórios batem com as rotas aninhadas (o teste
de elo que o item 53 ensinou a não pular); tela de expirado não vaza nome de
projeto/conteúdo.

### F5 — Encerramento

Varredura final de rotas; contagem da migração em hml; comentários
mentirosos removidos (`app_config.dart:34` "multi-tenant real chega no I4",
comentário do `model Content`); `final_report.md` + `variance_report.md`;
débito de 2026-07-09 fechado com nota no
`docs/09-crud-projeto/variance_report.md`; roadmap: 26 `[x]`, tabela de
vigilâncias atualizada (rotate-key sai). O que só aparelho/navegador real
provam (QR num Android físico, cookie em Safari/iOS) vai para _Validações
de campo pendentes_.

## Critérios de aceite globais

- Nenhuma rota responde sem sessão, exceto as públicas declaradas
  (varredura automatizada, não lista de memória).
- Projeto sem vínculo é indistinguível de inexistente (404), validado pelo
  **param** — não existe mais leitura de `x-project-id` no repositório.
- F5/deep link/expiração sem loop; URL pedida preservada.
- QR: token válido renderiza sem login; expirado mostra a tela dedicada;
  logout revoga.
- Segredo ausente derruba o boot (testado).
- Migração auditada por contagem; zero projeto órfão.
- App cliente e rota pública intocados (contrato do 25 verde).
- Pareceres do CISO por fase anexados em `docs/26-auth-multi-tenant/`.
- `pnpm build`/`pnpm lint`/`flutter analyze`/suítes verdes.

## Restrição dura de deploy

**Guards do backend (F2) e editor com login (F4) deployam juntos** — herdada
do plano de gaveta e agravada pela T3: a mudança de URL (header → param) é
breaking para o editor. **O token do QR vai no mesmo evento**: ligar o guard
sem ele quebraria o fluxo do item 51 na janela. Ou mesmo PR, ou merges na
mesma janela com deploy coordenado.

## Gate CISO (pontos nomeados para o parecer)

1. **Cookie de sessão host-only** (sem `Domain`) — o achado da T1: os quatro
   hosts são o mesmo site; um cookie com `Domain` faria a sessão de hml
   viajar para a API de prod.
2. **T5** — a regex `localhost` no CORS com `credentials: true`, inclusive
   em produção.
3. **T6** — o destino de `GET /v1/media/proxy` sob o guard (`@Public()` com
   throttle + anti-SSRF × sessão via cookie).
4. **T8 — o token de visualização do QR** (superfície nova de credencial em
   URL): TTL 15 min, hash em repouso, escopo de um conteúdo, 404
   indistinguível, revogação no logout — validar ou endurecer.
5. A postura CSRF da sessão por cookie: `SameSite=Lax` + CORS estrito +
   exigência de `Content-Type: application/json` nas mutações.

## Riscos

1. **Deploy F2/F4 dessincronizado** deixa o editor inteiro fora do ar — a
   restrição dura é regra de merge, não recomendação.
2. **Token do QR vazado** (chat, histórico, log de proxy) — mitigado por
   TTL 15 min + escopo só-leitura de um conteúdo + hash em repouso; o gate
   CISO pode endurecer.
3. **Cookie com `Domain` por descuido** — sessão de hml valendo em prod; o
   teste de contrato da F1 fixa o `Set-Cookie` host-only.
4. **CORS com credentials mal configurado** — "funciona local, quebra em
   hml" silencioso; erro monitorado dedicado + teste de contrato.
5. **Lockout do próprio admin** (senha do seed perdida): reset por env no
   Coolify + redeploy — documentar no runbook de deploy.
6. **Premissa da PSL**: o same-site depende da entrada `duckdns.org` na
   Public Suffix List (seção PRIVATE, mantida por submissão do DuckDNS) —
   fora do nosso controle, estável há anos; registrada como premissa, não
   tarefa.

## Decisões (todas do dev, 2026-08-27, via tech-manager)

| # | Decisão | Nota |
| --- | --- | --- |
| A1 | **Sessão server-side por cookie** (Postgres; httpOnly, host-only, `SameSite=Lax`, `Secure`) | Recomendação do PM seguida; sustentada pela T1. Consequências: sem fila de refresh; logout = delete; `/v1/media/:key` fora do 26. |
| A2 | **Tabela `Membership`** | Recomendação seguida. |
| A3 | **E-mail+senha com seed; argon2id; sem cadastro público** | OAuth registrado como evolução, fora deste item. |
| A4 | **`role` no schema, enforcement mínimo** (owner só no destrutivo/sensível) | Recomendação seguida; matriz fina é produto do 37. |
| A5 | **Admin do seed adota todos os projetos existentes** | Recomendação seguida; auditada por contagem. |
| A6 | **Fakes com sessão embutida; nunca `AUTH_DISABLED`** | Recomendação seguida. |
| A7 | **QR por token de visualização** (15 min, opaco+hash, um conteúdo, revogável, tela de expirado) | **Não** era a recomendação do PM (que aceitava a fricção do login); superfície nova no gate CISO (T8). |
| A8 | **`POST /v1/users` owner-only, sem UI** | Recomendação seguida. |

### Herdadas (não reabertas)

Guard global com `@Public()` explícito · 404 para não-membro ·
`src/public/*` fora do guard (aviso do plano 25 §6) · morte do
`ProjectScope`/`DEFAULT_PROJECT_ID` (A4 do item 46) · argon2id ·
CISO por fase · F2+F4 (e o token do QR) num único evento de deploy.

## O que o plano revisado herda (para o tech-lead)

Os pontos da §3 do `specs.md`, atualizados pelas decisões:

1. **D3 reescrita pela T3**: tenant no path (rotas aninhadas
   `/v1/projects/:projectId/contents…` e `…/categories…`), guard com helper
   único (`params.projectId ?? params.id`), `x-project-id` morto no
   backend/CORS/editor (17 call sites mapeados na T3); a forma final da
   rota (aninhada × query) fecha no plano.
2. **D1 reescrita pela A1**: sessão server-side substitui JWT+refresh; sem
   `AuthTokenStore`, sem interceptor de refresh, sem fila; entra
   `withCredentials` + interceptor de 401 depois do retry (T2).
3. **P2 cresce**: as 4 rotas de checkpoint (item 53) e o segundo
   `createdBy`; `rotate-key` é criação, não proteção; `POST /v1/users`; a
   rota de resolução do token do QR (A7).
4. **§6 do plano (colisão da capa) sai da lista de trabalho** — dissolvida
   pela A1; deixar o registro de que `/v1/media/:key` não é mais
   pré-requisito.
5. **A tabela do §2 do plano mente sobre o `ProjectScope`** ("continua
   existindo") — o débito do 46 o mata; reescrever.
6. **P5 reescrita**: E2E suspenso; pirâmide junto de cada fase + registro em
   _Validações de campo pendentes_ (QR em aparelho físico, cookie em
   Safari/iOS).
7. **D5 encolhida pela A4**: papéis ficam como fundação de schema com
   enforcement mínimo; a matriz completa sai do plano.
8. Detalhes de ancoragem: CORS mora em `configure-app.ts` (não `main.ts`);
   throttle por handler (lição dos três `forRoot`); T4 (`@nestjs/config` ×
   `process.env` manual) continua aberta para o plano decidir.
