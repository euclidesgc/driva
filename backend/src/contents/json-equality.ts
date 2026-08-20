/**
 * Igualdade semântica entre dois valores JSONB.
 *
 * O Postgres normaliza JSONB (ordem de chaves, espaços), mas o valor que o
 * Prisma devolve é JavaScript já desserializado: comparar por `JSON.stringify`
 * dependeria da ordem de inserção das chaves e diria que dois specs iguais
 * diferem. Publicar por causa disso criaria uma versão idêntica à que está no
 * ar, num histórico que é append-only e ninguém pode reescrever depois.
 *
 * Não interpreta o schema SDUI de propósito — o backend armazena o spec, não
 * o entende, e conhecer a forma dele aqui criaria um segundo lugar para manter
 * o contrato em dia.
 */
export function isSameJsonValue(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== typeof b) return false;

  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b)) return false;
    if (a.length !== b.length) return false;
    return a.every((item, index) => isSameJsonValue(item, b[index]));
  }

  if (typeof a === 'object' && typeof b === 'object') {
    const left = a as Record<string, unknown>;
    const right = b as Record<string, unknown>;
    const leftKeys = Object.keys(left);
    if (leftKeys.length !== Object.keys(right).length) return false;
    return leftKeys.every(
      (key) =>
        Object.prototype.hasOwnProperty.call(right, key) &&
        isSameJsonValue(left[key], right[key]),
    );
  }

  return false;
}
