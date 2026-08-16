export const MEDIA_PROXY_MAX_REDIRECTS = 3;

export const MEDIA_PROXY_MAX_BYTES = 10 * 1024 * 1024;

export const MEDIA_PROXY_TIMEOUT_MS = 10_000;

// `image/svg+xml` fica fora por decisão explícita do plano (controle 6):
// SVG carrega `<script>` e o proxy não sanitiza antes de repassar.
export const MEDIA_PROXY_ALLOWED_CONTENT_TYPES = new Set([
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
  'image/avif',
]);

// Mesmo formato de `UPLOAD_THROTTLE` em `projects.controller.ts` — cada
// chamada do proxy dispara uma busca de saída, custo parecido com upload.
export const MEDIA_PROXY_THROTTLE = { default: { limit: 30, ttl: 60_000 } };

export const MEDIA_PROXY_CACHE_CONTROL = 'public, max-age=60, must-revalidate';
