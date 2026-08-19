import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { PrismaService } from '../prisma/prisma.service';
import { ContentsService } from './contents.service';
import { decodeCursor, encodeCursor } from './cursor';

const NOW = new Date('2026-08-19T12:00:00.000Z');

type ContentFixture = {
  id: string;
  projectId: string;
  categoryId: string;
  name: string;
  nameNormalized: string;
  slug: string;
  description: string | null;
  draftSpec: Record<string, unknown>;
  draftUpdatedAt: Date;
  publishedVersionId: string | null;
  publishedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

function contentRow(overrides: Partial<ContentFixture> = {}): ContentFixture {
  return {
    id: 'content-1',
    projectId: 'project-1',
    categoryId: 'category-1',
    name: 'Home',
    nameNormalized: 'home',
    slug: 'home',
    description: null,
    draftSpec: {
      specVersion: 1,
      kind: 'content',
      id: 'content-1',
      name: 'Home',
      slug: 'home',
    },
    draftUpdatedAt: NOW,
    publishedVersionId: null,
    publishedAt: null,
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  };
}

// PrismaService estende PrismaClient, então `$transaction((tx) => ...)`
// recebe um client com a mesma forma do client de topo — o dublê reaproveita
// o próprio objeto como `tx`, igual ao que o Postgres real faria numa
// transação interativa.
function createPrismaMock() {
  const prisma = {
    content: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      updateMany: jest.fn(),
      deleteMany: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      delete: jest.fn(),
    },
    contentVersion: {
      aggregate: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
    category: {
      findFirst: jest.fn(),
    },
    $transaction: jest.fn(),
  };
  prisma.$transaction.mockImplementation((callback: (tx: unknown) => unknown) =>
    callback(prisma),
  );
  return prisma;
}

type PrismaMock = ReturnType<typeof createPrismaMock>;

function serviceWith(prisma: PrismaMock): ContentsService {
  return new ContentsService(prisma as unknown as PrismaService);
}

function p2002(constraint: string): Prisma.PrismaClientKnownRequestError {
  return new Prisma.PrismaClientKnownRequestError(
    `Unique constraint failed on the fields: (${constraint})`,
    { code: 'P2002', clientVersion: '6.19.3' },
  );
}

describe('ContentsService.publish', () => {
  it('não cria versão nova quando o rascunho não mudou desde a última publicação', async () => {
    const prisma = createPrismaMock();
    const row = contentRow({
      publishedVersionId: 'version-3',
      publishedAt: NOW,
      draftUpdatedAt: NOW,
    });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.findUnique.mockResolvedValue({ version: 3 });
    // Deixa o caminho de criação de versão completável mesmo não sendo
    // percorrido em código correto: se a guarda de idempotência sumir, o
    // publish precisa reprovar por asserção (uma versão criada de verdade),
    // não estourar num dublê incompleto antes de qualquer expect rodar.
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 3 } });
    prisma.contentVersion.create.mockResolvedValue({
      id: 'version-4',
      version: 4,
      createdAt: NOW,
    });

    const result = await serviceWith(prisma).publish('project-1', 'content-1', {});

    expect(prisma.contentVersion.create).not.toHaveBeenCalled();
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(result).toEqual({
      publishedVersion: { version: 3, publishedAt: NOW },
      hasUnpublishedChanges: false,
    });
  });

  it('carimba o draftSpec guardado no servidor, ignorando qualquer spec enviado no corpo', async () => {
    const prisma = createPrismaMock();
    const serverSpec = contentRow().draftSpec;
    const row = contentRow({ draftSpec: serverSpec, publishedVersionId: null, publishedAt: null });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: null } });
    prisma.contentVersion.create.mockResolvedValue({
      id: 'version-1',
      version: 1,
      createdAt: NOW,
    });

    const forgedBody = {
      note: 'nota legítima',
      spec: { specVersion: 1, kind: 'content', id: 'outro', name: 'Forjado', slug: 'forjado' },
    };
    await serviceWith(prisma).publish('project-1', 'content-1', forgedBody as never);

    const createArgs = prisma.contentVersion.create.mock.calls[0][0];
    expect(createArgs.data.spec).toBe(serverSpec);
  });

  it('publicação concorrente (choque de [contentId, version]) vira 409 em vez de estourar', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(contentRow());
    prisma.$transaction.mockRejectedValue(p2002('`content_id`,`version`'));

    await expect(
      serviceWith(prisma).publish('project-1', 'content-1', {}),
    ).rejects.toThrow(ConflictException);
  });

  it('depois de um unpublish, a numeração da próxima publicação continua do máximo já criado', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(
      contentRow({ publishedVersionId: null, publishedAt: null }),
    );
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 3 } });
    prisma.contentVersion.create.mockResolvedValue({
      id: 'version-4',
      version: 4,
      createdAt: NOW,
    });

    const result = await serviceWith(prisma).publish('project-1', 'content-1', {});

    expect(prisma.contentVersion.aggregate).toHaveBeenCalledWith({
      where: { contentId: 'content-1' },
      _max: { version: true },
    });
    expect(result.publishedVersion?.version).toBe(4);
  });
});

