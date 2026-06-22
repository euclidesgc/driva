import { z } from "zod";
import {
    CROSS_AXIS,
    MAIN_AXIS,
    MAIN_SIZE,
    TEXT_BASELINE,
} from "../enums";

/** Props compartilhadas por Row e Column (mesma forma — spec §2.2/§2.3). */
export const flexProps = z.object({
  mainAxisAlignment: z.enum(MAIN_AXIS).optional(),
  crossAxisAlignment: z.enum(CROSS_AXIS).optional(),
  mainAxisSize: z.enum(MAIN_SIZE).optional(),
  spacing: z.number().optional(),
  textBaseline: z.enum(TEXT_BASELINE).optional(),
});
