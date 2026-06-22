"use client";

import { useState } from "react";
import type { Diagnostic } from "@widgetmill/spec";

const plural = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

/** Rodapé do editor: resumo de erros/avisos de montagem + lista expansível. */
export function StatusBar({ diagnostics }: { diagnostics: Diagnostic[] }) {
  const [open, setOpen] = useState(false);
  const errors = diagnostics.filter((d) => d.severity === "error").length;
  const warnings = diagnostics.length - errors;
  const clean = diagnostics.length === 0;

  const summary = clean
    ? "✓ Sem problemas de montagem"
    : [errors ? `✕ ${plural(errors, "erro", "erros")}` : null, warnings ? `⚠ ${plural(warnings, "aviso", "avisos")}` : null]
        .filter(Boolean)
        .join(" · ");

  return (
    <div style={{ borderTop: "1px solid #e0e0e0", background: "#fafafa", fontSize: 12 }}>
      <button
        onClick={() => setOpen((o) => !o)}
        disabled={clean}
        style={{
          width: "100%",
          textAlign: "left",
          border: "none",
          background: "transparent",
          padding: "6px 12px",
          cursor: clean ? "default" : "pointer",
          color: clean ? "#1b7f3b" : errors ? "#b3261e" : "#a06b00",
          fontWeight: 600,
        }}
      >
        {summary}
        {!clean && <span style={{ color: "#888" }}>{open ? "  ▾" : "  ▸"}</span>}
      </button>
      {open && !clean && (
        <ul style={{ margin: 0, padding: "0 12px 8px 28px", maxHeight: 140, overflowY: "auto" }}>
          {diagnostics.map((d, i) => (
            <li key={i} style={{ color: d.severity === "error" ? "#b3261e" : "#a06b00", padding: "2px 0" }}>
              {d.severity === "error" ? "✕" : "⚠"} {d.message}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
