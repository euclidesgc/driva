"use client";

import { useEffect, useState } from "react";
import { slugify } from "@widgetmill/spec";

export interface IdentityValues {
  name: string;
  slug: string;
  description: string;
}

interface IdentityDialogProps {
  open: boolean;
  initial?: IdentityValues;
  onSubmit: (values: IdentityValues) => void;
  onCancel: () => void;
}

const EMPTY: IdentityValues = { name: "", slug: "", description: "" };

/** Diálogo de identidade do widget: Nome + slug editável (auto) + descrição. */
export function IdentityDialog({ open, initial, onSubmit, onCancel }: IdentityDialogProps) {
  const [values, setValues] = useState<IdentityValues>(initial ?? EMPTY);
  const [slugDirty, setSlugDirty] = useState(false);

  // Reinicializa ao (re)abrir.
  useEffect(() => {
    if (open) {
      setValues(initial ?? EMPTY);
      setSlugDirty(Boolean(initial?.slug));
    }
  }, [open, initial]);

  if (!open) return null;

  const setName = (name: string) =>
    setValues((v) => ({ ...v, name, slug: slugDirty ? v.slug : slugify(name) }));
  const setSlug = (slug: string) => {
    setSlugDirty(true);
    setValues((v) => ({ ...v, slug: slugify(slug) }));
  };

  const valid = values.name.trim() !== "" && values.slug.trim() !== "";

  return (
    <div style={overlay} onClick={onCancel}>
      <div style={dialog} onClick={(e) => e.stopPropagation()}>
        <h3 style={{ margin: "0 0 12px", fontSize: 16 }}>Identidade do widget</h3>

        <label style={label}>Nome</label>
        <input
          autoFocus
          value={values.name}
          onChange={(e) => setName(e.target.value)}
          placeholder="ex.: Botão Primário"
          style={input}
        />

        <label style={label}>Slug</label>
        <input
          value={values.slug}
          onChange={(e) => setSlug(e.target.value)}
          placeholder="ex.: botao_primario"
          style={{ ...input, fontFamily: "monospace" }}
        />

        <label style={label}>Descrição</label>
        <textarea
          value={values.description}
          onChange={(e) => setValues((v) => ({ ...v, description: e.target.value }))}
          placeholder="O que este widget faz…"
          rows={3}
          style={{ ...input, resize: "vertical" }}
        />

        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, marginTop: 16 }}>
          <button onClick={onCancel} style={btnGhost}>
            Cancelar
          </button>
          <button onClick={() => valid && onSubmit(values)} disabled={!valid} style={btnPrimary(valid)}>
            Confirmar
          </button>
        </div>
      </div>
    </div>
  );
}

const overlay: React.CSSProperties = {
  position: "fixed",
  inset: 0,
  background: "rgba(0,0,0,0.4)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  zIndex: 1100,
};
const dialog: React.CSSProperties = {
  background: "#fff",
  borderRadius: 10,
  padding: 20,
  width: 380,
  maxWidth: "90vw",
  boxShadow: "0 12px 32px rgba(0,0,0,0.25)",
};
const label: React.CSSProperties = {
  display: "block",
  fontSize: 12,
  color: "#555",
  margin: "10px 0 4px",
};
const input: React.CSSProperties = {
  width: "100%",
  padding: "8px 10px",
  border: "1px solid #ccc",
  borderRadius: 6,
  fontSize: 14,
  boxSizing: "border-box",
};
const btnGhost: React.CSSProperties = {
  padding: "8px 14px",
  border: "1px solid #ccc",
  background: "#fff",
  borderRadius: 6,
  cursor: "pointer",
};
const btnPrimary = (enabled: boolean): React.CSSProperties => ({
  padding: "8px 14px",
  border: "none",
  background: enabled ? "#1565C0" : "#9bbce0",
  color: "#fff",
  borderRadius: 6,
  cursor: enabled ? "pointer" : "not-allowed",
});
