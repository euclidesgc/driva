import { z } from "zod";
import { Bindable } from "../bindable";

/** Mapa livre de argumentos/propriedades de uma ação. */
const Params = z.record(z.unknown());

/** Ações disponíveis — spec §4. União discriminada por `type`. */
const Navigate = z.object({
  type: z.literal("navigate"),
  params: z.object({ routeId: z.string(), args: Params.optional() }),
});
const OpenUrl = z.object({
  type: z.literal("openUrl"),
  params: z.object({ url: Bindable(z.string()) }),
});
const GoBack = z.object({
  type: z.literal("goBack"),
  params: z.object({}).optional(),
});
const ShowDialog = z.object({
  type: z.literal("showDialog"),
  params: z.object({ dialogId: z.string(), params: Params.optional() }),
});
const Track = z.object({
  type: z.literal("track"),
  params: z.object({ event: z.string(), props: Params.optional() }),
});
const Custom = z.object({
  type: z.literal("custom"),
  params: z.object({ name: z.string(), params: Params.optional() }),
});

/** Uma ação. */
export const Action = z.discriminatedUnion("type", [
  Navigate,
  OpenUrl,
  GoBack,
  ShowDialog,
  Track,
  Custom,
]);

/** Lista ordenada de ações, executada em sequência (spec §4). */
export const ActionList = z.array(Action);

/** Eventos → lista de ações (ex.: `onTap`, `onLongPress`, `onDoubleTap`). */
export const Events = z.record(ActionList);

export type Action = z.infer<typeof Action>;
export type ActionList = z.infer<typeof ActionList>;
export type Events = z.infer<typeof Events>;
