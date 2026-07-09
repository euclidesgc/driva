import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { decodeCursor, encodeCursor } from './cursor';
import { CreateContentDto } from './dto/create-content.dto';
import {
  ListContentsQueryDto,
  SortField,
  SortOrder,
} from './dto/list-contents.query.dto';
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
};

type SortableRow = ContentRow & { createdAt: Date };

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

    const q = query.q?.trim();
    if (q) {
      where.nameNormalized = {
        contains: normalizeName(q),
        mode: 'insensitive',
      };
    }

    if (query.cursor) {
      const { value, id } = decodeCursor(query.cursor);
      const cursorField = this.cursorFieldFor(sort, value);
      // Keyset: continua estritamente APÓS o par (campo_sort, id) do cursor,
      // respeitando a direção. Empates no campo de sort são desempatados
      // pelo id (Decisão 5 do prd.md de docs/08).
      const isAfter = order === 'asc';
      where.OR = [
        { [sort]: isAfter ? { gt: cursorField } : { lt: cursorField } },
        {
          [sort]: { equals: cursorField },
          id: isAfter ? { gt: id } : { lt: id },
        },
      ];
    }

    const rows = await this.prisma.content.findMany({
      where,
      orderBy: [{ [sort]: order }, { id: order }],
      take: limit + 1,
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        categoryId: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last
        ? encodeCursor(this.sortValueOf(last, sort), last.id)
        : null;

    return {
      data: page.map((row) => this.toSummary(row)),
      nextCursor,
    };
  }

  async create(projectId: string, dto: CreateContentDto) {
    const categoryId = await this.resolveCategoryId(projectId, dto.categoryId);
    try {
      // O id é CUID2 cunhado pelo Prisma no insert; o spec precisa referenciar
      // esse mesmo id, então nasce após a linha existir e é preenchido em
      // seguida (o backend não interpreta o spec — só o monta válido de saída).
      const row = await this.prisma.$transaction(async (tx) => {
        const created = await tx.content.create({
          data: {
            projectId,
            categoryId,
            name: dto.name,
            nameNormalized: normalizeName(dto.name),
            slug: dto.slug,
            description: dto.description,
            spec: {},
          },
          select: { id: true },
        });
        // Conteúdo novo nasce VAZIO (sem `root`): o primeiro widget adicionado
        // no editor vira a raiz, de qualquer tipo. O backend não interpreta o
        // spec — só o monta válido de saída.
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
          data: { spec },
          select: {
            id: true,
            name: true,
            slug: true,
            description: true,
            categoryId: true,
            updatedAt: true,
          },
        });
      });
      return this.toSummary(row);
    } catch (error) {
      if (this.isSlugConflict(error)) {
        return this.throwSlugConflict(projectId, dto.slug);
      }
      throw error;
    }
  }

  async find(projectId: string, id: string) {
    const content = await this.prisma.content.findFirst({
      where: { id, projectId },
    });
    if (!content) throw new NotFoundException();
    return {
      id: content.id,
      name: content.name,
      slug: content.slug,
      ...(content.description !== null
        ? { description: content.description }
        : {}),
      categoryId: content.categoryId,
      spec: content.spec,
      updatedAt: content.updatedAt,
    };
  }

  async update(projectId: string, id: string, dto: UpdateContentDto) {
    if (dto.spec !== undefined && dto.spec['specVersion'] !== SPEC_VERSION) {
      throw new BadRequestException(
        `spec.specVersion precisa ser ${SPEC_VERSION}`,
      );
    }
    // `categoryId` presente move o conteúdo (validado); omitido preserva a
    // categoria atual (não força "Geral" — só o POST tem esse fallback).
    const categoryId =
      dto.categoryId !== undefined
        ? await this.assertCategoryInProject(projectId, dto.categoryId)
        : undefined;
    try {
      const result = await this.prisma.content.updateMany({
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
            ? { spec: dto.spec as Prisma.InputJsonValue }
            : {}),
        },
      });
      if (result.count === 0) throw new NotFoundException();
    } catch (error) {
      if (dto.slug !== undefined && this.isSlugConflict(error)) {
        return this.throwSlugConflict(projectId, dto.slug);
      }
      throw error;
    }
  }

  async remove(projectId: string, id: string) {
    const result = await this.prisma.content.deleteMany({
      where: { id, projectId },
    });
    if (result.count === 0) throw new NotFoundException();
  }

  /** POST sem `categoryId` -> "Geral" do projeto; com `categoryId` -> valida. */
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
      // Não deveria acontecer (seed garante a "Geral" por projeto), mas
      // falha de forma tratada em vez de violar a FK NOT NULL com erro cru.
      throw new BadRequestException(
        'projeto sem categoria "Geral" — contate o suporte',
      );
    }
    return geral.id;
  }

  /** Garante que `categoryId` existe E é do mesmo projeto (não vaza entre tenants). */
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

  private toSummary(row: ContentRow) {
    return {
      id: row.id,
      name: row.name,
      slug: row.slug,
      ...(row.description !== null ? { description: row.description } : {}),
      categoryId: row.categoryId,
      updatedAt: row.updatedAt,
    };
  }

  private isSlugConflict(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }

  // O corpo do 409 carrega um slug livre já calculado (`suggestedSlug`): o
  // editor consome esse campo direto e só deriva localmente quando ausente.
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
