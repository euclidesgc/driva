# PRD — Item 26: Autenticação e multi-tenant real

> ⚠️ **RASCUNHO — AGUARDANDO APROVAÇÃO DO DEV.** As seções marcadas
> `[decidido]` são decisões herdadas ou sem concorrente sério
> (`specs.md` §9); as marcadas `[aberto: An]` dependem das ambiguidades da
> §7 do `specs.md`, que estão com o dev via tech-manager. O caminho feliz
> abaixo está escrito **na variante recomendada pelo PM** (A1=B: sessão
> server-side com cookie) e será reescrito se o dev decidir diferente.
>
> Par deste documento: [`specs.md`](specs.md) (levantamento e ambiguidades).
> Plano técnico: será a revisão de
> [`docs/plans/26-auth-multi-tenant/plan.md`](../plans/26-auth-multi-tenant/plan.md)
> pelo tech-lead **depois** das decisões — a §3 do specs lista o que
> envelheceu nele.
>
> **Gate CISO por fase é condição de merge, não revisão final** `[decidido]`.

## Problema

Qualquer pessoa com a URL da API e um id de projeto lê, edita, publica,
arquiva e apaga tudo — o "auth" é o header `x-project-id`, que o próprio
cliente escolhe. O débito foi aceito em 2026-07-09 com um limite explícito:
**auth entra antes de abrir para usuários reais**. O item 25 fechou; o
driva tem app cliente de verdade; o limite venceu.

## Resultado esperado

1. **Ninguém sem sessão acessa nada** da API do editor — toda rota nasce
   protegida; as exceções (`health`, `src/public/*` por chave publicável,
   rotas de auth) são explícitas e auditáveis no código. `[decidido]`
2. **Ninguém com sessão acessa projeto que não é seu** — o vínculo
   usuário↔projeto mora no servidor e é validado em toda request; projeto
   alheio responde **404**. `[decidido]`
3. O editor **pede login uma vez** e depois não atrapalha: F5 mantém a
   sessão, deep link volta à URL pedida após o login, expiração renova ou
   despede com mensagem — nunca em loop. `[aberto: A1 define a mecânica]`
4. O app cliente **não percebe nada**: `x-driva-key` continua sendo a
   autenticação da rota pública. `[decidido]`
5. Os débitos herdados fecham juntos: singleton `ProjectScope` e
   `DEFAULT_PROJECT_ID` compilado morrem (item 46); `rotate-key` passa a
   existir, restrito ao dono (item 25/D1); `createdBy` de versão **e** de
   checkpoint passam a registrar quem fez. `[decidido]`

## Personas

- **Dono do driva** (admin do seed): único usuário real hoje; adota todos os
  projetos existentes na migração. `[aberto: A5, recomendação = adota tudo]`
- **Usuário convidado**: criado pelo dono via API (sem UI neste item), prova
  o isolamento entre tenants. `[aberto: A8]`
- **App cliente**: fora da mudança.

## Caminho feliz (variante recomendada — A1=B)

1. Usuária abre `https://hml.driva.duckdns.org/projects/abc/contents/x/edit`
   sem sessão → o editor redireciona para `/login` guardando a URL pedida.
2. Preenche e-mail e senha → `POST /v1/auth/login` valida (argon2id),
   cria a sessão no banco e devolve o cookie httpOnly
   (`Secure`, `SameSite=Lax`) + o usuário.
3. O editor volta **para a URL pedida no passo 1**. A lista de projetos vem
   das memberships dela (`GET /v1/projects` = "meus projetos").
4. Toda request seguinte viaja com o cookie; no servidor, o guard resolve
   sessão → usuário → membership no projeto da request → segue para o
   service, que continua recebendo `projectId: string` como hoje.
5. As capas de projeto continuam aparecendo — o navegador manda o cookie no
   `<img>` same-site, sem código novo.
6. F5, aba nova, fechar e voltar amanhã: a sessão persiste pelo cookie até o
   TTL; renovação é deslizante e invisível.
7. `Sair` no menu do shell → sessão revogada no servidor, estado local
   limpo, volta ao `/login`.

## Exceções e casos de borda

