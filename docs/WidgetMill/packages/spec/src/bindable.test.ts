import { z } from "zod";
import { Bindable } from "./bindable";
import { Color } from "./scalars";

describe("Bindable", () => {
  const schema = Bindable(z.number());

  it("aceita o valor tipado", () => {
    expect(schema.parse(12)).toBe(12);
  });

  it("aceita binding {{chave}}", () => {
    expect(schema.parse("{{preco}}")).toBe("{{preco}}");
  });

  it("aceita binding com pontos e espaços", () => {
    expect(schema.parse("{{ user.name }}")).toBe("{{ user.name }}");
  });

  it("aceita token $nome", () => {
    expect(schema.parse("$sm")).toBe("$sm");
  });

  it("rejeita string arbitrária", () => {
    expect(() => schema.parse("abc")).toThrow();
  });
});

describe("Color", () => {
  it("aceita #RRGGBB", () => {
    expect(Color.parse("#1565C0")).toBe("#1565C0");
  });

  it("aceita #AARRGGBB", () => {
    expect(Color.parse("#FF1565C0")).toBe("#FF1565C0");
  });

  it("rejeita nome de cor", () => {
    expect(() => Color.parse("red")).toThrow();
  });

  it("rejeita hex de 3 dígitos", () => {
    expect(() => Color.parse("#FFF")).toThrow();
  });
});
