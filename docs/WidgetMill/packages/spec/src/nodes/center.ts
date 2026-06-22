import { z } from "zod";
import { NodeRef } from "../node-ref";

/** Center — spec §2.11. */
export const CenterNode = z.object({
  type: z.literal("center"),
  props: z
    .object({
      widthFactor: z.number().optional(),
      heightFactor: z.number().optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
