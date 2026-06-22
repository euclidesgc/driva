import { z } from "zod";
import { BorderRadius } from "../complex/borderRadius";
import { EdgeInsets } from "../complex/edgeInsets";
import { NodeRef } from "../node-ref";
import { BindableColor } from "../scalars";

/** Card — superfície elevada do Material (catálogo Flutter). */
export const CardNode = z.object({
  type: z.literal("card"),
  props: z
    .object({
      color: BindableColor.optional(),
      elevation: z.number().optional(),
      borderRadius: BorderRadius.optional(),
      margin: EdgeInsets.optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
