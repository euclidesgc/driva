---
name: revisar-fase
description: Valida uma fase implementada contra o plan.md e as regras do projeto driva. Usada pelo QA ao fim de cada fase, antes do resumo de PR ao dev.
---

# Skill: revisar uma fase

Objetivo: dado o diff da fase, conferir item a item se o que foi feito bate com o que estava planejado — o caminho inverso da `criar-modulo`.

Confira, nesta ordem:

1. **Plano.** Cada tarefa da fase no `docs/NN-<nome>/plan.md` foi feita? Algo foi feito que NÃO estava no plano? Desvio não se aceita de cara: reporte ao tech-lead (correção ou justificativa ao dev).
2. **Fronteiras.** presentation não importa data; nenhuma lógica chama o get_it por dentro (só pageBuilder); nenhum módulo importa o interno de outro (só barrel público); domain sem `package:flutter` e sem `fromMap`.
3. **Convenções.** Estado sealed + switch exaustivo; `Either<Failure, T>` nos contratos; um use case por operação; entidade imutável; barrel público só com rota + DI; zero build_runner; `isClosed` após await.
4. **Spec SDUI** (se a fase toca no kernel/renderer): JSON só vira entidade via `parsePageSpec`; novo primitivo tem descriptor + builder + fixture; nada hardcoded no editor que devesse derivar do catálogo.
5. **Acessibilidade** (se a fase tem UI): cor não é o único sinal; controles com Semantics/tooltip; teclado funciona nos painéis.
6. **Cancela de máquina.** `flutter analyze` verde e testes existentes passando. Rode — não confie no relato.
7. **Docs.** O plan.md foi marcado com o progresso? specs/prd continuam dizendo a verdade?

Devolva: veredito por item (OK ou o que desviou, com arquivo e linha), e a lista do que precisa voltar como tarefa. Se algo contradiz uma regra do projeto, a regra ganha.
