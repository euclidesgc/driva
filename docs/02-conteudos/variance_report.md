# Variance Report — Conteúdos

Registro de desvios do `plan.md` aprovado. Cada entrada: **como estava · por que mudou · o que mudou**. Desvio só entra com aprovação do dev humano (regra do CLAUDE.md).

---

## 002 — Baseline resolvida automaticamente no start do container (não mais passo manual de OPS)

**Data:** 2026-07-04 · **Aprovado por:** dev humano ("pode ajustar como for preciso, só termine isso logo")

**Como estava (plano aprovado).** A Fase 5 previa o `resolve --applied 0_baseline` como **pré-condição manual, uma vez por ambiente**, rodada pelo dev no terminal do Coolify **antes** do primeiro deploy com migrations. O `CMD` do container era só `prisma migrate deploy && node dist/main.js`.

**Por que mudou.** No merge do PR #13 em `develop`, o auto-deploy de hml abortou com **`P3005`** — o passo manual foi esquecido (o banco de hml foi criado por `db push`, sem histórico de migrations). Falha **segura** (P3005 é preflight, não roda SQL — dados intactos), mas o deploy não completa. O passo manual provou-se frágil e repetiria no prod. **Não há dados a preservar** (projeto em fase inicial), então o backup deixa de ser gate.

**O que mudou.** O `CMD` do `backend/Dockerfile` passa a **auto-resolver a baseline**: `prisma migrate resolve --applied 0_baseline 2>/dev/null; prisma migrate deploy && node dist/main.js`. Idempotente na prática (no 1º deploy grava a baseline; nos seguintes erra "já aplicada", silenciado, e segue). O `&&` garante que o Nest só sobe se o migrate deploy suceder. Cobre hml **e** prod sem passo manual.

**Alternativa descartada.** Rodar o resolve à mão via override do `start_command` no Coolify — resolveria hml, mas exigiria repetir no prod e depende de acesso ao painel. O fix no `CMD` é permanente e versionado.

**Impacto.** Nenhuma mudança de escopo/critérios. Remove a pré-condição manual do roteiro OPS (Fase 5) e do `coolify.md`. **Limite conhecido:** banco 100% vazio/novo não deve usar este caminho (resolver baseline sem o schema faz o `migrate deploy` falhar de propósito) — não há ambiente assim hoje.

---

## 001 — Branch de integração no lugar de PR-de-fase direto para `develop`

**Data:** 2026-07-02 · **Aprovado por:** dev humano ("vai")

**Como estava (plano aprovado).** O `plan.md` previa "1 fase = 1 PR", cada fase nascendo de `develop` e voltando por PR **para `develop`**, com CI verde como pré-requisito de merge.

**Por que mudou.** A CI-cancela (`.github/workflows/ci.yml`) roda `flutter analyze` + testes no **workspace inteiro** e só dispara em PRs para `develop`/`main`. Como este é um **rename encadeado**, a Fase 1 (`sdui_core`) quebra de propósito o `sdui_flutter` e o `driva_editor` até as Fases 2 e 3 — o workspace só volta a compilar após a Fase 3. Logo, todo PR de fase intermediária miraria `develop` com a CI **vermelha** (comprovado no PR #8: job "Flutter — format + analyze + testes" falhou). Mergear assim exigiria furar a cancela (proibido) ou deixar `develop`/hml num estado meio-renomeado e quebrado.

**O que mudou.** Introduzida uma **branch de integração `feature/conteudos`** (nasce de `develop`):
- As Fases 1–4 viram PRs que **miram `feature/conteudos`** (não `develop`) → não disparam a CI-cancela; passam por QA + CISO + revisão do humano.
- Só o merge **`feature/conteudos` → `develop`** passa pela CI-cancela — aí o workspace já compila inteiro (1→3 + 4), ficando **verde e atômico**.
- Efeito colateral positivo: `develop`/hml nunca veem estado parcial; o rename cai de uma vez, testado.
- PR #8 (Fase 1) foi **re-apontado** de `develop` para `feature/conteudos` (preserva o trabalho e os gates já feitos).

**Alternativa descartada.** Expandir-migrar-contrair (criar `ContentSpec` como alias ao lado de `PageSpec` e remover ao final) manteria cada fase verde, mas espalha nomes duplicados temporários e é mais trabalho. A branch de integração é mais simples e limpa.

**Impacto no plano.** Nenhuma mudança de escopo, fases ou critérios de aceite — só a **topologia de merge**. A Fase 5 (migração, OPS do humano) e a Fase 6 (E2E + testes + docs) seguem iguais; a Fase 6 fecha antes do merge final na `develop`.
