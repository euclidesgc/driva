import { EdgeInsets } from "./edgeInsets";

describe("EdgeInsets", () => {
  it("aceita { all }", () => {
    expect(EdgeInsets.parse({ all: 16 })).toEqual({ all: 16 });
  });

  it("aceita symmetric { horizontal, vertical }", () => {
    expect(EdgeInsets.parse({ horizontal: 12, vertical: 8 })).toEqual({
      horizontal: 12,
      vertical: 8,
    });
  });

  it("preserva os lados em { left, top } (não descarta para symmetric)", () => {
    expect(EdgeInsets.parse({ left: 8, top: 4 })).toEqual({ left: 8, top: 4 });
  });

  it("rejeita valor não numérico", () => {
    expect(() => EdgeInsets.parse({ all: "x" })).toThrow();
  });

  it("rejeita chave desconhecida", () => {
    expect(() => EdgeInsets.parse({ foo: 1 })).toThrow();
  });
});
