import {
    AXIS,
    BOX_FIT,
    BUTTON_VARIANT,
    CLIP_BEHAVIOR,
    CROSS_AXIS,
    FLEX_FIT,
    IMAGE_SOURCE,
    MAIN_AXIS,
    MAIN_SIZE,
    RUN_ALIGNMENT,
    STACK_FIT,
    TEXT_ALIGN,
    TEXT_BASELINE,
    TEXT_OVERFLOW,
    WRAP_ALIGNMENT,
    WRAP_CROSS,
} from "../enums";
import { hasValue } from "../props/blank";
import type { FieldDescriptor } from "./types";

export { FIELD_TYPES } from "./types";
export type { FieldDescriptor, FieldType } from "./types";

/**
 * Rótulos dos grupos (seções do Inspector). Centralizados para consistência —
 * o editor renderiza um cabeçalho por grupo, na ordem de primeira aparição.
 */
const G = {
  layout: "Layout",
  size: "Tamanho",
  spacing: "Espaçamento",
  style: "Estilo",
  content: "Conteúdo",
  position: "Posição",
  events: "Eventos",
} as const;

const flexFields: FieldDescriptor[] = [
  { key: "mainAxisAlignment", type: "enum", enumValues: MAIN_AXIS, group: G.layout, optional: true, default: "start" },
  { key: "crossAxisAlignment", type: "enum", enumValues: CROSS_AXIS, group: G.layout, optional: true, default: "center" },
  { key: "mainAxisSize", type: "enum", enumValues: MAIN_SIZE, group: G.layout, optional: true, default: "max" },
  { key: "spacing", type: "double", group: G.spacing, default: 0 },
  // Só tem efeito com crossAxisAlignment = "baseline", mas fica acessível.
  { key: "textBaseline", type: "enum", enumValues: TEXT_BASELINE, group: G.layout, optional: true },
];

/**
 * Catálogo de field descriptors por primitivo. Adicionar um primitivo = uma
 * entrada aqui (+ schema em nodes/ + builder no renderer).
 */
