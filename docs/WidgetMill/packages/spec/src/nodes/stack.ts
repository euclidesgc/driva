import { z } from "zod";
import { AlignmentDirectional } from "../complex/alignment";
import { CLIP_BEHAVIOR, STACK_FIT } from "../enums";
import { NodeRef } from "../node-ref";

/** Stack — spec §2.4. Filhos podem ser Positioned. */
export const StackNode = z.object({
  type: z.literal("stack"),
  props: z
    .object({
      alignment: AlignmentDirectional.optional(),
      fit: z.enum(STACK_FIT).optional(),
      clipBehavior: z.enum(CLIP_BEHAVIOR).optional(),
    })
    .default({}),
  children: z.array(NodeRef).default([]),
});
