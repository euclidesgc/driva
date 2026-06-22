import { z } from "zod";
import { BindableColor } from "../scalars";

/** Divider — linha divisória horizontal (catálogo Flutter). */
export const DividerNode = z.object({
  type: z.literal("divider"),
  props: z
    .object({
      height: z.number().optional(),
      thickness: z.number().optional(),
      indent: z.number().optional(),
      endIndent: z.number().optional(),
      color: BindableColor.optional(),
    })
    .default({}),
});
