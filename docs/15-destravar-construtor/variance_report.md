# Variance report — Destravar o construtor

Desvios entre esta entrega e o método de trabalho / o plano de gaveta
`docs/plans/38-destravar-drop-e-envolver/plan.md`. Cada entrada registra **como estava**,
**por que mudou** e **o que mudou** — a ordem exigida pelo CLAUDE.md.

**Estado:** 1 desvio, **aprovado pelo humano antes de codar** (2026-08-15).

## VR-15-01 — F3 e F4 saem num PR só, contra o "1 fase = 1 PR"

**Aprovado pelo humano em 2026-08-15, antes do início da implementação.**

### Como estava

O CLAUDE.md (§ Método de trabalho) fixa **"1 fase = 1 PR"**, e o plano de gaveta tratava
as duas fases como paralelas e independentes: a F3 vinha marcada `[depende de F1]`
`[∥ com F2]`, sugerindo que kernel e editor poderiam ser revisados e integrados em PRs
distintos.

### Por que mudou

A conferência do plano contra o código atual (`develop`, pós-item 23) mostrou que o
paralelismo não existe — **é impossível deixar o workspace verde entre as duas fases**:

- `DropResolution` é uma **sealed class** (`packages/sdui_core/lib/src/ops/drop_ops.dart:15`).
  Os quatro `switch` do editor sobre ela
  (`apps/driva_editor/lib/modules/editor_module/presentation/editor/cubit/editor_cubit.dart:96`,
  `:131`, `:243`, `:277`) são **statements exaustivos sem `default`**. Acrescentar
  `DropRequiresWrap` no kernel (F3) **quebra a compilação do editor no mesmo commit**.
- Remover `DropRefusal.noSlotAvailable` do enum (`drop_ops.dart:8`) quebra junto o
  `_kindOf` do cubit (`:385-389`) e o `EditorNoticeMessage.of`
  (`.../widgets/status_bar/editor_notice_message.dart:11-29`), também exaustivo sem
  `default`.

Fechar a F3 sozinha exigiria um commit intermediário com `flutter analyze` vermelho —
o que viola a cancela de máquina do projeto ("pronto" = analyze verde) e reprovaria no
CI, que é a mesma régua do PR humano.

**Alternativa avaliada e descartada:** o kernel manter `noSlotAvailable` no enum como
valor morto, só para o editor continuar compilando, e a F4 removê-lo depois. Foi
recusada porque deixaria um valor **inalcançável** no contrato público do kernel — que é
exatamente o que a decisão D2 do plano existe para eliminar — e porque criaria uma
janela em que o kernel promete uma recusa que ele nunca mais emite.

### O que mudou

- As F3 e F4 continuam sendo **duas fases**: dois donos (`especialista-dominio` e
  `especialista-apresentacao`), dois critérios de aceite escritos em separado (`plan.md`
  §5) e **duas revisões de QA**.
- Elas passam a **fechar num único PR** (o PR 3 da §6 do `plan.md`).
- A razão está registrada como **decisão D7** do `plan.md`, com um aviso endereçado ao
  QA — para a fase não ser reprovada por regra, já que o desvio é consciente.

### Consequência prática

O PR 3 é maior que os demais e cruza a fronteira kernel/editor. A revisão deve ser feita
**em duas passadas** (primeiro o contrato do kernel, depois o consumo no editor), e não
como uma leitura única de diff.

### Como fica quando não valer mais

Não expira: é uma propriedade do sistema de tipos do Dart para `sealed`, não uma
conveniência de cronograma. Qualquer mudança futura que acrescente ou remova um caso de
`DropResolution` ou de `DropRefusal` terá o mesmo acoplamento entre kernel e editor.
