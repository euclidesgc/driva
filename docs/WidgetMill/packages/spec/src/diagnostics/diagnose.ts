import type { PuckComponent } from "../puck/types";
import { MULTI_CHILD_TYPES, slotKind } from "../nodes/slots";
import { hasValue, isBlank } from "../props/blank";

export type DiagnosticSeverity = "error" | "warning";

/** Um problema detectado numa montagem, localizado pelo `id` do nó Puck. */
export interface Diagnostic {
  nodeId?: string;
  severity: DiagnosticSeverity;
  code: string;
  message: string;
}

const FLEX_ONLY = new Set(["expanded", "flexible", "spacer"]);
const FLEX_PARENTS = new Set(["row", "column"]);
const EMPTY_WARN_SINGLE = new Set(["container", "center"]);
const MULTI = MULTI_CHILD_TYPES as readonly string[];

const MULTI_ROOTS_MSG =
  "Múltiplas raízes: um widget precisa de uma única raiz. Envolva tudo num Column/Container.";

function isComp(v: unknown): v is PuckComponent {
  return typeof v === "object" && v !== null && typeof (v as { type?: unknown }).type === "string";
}

function slotItems(value: unknown): PuckComponent[] {
  return Array.isArray(value) ? value.filter(isComp) : [];
}

function isEmptyText(data: unknown): boolean {
  return isBlank(data);
}

function walk(node: PuckComponent, parentType: string | null, out: Diagnostic[]): void {
  const id = node.props.id;
  const type = node.type;

  if (FLEX_ONLY.has(type) && !(parentType && FLEX_PARENTS.has(parentType))) {
    out.push({
      nodeId: id,
      severity: "error",
      code: "flex-child-outside-flex",
      message: `'${type}' só pode ser usado dentro de Row/Column.`,
    });
  }

  if (type === "positioned" && parentType !== "stack") {
    out.push({
      nodeId: id,
      severity: "error",
      code: "positioned-outside-stack",
      message: "'positioned' só pode ser usado dentro de Stack.",
    });
  }

  if (slotKind(type) === "child" && slotItems(node.props.child).length > 1) {
    out.push({
      nodeId: id,
      severity: "error",
      code: "single-child-overflow",
      message: `'${type}' aceita apenas um filho; os demais serão descartados.`,
    });
  }

  if (type === "container" && !isBlank(node.props.color) && hasValue(node.props.decoration)) {
    out.push({
      nodeId: id,
      severity: "error",
      code: "color-and-decoration",
      message: "Container não pode ter 'color' e 'decoration' ao mesmo tempo.",
    });
  }

  if (MULTI.includes(type) && slotItems(node.props.children).length === 0) {
    out.push({ nodeId: id, severity: "warning", code: "empty-layout", message: `'${type}' está vazio.` });
  } else if (EMPTY_WARN_SINGLE.has(type) && slotItems(node.props.child).length === 0) {
    out.push({ nodeId: id, severity: "warning", code: "empty-layout", message: `'${type}' está vazio.` });
  }

  if (type === "text" && isEmptyText(node.props.data)) {
    out.push({ nodeId: id, severity: "warning", code: "empty-text", message: "Text sem conteúdo." });
  }

  for (const slot of [node.props.child, node.props.children]) {
    for (const c of slotItems(slot)) walk(c, type, out);
  }
}

/**
 * Detecta montagens problemáticas a partir da árvore Puck (que carrega os `id`s).
 * Erros quebram/corrompem no Flutter; avisos são prováveis enganos de montagem.
 */
export function diagnose(content: PuckComponent[]): Diagnostic[] {
  const out: Diagnostic[] = [];
  const roots = content.filter(isComp);
  if (roots.length > 1) {
    for (const r of roots) {
      out.push({ nodeId: r.props.id, severity: "error", code: "multiple-roots", message: MULTI_ROOTS_MSG });
    }
  }
  for (const r of roots) walk(r, null, out);
  return out;
}
