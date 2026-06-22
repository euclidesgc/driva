import { z } from "zod";
import { NodeRef } from "../node-ref";

/** SafeArea — recua o filho dos intrusos do sistema (notch, status bar). */
export const SafeAreaNode = z.object({
  type: z.literal("safeArea"),
  props: z
    .object({
      top: z.boolean().optional(),
      bottom: z.boolean().optional(),
      left: z.boolean().optional(),
      right: z.boolean().optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
