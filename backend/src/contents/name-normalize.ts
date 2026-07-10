/**
 * Normaliza um nome para busca case- e acento-insensível: lowercase + sem
 * diacríticos, em Node (Decisão 6 do `prd.md` de docs/08 — sem extensão
 * Postgres, privilégio não garantido no Coolify). Alimenta
 * `Content.nameNormalized`, comparado via `ILIKE` no service.
 */
export function normalizeName(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();
}
