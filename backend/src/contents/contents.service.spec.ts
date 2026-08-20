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
    contentCheckpoint: {
      create: jest.fn(),
      findMany: jest.fn().mockResolvedValue([]),
      findFirst: jest.fn(),
    },
    contentVersion: {
      aggregate: jest.fn().mockResolvedValue({ _max: { version: null } }),
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      updateManyAndReturn: jest.fn().mockResolvedValue([]),
      upsert: jest.fn().mockResolvedValue({}),
      createMany: jest.fn().mockResolvedValue({ count: 0 }),
      createManyAndReturn: jest.fn().mockResolvedValue([]),
      delete: jest.fn().mockResolvedValue({}),
      deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
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

describe('ContentsService.update — checkpoint no salvar', () => {
  const spec = { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' };

  it('salvar sem nota não marca nada no histórico', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 1 });
    prisma.content.findFirst.mockResolvedValue(contentRow());
    prisma.contentVersion.findMany.mockResolvedValue([]);

    await serviceWith(prisma).update('project-1', 'content-1', { spec });

    expect(prisma.contentCheckpoint.create).not.toHaveBeenCalled();
  });

  it('salvar com nota marca um ponto, com o spec que o save gravou', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 1 });
    prisma.content.findFirst.mockResolvedValue(contentRow({ draftSpec: spec }));
    prisma.contentVersion.findMany.mockResolvedValue([]);

    await serviceWith(prisma).update('project-1', 'content-1', {
      spec,
      checkpointNote: 'antes de mexer no banner',
    });

    expect(prisma.contentCheckpoint.create).toHaveBeenCalledWith({
      data: {
        contentId: 'content-1',
        spec,
        note: 'antes de mexer no banner',
      },
    });
  });

  it('o checkpoint usa o spec lido de volta, não o do corpo — cobre o save que só renomeia', async () => {
    const prisma = createPrismaMock();
    const specNoBanco = { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' };
    prisma.content.updateMany.mockResolvedValue({ count: 1 });
    prisma.content.findFirst.mockResolvedValue(contentRow({ draftSpec: specNoBanco }));
    prisma.contentVersion.findMany.mockResolvedValue([]);

    await serviceWith(prisma).update('project-1', 'content-1', {
      name: 'Home renomeada',
      checkpointNote: 'só o nome',
    });

    expect(prisma.contentCheckpoint.create).toHaveBeenCalledWith({
      data: { contentId: 'content-1', spec: specNoBanco, note: 'só o nome' },
    });
  });

  it('salvar e marcar acontecem na mesma transação', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 1 });
    prisma.content.findFirst.mockResolvedValue(contentRow({ draftSpec: spec }));
    prisma.contentVersion.findMany.mockResolvedValue([]);

    await serviceWith(prisma).update('project-1', 'content-1', {
      spec,
      checkpointNote: 'ponto',
    });

    // Um checkpoint órfão de um save que falhou apontaria para um estado que
    // nunca existiu.
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
  });

  it('conteúdo de outro projeto não é salvo nem marcado', async () => {
    const prisma = createPrismaMock();
    prisma.content.updateMany.mockResolvedValue({ count: 0 });

    await expect(
      serviceWith(prisma).update('outro-projeto', 'content-1', {
        spec,
        checkpointNote: 'ponto',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.contentCheckpoint.create).not.toHaveBeenCalled();
  });
});

describe('ContentsService.findCheckpoint', () => {
  it('checkpoint de outro conteúdo devolve 404 mesmo com o id certo', async () => {
    const prisma = createPrismaMock();
    prisma.content.findFirst.mockResolvedValue(contentRow());
    prisma.contentCheckpoint.findFirst.mockResolvedValue(null);

    await expect(
      serviceWith(prisma).findCheckpoint('project-1', 'content-1', 'ckpt-de-outro'),
    ).rejects.toBeInstanceOf(NotFoundException);

    // O `contentId` precisa entrar na cláusula: sem ele, quem soubesse um id
    // leria o ponto de trabalho de outro conteúdo.
    expect(prisma.contentCheckpoint.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'ckpt-de-outro', contentId: 'content-1' },
      }),
    );
  });
});

