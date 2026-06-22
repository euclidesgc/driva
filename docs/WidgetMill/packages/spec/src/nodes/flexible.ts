import { z } from "zod";
import { FLEX_FIT } from "../enums";
import { NodeRef } from "../node-ref";

/** Flexible — spec §2.12. */
export const FlexibleNode = z.object({
  type: z.literal("flexible"),
  props: z
    .object({
      flex: z.number().int().optional(),
      fit: z.enum(FLEX_FIT).optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
