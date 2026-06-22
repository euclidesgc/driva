import { z } from "zod";

/** BoxConstraints — spec §2.1 (`constraints.*`). */
export const BoxConstraints = z
  .object({
    minWidth: z.number().optional(),
    maxWidth: z.number().optional(),
    minHeight: z.number().optional(),
    maxHeight: z.number().optional(),
  })
  .strict();

export type BoxConstraints = z.infer<typeof BoxConstraints>;
