import { z } from "zod";
import { NodeRef } from "../node-ref";

/** Expanded — spec §2.12. Válido só como filho direto de Row/Column. */
export const ExpandedNode = z.object({
  type: z.literal("expanded"),
  props: z.object({ flex: z.number().int().optional() }).default({}),
  child: NodeRef.optional(),
});
