import type { SpecNode } from "../tree";

export type SpecChangeKind = "added" | "removed" | "typeChanged" | "propChanged";

/** Uma mudança líquida entre dois snapshots, localizada por caminho do nó. */
export interface SpecChange {
  path: string;
  kind: SpecChangeKind;
  oldType?: string;
  newType?: string;
  key?: string;
  old?: unknown;
  new?: unknown;
}

export interface SpecDiff {
  changes: SpecChange[];
}

function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (typeof a !== typeof b || a === null || b === null) return false;
  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
    return a.every((x, i) => deepEqual(x, b[i]));
  }
  if (typeof a === "object") {
    const ao = a as Record<string, unknown>;
    const bo = b as Record<string, unknown>;
    const keys = Object.keys(ao);
    if (keys.length !== Object.keys(bo).length) return false;
    return keys.every((k) => deepEqual(ao[k], bo[k]));
  }
  return false;
}

function diffProps(
  a: Record<string, unknown> = {},
  b: Record<string, unknown> = {},
  path: string,
  out: SpecChange[],
): void {
  for (const key of new Set([...Object.keys(a), ...Object.keys(b)])) {
    if (!deepEqual(a[key], b[key])) {
      out.push({ path, kind: "propChanged", key, old: a[key], new: b[key] });
    }
  }
}

function diffNode(
  a: SpecNode | null,
  b: SpecNode | null,
  path: string,
  out: SpecChange[],
): void {
  if (!a && !b) return;
  if (!a && b) return void out.push({ path, kind: "added", newType: b.type });
  if (a && !b) return void out.push({ path, kind: "removed", oldType: a.type });
  // ambos presentes
  const an = a as SpecNode;
  const bn = b as SpecNode;
  if (an.type !== bn.type) {
    return void out.push({ path, kind: "typeChanged", oldType: an.type, newType: bn.type });
  }
  diffProps(an.props, bn.props, path, out);
  if (an.child || bn.child) {
    diffNode(an.child ?? null, bn.child ?? null, `${path}.child`, out);
  }
  const ac = an.children ?? [];
  const bc = bn.children ?? [];
  const len = Math.max(ac.length, bc.length);
  for (let i = 0; i < len; i++) {
    diffNode(ac[i] ?? null, bc[i] ?? null, `${path}.children[${i}]`, out);
  }
}

/** Diff estrutural líquido entre duas árvores de spec (raiz = "root"). */
export function diffTree(a: SpecNode | null, b: SpecNode | null): SpecDiff {
  const changes: SpecChange[] = [];
  diffNode(a, b, "root", changes);
  return { changes };
}
