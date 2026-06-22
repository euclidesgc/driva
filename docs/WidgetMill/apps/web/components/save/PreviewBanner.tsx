/** Aviso discreto de que a persistência é em memória (placeholder do M3). */
export function PreviewBanner() {
  return (
    <div
      style={{
        fontSize: 11,
        color: "#8a6d00",
        background: "#fff8e1",
        border: "1px solid #ffe082",
        borderRadius: 6,
        padding: "4px 8px",
      }}
    >
      Armazenamento em memória (sessão) — some ao recarregar a página. Integração
      com a API vem no M3.
    </div>
  );
}
