"use client";

import type { ReactNode } from "react";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  danger?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

/** Diálogo de confirmação genérico (ações destrutivas usam `danger`). */
export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = "Confirmar",
  cancelLabel = "Cancelar",
  danger = false,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  if (!open) return null;
  return (
    <div style={overlay} onClick={onCancel}>
      <div style={dialog} onClick={(e) => e.stopPropagation()}>
        <h3 style={{ margin: "0 0 8px", fontSize: 16 }}>{title}</h3>
        <div style={{ fontSize: 13, color: "#444", lineHeight: 1.5 }}>{message}</div>
        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, marginTop: 16 }}>
          <button onClick={onCancel} style={btnGhost}>
            {cancelLabel}
          </button>
          <button onClick={onConfirm} style={btnConfirm(danger)}>
            {confirmLabel}
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
  zIndex: 1300,
};
const dialog: React.CSSProperties = {
  background: "#fff",
  borderRadius: 10,
  padding: 20,
  width: 400,
  maxWidth: "90vw",
  boxShadow: "0 12px 32px rgba(0,0,0,0.25)",
};
const btnGhost: React.CSSProperties = {
  padding: "8px 14px",
  border: "1px solid #ccc",
  background: "#fff",
  borderRadius: 6,
  cursor: "pointer",
};
const btnConfirm = (danger: boolean): React.CSSProperties => ({
  padding: "8px 14px",
  border: "none",
  background: danger ? "#b3261e" : "#1565C0",
  color: "#fff",
  borderRadius: 6,
  cursor: "pointer",
});
