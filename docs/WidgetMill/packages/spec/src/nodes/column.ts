import { z } from "zod";
import { NodeRef } from "../node-ref";
import { flexProps } from "./_flex";

/** Column — spec §2.2. */
export const ColumnNode = z.object({
  type: z.literal("column"),
  props: flexProps.default({}),
  children: z.array(NodeRef).default([]),
});
