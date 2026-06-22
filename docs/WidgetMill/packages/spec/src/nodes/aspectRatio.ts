import { z } from "zod";
import { NodeRef } from "../node-ref";

/** AspectRatio — força uma razão largura/altura no filho (catálogo Flutter). */
export const AspectRatioNode = z.object({
  type: z.literal("aspectRatio"),
  // `aspectRatio` é obrigatório (sem default) — o Inspector marca com `*`.
  props: z.object({
    aspectRatio: z.number(),
  }),
  child: NodeRef.optional(),
});
