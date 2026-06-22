import { z } from "zod";
import { NodeRef } from "../node-ref";

/** Positioned — sub-tipo de filho do Stack (spec §2.4). */
export const PositionedNode = z.object({
  type: z.literal("positioned"),
  props: z
    .object({
      left: z.number().optional(),
      top: z.number().optional(),
      right: z.number().optional(),
      bottom: z.number().optional(),
      width: z.number().optional(),
      height: z.number().optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
