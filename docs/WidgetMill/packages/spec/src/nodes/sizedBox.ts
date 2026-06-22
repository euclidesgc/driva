import { z } from "zod";
import { BindableDimension } from "../complex/dimension";
import { NodeRef } from "../node-ref";

/** SizedBox — spec §2.9. */
export const SizedBoxNode = z.object({
  type: z.literal("sizedBox"),
  props: z
    .object({
      width: BindableDimension.optional(),
      height: BindableDimension.optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
