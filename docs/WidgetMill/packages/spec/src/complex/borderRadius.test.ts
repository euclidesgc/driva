import { BorderRadius } from "./borderRadius";

describe("BorderRadius", () => {
  it("aceita número uniforme", () => {
    expect(BorderRadius.parse(8)).toBe(8);
  });

  it("aceita por canto", () => {
    expect(BorderRadius.parse({ topLeft: 8, topRight: 8 })).toEqual({
      topLeft: 8,
      topRight: 8,
    });
  });

  it("rejeita string", () => {
    expect(() => BorderRadius.parse("8")).toThrow();
  });
});
