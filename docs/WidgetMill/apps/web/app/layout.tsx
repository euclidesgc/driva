import type { ReactNode } from "react";

export const metadata = {
  title: "WidgetMill — Editor",
  description: "Construtor visual de widgets",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="pt-BR">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
