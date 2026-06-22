import { z } from "zod";
import { NodeRef } from "../node-ref";

/** Opacity — aplica opacidade (0..1) ao filho (catálogo Flutter). */
export const OpacityNode = z.object({
  type: z.literal("opacity"),
  // `opacity` é obrigatório (sem default) — o Inspector marca com `*`.
  props: z.object({
    opacity: z.number().min(0).max(1),
  }),
  child: NodeRef.optional(),
});
