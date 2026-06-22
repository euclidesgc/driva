import { z } from "zod";
import { BindableColor } from "../scalars";

/** Icon — spec §2.7. `icon` (nome do catálogo Material) é obrigatório. */
export const IconNode = z.object({
  type: z.literal("icon"),
  props: z.object({
    icon: z.string(),
    size: z.number().optional(),
    color: BindableColor.optional(),
  }),
});
