import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Cancela de entrada: DTOs validados, campos desconhecidos rejeitados.
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
  );

  app.setGlobalPrefix('v1');

  // CORS: em dev, qualquer localhost (porta aleatória do flutter run); em
  // hml/prod, a lista exata de origens vem de CORS_ORIGINS (definida no Coolify,
  // separada por vírgula). Segredo/origem nunca fica no repo.
  const corsOrigins = process.env.CORS_ORIGINS?.split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  app.enableCors({
    origin: corsOrigins?.length
      ? corsOrigins
      : /^https?:\/\/localhost(:\d+)?$/,
    allowedHeaders: ['content-type', 'x-project-id'],
  });

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap();
