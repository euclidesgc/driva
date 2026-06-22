import { z } from "zod";
import { ActionList } from "../actions/index";
import { EdgeInsets } from "../complex/edgeInsets";
import { BorderRadius } from "../complex/borderRadius";
import { TextStyle } from "../complex/textStyle";
import { BORDER_STYLE, BUTTON_VARIANT } from "../enums";
import { NodeRef } from "../node-ref";
import { BindableColor, BindableString } from "../scalars";

/**
 * Estilo do botão — subconjunto de `ButtonStyle` do Flutter exposto no editor.
 * `borderRadius`/`side` viram o `shape`/`side` via `*.styleFrom(...)` no renderer.
 */
export const ButtonStyleProps = z.object({
  backgroundColor: BindableColor.optional(),
  foregroundColor: BindableColor.optional(),
  padding: EdgeInsets.optional(),
  elevation: z.number().optional(),
  borderRadius: BorderRadius.optional(),
  side: z
    .object({
      color: BindableColor.optional(),
      width: z.number().optional(),
      style: z.enum(BORDER_STYLE).optional(),
    })
    .optional(),
  textStyle: TextStyle.optional(),
});

/** Button — spec §2.8. `onPressed` é uma actionList (spec §4). */
export const ButtonNode = z.object({
  type: z.literal("button"),
  props: z
    .object({
      variant: z.enum(BUTTON_VARIANT).optional(),
      label: BindableString.optional(),
      // Ícone opcional (nome do catálogo Material) → `*.icon(...)` no renderer.
      icon: z.string().optional(),
      onPressed: ActionList.optional(),
      // Opcional: ausente = default do Flutter (true). O renderer aplica `?? true`.
      enabled: z.boolean().optional(),
      style: ButtonStyleProps.optional(),
    })
    .default({}),
  child: NodeRef.optional(),
});
