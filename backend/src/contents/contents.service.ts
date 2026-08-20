import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { decodeCursor, encodeCursor } from './cursor';
import { isSameJsonValue } from './json-equality';
import { CreateContentDto } from './dto/create-content.dto';
import {
  ListContentsQueryDto,
  SortField,
  SortOrder,
} from './dto/list-contents.query.dto';
import { ListVersionsQueryDto } from './dto/list-versions.query.dto';
import { PublishContentDto } from './dto/publish-content.dto';
import { UpdateContentDto } from './dto/update-content.dto';
import { normalizeName } from './name-normalize';

const SPEC_VERSION = 1;
const GERAL_SLUG = 'geral';

type ContentRow = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  categoryId: string;
  updatedAt: Date;
  draftUpdatedAt: Date;
  publishedAt: Date | null;
};

type SortableRow = ContentRow & { createdAt: Date };

type PublishState = { version: number; publishedAt: Date } | null;

const CONTENT_SUMMARY_SELECT = {
  id: true,
  name: true,
  slug: true,
  description: true,
  categoryId: true,
  updatedAt: true,
  draftUpdatedAt: true,
  publishedAt: true,
} as const;

@Injectable()
export class ContentsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(projectId: string, query: ListContentsQueryDto) {
    const sort: SortField = query.sort ?? 'updatedAt';
    const order: SortOrder = query.order ?? 'desc';
    const limit = query.limit ?? 20;

    const where: Prisma.ContentWhereInput = { projectId };

    if (query.categoryId) {
      where.categoryId = query.categoryId;
    }

    // Busca e keyset vão num AND de ORs: um `where.OR` único faria um
    // sobrescrever o outro.
    const and: Prisma.ContentWhereInput[] = [];

    const q = query.q?.trim();
    if (q) {
      and.push({
        OR: [
          {
            nameNormalized: { contains: normalizeName(q), mode: 'insensitive' },
          },
          { slug: { contains: q, mode: 'insensitive' } },
          { id: q },
        ],
      });
    }

    if (query.cursor) {
      const { value, id } = decodeCursor(query.cursor);
      const cursorField = this.cursorFieldFor(sort, value);
      const isAfter = order === 'asc';
      and.push({
        OR: [
          { [sort]: isAfter ? { gt: cursorField } : { lt: cursorField } },
          {
            [sort]: { equals: cursorField },
            id: isAfter ? { gt: id } : { lt: id },
          },
        ],
      });
    }

    if (and.length > 0) {
      where.AND = and;
    }

