"use client";

import { useEffect } from "react";

interface ToastProps {
  message: string | null;
  onDismiss: () => void;
  /** Auto-dismiss em ms (default 2500). */
  duration?: number;
}

/** Feedback efêmero no canto inferior. */
export function Toast({ message, onDismiss, duration = 2500 }: ToastProps) {
  useEffect(() => {
    if (!message) return;
    const id = setTimeout(onDismiss, duration);
    return () => clearTimeout(id);
  }, [message, duration, onDismiss]);

  if (!message) return null;
  return (
    <div
      role="status"
      style={{
        position: "fixed",
        bottom: 16,
        left: "50%",
        transform: "translateX(-50%)",
        background: "#323232",
        color: "#fff",
        padding: "8px 16px",
        borderRadius: 6,
        fontSize: 13,
        boxShadow: "0 4px 12px rgba(0,0,0,0.25)",
        zIndex: 1000,
      }}
    >
      {message}
    </div>
  );
}
