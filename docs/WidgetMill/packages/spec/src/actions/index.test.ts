import { Action, Events } from "./index";

describe("Action", () => {
  it("aceita navigate com routeId e args", () => {
    expect(() =>
      Action.parse({
        type: "navigate",
        params: { routeId: "route_product", args: { id: "{{productId}}" } },
      }),
    ).not.toThrow();
  });

  it("aceita track só com event", () => {
    expect(() =>
      Action.parse({ type: "track", params: { event: "cta_click" } }),
    ).not.toThrow();
  });

  it("aceita goBack sem params", () => {
    expect(() => Action.parse({ type: "goBack" })).not.toThrow();
  });

  it("rejeita type de ação desconhecido", () => {
    expect(() => Action.parse({ type: "explode" })).toThrow();
  });

  it("rejeita navigate sem routeId", () => {
    expect(() => Action.parse({ type: "navigate", params: {} })).toThrow();
  });
});

describe("Events", () => {
  it("mapeia evento → lista ordenada de ações", () => {
    const e = {
      onTap: [
        { type: "navigate", params: { routeId: "r" } },
        { type: "track", params: { event: "x" } },
      ],
    };
    expect(() => Events.parse(e)).not.toThrow();
  });
});
