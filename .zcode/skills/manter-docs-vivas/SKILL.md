---
name: manter-docs-vivas
description: Fecha a documentação viva de uma feature do driva (final_report, README, CHANGELOG, ANALYTICS, ERROR_LOGS). Usada pelo QA no fechamento (etapa 12 — DoD).
---

# Skill: manter as docs vivas

Objetivo: nada fica "na cabeça". A memória do que foi feito mora em arquivos versionados. Sem docs em dia, a DoD não fecha.

Na pasta da feature (`docs/NN-<nome>/`):
1. **final_report.md** — o relatório de entrega: roteiro cumprido, resultado de cada caso, links para os prints em `evidencias/`. Responde "isso foi testado mesmo?".
2. **specs.md / prd.md / plan.md** — conferir que dizem a verdade sobre o que existe. Desvio aprovado já deve estar refletido + registrado no **variance_report.md** (como estava, por que mudou, o que mudou). Documento que mente é pior que nenhum.

Na raiz do repositório:
3. **README.md** — atualizado com o que o módulo novo trouxe (como rodar, o que existe).
4. **CHANGELOG.md** — uma entrada objetiva do que a feature entregou.
5. **ANALYTICS.md** — por módulo: cada evento enviado, quando dispara, o que carrega. (No I1 do driva ainda não há analytics — registre "nenhum evento" explicitamente, não omita.)
6. **ERROR_LOGS.md** — por módulo: cada erro monitorado, quem dispara, em que situação (as `Failure` tipadas e o que o `AppBlocObserver` reporta).

Regra: escreva para o leitor de daqui a seis meses. Linguagem natural + técnica, pt-BR, curto e verificável.
