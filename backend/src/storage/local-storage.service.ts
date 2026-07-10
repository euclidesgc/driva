import { randomUUID } from 'node:crypto';
import { dirname, join, normalize } from 'node:path';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { Injectable, Logger } from '@nestjs/common';
import { StorageService } from './storage.service';
import { extensionFor } from './storage.util';

/**
 * Adapter local (default de dev, reversível) do port `StorageService`.
 *
 * Grava em `STORAGE_LOCAL_DIR` (default `.storage/`, relativa ao cwd do
 * processo Nest) — FORA de qualquer webroot/pasta servida estaticamente, para
 * que um binário malicioso salvo aqui nunca seja executável/servível direto
 * pelo servidor HTTP. O único jeito de ler o conteúdo é via `get(key)`,
 * chamado pelo endpoint de serving (que fixa content-type + `nosniff` — F2).
 *
 * A key é `<prefix>/<uuid>.<ext>` — o nome do arquivo é sempre um UUID gerado
 * aqui (nunca o filename do cliente — path traversal/overwrite); `prefix`
 * (ex.: `<projectId>/midias`) organiza em subpastas dentro de `baseDir`,
 * criadas sob demanda. O content-type é persistido num arquivo `<key>.meta`
 * ao lado do binário, pois o filesystem não carrega essa informação sozinho.
 */
@Injectable()
export class LocalStorageService implements StorageService {
  private readonly logger = new Logger(LocalStorageService.name);
  private readonly baseDir: string;
  private readonly ready: Promise<void>;

  constructor() {
    this.baseDir = join(
      process.cwd(),
      process.env.STORAGE_LOCAL_DIR?.trim() || '.storage',
    );
    this.ready = mkdir(this.baseDir, { recursive: true }).then(() => {
      this.logger.log(`storage local pronto em ${this.baseDir}`);
    });
  }

  async put(
    buffer: Buffer,
    contentType: string,
    prefix: string,
  ): Promise<string> {
    await this.ready;
    const key = `${prefix}/${randomUUID()}${extensionFor(contentType)}`;
    await mkdir(dirname(this.dataPath(key)), { recursive: true });
    await writeFile(this.dataPath(key), buffer);
    await writeFile(this.metaPath(key), contentType, 'utf-8');
    return key;
  }

  async get(
    key: string,
  ): Promise<{ buffer: Buffer; contentType: string } | null> {
    await this.ready;
    try {
      const [buffer, contentType] = await Promise.all([
        readFile(this.dataPath(key)),
        readFile(this.metaPath(key), 'utf-8'),
      ]);
      return { buffer, contentType };
    } catch (error) {
      if (this.isNotFound(error)) return null;
      throw error;
    }
  }

  async delete(key: string): Promise<void> {
    await this.ready;
    await Promise.all([
      rm(this.dataPath(key), { force: true }),
      rm(this.metaPath(key), { force: true }),
    ]);
  }

  private dataPath(key: string): string {
    return this.resolveWithinBase(key);
  }

  private metaPath(key: string): string {
    return this.resolveWithinBase(`${key}.meta`);
  }

  /**
   * `key` inclui o `prefix` do caller (`<projectId>/midias/<uuid>.<ext>`) —
   * `projectId` é sempre um CUID2 do próprio banco, mas resolve e confere
   * contra `baseDir` mesmo assim (defesa em profundidade contra traversal via
   * `..` numa key nunca deveria acontecer, mas não custa barrar).
   */
  private resolveWithinBase(key: string): string {
    const resolved = normalize(join(this.baseDir, key));
    if (resolved !== this.baseDir && !resolved.startsWith(this.baseDir + '/')) {
      throw new Error(`key de storage fora do baseDir: "${key}"`);
    }
    return resolved;
  }

  private isNotFound(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code: unknown }).code === 'ENOENT'
    );
  }
}
