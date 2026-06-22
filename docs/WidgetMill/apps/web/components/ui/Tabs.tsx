"use client";

import type { ReactElement } from "react";

interface TabOption<T extends string> {
  value: T;
  label: string;
}

interface TabsProps<T extends string> {
  value: T;
  options: ReadonlyArray<TabOption<T>>;
  onChange: (value: T) => void;
}

/**
 * Controle de abas segmentado, reutilizável. Visual alinhado ao app (mesma
 * família do segmentado `ModeTabs` do Inspector, porém mais caprichado): pílula
 * com fundo suave e aba ativa "elevada". Estilos inline (convenção do web).
 */
export function Tabs<T extends string>({
  value,
  options,
  onChange,
}: TabsProps<T>): ReactElement {
  return (
    <div
      role="tablist"
      style={{
        display: "flex",
        gap: 4,
        padding: 4,
        borderRadius: 10,
        background: "#f1f5f9",
        border: "1px solid #e2e8f0",
      }}
    >
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            role="tab"
            aria-selected={active}
            onClick={() => onChange(o.value)}
            style={{
              flex: 1,
              padding: "6px 10px",
              fontSize: 13,
              cursor: "pointer",
              borderRadius: 7,
              border: "none",
              background: active ? "#ffffff" : "transparent",
              color: active ? "#0f172a" : "#64748b",
              fontWeight: active ? 600 : 500,
              boxShadow: active ? "0 1px 2px rgba(0,0,0,0.12)" : "none",
              transition: "background 120ms, color 120ms",
            }}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
