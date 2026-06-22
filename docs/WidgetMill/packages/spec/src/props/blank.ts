/**
 * Regras de "valor em branco" (não informado) — **fonte única** reusada pela
 * tradução Puck→spec, pelos diagnósticos e pelas regras de visibilidade do
 * Inspector.
 *
 * Por que existe: ao limpar um campo opcional, o Puck **não remove a chave** —
 * deixa `""` num campo de texto, `{ all: undefined }` num objeto, `[]` numa
 * lista. Sem normalizar isso, opcionais "limpas" vazam para o spec/JSON e ainda
 * disparam diagnósticos presos (`"" != null`). Estas funções definem, num só
 * lugar, o que conta como ausência.
 */

/** `true` se o valor é "não informado": `null`/`undefined` ou string vazia/só-espaços. */
export function isBlank(value: unknown): boolean {
  return value == null || (typeof value === "string" && value.trim() === "");
}

/**
 * Remove recursivamente tudo que é branco e devolve `undefined` quando nada
 * sobra. Mantém `0` e `false` (valores legítimos, não ausência). Não muta a
 * entrada; strings não-brancas são preservadas como estão (sem `trim`).
 */
export function pruneBlank(value: unknown): unknown {
  if (value == null) return undefined;
  if (typeof value === "string") return value.trim() === "" ? undefined : value;
  if (Array.isArray(value)) {
    const items = value.map(pruneBlank).filter((v) => v !== undefined);
    return items.length > 0 ? items : undefined;
  }
  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      const pruned = pruneBlank(v);
      if (pruned !== undefined) out[k] = pruned;
    }
    return Object.keys(out).length > 0 ? out : undefined;
  }
  return value; // number, boolean, bigint, etc.
}

/**
 * `true` se há ao menos um valor "de verdade" em profundidade — i.e. sobra algo
 * após [pruneBlank]. Útil para regras como "tem decoration?" (objeto com pelo
 * menos um campo preenchido) sem tratar `{}` ou `{ color: "" }` como presença.
 */
export function hasValue(value: unknown): boolean {
  return pruneBlank(value) !== undefined;
}
