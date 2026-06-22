/**
 * Listas de enum compartilhadas entre schemas (`nodes/*`) e descriptors
 * (`descriptors/catalog`). Single source of truth para evitar drift.
 *
 * Exportadas como tuplas readonly (`as const`) para serem aceitas por `z.enum`
 * (diretamente) e pelos descriptors (via `enumValues`).
 */

export const MAIN_AXIS = [
  "start",
  "end",
  "center",
  "spaceBetween",
  "spaceAround",
  "spaceEvenly",
] as const;

export const CROSS_AXIS = [
  "start",
  "end",
  "center",
  "stretch",
  "baseline",
] as const;

export const MAIN_SIZE = ["min", "max"] as const;

export const TEXT_BASELINE = ["alphabetic", "ideographic"] as const;

export const TEXT_ALIGN = [
  "left",
  "right",
  "center",
  "justify",
  "start",
  "end",
] as const;

export const TEXT_OVERFLOW = ["clip", "fade", "ellipsis", "visible"] as const;

export const BOX_FIT = [
  "fill",
  "contain",
  "cover",
  "fitWidth",
  "fitHeight",
  "none",
  "scaleDown",
] as const;

export const IMAGE_SOURCE = ["network", "asset"] as const;

export const BUTTON_VARIANT = [
  "elevated",
  "text",
  "outlined",
  "filled",
] as const;

export const STACK_FIT = ["loose", "expand", "passthrough"] as const;

export const CLIP_BEHAVIOR = [
  "none",
  "hardEdge",
  "antiAlias",
  "antiAliasWithSaveLayer",
] as const;

export const FLEX_FIT = ["tight", "loose"] as const;

export const ALIGNMENT = [
  "topLeft",
  "topCenter",
  "topRight",
  "centerLeft",
  "center",
  "centerRight",
  "bottomLeft",
  "bottomCenter",
  "bottomRight",
] as const;

export const ALIGNMENT_DIRECTIONAL = [
  "topStart",
  "topCenter",
  "topEnd",
  "centerStart",
  "center",
  "centerEnd",
  "bottomStart",
  "bottomCenter",
  "bottomEnd",
] as const;

export const FONT_WEIGHT = [
  "w100",
  "w200",
  "w300",
  "w400",
  "w500",
  "w600",
  "w700",
  "w800",
  "w900",
] as const;

export const FONT_STYLE = ["normal", "italic"] as const;

export const TEXT_DECORATION = [
  "none",
  "underline",
  "overline",
  "lineThrough",
] as const;

export const BOX_SHAPE = ["rectangle", "circle"] as const;

export const BORDER_STYLE = ["solid", "none"] as const;

/** Eixo (direção) — usado por Wrap/ListView/SingleChildScrollView. */
export const AXIS = ["horizontal", "vertical"] as const;

/** Alinhamento no eixo principal do Wrap (espelha `WrapAlignment` do Flutter). */
export const WRAP_ALIGNMENT = [
  "start",
  "end",
  "center",
  "spaceBetween",
  "spaceAround",
  "spaceEvenly",
] as const;

/** Alinhamento das "runs" do Wrap (espelha `WrapAlignment`, usado em `runAlignment`). */
export const RUN_ALIGNMENT = WRAP_ALIGNMENT;

/** Alinhamento no eixo cruzado do Wrap (espelha `WrapCrossAlignment`). */
export const WRAP_CROSS = ["start", "end", "center"] as const;

/**
 * Ícones Material curados (catálogo do `Icon`/`button.icon`). **Deve espelhar**
 * `flutter/sdui_flutter/lib/src/parsing/material_icons.dart` (mapa name→IconData):
 * só estes renderizam, então o editor oferece um seletor em vez de texto livre.
 */
export const ICON_NAMES = [
  "add",
  "check",
  "close",
  "delete",
  "edit",
  "favorite",
  "home",
  "info",
  "menu",
  "person",
  "remove",
  "search",
  "settings",
  "star",
  "warning",
] as const;
