import { z } from "zod";

/**
 * EdgeInsets (padding / margin) — spec §3.1. Uma das três formas:
 * `{ all }`, `{ horizontal, vertical }` (symmetric) ou `{ left, top, right, bottom }`.
 *
 * `.strict()` em cada variante é essencial: sem ele, `{ left: 8 }` casaria com a
 * variante symmetric (campos opcionais) e os lados seriam **descartados**.
 */
export const EdgeInsets = z.union([
  z.object({ all: z.number() }).strict(),
  z
    .object({
      horizontal: z.number().optional(),
      vertical: z.number().optional(),
    })
    .strict(),
  z
    .object({
      left: z.number().optional(),
      top: z.number().optional(),
      right: z.number().optional(),
      bottom: z.number().optional(),
    })
    .strict(),
]);

export type EdgeInsets = z.infer<typeof EdgeInsets>;