describe('ContentsService.publish', () => {
  it('publicar um rascunho igual ao que está no ar não cria versão e conserva publishedAt', async () => {
    const prisma = createPrismaMock();
    const spec = { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' };
    const row = contentRow({
      draftSpec: spec,
      publishedVersionId: 'version-3',
      publishedAt: NOW,
      // Mais novo que o publish de propósito: salvar sobe este marcador, e
      // um save que só desfaz o que foi digitado deixa o rascunho igual ao
      // ar com timestamp mais novo. Publicar por timestamp criaria aqui uma
      // versão idêntica à v3, num histórico que ninguém pode reescrever.
      draftUpdatedAt: new Date(NOW.getTime() + 60_000),
    });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.findUnique.mockResolvedValue({ version: 3, spec });
    // Deixa o caminho de criação completável mesmo não sendo percorrido em
    // código correto: se a guarda de idempotência sumir, o publish reprova
    // por asserção, não estoura num dublê incompleto antes do expect.
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 3 } });
    prisma.contentVersion.create.mockResolvedValue({
      id: 'version-4',
      version: 4,
      createdAt: NOW,
    });
    prisma.contentVersion.findMany.mockResolvedValue([{ version: 3 }]);

    const result = await serviceWith(prisma).publish('project-1', 'content-1', {});

    expect(prisma.contentVersion.create).not.toHaveBeenCalled();
    expect(result).toEqual({
      publishedVersion: { version: 3, publishedAt: NOW },
      hasUnpublishedChanges: false,
      latestVersion: 3,
    });
    // O marcador do rascunho reconcilia para a próxima leitura nascer limpa,
    // e `publishedAt` fica intocado porque alimenta o ETag da rota pública.
    expect(prisma.content.update).toHaveBeenCalledWith({
      where: { id: 'content-1' },
      data: { draftUpdatedAt: NOW },
    });
  });

  it('a igualdade é semântica: ordem diferente das chaves não conta como mudança', async () => {
    const prisma = createPrismaMock();
    const row = contentRow({
      draftSpec: { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' },
      publishedVersionId: 'version-3',
      publishedAt: NOW,
      draftUpdatedAt: new Date(NOW.getTime() + 60_000),
    });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.findUnique.mockResolvedValue({
      version: 3,
      spec: { slug: 'home', name: 'Home', id: 'content-1', kind: 'content', specVersion: 1 },
    });
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 3 } });
    prisma.contentVersion.create.mockResolvedValue({ id: 'version-4', version: 4, createdAt: NOW });
    prisma.contentVersion.findMany.mockResolvedValue([{ version: 3 }]);

    await serviceWith(prisma).publish('project-1', 'content-1', {});

    expect(prisma.contentVersion.create).not.toHaveBeenCalled();
  });

  it('rascunho diferente do que está no ar cria a próxima versão', async () => {
    const prisma = createPrismaMock();
    const row = contentRow({
      draftSpec: { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home v2', slug: 'home' },
      publishedVersionId: 'version-3',
      publishedAt: NOW,
      draftUpdatedAt: new Date(NOW.getTime() + 60_000),
    });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.findUnique.mockResolvedValue({
      version: 3,
      spec: { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' },
    });
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 3 } });
    prisma.contentVersion.create.mockResolvedValue({ id: 'version-4', version: 4, createdAt: NOW });
    prisma.contentVersion.findMany.mockResolvedValue([{ version: 4 }]);

    const result = await serviceWith(prisma).publish('project-1', 'content-1', {});

    expect(prisma.contentVersion.create).toHaveBeenCalledTimes(1);
    expect(result.publishedVersion?.version).toBe(4);
  });

  it('rascunho igual a uma versão antiga, mas diferente da que está no ar, cria versão nova', async () => {
    const prisma = createPrismaMock();
    const specDaV1 = { specVersion: 1, kind: 'content', id: 'content-1', name: 'Original', slug: 'home' };
    const row = contentRow({
      draftSpec: specDaV1,
      publishedVersionId: 'version-3',
      publishedAt: NOW,
      draftUpdatedAt: new Date(NOW.getTime() + 60_000),
    });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.findUnique.mockResolvedValue({
      version: 3,
      spec: { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' },
    });
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 3 } });
    prisma.contentVersion.create.mockResolvedValue({ id: 'version-4', version: 4, createdAt: NOW });
    prisma.contentVersion.findMany.mockResolvedValue([{ version: 4 }]);

    const result = await serviceWith(prisma).publish('project-1', 'content-1', {});

    // Restaurar a v1 e publicar não faz o ponteiro voltar para a v1: cria a
    // v4 com aquele conteúdo. O histórico é append-only, e é isso que mantém
    // a auditoria linear.
    expect(prisma.contentVersion.create).toHaveBeenCalledTimes(1);
    expect(result.publishedVersion?.version).toBe(4);
  });

  it('conteúdo nunca publicado sempre cria a primeira versão', async () => {
    const prisma = createPrismaMock();
    const row = contentRow({ publishedVersionId: null, publishedAt: null });
    prisma.content.findFirst.mockResolvedValue(row);
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: null } });
    prisma.contentVersion.create.mockResolvedValue({ id: 'version-1', version: 1, createdAt: NOW });
    prisma.contentVersion.findMany.mockResolvedValue([{ version: 1 }]);

    const result = await serviceWith(prisma).publish('project-1', 'content-1', {});

    expect(prisma.contentVersion.findUnique).not.toHaveBeenCalled();
    expect(result.publishedVersion?.version).toBe(1);
  });

  it('tudo que decide o resultado é lido dentro da transação', async () => {
    const prisma = createPrismaMock();
    const spec = { specVersion: 1, kind: 'content', id: 'content-1', name: 'Home', slug: 'home' };
    const row = contentRow({
      draftSpec: spec,
      publishedVersionId: 'version-3',
      publishedAt: NOW,
    });
    prisma.contentVersion.findMany.mockResolvedValue([{ version: 3 }]);

    // O `tx` é um dublê **distinto** do cliente de topo, e só ele sabe
    // responder. O dublê que reaproveita o próprio `prisma` como `tx` deixa
    // um ponto cego: trocar cada `tx.` por `this.prisma.` no serviço manteria
    // a suíte verde, e a garantia transacional — a razão de a idempotência
    // não poder ser furada por um publish concorrente — deixaria de existir
    // sem nenhum teste vermelho.
    const tx = {
      content: { findFirst: jest.fn().mockResolvedValue(row), update: jest.fn() },
      contentVersion: {
        findUnique: jest.fn().mockResolvedValue({ version: 3, spec }),
        aggregate: jest.fn().mockResolvedValue({ _max: { version: 3 } }),
        create: jest.fn(),
      },
    };
    prisma.$transaction.mockImplementation((callback: (client: unknown) => unknown) =>
      callback(tx),
    );
    // O cliente de topo passa a recusar as leituras decisivas: se o serviço
    // usar `this.prisma` em vez de `tx`, o teste falha por exceção.
    prisma.content.findFirst.mockImplementation(() => {
      throw new Error('leitura decisiva fora da transação');
    });
    prisma.contentVersion.findUnique.mockImplementation(() => {
      throw new Error('leitura decisiva fora da transação');
    });

    const service = serviceWith(prisma);
    // `findContentOrThrow`, antes da transação, é a única leitura de topo
    // legítima — devolve a linha e não decide nada.
    prisma.content.findFirst.mockResolvedValueOnce(row);

    await service.publish('project-1', 'content-1', {});

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(tx.content.findFirst).toHaveBeenCalledTimes(1);
    expect(tx.contentVersion.findUnique).toHaveBeenCalledTimes(1);
    expect(tx.content.update).toHaveBeenCalledWith({
      where: { id: 'content-1' },
      data: { draftUpdatedAt: NOW },
    });
    expect(tx.contentVersion.create).not.toHaveBeenCalled();
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
    prisma.contentVersion.aggregate.mockResolvedValue({ _max: { version: 4 } });

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
    expect(prisma.contentVersion.upsert).not.toHaveBeenCalled();
    expect(prisma.contentVersion.createMany).not.toHaveBeenCalled();
    expect(prisma.contentVersion.createManyAndReturn).not.toHaveBeenCalled();
    expect(prisma.contentVersion.updateManyAndReturn).not.toHaveBeenCalled();
    expect(result).toEqual({
      publishedVersion: null,
      hasUnpublishedChanges: true,
      latestVersion: 4,
    });
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
