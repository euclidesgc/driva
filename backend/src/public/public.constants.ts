// 120/min: o dobro do editor (`ProjectsModule`) — um app cliente com várias
// telas soma mais requisições que um humano operando o editor.
export const PUBLIC_THROTTLE = { ttl: 60_000, limit: 120 };