    const rows = await this.prisma.content.findMany({
      where,
      orderBy: [{ [sort]: order }, { id: order }],
      take: limit + 1,
      select: { ...CONTENT_SUMMARY_SELECT, createdAt: true },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last
        ? encodeCursor(this.sortValueOf(last, sort), last.id)
        : null;

    const latestVersions = await this.latestVersionsFor(
      page.map((row) => row.id),
    );

    return {
      data: page.map((row) =>
        this.toSummary(row, latestVersions.get(row.id) ?? null),
      ),
      nextCursor,
    };
  }

  async create(projectId: string, dto: CreateContentDto) {
    const categoryId = await this.resolveCategoryId(projectId, dto.categoryId);
    try {
      const row = await this.prisma.$transaction(async (tx) => {
        const now = new Date();
        const created = await tx.content.create({
          data: {
            projectId,
            categoryId,
            name: dto.name,
            nameNormalized: normalizeName(dto.name),
            slug: dto.slug,
            description: dto.description,
            draftSpec: {},
            draftUpdatedAt: now,
          },
          select: { id: true },
        });
        const spec = {
          specVersion: SPEC_VERSION,
          kind: 'content',
          id: created.id,
          name: dto.name,
          slug: dto.slug,
          ...(dto.description !== undefined
            ? { description: dto.description }
            : {}),
        };
        return tx.content.update({
          where: { id: created.id },
          data: { draftSpec: spec, draftUpdatedAt: now },
          select: CONTENT_SUMMARY_SELECT,
        });
      });
      return this.toSummary(row, null);
    } catch (error) {
      if (this.isSlugConflict(error)) {
        return this.throwSlugConflict(projectId, dto.slug);
      }
      throw error;
    }
  }

  async find(projectId: string, id: string) {
    const content = await this.findContentOrThrow(projectId, id);
    return {
      id: content.id,
      name: content.name,
      slug: content.slug,
      ...(content.description !== null
        ? { description: content.description }
        : {}),
      categoryId: content.categoryId,
      spec: content.draftSpec,
      publishedVersion: await this.toPublishState(content),
      latestVersion: await this.latestVersionFor(content.id),
      hasUnpublishedChanges: this.hasUnpublishedChanges(content),
      updatedAt: content.updatedAt,
    };
  }

  async update(projectId: string, id: string, dto: UpdateContentDto) {
    if (dto.spec !== undefined && dto.spec['specVersion'] !== SPEC_VERSION) {
      throw new BadRequestException(
        `spec.specVersion precisa ser ${SPEC_VERSION}`,
      );
    }
    const categoryId =
      dto.categoryId !== undefined
        ? await this.assertCategoryInProject(projectId, dto.categoryId)
        : undefined;
    try {
      await this.prisma.$transaction(async (tx) => {
        const result = await tx.content.updateMany({
          where: { id, projectId },
          data: {
            ...(dto.name !== undefined
              ? { name: dto.name, nameNormalized: normalizeName(dto.name) }
              : {}),
            ...(dto.slug !== undefined ? { slug: dto.slug } : {}),
            ...(dto.description !== undefined
              ? { description: dto.description }
              : {}),
            ...(categoryId !== undefined ? { categoryId } : {}),
            ...(dto.spec !== undefined
              ? {
                  draftSpec: dto.spec as Prisma.InputJsonValue,
                  draftUpdatedAt: new Date(),
                }
              : {}),
          },
        });
        if (result.count === 0) throw new NotFoundException();
        if (dto.checkpointNote === undefined) return;

        // O checkpoint guarda o spec que este save gravou, lido de volta por
        // `tx`: usar `dto.spec` deixaria de fora o save que só renomeia, e
        // marcar um ponto no histórico sem o conteúdo do ponto não serve para
        // nada. Na mesma transação do save porque "salvar e marcar" é uma
        // operação só — um checkpoint órfão de um save que falhou apontaria
        // para um estado que nunca existiu.
        const saved = await tx.content.findFirst({
          where: { id, projectId },
          select: { draftSpec: true },
        });
        if (!saved) throw new NotFoundException();
        await tx.contentCheckpoint.create({
          data: {
            contentId: id,
            spec: saved.draftSpec as Prisma.InputJsonValue,
            note: dto.checkpointNote,
          },
        });
      });
    } catch (error) {
      if (dto.slug !== undefined && this.isSlugConflict(error)) {
        return this.throwSlugConflict(projectId, dto.slug);
      }
      throw error;
    }

    const updated = await this.prisma.content.findFirst({
      where: { id, projectId },
      select: CONTENT_SUMMARY_SELECT,
    });
    if (!updated) throw new NotFoundException();
    return this.toSummary(updated, await this.latestVersionFor(updated.id));
  }

  async remove(projectId: string, id: string) {
    const result = await this.prisma.content.deleteMany({
      where: { id, projectId },
    });
    if (result.count === 0) throw new NotFoundException();
  }

  async publish(projectId: string, id: string, dto: PublishContentDto) {
    await this.findContentOrThrow(projectId, id);
    try {
      const now = new Date();
      const outcome = await this.prisma.$transaction(async (tx) => {
        // Tudo que decide o resultado é lido por `tx`: um publish concorrente
        // que entrasse entre a leitura e a escrita produziria duas versões com
        // o mesmo conteúdo, e o histórico é append-only — não há como desfazer.
        const row = await tx.content.findFirst({
          where: { id, projectId },
          select: {
            draftSpec: true,
            publishedVersionId: true,
            publishedAt: true,
          },
        });
        if (!row) throw new NotFoundException();

        const published = row.publishedVersionId
          ? await tx.contentVersion.findUnique({
              where: { id: row.publishedVersionId },
              select: { version: true, spec: true },
            })
          : null;

        // A igualdade é de JSONB, não de timestamp: `draftUpdatedAt` sobe a
        // cada save, inclusive no save que apenas desfaz o que foi digitado.
        // Publicar por timestamp criaria uma versão idêntica à que está no ar
        // — ruído permanente num histórico que ninguém pode reescrever.
        if (
          published &&
          row.publishedAt &&
          isSameJsonValue(row.draftSpec, published.spec)
        ) {
          // O marcador do rascunho reconcilia com o publish que já existe, para
          // a próxima leitura nascer limpa. `publishedAt` não é tocado: ele
          // alimenta o ETag da rota pública, e mexer nele invalidaria o cache
          // de todo app cliente sem que nada tivesse mudado.
          await tx.content.update({
            where: { id },
            data: { draftUpdatedAt: row.publishedAt },
          });
          return {
            version: published.version,
            publishedAt: row.publishedAt,
          };
        }

        const latest = await tx.contentVersion.aggregate({
          where: { contentId: id },
          _max: { version: true },
        });
        const version = await tx.contentVersion.create({
          data: {
            contentId: id,
            version: (latest._max.version ?? 0) + 1,
            spec: row.draftSpec as Prisma.InputJsonValue,
            note: dto.note,
            createdAt: now,
          },
        });
        await tx.content.update({
          where: { id },
          data: {
            publishedVersionId: version.id,
            publishedAt: now,
            draftUpdatedAt: now,
          },
        });
        return { version: version.version, publishedAt: version.createdAt };
      });

      return {
        publishedVersion: {
          version: outcome.version,
          publishedAt: outcome.publishedAt,
        },
        latestVersion: await this.latestVersionFor(id),
        hasUnpublishedChanges: false,
      };
    } catch (error) {
      if (this.isP2002(error)) {
        throw new ConflictException('publicação concorrente, tente de novo');
      }
      throw error;
    }
  }

  async unpublish(projectId: string, id: string) {
    const result = await this.prisma.content.updateMany({
      where: { id, projectId },
      data: { publishedVersionId: null, publishedAt: null },
    });
    if (result.count === 0) throw new NotFoundException();
    return {
      publishedVersion: null,
      latestVersion: await this.latestVersionFor(id),
      hasUnpublishedChanges: true,
    };
  }

  async listVersions(projectId: string, id: string, query: ListVersionsQueryDto) {
    await this.findContentOrThrow(projectId, id);
    const limit = query.limit ?? 20;
    const where: Prisma.ContentVersionWhereInput = { contentId: id };

    if (query.cursor) {
      const { value } = decodeCursor(query.cursor);
      where.version = { lt: Number(value) };
    }

    const rows = await this.prisma.contentVersion.findMany({
      where,
      orderBy: { version: 'desc' },
      take: limit + 1,
      select: {
        id: true,
        version: true,
        note: true,
        createdAt: true,
        createdBy: true,
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last ? encodeCursor(String(last.version), last.id) : null;

    return {
      data: page.map((row) => ({
        version: row.version,
        ...(row.note !== null ? { note: row.note } : {}),
        createdAt: row.createdAt,
        ...(row.createdBy !== null ? { createdBy: row.createdBy } : {}),
      })),
      nextCursor,
    };
  }

  async listCheckpoints(
    projectId: string,
    id: string,
    query: ListVersionsQueryDto,
  ) {
    await this.findContentOrThrow(projectId, id);
    const limit = query.limit ?? 20;
    const where: Prisma.ContentCheckpointWhereInput = { contentId: id };

    // O cursor é a data, e não um número de sequência: checkpoint não tem
    // `version` de propósito — esse número é o que o usuário lê como "no ar
    // (v3)" e só publicação o consome.
    if (query.cursor) {
      const { value } = decodeCursor(query.cursor);
      where.createdAt = { lt: new Date(value) };
    }

    const rows = await this.prisma.contentCheckpoint.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      select: { id: true, note: true, createdAt: true, createdBy: true },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];

    return {
      data: page.map((row) => ({
        id: row.id,
        ...(row.note !== null ? { note: row.note } : {}),
        createdAt: row.createdAt,
        ...(row.createdBy !== null ? { createdBy: row.createdBy } : {}),
      })),
      nextCursor:
        hasMore && last
          ? encodeCursor(last.createdAt.toISOString(), last.id)
          : null,
    };
  }

  async findCheckpoint(projectId: string, id: string, checkpointId: string) {
    await this.findContentOrThrow(projectId, id);
    const row = await this.prisma.contentCheckpoint.findFirst({
      // `contentId` na cláusula, e não só o id do checkpoint: sem ele, quem
      // soubesse um id leria o ponto de trabalho de outro conteúdo — e o
      // dono do conteúdo já foi conferido acima contra o projeto.
      where: { id: checkpointId, contentId: id },
      select: { id: true, spec: true, note: true, createdAt: true, createdBy: true },
    });
    if (!row) throw new NotFoundException();
    return {
      id: row.id,
      spec: row.spec,
      ...(row.note !== null ? { note: row.note } : {}),
      createdAt: row.createdAt,
      ...(row.createdBy !== null ? { createdBy: row.createdBy } : {}),
    };
  }

  async findVersion(projectId: string, id: string, version: number) {
    await this.findContentOrThrow(projectId, id);
    const row = await this.prisma.contentVersion.findUnique({
      where: { contentId_version: { contentId: id, version } },
    });
    if (!row) throw new NotFoundException();
    return {
      version: row.version,
      spec: row.spec,
      ...(row.note !== null ? { note: row.note } : {}),
      createdAt: row.createdAt,
      ...(row.createdBy !== null ? { createdBy: row.createdBy } : {}),
    };
  }

  async restoreVersion(projectId: string, id: string, version: number) {
    await this.findContentOrThrow(projectId, id);
    const target = await this.prisma.contentVersion.findUnique({
      where: { contentId_version: { contentId: id, version } },
      select: { spec: true },
    });
    if (!target) throw new NotFoundException();
    await this.prisma.content.update({
      where: { id },
      data: {
        draftSpec: target.spec as Prisma.InputJsonValue,
        draftUpdatedAt: new Date(),
      },
    });
    return this.find(projectId, id);
  }

  // ContentVersion não carrega project_id próprio (D1: FK solta, join
  // explícito). Todo acesso a contentVersion precisa passar por aqui
  // primeiro para resolver posse — nunca consultar contentVersion direto a
  // partir de um id de content sem confirmar antes que ele é deste projeto.
  private async findContentOrThrow(projectId: string, id: string) {
    const content = await this.prisma.content.findFirst({
      where: { id, projectId },
    });
    if (!content) throw new NotFoundException();
    return content;
  }

  private hasUnpublishedChanges(row: {
    draftUpdatedAt: Date;
    publishedAt: Date | null;
  }): boolean {
    return row.publishedAt === null || row.draftUpdatedAt > row.publishedAt;
  }

  private async toPublishState(row: {
    publishedVersionId: string | null;
    publishedAt: Date | null;
  }): Promise<PublishState> {
    if (!row.publishedVersionId || !row.publishedAt) return null;
    const version = await this.prisma.contentVersion.findUnique({
      where: { id: row.publishedVersionId },
      select: { version: true },
    });
    if (!version) return null;
    return { version: version.version, publishedAt: row.publishedAt };
  }

  private async resolveCategoryId(
    projectId: string,
    categoryId: string | undefined,
  ): Promise<string> {
    if (categoryId !== undefined) {
      return this.assertCategoryInProject(projectId, categoryId);
    }
    const geral = await this.prisma.category.findFirst({
      where: { projectId, slug: GERAL_SLUG, parentId: null },
      select: { id: true },
    });
    if (!geral) {
      throw new BadRequestException(
        'projeto sem categoria "Geral" — contate o suporte',
      );
    }
    return geral.id;
  }

  private async assertCategoryInProject(
    projectId: string,
    categoryId: string,
  ): Promise<string> {
    const category = await this.prisma.category.findFirst({
      where: { id: categoryId, projectId },
      select: { id: true },
    });
    if (!category) {
      throw new BadRequestException(
        'categoryId inexistente ou de outro projeto',
      );
    }
    return category.id;
  }

  private cursorFieldFor(sort: SortField, value: string): string | Date {
    return sort === 'name' ? value : new Date(value);
  }

  private sortValueOf(row: SortableRow, sort: SortField): string {
    if (sort === 'name') return row.name;
    if (sort === 'createdAt') return row.createdAt.toISOString();
    return row.updatedAt.toISOString();
  }

  private toSummary(row: ContentRow, latestVersion: number | null) {
    return {
      id: row.id,
      name: row.name,
      slug: row.slug,
      ...(row.description !== null ? { description: row.description } : {}),
      categoryId: row.categoryId,
      updatedAt: row.updatedAt,
      publishedAt: row.publishedAt,
      hasUnpublishedChanges: this.hasUnpublishedChanges(row),
      latestVersion,
    };
  }

  // A `(sort: Desc)` de `[contentId, version]` (schema.prisma) faz do MAX
  // agregado um lookup pelo índice, não um table scan.
  private async latestVersionFor(contentId: string): Promise<number | null> {
    const latest = await this.prisma.contentVersion.aggregate({
      where: { contentId },
      _max: { version: true },
    });
    return latest._max.version ?? null;
  }

  private async latestVersionsFor(
    contentIds: string[],
  ): Promise<Map<string, number>> {
    if (contentIds.length === 0) return new Map();
    const grouped = await this.prisma.contentVersion.groupBy({
      by: ['contentId'],
      where: { contentId: { in: contentIds } },
      _max: { version: true },
    });
    return new Map(
      grouped
        .filter((row) => row._max.version !== null)
        .map((row) => [row.contentId, row._max.version as number]),
    );
  }

  private isP2002(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }

  private isSlugConflict(error: unknown): boolean {
    return this.isP2002(error);
  }

  private async throwSlugConflict(
    projectId: string,
    slug: string,
  ): Promise<never> {
    const suggestedSlug = await this.freeSlug(projectId, slug);
    throw new ConflictException({
      statusCode: 409,
      error: 'Conflict',
      message: 'slug já em uso neste projeto',
      suggestedSlug,
    });
  }

  private async freeSlug(projectId: string, base: string): Promise<string> {
    const rows = await this.prisma.content.findMany({
      where: {
        projectId,
        OR: [{ slug: base }, { slug: { startsWith: `${base}-` } }],
      },
      select: { slug: true },
    });
    const taken = new Set(rows.map((row) => row.slug));
    if (!taken.has(base)) return base;
    let suffix = 2;
    while (taken.has(`${base}-${suffix}`)) suffix++;
    return `${base}-${suffix}`;
  }
}