| Caso | Comportamento esperado |
| --- | --- |
| Senha ou e-mail errados | Mensagem única ("e-mail ou senha inválidos") — não revelar qual dos dois; contador de rate limit por IP. |
| Sessão expirada no meio do uso | Uma tentativa de renovação; falhou → `/login` com aviso "sessão expirada", **sem loop** e sem perder a URL. |
| Sessão revogada no servidor (logout em outra aba / admin) | Próxima request → 401 → mesma saída acima. |
| Token/cookie válido + projeto sem membership | **404** (não 403 — não-enumeração), no guard, antes de qualquer service. `[decidido]` |
| Deep link do editor sem sessão | Redireciona ao login e **volta à URL pedida** — inclusive `/projects/:projectId/contents/:id/edit` (o cenário do item 46). |
| QR "ver no celular" | Pede login no celular — rascunho é privado. Fricção aceita e registrada; link assinado é candidato futuro. `[aberto: A7]` |
| Rota pública com `x-driva-key` | Continua 200 sem sessão — `@Public()` explícito. `[decidido]` |
| `GET /health` | 200 sem sessão (monitoração do Coolify). `[decidido]` |
| Capa de projeto sob o guard | Não pode quebrar no deploy do guard — resolvida pela variante da A1 (cookie) ou pela rota `/v1/media/:key` (JWT). `[aberto: A1]` |
| `useFakeData` (dev sem servidor) | Editor abre **sem** tela de login, com sessão fake do repositório fake. `[aberto: A6]` |
| Boot sem segredo de sessão | O backend **não sobe** — falha explícita, nunca default. `[decidido]` |
| Migração aplicada com projetos órfãos | Não existe: contagem de projetos × memberships do admin antes/depois audita o seed. `[aberto: A5]` |
| Editor antigo (sem login) contra API nova | Impossível por construção: guards do backend e editor com login **deployam juntos** — restrição dura herdada do plano. `[decidido]` |
| Dois usuários na mesma máquina | Sem cache local hoje (item 17 não existe); quando o 17 chegar, a chave de cache leva o usuário e o logout limpa o cache — obrigação registrada **lá**. |

## Analytics

Não existe infraestrutura de analytics (débito registrado no PRD do item
51). Seguir o mesmo precedente: **eventos nomeados como débito**, sem
implementação —

- `login_succeeded` / `login_failed` (sem e-mail no payload)
- `session_expired` (renovação falhou e o usuário foi ao login)
- `logout_clicked`
- `project_access_denied` (404 por falta de membership — o sinal de tentativa
  de acesso indevido; este **também** vira log estruturado no backend, ver
  abaixo, porque é sinal de segurança e não de produto)

## Erros monitorados (log estruturado no backend)

- **Tentativa de acesso sem membership** (userId, projectId, rota) — o rastro
  de segurança mínimo do multi-tenant.
- **Falhas de login por IP acima do throttle** — força bruta.
- **Renovação com credencial revogada/reusada** — sinal de roubo de sessão.
- **Boot abortado por segredo ausente** — precisa gritar no log do Coolify.
- **CORS recusando origem** — é o modo silencioso de "login funciona local e
  não em hml"; logar a origem recusada.
- No editor: loop de 401 (mais de N idas ao login por minuto) logado via
  `AppBlocObserver`/`log` existente.

## Fases e os testes que cada uma pede

> Estrutura herdada do plano de gaveta (P1→P5), que o tech-lead revisará
> após as decisões; a pirâmide é unit/widget escrita **junto** da fase (E2E
> segue suspenso — o que sobrar vai para _Validações de campo pendentes_ do
> roadmap). `[decidido: processo]`

### F1 — Schema, seed e rotas de auth (nada protegido ainda) **[CISO]**

Tabelas de usuário/vínculo/sessão + login/logout/me + seed idempotente do
admin (adota os projetos existentes — A5).
**Testes:** unit do hash e da criação/revogação de sessão; e2e de contrato
do login (credencial boa/ruim/throttle); seed rodado duas vezes não duplica
nada; **o resto da API segue funcionando como hoje** (regressão).
**Aceite:** login devolve sessão; `/me` responde; API inalterada no resto.

### F2 — Guard global + membership + rotate-key **[CISO — a fase perigosa]**

