/**
 * Port de armazenamento de objetos binários (hoje: imagem de `Project`).
 *
 * O Postgres nunca guarda o binário — só a `key` devolvida por `put`
 * (ex.: `Project.imageKey`). A key é opaca para quem chama: nome/local físico
 * é decisão do adapter (local em dev, S3-compatível quando a Decisão 4 do
 * `prd.md` — Garage vs R2 — for resolvida).
 *
 * Contrato mínimo por enquanto (list/paginação não são necessários aqui).
 * O pipeline de segurança do upload (magic bytes, allowlist, reencode com
 * sharp, nome por UUID do servidor) é responsabilidade de quem CHAMA `put`
 * (o `ProjectsService`/pipeline da F2) — este port só move bytes.
 */
export abstract class StorageService {
  /** Grava `buffer` sob uma key nova e a devolve. Não recebe filename do cliente. */
  abstract put(buffer: Buffer, contentType: string): Promise<string>;

  /** Lê o objeto gravado sob `key`. `null` quando a key não existe. */
  abstract get(
    key: string,
  ): Promise<{ buffer: Buffer; contentType: string } | null>;

  /** Remove o objeto gravado sob `key`. No-op silencioso se já não existir. */
  abstract delete(key: string): Promise<void>;
}
