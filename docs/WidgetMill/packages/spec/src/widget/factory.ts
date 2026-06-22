import type { ZodError } from "zod";
import { WidgetSpec } from "../schema";
import type { SpecNode } from "../tree";

export interface MakeWidgetSpecInput {
  slug: string;
  name: string;
  tree: SpecNode;
  kind?: "primitive" | "composite";
  version?: number;
  propsSchema?: WidgetSpec["propsSchema"];
}

export type MakeWidgetSpecResult =
  | { ok: true; spec: WidgetSpec }
  | { ok: false; error: ZodError };

/**
 * Monta o envelope `WidgetSpec` a partir de uma árvore + identidade e o valida.
 * Defaults: `kind: "composite"`, `propsSchema: []`. Reusável pelo editor (web)
 * agora e pelo backend (M3) depois.
 */
export function makeWidgetSpec(input: MakeWidgetSpecInput): MakeWidgetSpecResult {
  const candidate = {
    specVersion: 1 as const,
    slug: input.slug,
    name: input.name,
    kind: input.kind ?? "composite",
    version: input.version,
    propsSchema: input.propsSchema ?? [],
    tree: input.tree,
  };
  const parsed = WidgetSpec.safeParse(candidate);
  if (!parsed.success) return { ok: false, error: parsed.error };
  // Valida o envelope, mas persiste a árvore **como recebida** — sem reintroduzir
  // defaults/estrutura do Zod (`props:{}`, `children:[]`). A spec salva fica
  // idêntica à montagem do editor (que já vem podada por `puckDataToSpec`). O
  // cast é seguro: a árvore foi validada acima; `SpecNode` é só a forma "frouxa".
  return { ok: true, spec: { ...parsed.data, tree: input.tree as WidgetSpec["tree"] } };
}
