import { Module } from '@nestjs/common';
import { LocalStorageService } from './local-storage.service';
import { S3StorageService } from './s3-storage.service';
import { StorageService } from './storage.service';

/**
 * Escolhe o adapter concreto por `STORAGE_DRIVER` (default `local`).
 *
 * `s3` está codado e pronto (`S3StorageService`, `@aws-sdk/client-s3`), mas
 * **não ligar em hml/prod** sem a Decisão 4 do `prd.md` (Garage vs R2 +
 * credenciais por env no Coolify — nunca no repo). Dev roda sempre no
 * adapter local.
 */
const storageProvider = {
  provide: StorageService,
  useFactory: () => {
    const driver = process.env.STORAGE_DRIVER?.trim() || 'local';
    switch (driver) {
      case 'local':
        return new LocalStorageService();
      case 's3':
        return new S3StorageService();
      default:
        throw new Error(
          `STORAGE_DRIVER="${driver}" não suportado (use "local" ou "s3").`,
        );
    }
  },
};

@Module({
  providers: [storageProvider],
  exports: [StorageService],
})
export class StorageModule {}
