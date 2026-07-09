import { Module } from '@nestjs/common';
import { ContentsModule } from './contents/contents.module';
import { HealthController } from './health/health.controller';
import { ProjectsModule } from './projects/projects.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [ContentsModule, StorageModule, ProjectsModule],
  controllers: [HealthController],
})
export class AppModule {}
