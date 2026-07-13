import { randomUUID } from 'node:crypto';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  NoSuchKey,
  NotFound,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { Injectable, Logger } from '@nestjs/common';
import { StorageService } from './storage.service';
import { extensionFor } from './storage.util';

/**
 * Adapter S3-compatível do port `StorageService` — pronto e codado, mas
 * **não ativado** por padrão (`STORAGE_DRIVER` continua `local`). Liga
 * quando a Decisão 4 do `prd.md` (Garage vs R2 + credenciais) for resolvida:
 * `STORAGE_DRIVER=s3` + as envs abaixo no Coolify (nunca no repo).
 *
 * Envs esperadas (ver `.env.example`):
 *  - `S3_ENDPOINT`    — endpoint S3-compatível (ex.: Garage/R2). Vazio = AWS S3 real.
 *  - `S3_BUCKET`      — bucket de destino.
 *  - `S3_ACCESS_KEY`  — access key id.
 *  - `S3_SECRET_KEY`  — secret access key.
 *  - `S3_REGION`      — região (default `auto`, aceito por Garage/R2).
 *  - `S3_KEY_PREFIX`  — prefixo raiz opcional, para namespacear a app dentro de
 *    um bucket compartilhado por vários serviços/ambientes (ex.: `driva-hml`).
 *    Vazio = grava na raiz do bucket.
 *
 * A key gravada é `<keyPrefix>/<prefix>/<uuid>.<ext>` — nome de arquivo sempre
 * um UUID gerado aqui (nunca o filename do cliente — mesma regra do adapter
 * local), `prefix` (ex.: `<projectId>/midias`) organiza por projeto e
 * `keyPrefix` (de `S3_KEY_PREFIX`) separa a app dentro do bucket. O
 * content-type é fixado no valor detectado pelo pipeline de upload
 * (`image-pipeline.ts`), nunca inferido pelo S3 a partir da extensão.
 *
 * A key final (já com o `keyPrefix`) é o que `put` devolve e o que fica gravado
 * em `Project.imageKey` — logo `get`/`delete` recebem a key completa e seguem
 * consistentes mesmo que o `S3_KEY_PREFIX` mude depois.
 */
@Injectable()
export class S3StorageService implements StorageService {
  private readonly logger = new Logger(S3StorageService.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  // Prefixo raiz opcional (`S3_KEY_PREFIX`), sem barras nas pontas — namespaceia
  // a app dentro de um bucket compartilhado. Vazio = grava na raiz do bucket.
  private readonly keyPrefix: string;

  constructor() {
    const endpoint = process.env.S3_ENDPOINT?.trim() || undefined;
    const bucket = process.env.S3_BUCKET?.trim();
    const accessKeyId = process.env.S3_ACCESS_KEY?.trim();
    const secretAccessKey = process.env.S3_SECRET_KEY?.trim();
    const region = process.env.S3_REGION?.trim() || 'auto';
    this.keyPrefix = (process.env.S3_KEY_PREFIX?.trim() || '').replace(
      /^\/+|\/+$/g,
      '',
    );

    if (!bucket || !accessKeyId || !secretAccessKey) {
      throw new Error(
        'STORAGE_DRIVER=s3 requer S3_BUCKET, S3_ACCESS_KEY e S3_SECRET_KEY definidos por env.',
      );
    }

    this.bucket = bucket;
    this.client = new S3Client({
      endpoint,
      region,
      credentials: { accessKeyId, secretAccessKey },
      // Adapters S3-compatíveis (Garage/R2) costumam exigir path-style;
      // AWS S3 real aceita ambos.
      forcePathStyle: true,
    });
    this.logger.log(
      `storage S3 pronto (bucket="${bucket}", endpoint="${endpoint ?? 'aws'}"` +
        `${this.keyPrefix ? `, keyPrefix="${this.keyPrefix}"` : ''})`,
    );
  }

  async put(
    buffer: Buffer,
    contentType: string,
    prefix: string,
  ): Promise<string> {
    const scoped = this.keyPrefix ? `${this.keyPrefix}/${prefix}` : prefix;
    const key = `${scoped}/${randomUUID()}${extensionFor(contentType)}`;
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: buffer,
        ContentType: contentType,
      }),
    );
    return key;
  }

  async get(
    key: string,
  ): Promise<{ buffer: Buffer; contentType: string } | null> {
    try {
      const result = await this.client.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      const buffer = Buffer.from(
        await result.Body!.transformToByteArray(),
      );
      return {
        buffer,
        contentType: result.ContentType ?? 'application/octet-stream',
      };
    } catch (error) {
      if (error instanceof NoSuchKey || error instanceof NotFound) {
        return null;
      }
      throw error;
    }
  }

  async delete(key: string): Promise<void> {
    await this.client.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
    );
  }
}
