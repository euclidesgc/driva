import { z } from "zod";
import { nodeOptions } from "./nodes";
import { ref, type SpecNode } from "./node-ref";

/** União discriminada (por `type`) de todos os primitivos. */
export const Node = z.discriminatedUnion("type", nodeOptions);

// Resolve a recursão: a partir daqui, todo `NodeRef` lazy aponta para `Node`.
ref.node = Node as unknown as z.ZodType<SpecNode>;

export type { SpecNode };
