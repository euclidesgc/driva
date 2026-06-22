import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { Node } from "../src/tree";

const NODES_DIR = join(process.cwd(), "fixtures", "nodes");

describe("fixtures golden (árvores de Node)", () => {
  const files = readdirSync(NODES_DIR).filter((f) => f.endsWith(".json"));

  it("há fixtures para validar", () => {
    expect(files.length).toBeGreaterThan(0);
  });

  it.each(files)("%s é um Node válido", (file) => {
    const json = JSON.parse(readFileSync(join(NODES_DIR, file), "utf8"));
    expect(() => Node.parse(json)).not.toThrow();
  });

  it("rejeita um node inválido com erro legível", () => {
    const result = Node.safeParse({
      type: "text",
      props: { overflow: "banana" },
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.length).toBeGreaterThan(0);
    }
  });
});
