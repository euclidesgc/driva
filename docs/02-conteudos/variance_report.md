# Variance Report — Conteúdos

Registro de desvios do `plan.md` aprovado. Cada entrada: **como estava · por que mudou · o que mudou**. Desvio só entra com aprovação do dev humano (regra do CLAUDE.md).

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
