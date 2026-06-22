import { BindableDimension, Dimension } from "./dimension";

describe("Dimension", () => {
  it("aceita número fixo (px)", () => {
    expect(Dimension.safeParse(200).success).toBe(true);
    expect(Dimension.safeParse(0).success).toBe(true);
  });

  it("aceita o token infinity", () => {
    expect(Dimension.safeParse({ unit: "infinity" }).success).toBe(true);
  });

  it("aceita % de tela com factor (largura/altura)", () => {
    expect(Dimension.safeParse({ unit: "screenWidth", factor: 0.5 }).success).toBe(true);
    expect(Dimension.safeParse({ unit: "screenHeight", factor: 1 }).success).toBe(true);
  });

  it("rejeita unit desconhecido", () => {
    expect(Dimension.safeParse({ unit: "parentWidth", factor: 0.5 }).success).toBe(false);
  });

  it("rejeita screen* sem factor", () => {
    expect(Dimension.safeParse({ unit: "screenWidth" }).success).toBe(false);
  });

  it("rejeita chaves extras (strict)", () => {
    expect(Dimension.safeParse({ unit: "infinity", extra: 1 }).success).toBe(false);
  });

  it("BindableDimension aceita número, binding e token", () => {
    expect(BindableDimension.safeParse(120).success).toBe(true);
    expect(BindableDimension.safeParse({ unit: "infinity" }).success).toBe(true);
    expect(BindableDimension.safeParse("{{w}}").success).toBe(true);
    expect(BindableDimension.safeParse("$size").success).toBe(true);
  });
});
