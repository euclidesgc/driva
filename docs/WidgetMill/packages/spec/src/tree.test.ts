import { Node } from "./tree";

describe("Node (união discriminada recursiva)", () => {
  it("aceita container > column > [text]", () => {
    const spec = {
      type: "container",
      props: { padding: { all: 16 } },
      child: {
        type: "column",
        props: { spacing: 8 },
        children: [{ type: "text", props: { data: "Olá" } }],
      },
    };
    expect(() => Node.parse(spec)).not.toThrow();
  });

  it("rejeita tipo desconhecido", () => {
    expect(() => Node.parse({ type: "naoexiste" })).toThrow();
  });

  it("rejeita enum inválido em text.overflow", () => {
    expect(() =>
      Node.parse({ type: "text", props: { data: "x", overflow: "banana" } }),
    ).toThrow();
  });

  it("text: props opcionais ausentes quando não informadas (Flutter aplica o default)", () => {
    const parsed = Node.parse({ type: "text", props: {} }) as {
      props: Record<string, unknown>;
    };
    expect(parsed.props.data).toBeUndefined();
    expect(parsed.props.softWrap).toBeUndefined();
    expect(parsed.props.textAlign).toBeUndefined();
    expect(parsed.props.overflow).toBeUndefined();
  });

  it("aceita binding {{label}} em text.data", () => {
    expect(() =>
      Node.parse({ type: "text", props: { data: "{{label}}" } }),
    ).not.toThrow();
  });
});
