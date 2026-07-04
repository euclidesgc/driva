# Final Report — Foco no Inspector (roadmap item 1 · melhorias item 16)

## O que era
Ao digitar em qualquer campo de propriedade do Inspector (ex.: elevação do card), o editor perdia o foco após **cada** caractere e exigia reclicar. Só o primeiro dígito colava.

## Causa raiz
Os editores de texto (`_StringEditor`, `_NumberEditor`, `_ColorEditor`, `_EdgeInsetsEditor` em [prop_field_editor.dart](../../apps/driva_editor/lib/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart)) usavam `TextFormField` com `initialValue` + uma `ValueKey` que **incluía o valor**. Cada tecla → `onChanged` → `updateProps` → rebuild → a key mudava → o Flutter destruía e recriava o campo → foco perdido.

## Correção
Editores de texto viraram `StatefulWidget` com `TextEditingController` próprio; a identidade do campo vive na key do Inspector (`nodeId_fieldKey`, já estável), não no valor. `didUpdateWidget` ressincroniza só em mudança externa, com comparação **semântica** nos numéricos (não quebra `1.` → `1.0`). Cor mantém uppercase via `TextInputFormatter`.

## Verificação

**Automatizada (regressão)** — [prop_field_editor_test.dart](../../apps/driva_editor/test/modules/editor_module/presentation/editor/widgets/prop_field_editor_test.dart), 4 casos: a `EditableTextState` não é recriada ao digitar (número e texto), o valor volta tipado, e trocar de nó reinicia o campo. Suíte do editor verde; `analyze` limpo; `format` ok.

**E2E visual (headless, CDP)** — [evidencias/rodada_02/](evidencias/rodada_02/): no editor real (build com o fix), digitar `10` e depois `5` char-a-char no campo numérico "Espaço entre filhos" do root acumula para `10` e `105`, com o campo **mantendo o foco** (borda laranja) — antes só `1` colaria. Scripts: [e2e_foco.sh](e2e_foco.sh) (build + serve + captura) e [e2e_drive_foco.mjs](e2e_drive_foco.mjs) (driver CDP puro). Rodada 01 foi descoberta de coordenadas (descartada).

## Entrega
PR #15 → `develop`. Roadmap item 1 marcado `[x]`.
