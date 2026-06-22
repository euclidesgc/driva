import { z } from "zod";
import { Events } from "../actions/index";
import { NodeRef } from "../node-ref";

/** GestureDetector — spec §2.14. Eventos: onTap, onLongPress, onDoubleTap. */
export const GestureDetectorNode = z.object({
  type: z.literal("gestureDetector"),
  events: Events.optional(),
  child: NodeRef.optional(),
});
