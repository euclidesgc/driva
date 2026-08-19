// 120/min: o dobro do editor (`ProjectsModule`) — um app cliente com várias
// telas soma mais requisições que um humano operando o editor. Formato igual
// a `UPLOAD_THROTTLE`/`MEDIA_PROXY_THROTTLE`: o que o `@Throttle()` espera.
export const PUBLIC_THROTTLE = { default: { limit: 120, ttl: 60_000 } };
