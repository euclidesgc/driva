import { Module } from '@nestjs/common';
import { ContentsModule } from './contents/contents.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [ContentsModule],
  controllers: [HealthController],
})
export class AppModule {}
