import type { SpecChange, SpecDiff as SpecDiffData } from "@widgetmill/spec";

const fmt = (v: unknown) => (v === undefined ? "∅" : JSON.stringify(v));

function describe(c: SpecChange): { text: string; color: string } {
  switch (c.kind) {
    case "added":
      return { text: `+ ${c.newType} em ${c.path}`, color: "#1b7f3b" };
    case "removed":
      return { text: `− ${c.oldType} em ${c.path}`, color: "#b3261e" };
    case "typeChanged":
      return { text: `${c.path}: ${c.oldType} → ${c.newType}`, color: "#1565C0" };
    case "propChanged":
      return {
        text: `${c.path} › ${c.key}: ${fmt(c.old)} → ${fmt(c.new)}`,
        color: "#1565C0",
      };
  }
}

/** Renderiza um diff estrutural de spec (lista colorida de mudanças). */
export function SpecDiff({ diff }: { diff: SpecDiffData }) {
  if (diff.changes.length === 0) {
    return <p style={{ fontSize: 12, color: "#777", margin: 0 }}>Sem diferenças.</p>;
  }
  return (
    <ul style={{ margin: 0, padding: 0, listStyle: "none", fontSize: 12, fontFamily: "monospace" }}>
      {diff.changes.map((c, i) => {
        const { text, color } = describe(c);
        return (
          <li key={i} style={{ color, padding: "2px 0", wordBreak: "break-word" }}>
            {text}
          </li>
        );
      })}
    </ul>
  );
}
