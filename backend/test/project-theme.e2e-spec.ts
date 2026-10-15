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

type ContentRecord = {
  id: string;
  projectId: string;
  name: string;
  slug: string;
  publishedAt: Date | null;
  publishedVersionId: string | null;
  updatedAt: Date;
  publishedSpec: Record<string, unknown>;
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

const aContent = (overrides: Partial<ContentRecord> = {}): ContentRecord => {
  const id = overrides.id ?? 'content-1';
  return {
    id,
    projectId: 'proj-1',
    name: 'Home',
    slug: 'home',
    publishedAt: new Date('2026-10-05T10:00:00.000Z'),
    publishedVersionId: `version-${id}`,
    updatedAt: new Date('2026-10-06T10:00:00.000Z'),
    publishedSpec: { specVersion: 2, kind: 'content', id, slug: overrides.slug ?? 'home' },
    ...overrides,
  };
};

// O Prisma só devolve as colunas pedidas em `select`; sem refletir isso, o
// teste de "a lista não traz `theme`" passaria mesmo com o select errado.
const pick = <T extends object>(record: T, select: Select) => {
  if (!select) return { ...record };
  const picked: Record<string, unknown> = {};
  for (const key of Object.keys(select)) {
    if (!select[key]) continue;
    picked[key] = key === '_count' ? EMPTY_COUNTS : record[key as keyof T];
  }
  return picked;
};

const project = (record: ProjectRecord, select: Select) => pick(record, select);

type PublishedWhere = {
  projectId: string;
  slug?: string;
  publishedVersionId?: { not: null };
};

const isPublishedMatch = (content: ContentRecord, where: PublishedWhere) =>
  content.projectId === where.projectId &&
  (where.slug === undefined || content.slug === where.slug) &&
  (where.publishedVersionId === undefined || content.publishedVersionId !== null);

function createInMemoryPrisma(seed: ProjectRecord[], contentSeed: ContentRecord[] = []) {
  const projects = new Map(seed.map((p) => [p.id, { ...p }]));
  const contents = contentSeed.map((c) => ({ ...c }));

  const prisma = {
    project: {
      findUnique: jest.fn(
        async ({ where, select }: { where: { id: string }; select?: Select }) => {
          const found = projects.get(where.id);
          return found ? project(found, select) : null;
        },
      ),
      findFirst: jest.fn(
        async ({
          where,
          select,
        }: {
          where: { publishableKey: string; archivedAt: null };
          select?: Select;
        }) => {
          const found = [...projects.values()].find(
            (p) => p.publishableKey === where.publishableKey && p.archivedAt === null,
          );
          return found ? project(found, select) : null;
        },
      ),
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
    content: {
      findFirst: jest.fn(
        async ({ where, select }: { where: PublishedWhere; select?: Select }) => {
          const found = contents.find((c) => isPublishedMatch(c, where));
          return found ? pick(found, select) : null;
        },
      ),
      findMany: jest.fn(
        async ({ where, select }: { where: PublishedWhere; select?: Select }) =>
          contents.filter((c) => isPublishedMatch(c, where)).map((c) => pick(c, select)),
      ),
    },
    contentVersion: {
      findUnique: jest.fn(async ({ where }: { where: { id: string } }) => {
        const owner = contents.find((c) => c.publishedVersionId === where.id);
        return owner ? { spec: owner.publishedSpec } : null;
      }),
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

describe('Tema do projeto — leitura pública GET /v1/public/contents', () => {
  let app: NestExpressApplication;
  let db: ReturnType<typeof createInMemoryPrisma>;

  const PUBLISHED_AT = new Date('2026-10-05T10:00:00.000Z');
  const SEEDED_THEME_AT = new Date('2026-10-02T00:00:00.000Z');
  const RED = { colors: { primary: '#FF0000' } };
  const BLUE = { colors: { primary: '#0000FF' } };

  const startWith = async (projects: ProjectRecord[], contents: ContentRecord[]) => {
    db = createInMemoryPrisma(projects, contents);
    app = await buildApp(db.prisma);
  };

  const readPublic = (slug: string, key = 'drv_pub_1', etag?: string) => {
    const req = request(app.getHttpServer())
      .get(`/v1/public/contents/${slug}`)
      .set('x-driva-key', key);
    return etag ? req.set('If-None-Match', etag) : req;
  };

  const putTheme = (body: unknown, id = 'proj-1') =>
    request(app.getHttpServer()).put(`/v1/projects/${id}/theme`).send(body as object);

  afterEach(async () => {
    await app.close();
  });

  it('projeto sem tema traz "theme": null, os campos de antes e o ETag sem -t', async () => {
    await startWith([aProject()], [aContent()]);

    const res = await readPublic('home');

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('theme', null);
    expect(res.body.id).toBe('content-1');
    expect(res.body.name).toBe('Home');
    expect(res.body.slug).toBe('home');
    expect(res.body.updatedAt).toBe(PUBLISHED_AT.toISOString());
    expect(res.body.spec).toEqual({
      specVersion: 2,
      kind: 'content',
      id: 'content-1',
      slug: 'home',
    });
    expect(Object.keys(res.body).sort()).toEqual(
      ['id', 'name', 'slug', 'spec', 'theme', 'updatedAt'],
    );
    expect(res.headers.etag).toBe(`"content-1-${PUBLISHED_AT.getTime()}"`);
  });

  it('depois do PUT do tema, dois conteúdos do projeto trazem o tema novo sem republicar', async () => {
    await startWith(
      [aProject()],
      [aContent(), aContent({ id: 'content-2', name: 'Sobre', slug: 'sobre' })],
    );

    const put = await putTheme({ theme: RED });
    const home = await readPublic('home');
    const about = await readPublic('sobre');

    expect(put.status).toBe(200);
    expect(home.status).toBe(200);
    expect(home.body.theme).toEqual(RED);
    expect(home.body.updatedAt).toBe(PUBLISHED_AT.toISOString());
    expect(about.status).toBe(200);
    expect(about.body.id).toBe('content-2');
    expect(about.body.theme).toEqual(RED);
    expect(about.body.updatedAt).toBe(PUBLISHED_AT.toISOString());
  });

  it('dois projetos com temas diferentes: cada chave recebe o seu', async () => {
    await startWith(
      [
        aProject({ theme: RED, themeUpdatedAt: SEEDED_THEME_AT }),
        aProject({
          id: 'proj-2',
          publishableKey: 'drv_pub_2',
          theme: BLUE,
          themeUpdatedAt: SEEDED_THEME_AT,
        }),
      ],
      [aContent(), aContent({ id: 'content-2', projectId: 'proj-2' })],
    );

    const first = await readPublic('home', 'drv_pub_1');
    const second = await readPublic('home', 'drv_pub_2');

    expect(first.body.id).toBe('content-1');
    expect(first.body.theme).toEqual(RED);
    expect(second.body.id).toBe('content-2');
    expect(second.body.theme).toEqual(BLUE);
  });

  it('revalidar com o ETag anterior dá 304 enquanto nada muda', async () => {
    await startWith([aProject({ theme: RED, themeUpdatedAt: SEEDED_THEME_AT })], [aContent()]);

    const first = await readPublic('home');
    const again = await readPublic('home', 'drv_pub_1', first.headers.etag);

    expect(first.headers.etag).toBe(
      `"content-1-${PUBLISHED_AT.getTime()}-t${SEEDED_THEME_AT.getTime()}"`,
    );
    expect(again.status).toBe(304);
  });

  it('revalidar com o ETag anterior depois de uma troca dá 200 com o tema novo', async () => {
    await startWith([aProject({ theme: RED, themeUpdatedAt: SEEDED_THEME_AT })], [aContent()]);

    const before = await readPublic('home');
    await putTheme({ theme: BLUE });
    const after = await readPublic('home', 'drv_pub_1', before.headers.etag);

    expect(after.status).toBe(200);
    expect(after.body.theme).toEqual(BLUE);
    expect(after.headers.etag).not.toBe(before.headers.etag);
  });

  it('revalidar com o ETag anterior depois de uma limpeza dá 200 com "theme": null', async () => {
    await startWith([aProject({ theme: RED, themeUpdatedAt: SEEDED_THEME_AT })], [aContent()]);

    const before = await readPublic('home');
    await putTheme({ theme: null });
    const after = await readPublic('home', 'drv_pub_1', before.headers.etag);

    expect(after.status).toBe(200);
    expect(after.body).toHaveProperty('theme', null);
    expect(after.headers.etag).not.toBe(before.headers.etag);
  });

  it('a lista pública não traz theme', async () => {
    await startWith([aProject({ theme: RED, themeUpdatedAt: SEEDED_THEME_AT })], [aContent()]);

    const res = await request(app.getHttpServer())
      .get('/v1/public/contents')
      .set('x-driva-key', 'drv_pub_1');

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0]).not.toHaveProperty('theme');
    expect(Object.keys(res.body.data[0]).sort()).toEqual(['id', 'name', 'slug', 'updatedAt']);
  });
});
