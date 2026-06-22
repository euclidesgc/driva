import { z } from "zod";
import { AXIS, RUN_ALIGNMENT, WRAP_ALIGNMENT, WRAP_CROSS } from "../enums";
import { NodeRef } from "../node-ref";

/** Wrap — flui os filhos em múltiplas linhas/colunas (catálogo Flutter). */
export const WrapNode = z.object({
  type: z.literal("wrap"),
  props: z
    .object({
      direction: z.enum(AXIS).optional(),
      alignment: z.enum(WRAP_ALIGNMENT).optional(),
      runAlignment: z.enum(RUN_ALIGNMENT).optional(),
      crossAxisAlignment: z.enum(WRAP_CROSS).optional(),
      spacing: z.number().optional(),
      runSpacing: z.number().optional(),
    })
    .default({}),
  children: z.array(NodeRef).default([]),
});
