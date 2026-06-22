import { z } from "zod";

/** BorderRadius — número uniforme ou por canto (spec §1.2 / §3.3). */
export const BorderRadius = z.union([
  z.number(),
  z
    .object({
      topLeft: z.number().optional(),
      topRight: z.number().optional(),
      bottomLeft: z.number().optional(),
      bottomRight: z.number().optional(),
    })
    .strict(),
]);

export type BorderRadius = z.infer<typeof BorderRadius>;
