import { z } from "zod";
import { FONT_STYLE, FONT_WEIGHT, TEXT_DECORATION } from "../enums";
import { Color } from "../scalars";

/** Pesos de fonte do Flutter (serializados pelo nome — spec §3.2 / §7). */
export const FontWeight = z.enum(FONT_WEIGHT);

/** TextStyle — spec §3.2. Todos os campos são opcionais. */
export const TextStyle = z
  .object({
    fontSize: z.number().optional(),
    fontWeight: FontWeight.optional(),
    fontStyle: z.enum(FONT_STYLE).optional(),
    color: Color.optional(),
    fontFamily: z.string().optional(),
    letterSpacing: z.number().optional(),
    wordSpacing: z.number().optional(),
    height: z.number().optional(),
    decoration: z.enum(TEXT_DECORATION).optional(),
  })
  .strict();

export type TextStyle = z.infer<typeof TextStyle>;
