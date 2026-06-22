"use client";

import { createContext, useContext } from "react";
import type { DiagnosticSeverity } from "@widgetmill/spec";

/** Mapa `nodeId → severidade` (erro tem precedência) p/ marcar o canvas. */
export const DiagnosticsContext = createContext<Map<string, DiagnosticSeverity>>(new Map());

export const useNodeDiagnostics = () => useContext(DiagnosticsContext);
