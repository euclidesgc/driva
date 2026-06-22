import {
  createRecord,
  deleteVersion,
  getVersion,
  isDeleted,
  latestVersion,
  publishedVersion,
  restoreVersion,
  saveVersion,
} from "./record";
import type { WidgetIdentity } from "./types";

const identity: WidgetIdentity = {
  slug: "card",
  name: "Card",
  description: "",
  kind: "composite",
};
const tree = { type: "text", props: { data: "oi" } };
const t = (n: number) => `2026-06-15T00:0${n}:00.000Z`;
const seed = () => createRecord(identity);

describe("widget record (event-sourced)", () => {
  it("createRecord começa sem versões", () => {
    expect(seed().versions).toEqual([]);
  });

  it("saveVersion incrementa o número e carimba a version no spec", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(1) });
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(2) });
    r = saveVersion(r, { tree, status: "published", author: "a", now: t(3) });
    expect(r.versions.map((v) => v.version)).toEqual([1, 2, 3]);
    expect(r.versions[0]!.spec.version).toBe(1);
    expect(latestVersion(r)?.version).toBe(3);
  });

  it("nunca remove/mutila versões anteriores (imutável)", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "published", author: "a", now: t(1) });
    const v1 = r.versions[0];
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(2) });
    expect(r.versions[0]).toBe(v1);
    expect(r.versions).toHaveLength(2);
  });

  it("publishedVersion = última com status published", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "published", author: "a", now: t(1) });
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(2) });
    expect(publishedVersion(r)?.version).toBe(1);
    r = saveVersion(r, { tree, status: "published", author: "a", now: t(3) });
    expect(publishedVersion(r)?.version).toBe(3);
  });

  it("mensagem default por status; custom respeitada", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(1) });
    r = saveVersion(r, {
      tree,
      status: "published",
      author: "a",
      now: t(2),
      message: "Restaurado de v1",
    });
    expect(r.versions[0]!.message).toBe("Rascunho salvo");
    expect(r.versions[1]!.message).toBe("Restaurado de v1");
  });

  it("getVersion retorna o snapshot certo (ou null)", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(1) });
    expect(getVersion(r, 1)?.version).toBe(1);
    expect(getVersion(r, 99)).toBeNull();
  });
});

describe("exclusão de versão (soft-delete, registrada)", () => {
  it("marca como excluída (autor/quando) mantendo na lista", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(1) });
    r = deleteVersion(r, 1, { author: "b", now: t(2) });
    expect(r.versions).toHaveLength(1);
    const v1 = r.versions[0]!;
    expect(isDeleted(v1)).toBe(true);
    expect(v1.deletedBy).toBe("b");
    expect(v1.deletedAt).toBe(t(2));
  });

  it("numeração é monotônica: não reusa número de versão excluída", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(1) }); // v1
    r = deleteVersion(r, 1, { author: "a", now: t(2) });
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(3) }); // v2
    expect(r.versions.map((v) => v.version)).toEqual([1, 2]);
  });

  it("latestVersion ignora excluídas", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(1) });
    r = saveVersion(r, { tree, status: "draft", author: "a", now: t(2) });
    r = deleteVersion(r, 2, { author: "a", now: t(3) });
    expect(latestVersion(r)?.version).toBe(1);
  });

  it("publishedVersion ignora excluídas", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "published", author: "a", now: t(1) });
    r = deleteVersion(r, 1, { author: "a", now: t(2) });
    expect(publishedVersion(r)).toBeNull();
  });

  it("excluir versão inexistente lança", () => {
    const r = seed();
    expect(() => deleteVersion(r, 99, { author: "a", now: t(1) })).toThrow();
  });

  it("restoreVersion desfaz o soft-delete e a versão volta a contar", () => {
    let r = seed();
    r = saveVersion(r, { tree, status: "published", author: "a", now: t(1) });
    r = deleteVersion(r, 1, { author: "a", now: t(2) });
    expect(isDeleted(r.versions[0]!)).toBe(true);
    expect(publishedVersion(r)).toBeNull();
    r = restoreVersion(r, 1);
    expect(isDeleted(r.versions[0]!)).toBe(false);
    expect(publishedVersion(r)?.version).toBe(1);
  });

  it("restaurar versão inexistente lança", () => {
    expect(() => restoreVersion(seed(), 99)).toThrow();
  });
});
