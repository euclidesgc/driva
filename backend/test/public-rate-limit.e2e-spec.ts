import { Test } from '@nestjs/testing';
import type { NestExpressApplication } from '@nestjs/platform-express';
import request from 'supertest';
import { configureApp } from '../src/configure-app';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { PUBLIC_THROTTLE } from '../src/public/public.constants';

// `ThrottlerModule` é `@Global()` e três módulos (`ProjectsModule`,
// `MediaModule`, `PublicModule`) chamam `forRoot` — o defeito que este
// arquivo prova só existe quando os três disputam o mesmo token, então o
// teste monta o `AppModule` de verdade, não `PublicModule` isolado.
//
// Nenhuma das requisições daqui passa da checagem de `x-driva-key`
// ausente (`public.controller.ts`, `keyOf` lança 404 antes de tocar
// `PublicService`) — então o `PrismaService` nunca deveria ser consultado.
// Um objeto vazio no lugar dele não pede Postgres real (a CI de backend
// não sobe banco no job atual) e, se algum caminho inesperado tentasse
// `this.prisma.content...`, falharia alto (`Cannot read properties of
// undefined`) em vez de mascarar o acesso.
const untouchedPrisma = {} as PrismaService;

async function buildApp(): Promise<NestExpressApplication> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(PrismaService)
    .useValue(untouchedPrisma)
    .compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}

describe('Rota pública — rate limit (item 25, D7)', () => {
  let app: NestExpressApplication;

  beforeEach(async () => {
    app = await buildApp();
  });

  afterEach(async () => {
    await app.close();
  });

  it('devolve 429 acima do limite, sem vazar projeto/slug/chave no corpo', async () => {
    const limit = PUBLIC_THROTTLE.default.limit;

    let last = { status: 0, body: {} as Record<string, unknown> };
    for (let i = 0; i < limit + 1; i += 1) {
      last = await request(app.getHttpServer()).get('/v1/public/contents');
    }

    expect(last.status).toBe(429);
    const serialized = JSON.stringify(last.body).toLowerCase();
    expect(serialized).not.toContain('project');
    expect(serialized).not.toContain('slug');
    expect(serialized).not.toContain('driva-key');
  });

  it('a rota de detalhe (:slug) está sob o mesmo limite', async () => {
    const limit = PUBLIC_THROTTLE.default.limit;

    let last = { status: 0 };
    for (let i = 0; i < limit + 1; i += 1) {
      last = await request(app.getHttpServer()).get(
        '/v1/public/contents/qualquer-slug',
      );
    }

    expect(last.status).toBe(429);
  });

  it('abaixo do limite, a rota responde 404 (chave ausente) — nunca 429', async () => {
    const belowLimit = PUBLIC_THROTTLE.default.limit - 1;

    let last = { status: 0 };
    for (let i = 0; i < belowLimit; i += 1) {
      last = await request(app.getHttpServer()).get('/v1/public/contents');
    }

    expect(last.status).toBe(404);
  });
});
