import { BoxConstraints } from "./constraints";

describe("BoxConstraints", () => {
  it("aceita min/max", () => {
    expect(BoxConstraints.parse({ minWidth: 0, maxWidth: 200 })).toEqual({
      minWidth: 0,
      maxWidth: 200,
    });
  });

  it("aceita objeto vazio", () => {
    expect(BoxConstraints.parse({})).toEqual({});
  });

  it("rejeita valor não numérico", () => {
    expect(() => BoxConstraints.parse({ minWidth: "x" })).toThrow();
  });
});
