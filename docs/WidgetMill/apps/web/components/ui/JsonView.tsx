"use client";

import { Highlight, themes } from "prism-react-renderer";
import { useState, type ReactElement } from "react";

interface JsonViewProps {
  /** Texto JSON já formatado (ex.: `JSON.stringify(spec, null, 2)`). */
  json: string;
}

/**
 * Visualização **read-only** de JSON com syntax-highlight
 * (`prism-react-renderer`) e botão de copiar. Reutilizável — a futura visão de
 * comparação de JSON (`CompareView`) pode usar o mesmo componente. Estilos
 * inline (convenção do web).
 */
export function JsonView({ json }: JsonViewProps): ReactElement {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(json);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    } catch {
      // clipboard indisponível (ex.: contexto inseguro) — ignora
    }
  };

  return (
    <div
      style={{
        flex: 1,
        minHeight: 0,
        display: "flex",
        flexDirection: "column",
        border: "1px solid #eee",
        borderRadius: 8,
        overflow: "hidden",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "flex-end",
          padding: 6,
          borderBottom: "1px solid #eee",
          background: "#fafafa",
        }}
      >
        <button
          type="button"
          onClick={copy}
          style={{
            fontSize: 11,
            padding: "3px 10px",
            borderRadius: 6,
            border: "1px solid #cbd5e1",
            background: copied ? "#dcfce7" : "#fff",
            color: copied ? "#166534" : "#334155",
            cursor: "pointer",
          }}
        >
          {copied ? "Copiado!" : "Copiar"}
        </button>
      </div>
      <div style={{ flex: 1, minHeight: 0, overflow: "auto" }}>
        <Highlight code={json} language="json" theme={themes.github}>
          {({ style, tokens, getLineProps, getTokenProps }) => (
            <pre
              style={{
                ...style,
                margin: 0,
                padding: 12,
                fontSize: 12,
                lineHeight: 1.5,
                fontFamily:
                  "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",
                background: "transparent",
              }}
            >
              {tokens.map((line, i) => (
                <div key={i} {...getLineProps({ line })}>
                  {line.map((token, key) => (
                    <span key={key} {...getTokenProps({ token })} />
                  ))}
                </div>
              ))}
            </pre>
          )}
        </Highlight>
      </div>
    </div>
  );
}
