import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Cancela de entrada: DTOs validados, campos desconhecidos rejeitados.
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
  );

  // Health fica fora do prefixo versionado: orquestrador (Coolify) bate
  // sempre em /health, sem acoplar o healthcheck à versão da API.
  app.setGlobalPrefix('v1', { exclude: ['health'] });

  // CORS: sempre libera `localhost` (porta aleatória do flutter run — permite
  // rodar o editor local apontando para a API de hml/prod ao testar). Em
  // hml/prod, some-se a lista exata de CORS_ORIGINS (definida no Coolify,
  // separada por vírgula). Segredo/origem nunca fica no repo.
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
