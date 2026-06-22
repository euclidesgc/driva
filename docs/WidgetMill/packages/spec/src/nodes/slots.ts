/**
 * Qual slot cada primitivo expõe — fonte única (espelha `child`/`children` dos
 * schemas). Usado pelo editor (Puck) e pela camada de diagnósticos.
 */
export const SINGLE_CHILD_TYPES = [
  "container",
  "center",
  "padding",
  "sizedBox",
  "positioned",
  "button",
  "expanded",
  "flexible",
  "gestureDetector",
  "card",
  "align",
  "aspectRatio",
  "fractionallySizedBox",
  "opacity",
  "safeArea",
  "singleChildScrollView",
] as const;

export const MULTI_CHILD_TYPES = ["column", "row", "stack", "wrap"] as const;

export type SlotKind = "child" | "children";

/** "child" (filho único), "children" (vários) ou undefined (folha). */
export function slotKind(type: string): SlotKind | undefined {
  if ((SINGLE_CHILD_TYPES as readonly string[]).includes(type)) return "child";
  if ((MULTI_CHILD_TYPES as readonly string[]).includes(type)) return "children";
  return undefined;
}
