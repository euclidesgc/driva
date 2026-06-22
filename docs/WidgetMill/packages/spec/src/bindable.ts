import { z } from "zod";

/** `"{{chave}}"` — referência a uma prop pública (spec §1.3). */
export const BINDING = /^\{\{\s*[\w.]+\s*\}\}$/;
/** `"$nome"` — token do design system (spec §5). */
export const TOKEN = /^\$[\w.]+$/;

/**
 * Aceita o valor tipado, **ou** um binding `"{{chave}}"`, **ou** um token `"$nome"`.
 * Binding é validado em um único lugar — toda prop "bindável" usa este helper.
 */
export const Bindable = <T extends z.ZodTypeAny>(inner: T) =>
  z.union([inner, z.string().regex(BINDING), z.string().regex(TOKEN)]);
