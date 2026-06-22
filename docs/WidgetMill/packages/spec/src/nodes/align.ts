import { z } from "zod";
import { Alignment } from "../complex/alignment";
import { NodeRef } from "../node-ref";

/** Align — posiciona o filho dentro de si (catálogo Flutter). */
export const AlignNode = z.object({
  type: z.literal("align"),
  props: z
    .object({
      alignment: Alignment.optional(),
      widthFactor: z.number().optional(),
      heightFactor: z.number().optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
