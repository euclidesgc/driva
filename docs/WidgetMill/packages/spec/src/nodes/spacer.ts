import { z } from "zod";

/** Spacer — spec §2.13. */
export const SpacerNode = z.object({
  type: z.literal("spacer"),
  props: z.object({ flex: z.number().int().optional() }).default({}),
});
