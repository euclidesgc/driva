import { BadRequestException } from '@nestjs/common';

/**
 * Cursor keyset opaco: base64 de `"<valorDoCampoOrdenado>|<id>"`. O backend
 * continua a listagem estritamente APÓS esse par, na mesma ordenação
 * `(sort, id)` — o `id` desempata valores repetidos do campo de sort
 * (Decisão 5 do `prd.md` de docs/08). Trocar `sort`/`order`/`q`/`categoryId`
 * invalida o cursor por construção: o cliente recomeça sem `cursor`.
 */
export type DecodedCursor = { value: string; id: string };

export function encodeCursor(value: string, id: string): string {
  return Buffer.from(`${value}|${id}`, 'utf8').toString('base64url');
}

export function decodeCursor(cursor: string): DecodedCursor {
  let raw: string;
  try {
    raw = Buffer.from(cursor, 'base64url').toString('utf8');
  } catch {
    throw new BadRequestException('cursor inválido');
  }
  const separatorIndex = raw.lastIndexOf('|');
  if (separatorIndex === -1) {
    throw new BadRequestException('cursor inválido');
  }
  const value = raw.slice(0, separatorIndex);
  const id = raw.slice(separatorIndex + 1);
  if (!value || !id) {
    throw new BadRequestException('cursor inválido');
  }
  return { value, id };
}
