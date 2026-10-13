---
name: manter-docs-vivas
description: Mantém a documentação viva do repositório driva (README, CHANGELOG, ANALYTICS, ERROR_LOGS) e o resumo de entrega na história do board Faz AI. Usada no fechamento da história, antes da Homologação.
---

# Skill: manter as docs vivas

Objetivo: nada fica "na cabeça". A memória do que foi feito mora em arquivos versionados e na história do board. Sem docs em dia, a história não fecha.

Na raiz do repositório (no mesmo PR da mudança):
1. **README.md** — atualizado com o que o módulo novo trouxe (como rodar, o que existe).
2. **CHANGELOG.md** — uma entrada objetiva do que a história entregou, na seção `Unreleased`.
3. **ANALYTICS.md** — por módulo: cada evento enviado, quando dispara, o que carrega. (Se o módulo ainda não envia analytics, registre "nenhum evento" explicitamente, não omita.)
4. **ERROR_LOGS.md** — por módulo: cada erro monitorado, quem dispara, em que situação (as `Failure` tipadas e o que o `AppBlocObserver` reporta).

Na história do board (não no repositório):
5. **Resumo de entrega e "Como testar"** — o que a bateria automatizada prova (unitário, widget, golden, contrato) e, com o **E2E suspenso desde 2026-08-20** (`CLAUDE.md` › _Método de trabalho_), o que ficou **sem verificação em hardware ou navegador real**. Responde "isso foi testado mesmo?", inclusive quando a resposta é "isto não". Cada item sem verificação também vira um card no Backlog do board ("Validação de campo: …"), ligado à história.

Regra: escreva para o leitor de daqui a seis meses. Linguagem natural + técnica, pt-BR, curto e verificável.
