"use client";

import { useState } from "react";
import { diffTree, type SpecNode } from "@widgetmill/spec";
import { PreviewFrame } from "../preview/PreviewFrame";
import { SpecDiff } from "./SpecDiff";

const json = (s: SpecNode | null) => (s ? JSON.stringify(s, null, 2) : "—");

interface CompareViewProps {
  open: boolean;
  versionLabel: string;
  oldSpec: SpecNode | null;
  currentSpec: SpecNode | null;
  onClose: () => void;
}

/** Comparação estilo Squidex: previews lado a lado + diff estrutural do spec. */
export function CompareView({
  open,
  versionLabel,
  oldSpec,
  currentSpec,
  onClose,
}: CompareViewProps) {
  const [mode, setMode] = useState<"diff" | "json">("diff");
  if (!open) return null;
  const diff = diffTree(oldSpec, currentSpec);

  return (
    <div style={overlay} onClick={onClose}>
      <div style={modal} onClick={(e) => e.stopPropagation()}>
        <div style={head}>
          <strong style={{ fontSize: 15 }}>Comparar {versionLabel} ↔ atual</strong>
          <button onClick={onClose} style={closeBtn} aria-label="Fechar">
            ×
          </button>
        </div>

        <div style={{ display: "flex", gap: 12, flex: 1, minHeight: 0 }}>
          <Column label={`${versionLabel} — somente leitura`} spec={oldSpec} />
          <Column label="Cópia de trabalho atual" spec={currentSpec} />
        </div>

        <div style={diffBox}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
            <span style={{ fontSize: 12, fontWeight: 600 }}>
              {mode === "diff" ? `Mudanças (${versionLabel} → atual)` : "JSON das versões"}
            </span>
            <div style={{ marginLeft: "auto", display: "flex", gap: 4 }}>
              <Tab active={mode === "diff"} onClick={() => setMode("diff")}>
                Diff
              </Tab>
              <Tab active={mode === "json"} onClick={() => setMode("json")}>
                JSON
              </Tab>
            </div>
          </div>
          {mode === "diff" ? (
            <SpecDiff diff={diff} />
          ) : (
            <div style={{ display: "flex", gap: 12 }}>
              <pre style={jsonPre}>{json(oldSpec)}</pre>
              <pre style={jsonPre}>{json(currentSpec)}</pre>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Tab({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      style={{
        fontSize: 11,
        padding: "2px 10px",
        borderRadius: 6,
        border: "1px solid " + (active ? "#1565C0" : "#ccc"),
        background: active ? "#1565C0" : "#fff",
        color: active ? "#fff" : "#444",
        cursor: "pointer",
      }}
    >
      {children}
    </button>
  );
}

function Column({ label, spec }: { label: string; spec: SpecNode | null }) {
  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0 }}>
      <div style={{ fontSize: 12, color: "#555", marginBottom: 4 }}>{label}</div>
      <div style={frame}>
        <PreviewFrame spec={spec} title={label} />
      </div>
    </div>
  );
}

const overlay: React.CSSProperties = {
  position: "fixed",
  inset: 0,
  background: "rgba(0,0,0,0.45)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  zIndex: 1200,
};
const modal: React.CSSProperties = {
  background: "#fff",
  borderRadius: 10,
  padding: 16,
  width: "min(900px, 92vw)",
  height: "min(640px, 90vh)",
  display: "flex",
  flexDirection: "column",
  gap: 12,
  boxShadow: "0 16px 40px rgba(0,0,0,0.3)",
};
const head: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
};
const closeBtn: React.CSSProperties = {
  border: "none",
  background: "transparent",
  fontSize: 24,
  lineHeight: 1,
  cursor: "pointer",
  color: "#666",
};
const frame: React.CSSProperties = {
  flex: 1,
  border: "1px solid #eee",
  borderRadius: 8,
  overflow: "hidden",
  minHeight: 0,
};
const diffBox: React.CSSProperties = {
  borderTop: "1px solid #eee",
  paddingTop: 10,
  maxHeight: 180,
  overflowY: "auto",
};
const jsonPre: React.CSSProperties = {
  flex: 1,
  minWidth: 0,
  margin: 0,
  fontSize: 11,
  lineHeight: 1.4,
  background: "#f7f7f7",
  border: "1px solid #eee",
  borderRadius: 6,
  padding: 8,
  overflowX: "auto",
  whiteSpace: "pre",
};
