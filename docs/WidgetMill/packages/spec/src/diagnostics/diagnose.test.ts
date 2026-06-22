import { diagnose } from "./diagnose";
import type { PuckComponent } from "../puck/types";

let seq = 0;
const c = (type: string, props: Record<string, unknown> = {}): PuckComponent => ({
  type,
  props: { id: `c-${seq++}`, ...props },
});
const codes = (content: PuckComponent[]) => diagnose(content).map((d) => d.code);

describe("diagnose", () => {
  it("árvore válida não gera diagnósticos", () => {
    const tree = c("column", {
      children: [c("text", { data: "oi" }), c("text", { data: "tchau" })],
    });
    expect(diagnose([tree])).toEqual([]);
  });

  it("múltiplas raízes → erro em cada raiz", () => {
    const d = diagnose([c("container", { child: [c("text", { data: "x" })] }), c("text", { data: "y" })]);
    const roots = d.filter((x) => x.code === "multiple-roots");
    expect(roots).toHaveLength(2);
    expect(roots[0]!.severity).toBe("error");
  });

  it("Expanded/Flexible/Spacer fora de Row/Column → erro", () => {
    const inContainer = c("container", { child: [c("expanded", { child: [c("text", { data: "x" })] })] });
    expect(codes([inContainer])).toContain("flex-child-outside-flex");
  });

  it("Expanded dentro de Column é válido", () => {
    const ok = c("column", { children: [c("expanded", { child: [c("text", { data: "x" })] })] });
    expect(codes([ok])).not.toContain("flex-child-outside-flex");
  });

  it("Positioned fora de Stack → erro", () => {
    const bad = c("column", { children: [c("positioned", { child: [c("text", { data: "x" })] })] });
    expect(codes([bad])).toContain("positioned-outside-stack");
  });

  it("slot de filho único com vários filhos → erro", () => {
    const bad = c("center", { child: [c("text", { data: "a" }), c("text", { data: "b" })] });
    expect(codes([bad])).toContain("single-child-overflow");
  });

  it("Container com color E decoration → erro", () => {
    const bad = c("container", {
      color: "#fff",
      decoration: { color: "#000" },
      child: [c("text", { data: "x" })],
    });
    expect(codes([bad])).toContain("color-and-decoration");
  });

  it("color limpo (\"\") + decoration → sem erro (campo vazio do Puck = ausente)", () => {
    // Regressão: o Puck deixa "" ao limpar o campo; "" != null mantinha o erro.
    const cleared = c("container", {
      color: "",
      decoration: { color: "#000" },
      child: [c("text", { data: "x" })],
    });
    expect(codes([cleared])).not.toContain("color-and-decoration");
  });

  it("color válido sem decoration → sem erro", () => {
    const ok = c("container", { color: "#fff", child: [c("text", { data: "x" })] });
    expect(codes([ok])).not.toContain("color-and-decoration");
  });

  it("color válido + decoration vazia ({}) → sem erro", () => {
    const ok = c("container", {
      color: "#fff",
      decoration: {},
      child: [c("text", { data: "x" })],
    });
    expect(codes([ok])).not.toContain("color-and-decoration");
  });

  it("layout vazio → aviso", () => {
    const d = diagnose([c("column", { children: [] })]);
    expect(d.some((x) => x.code === "empty-layout" && x.severity === "warning")).toBe(true);
  });

  it("Text vazio → aviso", () => {
    const d = diagnose([c("column", { children: [c("text", { data: "" })] })]);
    expect(d.some((x) => x.code === "empty-text" && x.severity === "warning")).toBe(true);
  });

  it("cada diagnóstico aponta o id do nó culpado", () => {
    const bad = c("positioned", { child: [c("text", { data: "x" })] });
    const d = diagnose([bad]);
    const pos = d.find((x) => x.code === "positioned-outside-stack");
    expect(pos?.nodeId).toBe(bad.props.id);
  });
});
