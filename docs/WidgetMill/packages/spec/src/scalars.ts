import { z } from "zod";
import { Bindable } from "./bindable";

/** Cor em hex `#RRGGBB` ou `#AARRGGBB` (spec §1.2). */
export const Color = z.string().regex(/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/);

// Aliases "bindáveis" reusados pelos nós — evitam repetir `Bindable(...)` em toda prop.
export const BindableColor = Bindable(Color);
export const BindableNumber = Bindable(z.number());
export const BindableString = Bindable(z.string());
