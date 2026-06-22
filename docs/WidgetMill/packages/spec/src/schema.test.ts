import { readFileSync } from "node:fs";
import { join } from "node:path";
import { WidgetSpec, PropDef } from "./schema";

const widget = (name: string) =>
  JSON.parse(
    readFileSync(join(process.cwd(), "fixtures", "widgets", name), "utf8"),
  );

describe("WidgetSpec", () => {
  it("valida o fixture primary_button (spec §6)", () => {
    expect(() => WidgetSpec.parse(widget("primary_button.json"))).not.toThrow();
  });

  it("rejeita specVersion != 1", () => {
    const w = widget("primary_button.json");
    w.specVersion = 2;
    expect(() => WidgetSpec.parse(w)).toThrow();
  });

  it("propsSchema default = [] quando ausente", () => {
    const parsed = WidgetSpec.parse({
      specVersion: 1,
      slug: "x",
      name: "X",
      kind: "primitive",
      tree: { type: "text", props: { data: "a" } },
    });
    expect(parsed.propsSchema).toEqual([]);
  });

  it("rejeita kind inválido", () => {
    expect(() =>
      WidgetSpec.parse({
        specVersion: 1,
        slug: "x",
        name: "X",
        kind: "molecule",
        tree: { type: "text", props: {} },
      }),
    ).toThrow();
  });
});

describe("PropDef", () => {
  it("required default = false", () => {
    expect(PropDef.parse({ key: "k", type: "string" }).required).toBe(false);
  });

  it("rejeita type não suportado", () => {
    expect(() => PropDef.parse({ key: "k", type: "vector" })).toThrow();
  });
});
