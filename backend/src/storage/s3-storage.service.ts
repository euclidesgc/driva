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
 *
 * A key gravada é sempre um UUID gerado aqui (nunca o filename do cliente —
 * mesma regra do adapter local), e o content-type é fixado no valor
 * detectado pelo pipeline de upload (`image-pipeline.ts`), nunca inferido
 * pelo S3 a partir da extensão.
 */
@Injectable()
export class S3StorageService implements StorageService {
  private readonly logger = new Logger(S3StorageService.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor() {
    const endpoint = process.env.S3_ENDPOINT?.trim() || undefined;
    const bucket = process.env.S3_BUCKET?.trim();
    const accessKeyId = process.env.S3_ACCESS_KEY?.trim();
    const secretAccessKey = process.env.S3_SECRET_KEY?.trim();
    const region = process.env.S3_REGION?.trim() || 'auto';

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
      `storage S3 pronto (bucket="${bucket}", endpoint="${endpoint ?? 'aws'}")`,
    );
  }

  async put(buffer: Buffer, contentType: string): Promise<string> {
    const key = randomUUID();
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
