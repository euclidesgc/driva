import { z } from "zod";
import { Alignment } from "../complex/alignment";
import { NodeRef } from "../node-ref";

/**
 * FractionallySizedBox — dimensiona o filho como fração do espaço do **pai**
 * (complementa o `Dimension` de width/height, que é relativo à **tela**).
 */
export const FractionallySizedBoxNode = z.object({
  type: z.literal("fractionallySizedBox"),
  props: z
    .object({
      widthFactor: z.number().optional(),
      heightFactor: z.number().optional(),
      alignment: Alignment.optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
