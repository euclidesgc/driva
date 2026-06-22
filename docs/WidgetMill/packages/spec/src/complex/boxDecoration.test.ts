import { BoxDecoration } from "./boxDecoration";

describe("BoxDecoration", () => {
  it("aceita color + borderRadius uniforme", () => {
    expect(BoxDecoration.parse({ color: "#FF1565C0", borderRadius: 8 })).toEqual({
      color: "#FF1565C0",
      borderRadius: 8,
    });
  });

  it("aceita color via binding {{bg}}", () => {
    expect(() =>
      BoxDecoration.parse({ color: "{{bg}}", borderRadius: 8 }),
    ).not.toThrow();
  });

  it("aceita gradient linear", () => {
    const g = {
      gradient: {
        type: "linear",
        colors: ["#FFFFFF", "#000000"],
        begin: "topLeft",
        end: "bottomRight",
      },
    };
    expect(() => BoxDecoration.parse(g)).not.toThrow();
  });

  it("aceita boxShadow", () => {
    expect(() =>
      BoxDecoration.parse({
        boxShadow: [{ color: "#33000000", blurRadius: 4, offsetY: 2 }],
      }),
    ).not.toThrow();
  });

  it("rejeita shape inválido", () => {
    expect(() => BoxDecoration.parse({ shape: "triangle" })).toThrow();
  });
});
