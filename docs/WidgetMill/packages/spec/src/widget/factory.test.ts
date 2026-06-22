import { makeWidgetSpec } from "./factory";

const tree = { type: "text", props: { data: "oi" } };

describe("makeWidgetSpec", () => {
  it("monta um WidgetSpec válido com defaults (composite, propsSchema [])", () => {
    const r = makeWidgetSpec({ slug: "card", name: "Card", tree });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.spec.specVersion).toBe(1);
      expect(r.spec.kind).toBe("composite");
      expect(r.spec.propsSchema).toEqual([]);
      // O parse normaliza a árvore (aplica defaults), preservando o conteúdo.
      const out = r.spec.tree as { type: string; props?: { data?: string } };
      expect(out.type).toBe("text");
      expect(out.props?.data).toBe("oi");
    }
  });

  it("respeita version explícita", () => {
    const r = makeWidgetSpec({ slug: "card", name: "Card", tree, version: 3 });
    expect(r.ok && r.spec.version).toBe(3);
  });

  it("falha com árvore inválida (tipo desconhecido)", () => {
    const r = makeWidgetSpec({
      slug: "x",
      name: "X",
      tree: { type: "naoexiste" } as never,
    });
    expect(r.ok).toBe(false);
  });
});
