import { z } from "zod";
import { BindableColor } from "../scalars";
import { BindableDimension } from "../complex/dimension";
import { EdgeInsets } from "../complex/edgeInsets";
import { BoxDecoration } from "../complex/boxDecoration";
import { Alignment } from "../complex/alignment";
import { BoxConstraints } from "../complex/constraints";
import { NodeRef } from "../node-ref";

/** Container — spec §2.1. `color` e `decoration` são mutuamente exclusivos. */
const containerProps = z
  .object({
    width: BindableDimension.optional(),
    height: BindableDimension.optional(),
    padding: EdgeInsets.optional(),
    margin: EdgeInsets.optional(),
    color: BindableColor.optional(),
    alignment: Alignment.optional(),
    decoration: BoxDecoration.optional(),
    constraints: BoxConstraints.optional(),
  })
  .default({})
  .refine((p) => !(p.color !== undefined && p.decoration !== undefined), {
    message: "color e decoration são mutuamente exclusivos (regra do Flutter)",
    path: ["color"],
  });

export const ContainerNode = z.object({
  type: z.literal("container"),
  props: containerProps,
  child: NodeRef.optional(),
});
