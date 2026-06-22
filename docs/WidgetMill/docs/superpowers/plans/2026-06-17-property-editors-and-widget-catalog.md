# Plano — Editores de propriedade padronizados, dimensões relativas e catálogo de widgets

> Branch: `feature/property-editors-and-widget-catalog` (a partir de `develop`, Gitflow).
> Tarefa noturna autônoma (usuário dormindo). Implementar tudo; **sem merge** na develop (aguarda revisão).
> Doc em disco p/ sobreviver a restart do processo. Atualizar o checklist conforme avança.

## Contexto (estado atual mapeado)

- **Kernel** (`packages/spec`): `width/height` são `BindableNumber` (número puro, sem modos relativos). `BoxDecoration` já tem `boxShadow`/`border`/`gradient` ricos **no schema**, mas o editor só expõe `color`+`borderRadius`+`shape`+`border`. `button.style` existe no schema (backgroundColor/foregroundColor/padding) mas **não** está no descriptor (não editável). `FieldType` (em `descriptors/types.ts`) é o registro de "property editor kinds". `required`/`optional`/`group` já existem; o `*` já é renderizado via `RequiredMark`. Enums centralizados em `enums.ts`. Anti-drift: `catalog.test.ts` exige descriptor por node type.
- **Web** (`apps/web`): campos customizados em `lib/inspector-fields.tsx` (`{type:"custom", render}` + `FieldLabel` + `ModeTabs`/`NumberInput`/`pruneBlank`). `puck-config.tsx` mapeia `FieldType → campo Puck` e gera componentes/paleta. `group` dos descriptors **não é usado** hoje (campos renderizados num lista plana).
- **Renderer** (`flutter/sdui_flutter`): builders leem `node.props` cru; `parsers.dart` converte. `buildContainer` tem `BuildContext` (→ posso resolver dimensões relativas). Golden test renderiza `packages/spec/fixtures/nodes/*.json` exigindo zero exceção.

## Objetivos (do `/goal`)

1. Valores numéricos relativos/de dispositivo (`double.infinity`, MediaQuery, %) nas props de tamanho.
2. Propriedades faltantes (sombras, variantes/estilo de botão, etc.).
3. Editores de propriedade **padronizados e reutilizáveis** (por categoria de tipo de entrada).
4. Marcar obrigatórias com `*` (já suportado — auditar e aplicar).
5. Trazer widgets relevantes do catálogo Flutter.
6. UX/UI agradável no Inspector (referência: FlutterFlow).

## Design

### A. Dimensão (`Dimension`) — headline
Novo tipo complexo `complex/dimension.ts`. União (back-compat: número puro continua válido):
- `number` → px fixo.
- `{ unit: "infinity" }` → `double.infinity` (preencher disponível).
- `{ unit: "screenWidth", factor }` → `MediaQuery.sizeOf(c).width * factor` (% da tela). `factor` = multiplicador (0.5 = 50%).
- `{ unit: "screenHeight", factor }` → idem altura.

`BindableDimension = Bindable(Dimension)`. Todas resolvem para um `double?` dado o `context` (sem widget extra). "% do pai" fica fora do `Dimension` (usa o widget **FractionallySizedBox**, abaixo).

Aplicar em: `container.width/height`, `sizedBox.width/height`, `image.width/height`, `positioned.width/height`. Novo `FieldType: "dimension"`.

### B. Enriquecer schemas + expor no editor
- **Button**: `style` ganha `elevation`, `borderRadius`, `side` (color/width), `textStyle`; novo prop `icon` (nome do ícone → `*.icon(...)`). Expor `style` (FieldType `buttonStyle`, editor custom agrupado) e `icon` (FieldType `iconData`/string) no descriptor.
- **BoxDecoration**: expor `boxShadow` (editor custom de lista — `shadowList`) e `gradient` no editor.

### C. Novos widgets (schema + descriptor + categoria + builder + parser)
Wrap, Card, Divider, Align, AspectRatio, FractionallySizedBox, Opacity, SafeArea, SingleChildScrollView. (Stretch: ClipRRect, ListView.)
Enums novos: `AXIS` (horizontal/vertical), `WRAP_ALIGNMENT`, `WRAP_CROSS`, `RUN_ALIGNMENT`, `VERTICAL_DIRECTION` (se preciso).

### D. Editores reutilizáveis (web, em `inspector-fields.tsx`)
- `DimensionField` (ModeTabs: Fixo / Preencher / % Largura / % Altura). **Flagship.**
- `shadowListField` (lista de sombras: cor + offsetX/Y + blur + spread; add/remover).
- `buttonStyleField` (sub-editores agrupados: cores, elevação, raio, borda, textStyle).
- Cabeçalhos de seção (agrupamento por `group`) no Inspector — separadores estilo FlutterFlow.

### E. Obrigatórias (`*`)
Auditar: `aspectRatio.aspectRatio` (req), `opacity.opacity` (req), demais conforme schema.

### F. Renderer
`resolveDimension(context, v)` em `parsers.dart`; novos builders; `button` com `icon` + style enriquecido; parsers de gradient/shadow já existem (reusar). Manter golden verde; adicionar fixtures novos só com os dois lados prontos.

## Ordem de execução (commits lógicos; verificar a cada bloco)
1. **Kernel**: enums + dimension + enrich (button/decoration) + novos nodes + descriptors + categorias + index. `tsc` + `vitest`. **commit**.
2. **Renderer**: resolveDimension + novos builders + button/parsers + registry. `flutter analyze` + `flutter test`. Recompilar asset do preview. **commit**.
3. **Web**: DimensionField + shadowList + buttonStyle + boxDecoration rico + expor button.style + section headers + map de FieldTypes. `tsc` + `next build`. **commit**.
4. **Fixtures golden** novos (dimensão + alguns widgets) + testes de consolidação + `docs/roadmap-execucao.md` + **commit** final.

## Checklist
- [ ] 1. Kernel
- [ ] 2. Renderer
- [ ] 3. Web
- [ ] 4. Fixtures/testes/roadmap
