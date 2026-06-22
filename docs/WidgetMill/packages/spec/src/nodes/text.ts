import { z } from "zod";
import { TextStyle } from "../complex/textStyle";
import { TEXT_ALIGN, TEXT_OVERFLOW } from "../enums";
import { BindableString } from "../scalars";

/** Text — spec §2.5. */
export const TextNode = z.object({
  type: z.literal("text"),
  props: z
    .object({
      data: BindableString.optional(),
      style: TextStyle.optional(),
      textAlign: z.enum(TEXT_ALIGN).optional(),
      maxLines: z.number().int().optional(),
      overflow: z.enum(TEXT_OVERFLOW).optional(),
      softWrap: z.boolean().optional(),
    })
    .default({}),
});
