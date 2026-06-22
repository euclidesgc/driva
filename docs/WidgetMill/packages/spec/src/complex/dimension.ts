import { z } from "zod";
import { Bindable } from "../bindable";

/**
 * Dimensão (width/height e afins). Além do número fixo em px, aceita um **token
 * relativo** que o renderer resolve em runtime com o `BuildContext`:
 *
 * - `number`                                  → px fixo.
 * - `{ unit: "infinity" }`                    → `double.infinity` (preenche o disponível).
 * - `{ unit: "screenWidth",  factor }`        → `MediaQuery.sizeOf(c).width  * factor`.
 * - `{ unit: "screenHeight", factor }`        → `MediaQuery.sizeOf(c).height * factor`.
 *
 * `factor` é o **multiplicador** (0.5 = 50% da tela). Todas as formas resolvem
 * para um `double` (sem widget extra). Para "% do pai", use `fractionallySizedBox`.
 */
export const DIMENSION_UNITS = ["infinity", "screenWidth", "screenHeight"] as const;

const DimensionToken = z.union([
  z.object({ unit: z.literal("infinity") }).strict(),
  z.object({ unit: z.literal("screenWidth"), factor: z.number() }).strict(),
  z.object({ unit: z.literal("screenHeight"), factor: z.number() }).strict(),
]);

/** Valor de dimensão: px fixo ou token relativo. */
export const Dimension = z.union([z.number(), DimensionToken]);

/** Dimensão bindável (`{{prop}}` / `$token`). Usada por width/height. */
export const BindableDimension = Bindable(Dimension);

export type Dimension = z.infer<typeof Dimension>;
