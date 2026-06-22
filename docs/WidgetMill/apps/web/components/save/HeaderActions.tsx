"use client";

import { latestVersion, publishedVersion, type VersionStatus } from "@widgetmill/spec";
import { useWidgetSession } from "../../lib/widget-session";

interface HeaderActionsProps {
  onSave: (status: VersionStatus) => void;
  onOpenHistory: () => void;
  onEditMetadata: () => void;
  /** Há erros de montagem? Bloqueia "Salvar e Publicar". */
  canPublish: boolean;
}

/** Botões Salvar / Salvar e Publicar / Histórico + chip de status (header do Puck). */
export function HeaderActions({
  onSave,
  onOpenHistory,
  onEditMetadata,
  canPublish,
}: HeaderActionsProps) {
  const { record, identity, editingFrom } = useWidgetSession();
  const latest = record ? latestVersion(record) : null;
  const used = record ? publishedVersion(record) : null;

  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      {/* O NOME do componente já aparece centralizado no header (headerTitle do
          Puck). Aqui mostramos só o status/versão para não duplicar. */}
      <span style={chip}>
        {identity ? (
          <>
            <span style={{ color: "#888" }}>
              {latest ? `v${latest.version} · ${labelStatus(latest.status)}` : "não salvo"}
            </span>
            {used && <span style={badge}>usada: v{used.version}</span>}
            {editingFrom != null && (
              <span style={{ ...badge, background: "#fff3e0", color: "#e65100" }}>
                editando a partir de v{editingFrom}
              </span>
            )}
          </>
        ) : (
          <span style={{ color: "#888" }}>não salvo</span>
        )}
      </span>

      {identity && (
        <button onClick={onEditMetadata} style={btnGhost} title="Editar metadados">
          ✎
        </button>
      )}
      <button onClick={onOpenHistory} style={btnGhost} disabled={!latest}>
        Histórico
      </button>
      <button onClick={() => onSave("draft")} style={btnGhost}>
        Salvar
      </button>
      <button
        onClick={() => onSave("published")}
        disabled={!canPublish}
        title={canPublish ? undefined : "Corrija os erros de montagem para publicar"}
        style={canPublish ? btnPrimary : btnDisabled}
      >
        Salvar e Publicar
      </button>
    </div>
  );
}

const labelStatus = (s: VersionStatus) => (s === "published" ? "publicado" : "rascunho");

const chip: React.CSSProperties = {
  fontSize: 12,
  display: "inline-flex",
  alignItems: "center",
  gap: 6,
  marginRight: 4,
};
const badge: React.CSSProperties = {
  fontSize: 10,
  background: "#e3f2fd",
  color: "#1565C0",
  borderRadius: 10,
  padding: "1px 8px",
};
const btnGhost: React.CSSProperties = {
  padding: "6px 10px",
  border: "1px solid #ccc",
  background: "#fff",
  borderRadius: 6,
  fontSize: 13,
  cursor: "pointer",
};
const btnPrimary: React.CSSProperties = {
  padding: "6px 12px",
  border: "none",
  background: "#1565C0",
  color: "#fff",
  borderRadius: 6,
  fontSize: 13,
  cursor: "pointer",
};
const btnDisabled: React.CSSProperties = {
  ...btnPrimary,
  background: "#9bbce0",
  cursor: "not-allowed",
};
