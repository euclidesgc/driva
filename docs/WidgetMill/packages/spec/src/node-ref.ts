import { z } from "zod";

/**
 * Tipo recursivo de um nó do spec. Os campos `child`/`children` referenciam o
 * próprio `Node`, daí a recursão.
 */
export interface SpecNode {
  type: string;
  props?: Record<string, unknown>;
  events?: Record<string, unknown>;
  child?: SpecNode;
  children?: SpecNode[];
}

/**
 * Holder mutável que quebra o ciclo de import: os nós dependem de `Node` (para
 * `child`/`children`), mas `Node` é a união *de* todos os nós. Em vez de um
 * import circular (que estoura no TDZ ao montar os schemas), os nós usam o
 * `NodeRef` lazy abaixo; `tree.ts` preenche `ref.node` quando a união existe.
 */
export const ref: { node: z.ZodType<SpecNode> } = {
  node: z.never() as unknown as z.ZodType<SpecNode>,
};

/** Referência lazy ao `Node`, reutilizável em qualquer `child`/`children`. */
export const NodeRef: z.ZodType<SpecNode> = z.lazy(() => ref.node);