Guard global; `@Public()` em health/public/auth (+ `media/proxy` conforme
T6); `ProjectMemberGuard` cobrindo **header e param `:id`** (o furo da §2.1
do specs); `GET /v1/projects` por membership; criador vira dono na mesma
transação; `rotate-key` nasce owner-only; `createdBy` preenchido nos dois
pontos de escrita; destino da capa de projeto embutido (A1).
**Testes:** varredura automatizada de rotas → 401 sem sessão (exceto as
públicas); matriz membership (404 alheio, 200 próprio, param e header);
rotate-key troca a chave e a antiga morre; capa continua servida.
**Aceite:** os quatro critérios do plano P2 + "capas continuam aparecendo".

### F3 — Editor: módulo de auth (domain/data, sem UI) **[∥ F1/F2]**

Gabarito `preferences_module`; repositório real + fake; `UnauthorizedFailure`
no `sealed Failure` (o compilador lista os call sites).
**Testes:** unit de use cases e do repositório fake; `flutter analyze` verde;
comportamento do app inalterado.

### F4 — Editor: login, sessão, redirect, logout — **deploya junto com F2**

Tela de login fora do shell; restauração de sessão no bootstrap; redirect
global do go_router com retorno à URL pedida; logout no shell; morte do
`ProjectScope`/`DEFAULT_PROJECT_ID` (débito 46). O tamanho desta fase
depende da A1 (com cookie server-side não há token store nem fila de
refresh).
**Testes:** widget do redirect (com deep link); cubit de login; sessão
expirada → login sem loop; se A1=JWT, o teste da fila (4 paralelos → 1
refresh) é **obrigatório**.

### F5 — Encerramento

Varredura final de rotas, contagem da migração em hml, comentários mentirosos
removidos (`app_config.dart:34` "multi-tenant real chega no I4", comentário
do `model Content`), `final_report.md` + `variance_report.md`, débito de
2026-07-09 fechado com nota no `docs/09-crud-projeto/variance_report.md`,
roadmap: 26 `[x]`, tabela de vigilâncias atualizada (rotate-key sai).
O que só aparelho/navegador real provam (login em celular via QR, cookie em
Safari/iOS) vai para _Validações de campo pendentes_.

## Critérios de aceite globais

- Nenhuma rota responde sem sessão, exceto as públicas declaradas
  (varredura automatizada, não lista de memória).
- Projeto sem vínculo é indistinguível de projeto inexistente (404) — pelo
  header **e** pelo param.
- F5/deep link/expiração sem loop no editor; URL pedida preservada.
- Segredo ausente derruba o boot (testado).
- Migração auditada por contagem; zero projeto órfão.
- App cliente e rota pública intocados (contrato do 25 verde).
- Pareceres do CISO anexados por fase em `docs/26-auth-multi-tenant/`.
- `pnpm build`/`pnpm lint`/`flutter analyze`/suítes verdes.

## Riscos

1. **Deploy F2/F4 dessincronizado** deixa o editor inteiro fora do ar — a
   restrição dura é regra de merge, não recomendação.
2. **Cookie cross-site** (se T1 desmentir a PSL): SameSite=None + defesa
   CSRF reforçada, ou queda para a variante JWT — é o risco que mais mexe no
   desenho, por isso T1 é a primeira pergunta técnica.
3. **Capa de projeto quebrando no deploy do guard** — pré-requisito
   embutido na F2, qualquer que seja a variante (specs §5).
4. **Lockout do próprio admin** (senha do seed perdida): o reset é por env
   no Coolify + redeploy — documentar no runbook de deploy.
5. **CORS com credentials mal configurado** = "funciona local, quebra em
   hml" silencioso — erro monitorado dedicado (acima) e teste de contrato.
6. **Flag de conveniência que desliga auth** — vetada por desenho (A6);
   qualquer exceção exige parecer do CISO.

## Decisões

### Herdadas (não reabertas) `[decidido]`

Guard global com `@Public()` explícito · 404 para não-membro ·
`src/public/*` fora do guard (aviso do plano 25 §6) · morte do
`ProjectScope`/`DEFAULT_PROJECT_ID` (A4 do item 46) · sem cadastro público
(fronteira 37) · argon2id · F2+F4 deployam juntos · CISO por fase.

### Aguardando o dev `[aberto]`

A1 formato de sessão (**primeira da fila — destrava A6/A7 e o tamanho da
F4**) · A2 onde mora o vínculo · A3 provedor de identidade · A4 papéis
agora × fundação · A5 migração · A6 dev local · A7 QR do preview ·
A8 gestão mínima de usuário. Opções, impactos e recomendações: `specs.md`
§7.
