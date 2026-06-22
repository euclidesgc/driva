import { TextStyle } from "./textStyle";

describe("TextStyle", () => {
  it("aceita campos válidos", () => {
    const s = {
      fontSize: 16,
      fontWeight: "w600",
      color: "#FFFFFF",
      decoration: "lineThrough",
    };
    expect(TextStyle.parse(s)).toEqual(s);
  });

  it("aceita objeto vazio (tudo opcional)", () => {
    expect(TextStyle.parse({})).toEqual({});
  });

  it("rejeita fontWeight inválido", () => {
    expect(() => TextStyle.parse({ fontWeight: "bold" })).toThrow();
  });

  it("rejeita cor inválida", () => {
    expect(() => TextStyle.parse({ color: "white" })).toThrow();
  });
});
