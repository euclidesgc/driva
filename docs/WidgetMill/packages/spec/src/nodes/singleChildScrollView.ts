import { z } from "zod";
import { EdgeInsets } from "../complex/edgeInsets";
import { AXIS } from "../enums";
import { NodeRef } from "../node-ref";

/** SingleChildScrollView — torna o filho rolável num eixo (catálogo Flutter). */
export const SingleChildScrollViewNode = z.object({
  type: z.literal("singleChildScrollView"),
  props: z
    .object({
      scrollDirection: z.enum(AXIS).optional(),
      reverse: z.boolean().optional(),
      padding: EdgeInsets.optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