describe('ContentsService.unpublish', () => {
  it('zera o ponteiro de publicação sem nenhuma escrita destrutiva sobre a versão publicada', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 1 });

    const result = await serviceWith(prisma).unpublish('project-1', 'content-1');

    expect(prisma.content.updateMany).toHaveBeenCalledTimes(1);
    expect(prisma.content.updateMany).toHaveBeenCalledWith({
      where: { id: 'content-1', projectId: 'project-1' },
      data: { publishedVersionId: null, publishedAt: null },
    });
    // "Não apaga versão" cobre a chamada direta a contentVersion e também o
    // nested write escondido num content.update/updateMany
    // (`data: { versions: { deleteMany: {} } } }`) — por isso cada delegate
    // de escrita/apagamento precisa aparecer aqui, não só o que a
    // implementação atual usa.
    expect(prisma.content.update).not.toHaveBeenCalled();
    expect(prisma.content.delete).not.toHaveBeenCalled();
    expect(prisma.content.deleteMany).not.toHaveBeenCalled();
    expect(prisma.contentVersion.create).not.toHaveBeenCalled();
    expect(prisma.contentVersion.update).not.toHaveBeenCalled();
    expect(prisma.contentVersion.updateMany).not.toHaveBeenCalled();
    expect(prisma.contentVersion.delete).not.toHaveBeenCalled();
    expect(prisma.contentVersion.deleteMany).not.toHaveBeenCalled();
    expect(result).toEqual({ publishedVersion: null, hasUnpublishedChanges: true });
  });

  it('id de outro projeto não zera nada e devolve 404', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 0 });

    await expect(
      serviceWith(prisma).unpublish('project-alheio', 'content-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

describe('ContentsService.restoreVersion', () => {
  it('escreve o spec restaurado no rascunho e não mexe no ponteiro de publicação', async () => {
    const prisma = createPrismaMock();
    const restoredSpec = { specVersion: 1, kind: 'content', id: 'content-1', name: 'Versão antiga', slug: 'home' };
    prisma.content.findFirst
      .mockResolvedValueOnce(contentRow({ publishedVersionId: 'version-9', publishedAt: NOW }))
      .mockResolvedValueOnce(
        contentRow({ draftSpec: restoredSpec, publishedVersionId: 'version-9', publishedAt: NOW }),
      );
    prisma.contentVersion.findUnique
      .mockResolvedValueOnce({ spec: restoredSpec })
      .mockResolvedValueOnce({ version: 9 });

    const result = await serviceWith(prisma).restoreVersion('project-1', 'content-1', 3);

    expect(prisma.content.update).toHaveBeenCalledTimes(1);
    expect(prisma.content.update).toHaveBeenCalledWith({
      where: { id: 'content-1' },
      data: { draftSpec: restoredSpec, draftUpdatedAt: expect.any(Date) },
    });
    expect(prisma.contentVersion.create).not.toHaveBeenCalled();
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(result.publishedVersion).toEqual({ version: 9, publishedAt: NOW });
  });

  it('versão inexistente devolve 404 sem tocar o rascunho', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValueOnce(contentRow());
    prisma.contentVersion.findUnique.mockResolvedValueOnce(null);

    await expect(
      serviceWith(prisma).restoreVersion('project-1', 'content-1', 999),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.content.update).not.toHaveBeenCalled();
  });
});

describe('ContentsService — hasUnpublishedChanges', () => {
  it('conteúdo nunca publicado devolve publishedVersion nulo sem consultar contentVersion', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(
      contentRow({ publishedVersionId: null, publishedAt: null }),
    );

    const result = await serviceWith(prisma).find('project-1', 'content-1');

    expect(result.publishedVersion).toBeNull();
    expect(result.hasUnpublishedChanges).toBe(true);
    expect(prisma.contentVersion.findUnique).not.toHaveBeenCalled();
  });

  it('renomear ou trocar o slug não move draftUpdatedAt, então não abre pendência de publicação', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 1 });
    prisma.content.findFirst.mockResolvedValue(
      contentRow({ name: 'Novo nome', slug: 'novo-slug', publishedVersionId: 'version-1', publishedAt: NOW }),
    );

    const result = await serviceWith(prisma).update('project-1', 'content-1', {
      name: 'Novo nome',
      slug: 'novo-slug',
    });

    const updateManyArgs = prisma.content.updateMany.mock.calls[0][0];
    expect(updateManyArgs.data).not.toHaveProperty('draftUpdatedAt');
    expect(result.hasUnpublishedChanges).toBe(false);
  });

  it('editar o spec move draftUpdatedAt e abre pendência de publicação', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 1 });
    prisma.content.findFirst.mockResolvedValue(
      contentRow({ publishedVersionId: 'version-1', publishedAt: NOW }),
    );

    await serviceWith(prisma).update('project-1', 'content-1', {
      spec: { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' },
    });

    const updateManyArgs = prisma.content.updateMany.mock.calls[0][0];
    expect(updateManyArgs.data).toHaveProperty('draftUpdatedAt');
  });
});

