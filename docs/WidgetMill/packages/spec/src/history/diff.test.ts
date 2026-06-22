import { diffTree } from "./diff";

const text = (data: string) => ({ type: "text", props: { data } });

describe("diffTree", () => {
  it("árvores iguais → sem mudanças", () => {
    expect(diffTree(text("a"), text("a")).changes).toEqual([]);
  });

  it("ambos nulos → sem mudanças", () => {
    expect(diffTree(null, null).changes).toEqual([]);
  });

  it("prop alterada → propChanged com old/new", () => {
    expect(diffTree(text("a"), text("b")).changes).toEqual([
      { path: "root", kind: "propChanged", key: "data", old: "a", new: "b" },
    ]);
  });

  it("tipo trocado → typeChanged (sem descer)", () => {
    expect(
      diffTree(text("a"), { type: "icon", props: { icon: "x" } }).changes,
    ).toEqual([{ path: "root", kind: "typeChanged", oldType: "text", newType: "icon" }]);
  });

  it("filho adicionado em children", () => {
    const a = { type: "column", children: [text("a")] };
    const b = { type: "column", children: [text("a"), text("b")] };
    expect(diffTree(a, b).changes).toEqual([
      { path: "root.children[1]", kind: "added", newType: "text" },
    ]);
  });

  it("filho removido (single child)", () => {
    const a = { type: "center", child: text("x") };
    const b = { type: "center" };
    expect(diffTree(a, b).changes).toEqual([
      { path: "root.child", kind: "removed", oldType: "text" },
    ]);
  });

  it("prop adicionada e removida contam como propChanged", () => {
    const a = { type: "container", props: { width: 10 } };
    const b = { type: "container", props: { height: 20 } };
    const d = diffTree(a, b).changes;
    expect(d).toContainEqual({
      path: "root",
      kind: "propChanged",
      key: "width",
      old: 10,
      new: undefined,
    });
    expect(d).toContainEqual({
      path: "root",
      kind: "propChanged",
      key: "height",
      old: undefined,
      new: 20,
    });
  });

  it("valores de prop em objeto comparados por igualdade profunda", () => {
    const a = { type: "container", props: { padding: { all: 16 } } };
    const b = { type: "container", props: { padding: { all: 16 } } };
    expect(diffTree(a, b).changes).toEqual([]);
  });
});
