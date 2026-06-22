// Superfície pública do @widgetmill/spec.

// Núcleo: árvore de nós e documento de topo.
export { Node } from "./tree";
export type { SpecNode } from "./tree";
export { WidgetSpec, PropDef } from "./schema";

// Helpers de binding e escalares.
export { Bindable, BINDING, TOKEN } from "./bindable";
export { Color } from "./scalars";

// Tipos complexos.
export { EdgeInsets } from "./complex/edgeInsets";
export { TextStyle, FontWeight } from "./complex/textStyle";
export { BorderRadius } from "./complex/borderRadius";
export { BoxDecoration } from "./complex/boxDecoration";
export { Alignment, AlignmentDirectional } from "./complex/alignment";
export { BoxConstraints } from "./complex/constraints";
export { Dimension, BindableDimension, DIMENSION_UNITS } from "./complex/dimension";

// Listas de enum (valores) — reusáveis por descriptors e pelo editor.
export {
  ALIGNMENT,
  ALIGNMENT_DIRECTIONAL,
  FONT_WEIGHT,
  FONT_STYLE,
  TEXT_DECORATION,
  BOX_SHAPE,
  BORDER_STYLE,
  AXIS,
  WRAP_ALIGNMENT,
  RUN_ALIGNMENT,
  WRAP_CROSS,
  ICON_NAMES,
} from "./enums";

// Normalização de "valor em branco" (opcionais limpas) — fonte única.
export { isBlank, hasValue, pruneBlank } from "./props/blank";

// Eventos e ações.
export { Action, ActionList, Events } from "./actions/index";

// Schemas individuais dos primitivos (úteis para descriptors/registry futuros).
export { nodeOptions } from "./nodes/index";

// Slots dos primitivos (filho único vs vários) — fonte única p/ editor e diagnóstico.
export { SINGLE_CHILD_TYPES, MULTI_CHILD_TYPES, slotKind } from "./nodes/slots";
export type { SlotKind } from "./nodes/slots";

// Diagnóstico de montagens problemáticas (validação do editor).
export { diagnose } from "./diagnostics/diagnose";
export type { Diagnostic, DiagnosticSeverity } from "./diagnostics/diagnose";

// Tradutor Puck ↔ spec (editor).
export {
  specToPuck,
  puckToSpec,
  specToPuckData,
  puckDataToSpec,
} from "./puck/translate";
export type { PuckComponent, PuckData, PuckProps } from "./puck/types";

// Field descriptors (geram o Inspector).
export {
  descriptorsByType,
  descriptorsFor,
  FIELD_TYPES,
} from "./descriptors/catalog";
export type { FieldDescriptor, FieldType } from "./descriptors/types";
// Agrupamento dos primitivos na paleta do editor (categorias colapsáveis).
export { COMPONENT_CATEGORIES, paletteCategories } from "./descriptors/categories";
export type { PaletteCategory } from "./descriptors/categories";

// Identidade e montagem de widgets.
export { slugify } from "./identity/slug";
export { makeWidgetSpec } from "./widget/factory";
export type { MakeWidgetSpecInput, MakeWidgetSpecResult } from "./widget/factory";

// Versionamento (estilo Squidex): registro append-only + diff estrutural.
export {
  createRecord,
  saveVersion,
  editIdentity,
  deleteVersion,
  restoreVersion,
  isDeleted,
  latestVersion,
  publishedVersion,
  getVersion,
} from "./history/record";
export type { SaveVersionInput } from "./history/record";
export type {
  VersionStatus,
  WidgetIdentity,
  WidgetVersion,
  WidgetRecord,
} from "./history/types";
export { diffTree } from "./history/diff";
export type { SpecDiff, SpecChange, SpecChangeKind } from "./history/diff";
