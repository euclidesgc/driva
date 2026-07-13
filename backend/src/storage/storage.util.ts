const CONTENT_TYPE_TO_EXTENSION: Record<string, string> = {
  'image/png': '.png',
  'image/jpeg': '.jpg',
  'image/webp': '.webp',
};

/**
 * Extensão de arquivo pro `contentType` já validado pelo pipeline de upload
 * (`image-pipeline.ts` — allowlist fechada png/jpeg/webp). Fallback vazio
 * para qualquer tipo fora dessa allowlist (não deveria acontecer, mas o
 * adapter não quebra por isso).
 */
export function extensionFor(contentType: string): string {
  return CONTENT_TYPE_TO_EXTENSION[contentType] ?? '';
}
