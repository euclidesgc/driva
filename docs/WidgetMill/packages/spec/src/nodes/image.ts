import { z } from "zod";
import { BOX_FIT, IMAGE_SOURCE } from "../enums";
import { BindableString } from "../scalars";
import { BindableDimension } from "../complex/dimension";

/** Image — spec §2.6. */
export const ImageNode = z.object({
  type: z.literal("image"),
  props: z
    .object({
      source: z.enum(IMAGE_SOURCE).optional(),
      src: BindableString.optional(),
      width: BindableDimension.optional(),
      height: BindableDimension.optional(),
      fit: z.enum(BOX_FIT).optional(),
    })
    .default({}),
});
