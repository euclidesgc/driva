# @widgetmill/spec

O **kernel** do WidgetMill: os schemas Zod que definem o spec JSON. Única fonte de verdade — tipos TS, validação (FE/BE), forms do Inspector e fixtures para o renderer Dart derivam daqui.

## Estrutura

```
src/
├─ bindable.ts        # Bindable(inner): valor | "{{chave}}" | "$token"
├─ scalars.ts         # Color e outros escalares
├─ complex/           # EdgeInsets, TextStyle, BoxDecoration, Alignment, ...
├─ actions/           # Action (união por type) + Events
├─ nodes/             # um schema por primitivo (container, text, column, ...)
├─ tree.ts            # Node (união discriminada recursiva via z.lazy)
├─ schema.ts          # WidgetSpec (specVersion, propsSchema, tree) + PropDef
└─ index.ts           # superfície pública
fixtures/             # specs canônicos (.json) — contrato golden com o Dart
```

## Princípio

> Um e apenas um lugar define a forma do spec. Todo o resto deriva.

Adicionar um primitivo = uma entrada de schema em `nodes/` + um item em `nodeOptions`. Nada mais muda no kernel.

## Scripts

```bash
pnpm test         # vitest
pnpm typecheck    # tsc --noEmit
```
