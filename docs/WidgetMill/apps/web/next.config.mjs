import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  // O kernel é distribuído como TS-source; o Next precisa transpilá-lo.
  transpilePackages: ["@widgetmill/spec"],
  // Monorepo: fixa a raiz de rastreamento (evita o aviso de múltiplos lockfiles).
  outputFileTracingRoot: path.join(__dirname, "../../"),
};

export default nextConfig;
