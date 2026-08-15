import { Module } from '@nestjs/common';
import { CategoriesModule } from './categories/categories.module';
import { ContentsModule } from './contents/contents.module';
import { HealthController } from './health/health.controller';
import { ProjectsModule } from './projects/projects.module';
import { PublicModule } from './public/public.module';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    ContentsModule,
    StorageModule,
    ProjectsModule,
    CategoriesModule,
    PublicModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
