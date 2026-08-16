import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { MEDIA_IP_BLOCKLIST, isBlockedIp } from './url-guard';

@Module({
  imports: [
    ThrottlerModule.forRoot({ throttlers: [{ ttl: 60_000, limit: 60 }] }),
  ],
  controllers: [MediaController],
  providers: [
    MediaService,
    { provide: MEDIA_IP_BLOCKLIST, useValue: isBlockedIp },
  ],
})
export class MediaModule {}
