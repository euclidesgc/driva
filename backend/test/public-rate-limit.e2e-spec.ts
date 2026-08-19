import { Test } from '@nestjs/testing';
import type { NestExpressApplication } from '@nestjs/platform-express';
import request from 'supertest';
import { configureApp } from '../src/configure-app';
import { PublicModule } from '../src/public/public.module';
import { PUBLIC_THROTTLE } from '../src/public/public.constants';

// Sem `x-driva-key` a rota devolve 404 antes de qualquer consulta ao banco
// (`public.controller.ts`, `keyOf`) — o que deixa este teste exercitar o
// `ThrottlerGuard` de verdade, em processo, sem depender de Postgres.
describe('Rota pública — rate limit (item 25, D7)', () => {
  let app: NestExpressApplication;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [PublicModule],
    }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>();
    configureApp(app);
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('devolve 429 acima do limite, sem vazar projeto/slug/chave no corpo', async () => {
    const limit = PUBLIC_THROTTLE.limit;

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
    const limit = PUBLIC_THROTTLE.limit;

    let last = { status: 0 };
    for (let i = 0; i < limit + 1; i += 1) {
      last = await request(app.getHttpServer()).get(
        '/v1/public/contents/qualquer-slug',
      );
    }

    expect(last.status).toBe(429);
  });

  it('abaixo do limite, a rota responde 404 (chave ausente) — nunca 429', async () => {
    const belowLimit = PUBLIC_THROTTLE.limit - 1;

    let last = { status: 0 };
    for (let i = 0; i < belowLimit; i += 1) {
      last = await request(app.getHttpServer()).get('/v1/public/contents');
    }

    expect(last.status).toBe(404);
  });
});