describe('ContentsService — escopo de tenant', () => {
  it('conteúdo de outro projeto é invisível a find()', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(null);

    await expect(
      serviceWith(prisma).find('project-a', 'content-de-outro-projeto'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.content.findFirst).toHaveBeenCalledWith({
      where: { id: 'content-de-outro-projeto', projectId: 'project-a' },
    });
  });

  it('remove() filtra por projectId — id de outro projeto devolve 404 sem apagar nada', async () => {
    const prisma = createPrismaMock();
    prisma.content.deleteMany.mockResolvedValue({ count: 0 });

    await expect(
      serviceWith(prisma).remove('project-a', 'content-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.content.deleteMany).toHaveBeenCalledWith({
      where: { id: 'content-1', projectId: 'project-a' },
    });
  });
});

describe('ContentsService.create — conflito de slug', () => {
  it('slug já usado no projeto devolve 409 com uma sugestão de slug livre', async () => {
    const prisma = createPrismaMock();
    prisma.category.findFirst.mockResolvedValue({ id: 'category-1' });
    prisma.$transaction.mockRejectedValue(p2002('`project_id`,`slug`'));
    prisma.content.findMany.mockResolvedValue([{ slug: 'home' }]);

    try {
      await serviceWith(prisma).create('project-1', {
        name: 'Home',
        slug: 'home',
        categoryId: 'category-1',
      });
      throw new Error('deveria ter lançado ConflictException');
    } catch (error) {
      expect(error).toBeInstanceOf(ConflictException);
      expect((error as ConflictException).getStatus()).toBe(409);
      expect((error as ConflictException).getResponse()).toMatchObject({
        suggestedSlug: 'home-2',
      });
    }
  });

  it('projeto sem categoria "Geral" e sem categoryId no corpo falha alto, nunca cria conteúdo órfão', async () => {
    const prisma = createPrismaMock();
    prisma.category.findFirst.mockResolvedValue(null);

    await expect(
      serviceWith(prisma).create('project-1', { name: 'Home', slug: 'home' }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});

describe('ContentsService.listVersions — paginação por cursor', () => {
  it('devolve a página em ordem decrescente e um cursor que decodifica a última linha', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(contentRow());
    prisma.contentVersion.findMany.mockResolvedValue(
      [5, 4, 3].map((version) => ({
        id: `version-${version}`,
        version,
        note: null,
        createdAt: NOW,
        createdBy: null,
      })),
    );

    const result = await serviceWith(prisma).listVersions('project-1', 'content-1', {
      limit: 2,
    } as never);

    expect(result.data.map((row) => row.version)).toEqual([5, 4]);
    expect(decodeCursor(result.nextCursor as string)).toEqual({ value: '4', id: 'version-4' });
  });

  it('usa o cursor recebido para pedir só versões abaixo do valor decodificado', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(contentRow());
    prisma.contentVersion.findMany.mockResolvedValue([]);

    await serviceWith(prisma).listVersions('project-1', 'content-1', {
      cursor: encodeCursor('4', 'version-4'),
      limit: 2,
    } as never);

    const findManyArgs = prisma.contentVersion.findMany.mock.calls[0][0];
    expect(findManyArgs.where).toEqual({ contentId: 'content-1', version: { lt: 4 } });
  });

  it('sem próxima página, nextCursor vem nulo', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(contentRow());
    prisma.contentVersion.findMany.mockResolvedValue([
      { id: 'version-1', version: 1, note: null, createdAt: NOW, createdBy: null },
    ]);

    const result = await serviceWith(prisma).listVersions('project-1', 'content-1', {
      limit: 20,
    } as never);

    expect(result.nextCursor).toBeNull();
  });
});
