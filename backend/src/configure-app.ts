import { json, urlencoded } from 'express';
import type { NextFunction, Request, Response } from 'express';
import { ValidationPipe } from '@nestjs/common';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { MAX_UPLOAD_BYTES } from './projects/image-pipeline';

// Tudo que o bootstrap real faz antes de `listen` — extraído para os testes
// (`Test.createTestingModule(...).createNestApplication()`) montarem o app
// exatamente como ele roda em produção. Sem isto, a suíte precisaria
// redeclarar `setGlobalPrefix`/`enableCors` por conta própria, e a asserção
// de ACAO em `#44` (a razão de o proxy de mídia existir) provaria uma cópia
// do bootstrap, não o bootstrap.
export function configureApp(app: NestExpressApplication): void {
  // Em hml/prod o container só enxerga a conexão TCP vinda do Traefik — sem
  // isto, `req.ip` (a chave do `ThrottlerGuard`, `projects.controller.ts` e
  // `media.controller.ts`) é sempre o IP interno do proxy reverso, **igual
  // para todo mundo**: um atacante esgota o balde único e os usuários
  // legítimos tomam 429 pelo resto da janela. `1` confia só no hop
  // imediato (o Traefik) — nunca uma cadeia arbitrária de
  // `X-Forwarded-For`, que qualquer chamador poderia forjar e o rate limit
  // ficaria pior do que sem `trust proxy` nenhum.
  app.set('trust proxy', 1);

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

  // Leitura de conteúdo publicado é consumida pelo app de qualquer cliente,
  // de qualquer origem — a lista de `CORS_ORIGINS` vale só para o editor.
  app.use('/v1/public', (req: Request, res: Response, next: NextFunction) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'content-type, if-none-match, x-driva-key',
    );
    res.setHeader('Access-Control-Expose-Headers', 'etag');
    if (req.method === 'OPTIONS') {
      res.status(204).end();
      return;
    }
    next();
  });

  const corsOrigins =
    process.env.CORS_ORIGINS?.split(',')
      .map((o) => o.trim())
      .filter(Boolean) ?? [];
  const localhost = /^https?:\/\/localhost(:\d+)?$/;
  app.enableCors({
    origin: [...corsOrigins, localhost],
    allowedHeaders: ['content-type', 'x-project-id'],
  });
}
