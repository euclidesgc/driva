import { nodeOptions } from "../nodes";
import { descriptorsByType, descriptorsFor, FIELD_TYPES } from "./catalog";

const nodeTypes = nodeOptions.map(
  (opt) => (opt.shape.type as { value: string }).value,
);

describe("field descriptors", () => {
  it("todo primitivo tem um descriptor (anti-drift)", () => {
    for (const type of nodeTypes) {
      expect(
        descriptorsByType[type],
        `falta descriptor para "${type}"`,
      ).toBeDefined();
    }
  });

  it("todos os campos usam um FieldType válido", () => {
    for (const fields of Object.values(descriptorsByType)) {
      for (const f of fields) {
        expect(FIELD_TYPES).toContain(f.type);
      }
    }
  });

  it("Container esconde 'color' quando há decoration (regra do Flutter)", () => {
    const color = descriptorsFor("container").find((f) => f.key === "color")!;
    expect(color.hidden?.({ decoration: { color: "#fff" } })).toBe(true);
    expect(color.hidden?.({})).toBe(false);
  });

  it("Container: decoration vazia/em-branco NÃO esconde 'color' (usa hasValue)", () => {
    const color = descriptorsFor("container").find((f) => f.key === "color")!;
    expect(color.hidden?.({ decoration: {} })).toBe(false);
    expect(color.hidden?.({ decoration: { color: "" } })).toBe(false);
  });

  it("marca obrigatórias (icon.icon e padding.padding)", () => {
    expect(descriptorsFor("icon").find((f) => f.key === "icon")?.required).toBe(true);
    expect(descriptorsFor("padding").find((f) => f.key === "padding")?.required).toBe(true);
  });

  it("marca enums opcionais clearáveis (textBaseline, container.alignment)", () => {
    expect(descriptorsFor("column").find((f) => f.key === "textBaseline")?.optional).toBe(true);
    expect(descriptorsFor("container").find((f) => f.key === "alignment")?.optional).toBe(true);
  });

  it("Text expõe data/style/textAlign", () => {
    const keys = descriptorsFor("text").map((f) => f.key);
    expect(keys).toEqual(expect.arrayContaining(["data", "style", "textAlign"]));
  });

  it("Button expõe onPressed como actionList", () => {
    const onPressed = descriptorsFor("button").find((f) => f.key === "onPressed")!;
    expect(onPressed.type).toBe("actionList");
  });

  it("width/height de container/sizedBox/image usam o FieldType dimension", () => {
    for (const t of ["container", "sizedBox", "image"]) {
      expect(descriptorsFor(t).find((f) => f.key === "width")?.type).toBe("dimension");
      expect(descriptorsFor(t).find((f) => f.key === "height")?.type).toBe("dimension");
    }
  });

  it("aspectRatio e opacity marcam o campo obrigatório", () => {
    expect(descriptorsFor("aspectRatio").find((f) => f.key === "aspectRatio")?.required).toBe(true);
    expect(descriptorsFor("opacity").find((f) => f.key === "opacity")?.required).toBe(true);
  });

  it("button expõe style (buttonStyle) e icon", () => {
    const button = descriptorsFor("button");
    expect(button.map((f) => f.key)).toEqual(expect.arrayContaining(["style", "icon"]));
    expect(button.find((f) => f.key === "style")?.type).toBe("buttonStyle");
  });

  it("descriptorsFor de tipo desconhecido retorna []", () => {
    expect(descriptorsFor("naoexiste")).toEqual([]);
  });
});
