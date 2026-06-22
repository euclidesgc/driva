import { Node } from "../tree";

/** Parse via a união `Node` — garante também que o `type` está registrado. */
const parse = (v: unknown) => Node.parse(v) as { props: Record<string, unknown> };

describe("Container (enriquecido)", () => {
  it("aceita alignment + decoration", () => {
    expect(() =>
      parse({
        type: "container",
        props: {
          alignment: "center",
          decoration: { color: "#FF1565C0", borderRadius: 8 },
        },
      }),
    ).not.toThrow();
  });

  it("rejeita color e decoration juntos (regra do Flutter)", () => {
    expect(() =>
      parse({
        type: "container",
        props: { color: "#FFFFFF", decoration: { color: "#000000" } },
      }),
    ).toThrow();
  });
});

describe("Row", () => {
  it("mainAxisSize opcional: ausente quando não informado (Flutter aplica o default)", () => {
    expect(parse({ type: "row" }).props.mainAxisSize).toBeUndefined();
  });
});

describe("Stack / Positioned", () => {
  it("alignment/clipBehavior opcionais: ausentes quando não informados", () => {
    const p = parse({ type: "stack" }).props;
    expect(p.alignment).toBeUndefined();
    expect(p.clipBehavior).toBeUndefined();
  });

  it("rejeita fit inválido", () => {
    expect(() => parse({ type: "stack", props: { fit: "nope" } })).toThrow();
  });

  it("Positioned aceita left/top", () => {
    expect(() =>
      parse({ type: "positioned", props: { left: 4, top: 8 } }),
    ).not.toThrow();
  });
});

describe("Image", () => {
  it("source/fit opcionais: ausentes quando não informados", () => {
    const p = parse({ type: "image", props: { src: "https://x/y.png" } }).props;
    expect(p.source).toBeUndefined();
    expect(p.fit).toBeUndefined();
  });

  it("rejeita fit inválido", () => {
    expect(() => parse({ type: "image", props: { fit: "nope" } })).toThrow();
  });
});

describe("Icon", () => {
  it("size opcional: ausente quando não informado (Flutter aplica 24)", () => {
    expect(parse({ type: "icon", props: { icon: "home" } }).props.size).toBeUndefined();
  });
});

describe("Button", () => {
  it("variant/enabled opcionais: ausentes quando não informados (Flutter aplica o default)", () => {
    const p = parse({ type: "button", props: { label: "OK" } }).props;
    expect(p.variant).toBeUndefined();
    expect(p.enabled).toBeUndefined();
  });

  it("rejeita variant inválido", () => {
    expect(() => parse({ type: "button", props: { variant: "ghost" } })).toThrow();
  });
});

describe("SizedBox / Padding / Center", () => {
  it("SizedBox aceita width/height", () => {
    expect(() =>
      parse({ type: "sizedBox", props: { width: 10, height: 20 } }),
    ).not.toThrow();
  });

  it("Padding exige padding", () => {
    expect(() => parse({ type: "padding" })).toThrow();
    expect(() =>
      parse({ type: "padding", props: { padding: { all: 8 } } }),
    ).not.toThrow();
  });

  it("Center aceita widthFactor", () => {
    expect(() =>
      parse({ type: "center", props: { widthFactor: 1.5 } }),
    ).not.toThrow();
  });
});

describe("GestureDetector / eventos", () => {
  it("aceita onTap com lista de ações + child", () => {
    expect(() =>
      parse({
        type: "gestureDetector",
        events: { onTap: [{ type: "navigate", params: { routeId: "r" } }] },
        child: { type: "text", props: { data: "x" } },
      }),
    ).not.toThrow();
  });

  it("Button aceita onPressed (actionList)", () => {
    expect(() =>
      parse({
        type: "button",
        props: {
          label: "OK",
          onPressed: [{ type: "track", params: { event: "e" } }],
        },
      }),
    ).not.toThrow();
  });

  it("Button valida o onPressed (rejeita ação inválida)", () => {
    expect(() =>
      parse({
        type: "button",
        props: { label: "OK", onPressed: [{ type: "explode" }] },
      }),
    ).toThrow();
  });

  it("rejeita ação inválida em onTap", () => {
    expect(() =>
      parse({
        type: "gestureDetector",
        events: { onTap: [{ type: "explode" }] },
      }),
    ).toThrow();
  });
});

describe("Expanded / Flexible / Spacer", () => {
  it("Expanded flex opcional: ausente quando não informado (Flutter aplica 1)", () => {
    expect(parse({ type: "expanded" }).props.flex).toBeUndefined();
  });

  it("Flexible fit opcional: ausente quando não informado", () => {
    expect(parse({ type: "flexible" }).props.fit).toBeUndefined();
  });

  it("Spacer flex opcional: ausente quando não informado (Flutter aplica 1)", () => {
    expect(parse({ type: "spacer" }).props.flex).toBeUndefined();
  });
});