export const descriptorsByType: Record<string, FieldDescriptor[]> = {
  container: [
    { key: "width", type: "dimension", group: G.size },
    { key: "height", type: "dimension", group: G.size },
    { key: "padding", type: "edgeInsets", group: G.spacing },
    { key: "margin", type: "edgeInsets", group: G.spacing },
    { key: "alignment", type: "alignment", group: G.layout, optional: true },
    {
      key: "color",
      type: "color",
      group: G.style,
      // Regra do Flutter: color ⊥ decoration. Usa `hasValue` (não `!= undefined`)
      // para que uma decoration limpa/vazia não esconda o campo color.
      hidden: (props) => hasValue(props.decoration),
    },
    { key: "decoration", type: "boxDecoration", group: G.style },
  ],
  column: flexFields,
  row: flexFields,
  wrap: [
    { key: "direction", type: "enum", enumValues: AXIS, group: G.layout, optional: true, default: "horizontal" },
    { key: "alignment", type: "enum", enumValues: WRAP_ALIGNMENT, group: G.layout, optional: true, default: "start" },
    { key: "runAlignment", type: "enum", enumValues: RUN_ALIGNMENT, group: G.layout, optional: true, default: "start" },
    { key: "crossAxisAlignment", type: "enum", enumValues: WRAP_CROSS, group: G.layout, optional: true, default: "start" },
    { key: "spacing", type: "double", group: G.spacing, default: 0 },
    { key: "runSpacing", type: "double", group: G.spacing, default: 0 },
  ],
  stack: [
    { key: "alignment", type: "alignmentDirectional", group: G.layout, optional: true, default: "topStart" },
    { key: "fit", type: "enum", enumValues: STACK_FIT, group: G.layout, optional: true, default: "loose" },
    { key: "clipBehavior", type: "enum", enumValues: CLIP_BEHAVIOR, group: G.layout, optional: true, default: "hardEdge" },
  ],
  positioned: [
    { key: "left", type: "double", group: G.position },
    { key: "top", type: "double", group: G.position },
    { key: "right", type: "double", group: G.position },
    { key: "bottom", type: "double", group: G.position },
    { key: "width", type: "double", group: G.size },
    { key: "height", type: "double", group: G.size },
  ],
  text: [
    { key: "data", type: "string", group: G.content },
    { key: "style", type: "textStyle", group: G.style },
    { key: "textAlign", type: "enum", enumValues: TEXT_ALIGN, group: G.content, optional: true, default: "start" },
    { key: "maxLines", type: "int", group: G.content },
    { key: "overflow", type: "enum", enumValues: TEXT_OVERFLOW, group: G.content, optional: true, default: "clip" },
    { key: "softWrap", type: "bool", group: G.content, optional: true, default: true },
  ],
  image: [
    { key: "source", type: "enum", enumValues: IMAGE_SOURCE, group: G.content, optional: true, default: "network" },
    { key: "src", type: "string", group: G.content },
    { key: "width", type: "dimension", group: G.size },
    { key: "height", type: "dimension", group: G.size },
    { key: "fit", type: "enum", enumValues: BOX_FIT, group: G.content, optional: true, default: "contain" },
  ],
  icon: [
    { key: "icon", type: "iconData", group: G.content, required: true },
    { key: "size", type: "double", group: G.style, default: 24 },
    { key: "color", type: "color", group: G.style },
  ],
  button: [
    { key: "variant", type: "enum", enumValues: BUTTON_VARIANT, group: G.style, optional: true, default: "elevated" },
    { key: "label", type: "string", group: G.content },
    { key: "icon", type: "iconData", group: G.content, optional: true },
    { key: "enabled", type: "bool", group: G.content, optional: true, default: true },
    { key: "style", type: "buttonStyle", group: G.style },
    { key: "onPressed", type: "actionList", group: G.events },
  ],
  card: [
    { key: "color", type: "color", group: G.style },
    { key: "elevation", type: "double", group: G.style },
    { key: "borderRadius", type: "borderRadius", group: G.style },
    { key: "margin", type: "edgeInsets", group: G.spacing },
  ],
  divider: [
    { key: "height", type: "double", group: G.layout },
    { key: "thickness", type: "double", group: G.style },
    { key: "indent", type: "double", group: G.spacing },
    { key: "endIndent", type: "double", group: G.spacing },
    { key: "color", type: "color", group: G.style },
  ],
  sizedBox: [
    { key: "width", type: "dimension", group: G.size },
    { key: "height", type: "dimension", group: G.size },
  ],
  padding: [{ key: "padding", type: "edgeInsets", group: G.spacing, required: true }],
  center: [
    { key: "widthFactor", type: "double", group: G.size },
    { key: "heightFactor", type: "double", group: G.size },
  ],
  align: [
    { key: "alignment", type: "alignment", group: G.layout, optional: true },
    { key: "widthFactor", type: "double", group: G.size },
    { key: "heightFactor", type: "double", group: G.size },
  ],
  aspectRatio: [{ key: "aspectRatio", type: "double", group: G.size, required: true }],
  fractionallySizedBox: [
    { key: "widthFactor", type: "double", group: G.size },
    { key: "heightFactor", type: "double", group: G.size },
    { key: "alignment", type: "alignment", group: G.layout, optional: true },
  ],
  opacity: [{ key: "opacity", type: "double", group: G.style, required: true }],
  safeArea: [
    { key: "top", type: "bool", group: G.layout, optional: true, default: true },
    { key: "bottom", type: "bool", group: G.layout, optional: true, default: true },
    { key: "left", type: "bool", group: G.layout, optional: true, default: true },
    { key: "right", type: "bool", group: G.layout, optional: true, default: true },
  ],
  singleChildScrollView: [
    { key: "scrollDirection", type: "enum", enumValues: AXIS, group: G.layout, optional: true, default: "vertical" },
    { key: "reverse", type: "bool", group: G.layout, optional: true, default: false },
    { key: "padding", type: "edgeInsets", group: G.spacing },
  ],
  expanded: [{ key: "flex", type: "int", group: G.layout, default: 1 }],
  flexible: [
    { key: "flex", type: "int", group: G.layout, default: 1 },
    { key: "fit", type: "enum", enumValues: FLEX_FIT, group: G.layout, optional: true, default: "loose" },
  ],
  spacer: [{ key: "flex", type: "int", group: G.layout, default: 1 }],
  // Sem props editáveis; eventos são tratados pelo editor de eventos (T2.6).
  gestureDetector: [],
};

/** Descriptors de um primitivo (ou `[]` se desconhecido). */
export function descriptorsFor(type: string): FieldDescriptor[] {
  return descriptorsByType[type] ?? [];
}
