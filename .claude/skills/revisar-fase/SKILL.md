---
name: revisar-fase
description: Valida uma fase implementada contra o plan.md e as regras do projeto driva. Usada pelo QA ao fim de cada fase, antes do resumo de PR ao dev.
---

# Skill: revisar uma fase

Objetivo: dado o diff da fase, conferir item a item se o que foi feito bate com o que estava planejado — o caminho inverso da `criar-modulo`.

**O que já foi conferido antes de você.** Cada tarefa que mudou comportamento passou por um `supervisor-dod`, que cobrou o **DoD daquela tarefa** sem conhecer o plano. Você é o oposto: conhece o plano e olha o **conjunto**. Não reconfira critério de tarefa item a item — se o conjunto contradisser um veredito verde dele (a tarefa cumpriu o critério, mas o critério não era o que a fase precisava), aí sim é achado seu, e volta ao tech-lead como qualquer desvio.

Confira, nesta ordem:

1. **Plano.** Cada tarefa da fase no `docs/NN-<nome>/plan.md` foi feita? Algo foi feito que NÃO estava no plano? Desvio não se aceita de cara: reporte ao tech-lead (correção ou justificativa ao dev).
2. **Fronteiras.** presentation não importa data; nenhuma lógica chama o get_it por dentro (só pageBuilder); nenhum módulo importa o interno de outro (só barrel público); domain sem `package:flutter` e sem `fromMap`.
3. **Convenções.** Estado sealed + switch exaustivo; `Either<Failure, T>` nos contratos; um use case por operação; entidade imutável; barrel público só com rota + DI; zero build_runner; `isClosed` após await.
4. **Design system e widgets** (se a fase tem UI — vale `driva_editor`, `driva_demo_app` e `sdui_flutter`). **Comece rodando `bash scripts/gates_guard.sh`** — é o mesmo guard-script que a CI roda, e ele já decide (a) e (d) por grep nos apps (`sdui_flutter` fica fora do Gate 1, inteiro). Ele aceita `// gate1-ok: <motivo>` e `// gate4-ok: <motivo>` como escape por linha: **escape novo no diff é item de revisão** — confira se o motivo é real e não uma forma de calar o gate. (b) e (c) são heurísticos e ficam com você, no olho. Régua de cada um: (a) **Gate 1 — nenhuma função/método retorna `Widget`** — cada pedaço de UI é um widget próprio com dados pelo construtor (permitidos: `build`, `pageBuilder`, callbacks `itemBuilder`/`builder:` sem árvore inline extensa; **exceção**: os builders do renderer SDUI em `packages/sdui_flutter/lib/src/builders/`); (b) **Gate 3 — uma classe/widget por arquivo** (podem coabitar: par `StatefulWidget`+`State`, cubit+estados via `part of`, família `sealed`, enums num `*_enum.dart`; o alvo são arquivos gordos com vários widgets distintos); (c) **Gate 2 — widget no tier certo** — feature → módulo → `core/widgets/` (o "components", por categoria + barrel); widget genérico não pode morar dentro da feature; (d) **Gate 4 — zero hardcode de estilo** — cor/tipografia/espaçamento/raio/duração vêm de `core/theme/` (token/`Theme.of`), nada de `Color(0x…)`/`EdgeInsets.all(16)`/`TextStyle(fontSize:)`/`BorderRadius.circular(16)` cru (tokenizar tudo, inclusive device-mock, gradientes e paleta de syntax); (e) **escopo mínimo de rebuild** — sem `BlocBuilder` único no topo de tela grande; rebuild escopado por painel (`BlocSelector`/`buildWhen`) ou estado efêmero em widget-folha pequeno.
5. **Spec SDUI** (se a fase toca no kernel/renderer): JSON só vira entidade via `parsePageSpec`; novo primitivo tem descriptor + builder + fixture; nada hardcoded no editor que devesse derivar do catálogo.
6. **Acessibilidade** (se a fase tem UI): cor não é o único sinal; controles com Semantics/tooltip; teclado funciona nos painéis.
7. **Cancela de máquina.** `flutter analyze` verde, `bash scripts/gates_guard.sh` limpo e testes existentes passando. Rode — não confie no relato. As suítes Flutter rodam **de dentro da pasta do pacote** (`packages/sdui_flutter`, `apps/driva_editor`, `apps/driva_demo_app`); a partir da raiz os goldens estouram com `FontManifest.json vazio`.
8. **Docs.** O plan.md foi marcado com o progresso? specs/prd continuam dizendo a verdade?

Devolva: veredito por item (OK ou o que desviou, com arquivo e linha), e a lista do que precisa voltar como tarefa. Se algo contradiz uma regra do projeto, a regra ganha.
