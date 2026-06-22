import { hasValue, isBlank, pruneBlank } from "./blank";

describe("isBlank", () => {
  it("trata null/undefined/string vazia/só-espaços como branco", () => {
    expect(isBlank(null)).toBe(true);
    expect(isBlank(undefined)).toBe(true);
    expect(isBlank("")).toBe(true);
    expect(isBlank("   ")).toBe(true);
  });

  it("não trata 0, false e string com conteúdo como branco", () => {
    expect(isBlank(0)).toBe(false);
    expect(isBlank(false)).toBe(false);
    expect(isBlank("x")).toBe(false);
  });
});

describe("pruneBlank", () => {
  it("remove brancos rasos e devolve undefined quando nada sobra", () => {
    expect(pruneBlank("")).toBeUndefined();
    expect(pruneBlank("  ")).toBeUndefined();
    expect(pruneBlank(null)).toBeUndefined();
    expect(pruneBlank(undefined)).toBeUndefined();
    expect(pruneBlank({})).toBeUndefined();
    expect(pruneBlank([])).toBeUndefined();
  });

  it("mantém 0 e false (valores legítimos, não ausência)", () => {
    expect(pruneBlank(0)).toBe(0);
    expect(pruneBlank(false)).toBe(false);
  });

  it("preserva strings não-brancas sem aplicar trim", () => {
    expect(pruneBlank("  oi  ")).toBe("  oi  ");
  });

  it("poda objetos em profundidade; chave só-branco some", () => {
    expect(pruneBlank({ color: "", borderRadius: 8 })).toEqual({ borderRadius: 8 });
    expect(pruneBlank({ color: "" })).toBeUndefined();
    expect(pruneBlank({ a: { b: "" } })).toBeUndefined();
    expect(pruneBlank({ a: { b: "", c: 0 } })).toEqual({ a: { c: 0 } });
  });

  it("poda arrays, removendo itens brancos", () => {
    expect(pruneBlank(["", "x", null])).toEqual(["x"]);
    expect(pruneBlank(["", null])).toBeUndefined();
  });

  it("não muta a entrada", () => {
    const input = { color: "", size: 1 };
    pruneBlank(input);
    expect(input).toEqual({ color: "", size: 1 });
  });
});

describe("hasValue", () => {
  it("é true quando sobra algo de verdade após podar", () => {
    expect(hasValue({ color: "#fff" })).toBe(true);
    expect(hasValue({ a: 0 })).toBe(true);
  });

  it("é false para branco/vazio em profundidade", () => {
    expect(hasValue({})).toBe(false);
    expect(hasValue({ color: "" })).toBe(false);
    expect(hasValue(null)).toBe(false);
    expect(hasValue("")).toBe(false);
  });
});
