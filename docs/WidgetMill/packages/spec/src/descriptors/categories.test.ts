import { nodeOptions } from "../nodes";
import { COMPONENT_CATEGORIES, paletteCategories } from "./categories";

const nodeTypes = nodeOptions.map(
  (opt) => (opt.shape.type as { value: string }).value,
);

describe("palette categories", () => {
  it("todo primitivo aparece em exatamente uma categoria (anti-drift)", () => {
    const placed = paletteCategories(nodeTypes).flatMap((c) => c.components);
    expect(new Set(placed).size).toBe(placed.length); // sem duplicatas
    expect(new Set(placed)).toEqual(new Set(nodeTypes)); // cobre todos
  });

  it("não sobra 'Outros' quando tudo está categorizado", () => {
    const cats = paletteCategories(nodeTypes);
    expect(cats.find((c) => c.name === "other")).toBeUndefined();
  });

  it("primitivo não-categorizado cai em 'Outros'", () => {
    const cats = paletteCategories(["text", "naoexiste"]);
    expect(cats.find((c) => c.name === "other")?.components).toContain("naoexiste");
  });

  it("ignora categorias/tipos ausentes do conjunto pedido", () => {
    const cats = paletteCategories(["text"]);
    expect(cats.find((c) => c.name === "content")?.components).toEqual(["text"]);
    expect(cats.find((c) => c.name === "layout")).toBeUndefined();
  });

  it("preserva a ordem declarada em COMPONENT_CATEGORIES", () => {
    const order = paletteCategories(nodeTypes)
      .filter((c) => c.name !== "other")
      .map((c) => c.name);
    const declared = COMPONENT_CATEGORIES.map((c) => c.name).filter((n) =>
      order.includes(n),
    );
    expect(order).toEqual(declared);
  });
});
