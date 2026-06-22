"use client";

import {
  isDeleted,
  publishedVersion,
  type WidgetRecord,
  type WidgetVersion,
} from "@widgetmill/spec";

interface HistoryPanelProps {
  open: boolean;
  record: WidgetRecord | null;
  onClose: () => void;
  onLoad: (version: number) => void;
  onCompare: (version: number) => void;
  onDelete: (version: number) => void;
  onRestore: (version: number) => void;
}

function fromNow(iso: string): string {
  const rtf = new Intl.RelativeTimeFormat("pt-BR", { numeric: "auto" });
  const sec = Math.round((new Date(iso).getTime() - Date.now()) / 1000);
  if (Math.abs(sec) < 60) return rtf.format(sec, "second");
  const min = Math.round(sec / 60);
  if (Math.abs(min) < 60) return rtf.format(min, "minute");
  const hr = Math.round(min / 60);
  if (Math.abs(hr) < 24) return rtf.format(hr, "hour");
  return rtf.format(Math.round(hr / 24), "day");
}

/** Painel lateral de histórico (estilo Squidex): versões + Carregar/Comparar. */
export function HistoryPanel({
  open,
  record,
  onClose,
  onLoad,
  onCompare,
  onDelete,
  onRestore,
}: HistoryPanelProps) {
  if (!open) return null;
  const used = record ? publishedVersion(record) : null;
  const versions = record ? [...record.versions].reverse() : [];

  return (
    <div style={drawer}>
      <div style={header}>
        <strong style={{ fontSize: 14 }}>Histórico</strong>
        <button onClick={onClose} style={closeBtn} aria-label="Fechar">
          ×
        </button>
      </div>

      {versions.length === 0 ? (
        <p style={{ fontSize: 12, color: "#777", padding: 12 }}>Nenhuma versão salva ainda.</p>
      ) : (
        <ul style={{ listStyle: "none", margin: 0, padding: 0, overflowY: "auto" }}>
          {versions.map((v) => (
            <Row
              key={v.version}
              v={v}
              isUsed={used?.version === v.version}
              onLoad={() => onLoad(v.version)}
              onCompare={() => onCompare(v.version)}
              onDelete={() => onDelete(v.version)}
              onRestore={() => onRestore(v.version)}
            />
          ))}
        </ul>
      )}
    </div>
  );
}

function Row({
  v,
  isUsed,
  onLoad,
  onCompare,
  onDelete,
  onRestore,
}: {
  v: WidgetVersion;
  isUsed: boolean;
  onLoad: () => void;
  onCompare: () => void;
  onDelete: () => void;
  onRestore: () => void;
}) {
  if (isDeleted(v)) {
    return (
      <li style={{ ...row, opacity: 0.7 }}>
        <div style={{ ...avatar, background: "#9e9e9e" }}>🗑</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, textDecoration: "line-through", color: "#777" }}>
            {v.message} <span>v{v.version}</span>
          </div>
          <div style={{ fontSize: 11, color: "#b3261e" }}>
            excluída por {v.deletedBy} · {fromNow(v.deletedAt!)}
          </div>
          <div style={{ marginTop: 4 }}>
            <button onClick={onRestore} style={{ ...linkBtn, color: "#1b7f3b" }}>
              Restaurar
            </button>
          </div>
        </div>
      </li>
    );
  }
  return (
    <li style={row}>
      <div style={avatar}>{v.author.charAt(0).toUpperCase()}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13 }}>
          <strong>{v.message}</strong> <span style={{ color: "#888" }}>v{v.version}</span>
          {v.status === "published" && <span style={badgePub}>publicado</span>}
          {isUsed && <span style={badgeUsed}>usada</span>}
        </div>
        <div style={{ fontSize: 11, color: "#888" }}>
          {v.author} · {fromNow(v.createdAt)}
        </div>
        <div style={{ marginTop: 4 }}>
          <button onClick={onLoad} style={linkBtn}>
            Carregar
          </button>
          <span style={{ color: "#ccc", margin: "0 4px" }}>·</span>
          <button onClick={onCompare} style={linkBtn}>
            Comparar
          </button>
          <span style={{ color: "#ccc", margin: "0 4px" }}>·</span>
          <button onClick={onDelete} style={{ ...linkBtn, color: "#b3261e" }}>
            Excluir
          </button>
        </div>
      </div>
    </li>
  );
}

const drawer: React.CSSProperties = {
  position: "fixed",
  top: 0,
  right: 0,
  bottom: 0,
  width: 340,
  maxWidth: "90vw",
  background: "#fff",
  borderLeft: "1px solid #e0e0e0",
  boxShadow: "-8px 0 24px rgba(0,0,0,0.12)",
  zIndex: 1050,
  display: "flex",
  flexDirection: "column",
};
const header: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: 12,
  borderBottom: "1px solid #eee",
};
const closeBtn: React.CSSProperties = {
  border: "none",
  background: "transparent",
  fontSize: 22,
  lineHeight: 1,
  cursor: "pointer",
  color: "#666",
};
const row: React.CSSProperties = {
  display: "flex",
  gap: 10,
  padding: 12,
  borderBottom: "1px solid #f2f2f2",
};
const avatar: React.CSSProperties = {
  width: 28,
  height: 28,
  borderRadius: "50%",
  background: "#1565C0",
  color: "#fff",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  fontSize: 13,
  flexShrink: 0,
};
const badge: React.CSSProperties = {
  fontSize: 10,
  borderRadius: 10,
  padding: "1px 8px",
  marginLeft: 6,
};
const badgePub: React.CSSProperties = { ...badge, background: "#e8f5e9", color: "#1b7f3b" };
const badgeUsed: React.CSSProperties = { ...badge, background: "#e3f2fd", color: "#1565C0" };
const linkBtn: React.CSSProperties = {
  border: "none",
  background: "transparent",
  color: "#1565C0",
  fontSize: 12,
  cursor: "pointer",
  padding: 0,
};
