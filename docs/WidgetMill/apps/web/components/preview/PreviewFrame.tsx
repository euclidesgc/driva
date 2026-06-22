"use client";

import { useCallback, useEffect, useRef } from "react";
import type { SpecNode } from "@widgetmill/spec";

interface PreviewFrameProps {
  spec: SpecNode | null;
  onAction?: (action: unknown) => void;
  title?: string;
}

/**
 * Embarca o preview Flutter (`/preview/index.html`) e conversa com ele via
 * postMessage. Cada instância só ouve mensagens do SEU iframe (`e.source`),
 * então pode haver vários lado a lado (ex.: comparação de versões).
 */
export function PreviewFrame({ spec, onAction, title = "preview" }: PreviewFrameProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const ready = useRef(false);
  const specRef = useRef<SpecNode | null>(spec);
  specRef.current = spec;
  // `onAction` muda de identidade a cada render do editor; guardá-lo num ref
  // mantém o listener estável (monta uma vez) sem perder a callback atual.
  const onActionRef = useRef(onAction);
  onActionRef.current = onAction;

  const send = useCallback((s: SpecNode | null) => {
    if (!s) return;
    iframeRef.current?.contentWindow?.postMessage(
      JSON.stringify({ type: "render", spec: s }),
      "*",
    );
  }, []);

  useEffect(() => {
    const onMessage = (e: MessageEvent) => {
      if (e.source !== iframeRef.current?.contentWindow) return;
      let data: { type?: string };
      try {
        data = JSON.parse(typeof e.data === "string" ? e.data : "");
      } catch {
        return;
      }
      // O preview re-anuncia `ready` até receber o 1º render; respondemos a
      // cada `ready` com o spec mais recente — handshake idempotente e imune a
      // corridas (editor ainda montando, iframe recarregando, etc.).
      if (data.type === "ready") {
        ready.current = true;
        send(specRef.current);
      } else if (data.type === "action") {
        onActionRef.current?.(data);
      }
    };
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [send]);

  // Reenvia quando o spec muda (após o handshake `ready`).
  useEffect(() => {
    if (ready.current) send(spec);
  }, [spec, send]);

  return (
    <iframe
      ref={iframeRef}
      src="/preview/index.html"
      title={title}
      style={{ width: "100%", height: "100%", border: "none" }}
    />
  );
}
