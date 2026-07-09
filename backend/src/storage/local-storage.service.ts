import { randomUUID } from 'node:crypto';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { Injectable, Logger } from '@nestjs/common';
import { StorageService } from './storage.service';

/**
 * Adapter local (default de dev, reversível) do port `StorageService`.
 *
 * Grava em `STORAGE_LOCAL_DIR` (default `.storage/`, relativa ao cwd do
 * processo Nest) — FORA de qualquer webroot/pasta servida estaticamente, para
 * que um binário malicioso salvo aqui nunca seja executável/servível direto
 * pelo servidor HTTP. O único jeito de ler o conteúdo é via `get(key)`,
 * chamado pelo endpoint de serving (que fixa content-type + `nosniff` — F2).
 *
 * A key é o nome do arquivo, sempre um UUID gerado aqui (nunca o filename do
 * cliente — path traversal/overwrite). O content-type é persistido num
 * arquivo `<key>.meta` ao lado do binário, pois o filesystem não carrega essa
 * informação sozinho.
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

  async put(buffer: Buffer, contentType: string): Promise<string> {
    await this.ready;
    const key = randomUUID();
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
    return join(this.baseDir, key);
  }

  private metaPath(key: string): string {
    return join(this.baseDir, `${key}.meta`);
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
