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

  // CORS restrito ao editor em dev (porta aleatória do flutter run).
  app.enableCors({
    origin: /^https?:\/\/localhost(:\d+)?$/,
    allowedHeaders: ['content-type', 'x-project-id'],
  });

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap();
