import { json, urlencoded } from 'express';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MAX_UPLOAD_BYTES } from './projects/image-pipeline';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // O default ~100kb do Express estoura o upload de imagem. Multipart não
  // passa por aqui — quem limita o arquivo é o `FileInterceptor` (multer).
  const bodyLimit = `${MAX_UPLOAD_BYTES + 1024 * 1024}b`;
  app.use(json({ limit: bodyLimit }));
  app.use(urlencoded({ limit: bodyLimit, extended: true }));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.setGlobalPrefix('v1', { exclude: ['health'] });

  const corsOrigins =
    process.env.CORS_ORIGINS?.split(',')
      .map((o) => o.trim())
      .filter(Boolean) ?? [];
  const localhost = /^https?:\/\/localhost(:\d+)?$/;
  app.enableCors({
    origin: [...corsOrigins, localhost],
    allowedHeaders: ['content-type', 'x-project-id'],
  });

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap();
