import { z } from "zod";
import { Node } from "./tree";

/** Declaração de uma prop pública do widget (alimenta binding `{{key}}`). */
export const PropDef = z.object({
  key: z.string(),
  type: z.enum([
    "string",
    "int",
    "double",
    "bool",
    "color",
    "enum",
    "edgeInsets",
    "textStyle",
    "boxDecoration",
  ]),
  required: z.boolean().default(false),
  default: z.unknown().optional(),
  enumValues: z.array(z.string()).optional(),
});

/**
 * Documento de topo de um widget salvo. `specVersion` permite migração futura
 * sem quebrar widgets existentes (spec §7).
 */
export const WidgetSpec = z.object({
  specVersion: z.literal(1),
  slug: z.string(),
  name: z.string(),
  kind: z.enum(["primitive", "composite"]),
  version: z.number().int().optional(),
  propsSchema: z.array(PropDef).default([]),
  tree: Node,
});

export type PropDef = z.infer<typeof PropDef>;
export type WidgetSpec = z.infer<typeof WidgetSpec>;
