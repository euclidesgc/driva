import { Test } from '@nestjs/testing';
import type { NestExpressApplication } from '@nestjs/platform-express';
import request from 'supertest';
import { configureApp } from '../src/configure-app';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

type Row = {
  id: string;
  projectId: string;
  categoryId: string;
  name: string;
  nameNormalized: string;
  slug: string;
  description: string | null;
  kind: string;
  draftSpec: Record<string, unknown>;
  draftUpdatedAt: Date;
  publishedVersionId: string | null;
  publishedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

type Where = {
  id?: string;
  projectId?: string;
  kind?: string;
  slug?: string;
  publishedVersionId?: { not: null };
};

const matches = (row: Row, where: Where) =>
  (where.id === undefined || row.id === where.id) &&
  (where.projectId === undefined || row.projectId === where.projectId) &&
  (where.kind === undefined || row.kind === where.kind) &&
  (where.slug === undefined || row.slug === where.slug) &&
  (where.publishedVersionId === undefined || row.publishedVersionId !== null);

const NOW = new Date('2026-10-15T10:00:00.000Z');

// Dublê em memória do que ContentsService e PublicService pedem ao Prisma.
function createInMemoryPrisma(seed: Row[] = []) {
  const rows = seed.map((r) => ({ ...r }));
  let counter = 0;

  const prisma: Record<string, any> = {
    category: {
      findFirst: jest.fn(async () => ({ id: 'cat-1' })),
    },
    project: {
      findFirst: jest.fn(async () => ({
        id: 'default',
        theme: null,
        themeUpdatedAt: null,
      })),
    },
    content: {
      create: jest.fn(async ({ data }: { data: Partial<Row> }) => {
        const row = {
          id: `c-${++counter}`,
          publishedVersionId: null,
          publishedAt: null,
          createdAt: NOW,
          updatedAt: NOW,
          description: null,
          ...data,
        } as Row;
        rows.push(row);
        return { id: row.id };
      }),
      update: jest.fn(
        async ({ where, data }: { where: { id: string }; data: Partial<Row> }) => {
          const row = rows.find((r) => r.id === where.id)!;
          Object.assign(row, data);
          return { ...row };
        },
      ),
      updateMany: jest.fn(
        async ({ where, data }: { where: Where; data: Partial<Row> }) => {
          const found = rows.filter((r) => matches(r, where));
          found.forEach((r) => Object.assign(r, data));
          return { count: found.length };
        },
      ),
      findFirst: jest.fn(async ({ where }: { where: Where }) => {
        const found = rows.find((r) => matches(r, where));
        return found ? { ...found } : null;
      }),
      findMany: jest.fn(async ({ where }: { where: Where }) =>
        rows.filter((r) => matches(r, where)).map((r) => ({ ...r })),
      ),
    },
    contentVersion: {
      groupBy: jest.fn(async () => []),
      aggregate: jest.fn(async () => ({ _max: { version: null } })),
      findUnique: jest.fn(async () => ({ spec: { specVersion: 2 } })),
    },
  };
  prisma.$transaction = jest.fn(async (fn: (tx: unknown) => unknown) => fn(prisma));
  return { prisma, rows };
}

async function buildApp(prisma: unknown) {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
    .overrideProvider(PrismaService)
    .useValue(prisma)
    .compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}

describe('Componente como Content com kind — contrato HTTP', () => {
  let app: NestExpressApplication;
  let db: ReturnType<typeof createInMemoryPrisma>;

  const start = async (seed: Row[] = []) => {
    db = createInMemoryPrisma(seed);
    app = await buildApp(db.prisma);
  };
  const http = () => request(app.getHttpServer());

  afterEach(async () => {
    await app.close();
  });

  it('cria com kind: component e injeta o kind no spec inicial', async () => {
    await start();

    const res = await http()
      .post('/v1/contents')
      .send({ name: 'Selo', slug: 'selo', kind: 'component' });

    expect(res.status).toBe(201);
    expect(res.body.kind).toBe('component');
    expect(db.rows[0].kind).toBe('component');
    expect(db.rows[0].draftSpec.kind).toBe('component');
  });

  it('sem kind no corpo, cria um conteúdo', async () => {
    await start();

    const res = await http().post('/v1/contents').send({ name: 'Home', slug: 'home' });

    expect(res.status).toBe(201);
    expect(res.body.kind).toBe('content');
  });

  it('recusa kind fora da lista com 400', async () => {
    await start();

    const res = await http()
      .post('/v1/contents')
      .send({ name: 'X', slug: 'x', kind: 'widget' });

    expect(res.status).toBe(400);
  });

  it('lista com ?kind=component sem trazer conteúdos, e sem kind sem trazer componentes', async () => {
    await start();
    await http().post('/v1/contents').send({ name: 'Home', slug: 'home' });
    await http()
      .post('/v1/contents')
      .send({ name: 'Selo', slug: 'selo', kind: 'component' });

    const components = await http().get('/v1/contents?kind=component');
    const contents = await http().get('/v1/contents');

    expect(components.status).toBe(200);
    expect(components.body.data.map((c: { slug: string }) => c.slug)).toEqual(['selo']);
    expect(contents.body.data.map((c: { slug: string }) => c.slug)).toEqual(['home']);
  });

  it('recusa com 400 um PUT com spec.kind divergente do kind da linha', async () => {
    await start();
    const created = await http()
      .post('/v1/contents')
      .send({ name: 'Selo', slug: 'selo', kind: 'component' });

    const res = await http()
      .put(`/v1/contents/${created.body.id}`)
      .send({
        spec: { specVersion: 2, kind: 'content', id: created.body.id },
      });

    expect(res.status).toBe(400);
    expect(db.rows[0].draftSpec.kind).toBe('component');
  });

  it('aceita o PUT quando spec.kind bate com o da linha', async () => {
    await start();
    const created = await http()
      .post('/v1/contents')
      .send({ name: 'Selo', slug: 'selo', kind: 'component' });

    const res = await http()
      .put(`/v1/contents/${created.body.id}`)
      .send({
        spec: { specVersion: 2, kind: 'component', id: created.body.id },
      });

    expect(res.status).toBe(200);
  });

  it('a rota pública não serve componente publicado', async () => {
    const published = {
      id: 'comp-1',
      projectId: 'default',
      categoryId: 'cat-1',
      name: 'Selo',
      nameNormalized: 'selo',
      slug: 'selo',
      description: null,
      kind: 'component',
      draftSpec: {},
      draftUpdatedAt: NOW,
      publishedVersionId: 'v1',
      publishedAt: NOW,
      createdAt: NOW,
      updatedAt: NOW,
    };
    await start([published, { ...published, id: 'page-1', slug: 'home', kind: 'content' }]);

    const component = await http()
      .get('/v1/public/contents/selo')
      .set('x-driva-key', 'k');
    const page = await http().get('/v1/public/contents/home').set('x-driva-key', 'k');
    const list = await http().get('/v1/public/contents').set('x-driva-key', 'k');

    expect(component.status).toBe(404);
    expect(page.status).toBe(200);
    expect(list.body.data.map((c: { slug: string }) => c.slug)).toEqual(['home']);
  });
});
