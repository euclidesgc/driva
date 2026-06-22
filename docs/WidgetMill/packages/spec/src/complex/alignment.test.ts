import { Alignment, AlignmentDirectional } from "./alignment";

describe("Alignment", () => {
  it("aceita center e bottomRight", () => {
    expect(Alignment.parse("center")).toBe("center");
    expect(Alignment.parse("bottomRight")).toBe("bottomRight");
  });

  it("rejeita variante direcional", () => {
    expect(() => Alignment.parse("bottomEnd")).toThrow();
  });
});

describe("AlignmentDirectional", () => {
  it("aceita bottomEnd", () => {
    expect(AlignmentDirectional.parse("bottomEnd")).toBe("bottomEnd");
  });

  it("rejeita bottomRight", () => {
    expect(() => AlignmentDirectional.parse("bottomRight")).toThrow();
  });
});
