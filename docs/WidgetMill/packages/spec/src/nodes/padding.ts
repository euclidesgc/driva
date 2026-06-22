import { z } from "zod";
import { EdgeInsets } from "../complex/edgeInsets";
import { NodeRef } from "../node-ref";

/** Padding — spec §2.10. `padding` é obrigatório. */
export const PaddingNode = z.object({
  type: z.literal("padding"),
  props: z.object({ padding: EdgeInsets }),
  child: NodeRef.optional(),
});
