import { BadRequestException } from '@nestjs/common';
import sharp from 'sharp';

/**
 * Pipeline de upload de imagem de `Project` — não-negociáveis do CISO
 * (`docs/09-crud-projeto/prd.md` › Segurança do upload). Quem chama `put` do
 * `StorageService` só recebe bytes já validados/reencodados; o nome/key é
 * gerado pelo próprio `StorageService.put` (UUID do servidor).
 *
 * Etapas, na ordem:
 *  1. Magic bytes (`detectImageType`, checagem própria — sem dependência
 *     externa; a allowlist é fechada em 3 formatos) — NUNCA confiar em
 *     `Content-Type`/extensão do multipart, que o cliente controla livremente.
 *  2. Allowlist fechada: png/jpg/webp. SVG e qualquer outro tipo, fora.
 *  3. Reencode com `sharp` — mata polyglot/webshell embutido no arquivo
 *     original (o arquivo gravado nunca é o buffer recebido), strip de EXIF,
 *     e redimensiona/limita a decodificação contra decompression bomb via
 *     `limitInputPixels` + teto de dimensão de saída.
 */

/** Teto do arquivo de upload (bytes) — replicado no limit do FileInterceptor. */
export const MAX_UPLOAD_BYTES = 8 * 1024 * 1024; // 8MB

/** Teto de dimensão decodificada (defesa contra decompression bomb). */
const MAX_INPUT_PIXELS = 50_000_000; // ~50MP (ex.: 8000x6250)

/** Teto de dimensão de saída pós-reencode (card de projeto não precisa mais). */
const MAX_OUTPUT_DIMENSION = 2048;

export type DetectedImageType = 'png' | 'jpeg' | 'webp';

const DETECTED_TYPE_TO_MIME: Record<DetectedImageType, string> = {
  png: 'image/png',
  jpeg: 'image/jpeg',
  webp: 'image/webp',
};

const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const JPEG_SIGNATURE = [0xff, 0xd8, 0xff];
const RIFF_SIGNATURE = [0x52, 0x49, 0x46, 0x46]; // "RIFF"
const WEBP_SIGNATURE = [0x57, 0x45, 0x42, 0x50]; // "WEBP"

function matchesSignature(
  buffer: Buffer,
  signature: number[],
  offset = 0,
): boolean {
  if (buffer.length < offset + signature.length) {
    return false;
  }
  return signature.every((byte, index) => buffer[offset + index] === byte);
}

/**
 * Detecta o tipo real da imagem pelos magic bytes (não pelo `Content-Type`
 * ou extensão informados pelo cliente). Allowlist fechada: png/jpeg/webp.
 * Qualquer outra assinatura (incluindo SVG, que é texto) — `null`.
 */
export function detectImageType(buffer: Buffer): DetectedImageType | null {
  if (matchesSignature(buffer, PNG_SIGNATURE)) {
    return 'png';
  }
  if (matchesSignature(buffer, JPEG_SIGNATURE)) {
    return 'jpeg';
  }
  if (
    matchesSignature(buffer, RIFF_SIGNATURE) &&
    matchesSignature(buffer, WEBP_SIGNATURE, 8)
  ) {
    return 'webp';
  }
  return null;
}

export interface ProcessedImage {
  buffer: Buffer;
  contentType: string;
}

/**
 * Valida (magic bytes + allowlist) e reencoda `input` para o mesmo formato
 * detectado. Lança `BadRequestException` (400) para qualquer violação —
 * nunca deixa passar o buffer original adiante.
 */
export async function processUploadedImage(
  input: Buffer,
): Promise<ProcessedImage> {
  const detected = detectImageType(input);
  if (!detected) {
    throw new BadRequestException(
      'imagem inválida: tipo não suportado (aceito apenas png, jpg, webp)',
    );
  }

  const pipeline = sharp(input, { limitInputPixels: MAX_INPUT_PIXELS })
    // rotate() sem args: aplica a orientação EXIF antes de descartá-la.
    .rotate()
    .resize({
      width: MAX_OUTPUT_DIMENSION,
      height: MAX_OUTPUT_DIMENSION,
      fit: 'inside',
      withoutEnlargement: true,
    });

  try {
    const { buffer, contentType } = await encodeByMime(
      pipeline,
      DETECTED_TYPE_TO_MIME[detected],
    );
    return { buffer, contentType };
  } catch {
    // sharp lança em decompression bomb (limitInputPixels), imagem corrompida
    // ou qualquer payload malformado disfarçado de png/jpg/webp válido.
    throw new BadRequestException(
      'imagem inválida: falha ao processar o arquivo',
    );
  }
}

async function encodeByMime(
  pipeline: ReturnType<typeof sharp>,
  mime: string,
): Promise<ProcessedImage> {
  switch (mime) {
    case 'image/png':
      return {
        buffer: await pipeline.png().toBuffer(),
        contentType: 'image/png',
      };
    case 'image/webp':
      return {
        buffer: await pipeline.webp().toBuffer(),
        contentType: 'image/webp',
      };
    default:
      return {
        buffer: await pipeline.jpeg().toBuffer(),
        contentType: 'image/jpeg',
      };
  }
}
