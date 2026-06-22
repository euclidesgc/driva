import { z } from "zod";
import { BORDER_STYLE, BOX_SHAPE } from "../enums";
import { BindableColor } from "../scalars";
import { BorderRadius } from "./borderRadius";
import { Alignment } from "./alignment";

/** Borda uniforme — spec §3.3. */
const Border = z
  .object({
    color: BindableColor.optional(),
    width: z.number().optional(),
    style: z.enum(BORDER_STYLE).optional(),
  })
  .strict();

/** Item de sombra — spec §3.3. */
const BoxShadow = z
  .object({
    color: BindableColor.optional(),
    offsetX: z.number().optional(),
    offsetY: z.number().optional(),
    blurRadius: z.number().optional(),
    spreadRadius: z.number().optional(),
  })
  .strict();

/** Gradiente linear/radial — spec §3.3. */
const Gradient = z
  .object({
    type: z.enum(["linear", "radial"]),
    colors: z.array(BindableColor),
    stops: z.array(z.number()).optional(),
    begin: Alignment.optional(),
    end: Alignment.optional(),
  })
  .strict();

/** BoxDecoration — spec §3.3. Mutuamente exclusiva com `color` no Container. */
export const BoxDecoration = z
  .object({
    color: BindableColor.optional(),
    borderRadius: BorderRadius.optional(),
    border: Border.optional(),
    boxShadow: z.array(BoxShadow).optional(),
    gradient: Gradient.optional(),
    shape: z.enum(BOX_SHAPE).optional(),
  })
  .strict();

export type BoxDecoration = z.infer<typeof BoxDecoration>;
