import { z } from "zod";
import { NodeRef } from "../node-ref";
import { flexProps } from "./_flex";

/** Row — spec §2.3 (mesma forma de Column). */
export const RowNode = z.object({
  type: z.literal("row"),
  props: flexProps.default({}),
  children: z.array(NodeRef).default([]),
});
