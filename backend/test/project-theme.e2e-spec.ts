import { Test } from '@nestjs/testing';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { Prisma } from '@prisma/client';
import request from 'supertest';
import { configureApp } from '../src/configure-app';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

type ProjectRecord = {
  id: string;
  title: string;
  description: string | null;
  imageKey: string | null;
  archivedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  publishableKey: string;
  theme: Prisma.JsonValue | null;
  themeUpdatedAt: Date | null;
};

type Select = Record<string, unknown> | undefined;

const EMPTY_COUNTS = { contents: 0, categories: 0 };

const aProject = (overrides: Partial<ProjectRecord> = {}): ProjectRecord => ({
  id: 'proj-1',
  title: 'Projeto 1',
  description: null,
  imageKey: null,
  archivedAt: null,
  createdAt: new Date('2026-10-01T00:00:00.000Z'),
  updatedAt: new Date('2026-10-01T00:00:00.000Z'),
  publishableKey: 'drv_pub_1',
  theme: null,
  themeUpdatedAt: null,
  ...overrides,
});

// O Prisma só devolve as colunas pedidas em `select`; sem refletir isso, o
// teste de "a lista não traz `theme`" passaria mesmo com o select errado.
const project = (record: ProjectRecord, select: Select) => {
  if (!select) return { ...record };
  const picked: Record<string, unknown> = {};
  for (const key of Object.keys(select)) {
    if (!select[key]) continue;
    picked[key] =
      key === '_count' ? EMPTY_COUNTS : record[key as keyof ProjectRecord];
  }
  return picked;
};

function createInMemoryPrisma(seed: ProjectRecord[]) {
  const projects = new Map(seed.map((p) => [p.id, { ...p }]));

  const prisma = {
    project: {
      findUnique: jest.fn(
        async ({ where, select }: { where: { id: string }; select?: Select }) => {
          const found = projects.get(where.id);
          return found ? project(found, select) : null;
        },
      ),
      findFirst: jest.fn(),
      findMany: jest.fn(
        async ({ where, select }: { where?: { archivedAt?: unknown }; select?: Select }) =>
          [...projects.values()]
            .filter((p) => (where?.archivedAt === null ? p.archivedAt === null : true))
            .map((p) => project(p, select)),
      ),
      update: jest.fn(
        async ({
          where,
          data,
          select,
        }: {
          where: { id: string };
          data: Record<string, unknown>;
          select?: Select;
        }) => {
          const found = projects.get(where.id);
          if (!found) throw new Error(`project ${where.id} não existe no dublê`);
          const { theme, ...rest } = data;
          Object.assign(found, rest);
          if (theme !== undefined) {
            found.theme = theme === Prisma.DbNull ? null : (theme as Prisma.JsonValue);
          }
          return project(found, select);
        },
      ),
    },
  };

  return { prisma, projects };
}

async function buildApp(
  prisma: unknown,
): Promise<NestExpressApplication> {
  const moduleRef = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(PrismaService)
    .useValue(prisma)
    .compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}

const THEME_MESSAGE = 'theme precisa ser um objeto ou null';

describe('Tema do projeto — PUT /v1/projects/:id/theme', () => {
  let app: NestExpressApplication;
  let db: ReturnType<typeof createInMemoryPrisma>;

  const startWith = async (...seed: ProjectRecord[]) => {
    db = createInMemoryPrisma(seed);
    app = await buildApp(db.prisma);
  };

  const getProject = (id = 'proj-1') =>
    request(app.getHttpServer()).get(`/v1/projects/${id}`);

  const putTheme = (body: unknown, id = 'proj-1') =>
    request(app.getHttpServer()).put(`/v1/projects/${id}/theme`).send(body as object);

  afterEach(async () => {
    await app.close();
  });

  it('projeto sem tema traz theme null no GET :id', async () => {
    await startWith(aProject());

    const res = await getProject();

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('theme', null);
  });

  it('grava o objeto como veio, inclusive chave desconhecida, e o GET :id o traz', async () => {
    await startWith(aProject());
    const theme = {
      colors: { primary: '#FF0000' },
      chaveDesconhecida: { qualquer: ['coisa', 1, true] },
    };

    const put = await putTheme({ theme });
    const get = await getProject();

    expect(put.status).toBe(200);
    expect(put.body.theme).toEqual(theme);
    expect(put.body.id).toBe('proj-1');
    expect(get.body.theme).toEqual(theme);
  });

  it('{"theme": null} limpa o tema e o GET :id traz null', async () => {
    await startWith(aProject({ theme: { colors: { primary: '#FF0000' } } }));

    const put = await putTheme({ theme: null });
    const get = await getProject();

    expect(put.status).toBe(200);
    expect(put.body.theme).toBeNull();
    expect(get.body.theme).toBeNull();
  });

  it.each([
    ['texto', { theme: 'abc' }],
    ['número', { theme: 1 }],
    ['booleano', { theme: true }],
    ['lista', { theme: [] }],
    ['corpo sem theme', {}],
  ])('recusa com 400 quando theme é %s e mantém o tema anterior', async (_, body) => {
    const previous = { colors: { primary: '#00FF00' } };
    await startWith(aProject({ theme: previous }));

    const put = await putTheme(body);
    const get = await getProject();

    expect(put.status).toBe(400);
    expect(put.body.message).toContain(THEME_MESSAGE);
    expect(db.prisma.project.update).not.toHaveBeenCalled();
    expect(get.body.theme).toEqual(previous);
  });

  it('id inexistente dá 404 sem chamar update', async () => {
    await startWith(aProject());

    const put = await putTheme({ theme: {} }, 'nao-existe');

    expect(put.status).toBe(404);
    expect(db.prisma.project.update).not.toHaveBeenCalled();
  });

  it('projeto arquivado aceita a gravação', async () => {
    await startWith(aProject({ archivedAt: new Date('2026-10-02T00:00:00.000Z') }));

    const put = await putTheme({ theme: { colors: { primary: '#0000FF' } } });

    expect(put.status).toBe(200);
    expect(put.body.theme).toEqual({ colors: { primary: '#0000FF' } });
  });

  it('a limpeza grava Prisma.DbNull e toda gravação preenche themeUpdatedAt com uma data', async () => {
    await startWith(aProject());

    await putTheme({ theme: { colors: {} } });
    await putTheme({ theme: null });

    const [write, clear] = db.prisma.project.update.mock.calls.map(
      ([args]) => args.data,
    );
    expect(write.theme).toEqual({ colors: {} });
    expect(write.themeUpdatedAt).toBeInstanceOf(Date);
    expect(clear.theme).toBe(Prisma.DbNull);
    expect(clear.themeUpdatedAt).toBeInstanceOf(Date);
    expect(db.projects.get('proj-1')?.themeUpdatedAt).toBeInstanceOf(Date);
  });

  it('GET /v1/projects (lista) não traz a chave theme', async () => {
    await startWith(aProject({ theme: { colors: { primary: '#FF0000' } } }));

    const res = await request(app.getHttpServer()).get('/v1/projects');

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).not.toHaveProperty('theme');
  });
});
