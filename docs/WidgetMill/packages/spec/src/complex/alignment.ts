import { z } from "zod";
import { ALIGNMENT, ALIGNMENT_DIRECTIONAL } from "../enums";

/** Alignment — spec §3.4. */
export const Alignment = z.enum(ALIGNMENT);

/** Variante direcional (usada por Stack) — spec §3.4. */
export const AlignmentDirectional = z.enum(ALIGNMENT_DIRECTIONAL);

export type Alignment = z.infer<typeof Alignment>;
export type AlignmentDirectional = z.infer<typeof AlignmentDirectional>;
