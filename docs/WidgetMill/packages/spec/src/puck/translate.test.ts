import { Node } from "../tree";
import {
  specToPuck,
  puckToSpec,
  specToPuckData,
  puckDataToSpec,
} from "./translate";
import type { SpecNode } from "../node-ref";
import type { PuckComponent, PuckData } from "./types";

const roundTrip = (node: SpecNode): SpecNode => puckToSpec(specToPuck(node));

// PRNG determinístico (mulberry32) — property-based sem dependência externa.
function rng(seed: number): () => number {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const LEAVES = ["text", "icon", "spacer"] as const;
const SINGLE = ["container", "center", "padding", "sizedBox"] as const;
const MULTI = ["column", "row", "stack"] as const;

function genNode(rand: () => number, depth: number): SpecNode {
  const pick = <T>(arr: readonly T[]): T =>
    arr[Math.floor(rand() * arr.length)]!;

  if (depth <= 0) {
    const type = pick(LEAVES);
    if (type === "text") return { type, props: { data: "x" } };
    if (type === "icon") return { type, props: { icon: "home" } };
    return { type: "spacer" };
  }

  if (rand() < 0.45) {
    const type = pick(SINGLE);
    const node: SpecNode = { type, child: genNode(rand, depth - 1) };
    if (type === "padding") node.props = { padding: { all: 8 } };
    return node;
  }

  const type = pick(MULTI);
  const count = 1 + Math.floor(rand() * 2);
  return {
    type,
    children: Array.from({ length: count }, () => genNode(rand, depth - 1)),
  };
}

describe("Tradutor Puck ↔ spec", () => {
  it("specToPuck achata as props e cria slots", () => {
    const puck = specToPuck({
      type: "container",
      props: { padding: { all: 8 } },
      child: { type: "text", props: { data: "oi" } },
    });
    expect(puck.type).toBe("container");
    expect((puck.props as Record<string, unknown>).padding).toEqual({ all: 8 });
    expect(typeof (puck.props as Record<string, unknown>).id).toBe("string");
    const slot = (puck.props as Record<string, unknown>).child as Array<{
      type: string;
    }>;
    expect(slot[0]!.type).toBe("text");
  });

  it("puckToSpec descarta o id e reconstrói a árvore", () => {
    const node: SpecNode = {
      type: "column",
      props: { spacing: 8 },
      children: [{ type: "text", props: { data: "a" } }],
    };
    expect(roundTrip(node)).toEqual(node);
  });

  it("preserva eventos no round-trip", () => {
    const node: SpecNode = {
      type: "gestureDetector",
      events: {
        onTap: [{ type: "navigate", params: { routeId: "r" } }],
      },
      child: { type: "text", props: { data: "x" } },
    };
    expect(roundTrip(node)).toEqual(node);
  });

  const handcrafted: SpecNode[] = [
    { type: "text", props: { data: "só texto" } },
    { type: "spacer" },
    {
      type: "container",
      props: { padding: { all: 16 }, color: "#FFFFFF" },
      child: {
        type: "column",
        props: { spacing: 8 },
        children: [
          { type: "text", props: { data: "a" } },
          { type: "row", children: [{ type: "icon", props: { icon: "star" } }] },
        ],
      },
    },
  ];

  it.each(handcrafted)("round-trip idempotente (caso %#)", (node) => {
    expect(roundTrip(node)).toEqual(node);
  });

  it("round-trip idempotente em 200 árvores geradas (e válidas no kernel)", () => {
    for (let seed = 1; seed <= 200; seed++) {
      const node = genNode(rng(seed), 3);
      expect(Node.safeParse(node).success).toBe(true);
      expect(roundTrip(node)).toEqual(node);
    }
  });
});

describe("puckDataToSpec — raiz única vs múltiplas", () => {
  const dataWith = (...nodes: SpecNode[]): PuckData => ({
    content: nodes.map((n) => specToPuck(n)),
    root: {},
  });

  it("conteúdo vazio → undefined", () => {
    expect(puckDataToSpec({ content: [], root: {} })).toBeUndefined();
  });

  it("raiz única é retornada sem envolver", () => {
    const node: SpecNode = { type: "text", props: { data: "oi" } };
    expect(puckDataToSpec(dataWith(node))).toEqual(node);
  });

  it("múltiplas raízes são envolvidas num column implícito (não descarta)", () => {
    const a: SpecNode = { type: "container", child: { type: "text", props: { data: "a" } } };
    const b: SpecNode = { type: "text", props: { data: "b" } };
    expect(puckDataToSpec(dataWith(a, b))).toEqual({
      type: "column",
      children: [a, b],
    });
  });

  it("round-trip de doc com raiz única preserva o nó", () => {
    const node: SpecNode = {
      type: "column",
      props: { spacing: 8 },
      children: [{ type: "text", props: { data: "x" } }],
    };
    expect(puckDataToSpec(specToPuckData(node))).toEqual(node);
  });
});

describe("puckToSpec — poda opcionais em branco", () => {
  // O Puck deixa "" / {} / [] ao limpar um campo opcional; o spec não deve
  // carregar isso (ver pruneBlank). `0` e `false` são valores reais e ficam.
  const comp = (props: Record<string, unknown>): PuckComponent => ({
    type: "container",
    props: { id: "c-0", ...props },
  });

  it("descarta uma cor limpada (\"\")", () => {
    expect(puckToSpec(comp({ color: "" }))).toEqual({ type: "container" });
  });

  it("descarta objetos/arrays vazios mas mantém 0", () => {
    expect(puckToSpec(comp({ width: 0, color: "", decoration: {}, margin: [] }))).toEqual({
      type: "container",
      props: { width: 0 },
    });
  });

  it("decoration só com valores em branco some inteira", () => {
    expect(
      puckToSpec(comp({ decoration: { color: "", borderRadius: undefined } })),
    ).toEqual({ type: "container" });
  });

  it("preserva valores reais (incluindo aninhados)", () => {
    expect(puckToSpec(comp({ decoration: { color: "#fff" }, padding: { all: 8 } }))).toEqual({
      type: "container",
      props: { decoration: { color: "#fff" }, padding: { all: 8 } },
    });
  });
});
