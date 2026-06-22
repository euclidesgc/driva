import type { SpecNode } from "../node-ref";
import { pruneBlank } from "../props/blank";
import type { PuckComponent, PuckData, PuckProps } from "./types";

/**
 * Tradutor bidirecional Puck ↔ spec (elaboração §2.3). É **simétrico** e keia
 * pela presença de `child`/`children`/`events`/`props` — sem registro de tipos.
 *
 * Invariante (testada): `puckToSpec(specToPuck(s))` é igual a `s` (o `id`
 * gerado pelo Puck é descartado na volta).
 */

/** Gera ids estáveis por ordem de travessia (determinístico por chamada de topo). */
function idMaker(): () => string {
  let n = 0;
  return () => `c-${n++}`;
}

function isPuckComponent(value: unknown): value is PuckComponent {
  return (
    typeof value === "object" &&
    value !== null &&
    typeof (value as { type?: unknown }).type === "string" &&
    typeof (value as { props?: unknown }).props === "object"
  );
}

function asPuckComponentArray(value: unknown): PuckComponent[] {
  return Array.isArray(value) ? value.filter(isPuckComponent) : [];
}

export function specToPuck(
  node: SpecNode,
  makeId: () => string = idMaker(),
): PuckComponent {
  const props: PuckProps = { id: makeId() };

  if (node.props) Object.assign(props, node.props);
  if (node.events) props.events = node.events;
  if (node.child) props.child = [specToPuck(node.child, makeId)];
  if (node.children && node.children.length > 0) {
    props.children = node.children.map((c) => specToPuck(c, makeId));
  }

  return { type: node.type, props };
}

export function puckToSpec(component: PuckComponent): SpecNode {
  const { id: _id, child, children, events, ...rest } = component.props;
  const node: SpecNode = { type: component.type };

  // Poda opcionais "em branco": campos limpos no Inspector (o Puck deixa `""`,
  // `{ all: undefined }`, `[]`…) não devem constar no spec/JSON. `pruneBlank`
  // devolve `undefined` quando nada sobra, então só atribui props se houver
  // valor real (mantém `0`/`false`).
  const props = pruneBlank(rest);
  if (props !== undefined) {
    node.props = props as Record<string, unknown>;
  }
  if (events !== undefined) node.events = events as Record<string, unknown>;

  const childArr = asPuckComponentArray(child);
  const firstChild = childArr[0];
  if (firstChild) node.child = puckToSpec(firstChild);

  const childrenArr = asPuckComponentArray(children);
  if (childrenArr.length > 0) node.children = childrenArr.map(puckToSpec);

  return node;
}

/** Envolve um nó de topo no documento Puck completo. */
export function specToPuckData(node: SpecNode): PuckData {
  return { content: [specToPuck(node)], root: {} };
}

/**
 * Extrai o nó de topo de um documento Puck. Um widget tem raiz única: se o
 * canvas tiver mais de uma raiz, elas são envolvidas num `column` implícito
 * (em vez de descartar tudo além da primeira).
 */
export function puckDataToSpec(data: PuckData): SpecNode | undefined {
  const roots = asPuckComponentArray(data.content);
  if (roots.length === 0) return undefined;
  if (roots.length === 1) return puckToSpec(roots[0]!);
  return { type: "column", children: roots.map(puckToSpec) };
}
