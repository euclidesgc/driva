import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

type CategoryRow = {
  id: string;
  name: string;
  slug: string;
  parentId: string | null;
  projectId: string;
};

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(projectId: string) {
    const rows = await this.prisma.category.findMany({
      where: { projectId },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        parentId: true,
        projectId: true,
      },
    });
    return rows.map((row) => this.toSummary(row));
  }

  async create(projectId: string, dto: CreateCategoryDto) {
    if (dto.parentId !== undefined) {
      await this.assertParentInProject(projectId, dto.parentId);
    }
    const slug = this.slugify(dto.name);
    try {
      const row = await this.prisma.category.create({
        data: {
          projectId,
          name: dto.name,
          slug,
          parentId: dto.parentId ?? null,
        },
        select: {
          id: true,
          name: true,
          slug: true,
          parentId: true,
          projectId: true,
        },
      });
      return this.toSummary(row);
    } catch (error) {
      if (this.isSlugConflict(error)) {
        return this.throwSlugConflict(projectId, slug);
      }
      throw error;
    }
  }

  async update(projectId: string, id: string, dto: UpdateCategoryDto) {
    const current = await this.prisma.category.findFirst({
      where: { id, projectId },
    });
    if (!current) throw new NotFoundException();

    // `undefined` (chave ausente) = preserva o parentId atual; `null`
    // explícito = vira raiz; string = move para o novo pai (validado
    // abaixo). `class-transformer` preserva essa distinção no valor mesmo
    // quando a chave não veio no JSON (`plainToInstance` não força `null`).
    const movingParent = dto.parentId !== undefined;
    const newParentId = dto.parentId;
    if (movingParent && newParentId !== null && newParentId !== undefined) {
      await this.assertParentInProject(projectId, newParentId);
      await this.assertNoCycle(id, newParentId);
    }

    try {
      const row = await this.prisma.category.update({
        where: { id },
        data: {
          ...(dto.name !== undefined ? { name: dto.name } : {}),
          ...(movingParent ? { parentId: dto.parentId ?? null } : {}),
        },
        select: {
          id: true,
          name: true,
          slug: true,
          parentId: true,
          projectId: true,
        },
      });
      return this.toSummary(row);
    } catch (error) {
      if (this.isSlugConflict(error)) {
        return this.throwSlugConflict(projectId, current.slug);
      }
      throw error;
    }
  }

  async remove(projectId: string, id: string) {
    const current = await this.prisma.category.findFirst({
      where: { id, projectId },
    });
    if (!current) throw new NotFoundException();

    const [contentCount, childrenCount] = await Promise.all([
      this.prisma.content.count({ where: { categoryId: id } }),
      this.prisma.category.count({ where: { parentId: id } }),
    ]);
    if (contentCount > 0 || childrenCount > 0) {
      throw new ConflictException({
        statusCode: 409,
        error: 'Conflict',
        message:
          'categoria tem conteúdos ou subcategorias; mova ou apague antes',
      });
    }

    await this.prisma.category.delete({ where: { id } });
  }

  private async assertParentInProject(
    projectId: string,
    parentId: string,
  ): Promise<void> {
    const parent = await this.prisma.category.findFirst({
      where: { id: parentId, projectId },
      select: { id: true },
    });
    if (!parent) {
      throw new BadRequestException(
        'parentId inexistente ou de outro projeto',
      );
    }
  }

  /** Impede que uma categoria vire pai de um dos seus próprios ancestrais/dela mesma. */
  private async assertNoCycle(
    id: string,
    newParentId: string,
  ): Promise<void> {
    if (id === newParentId) {
      throw new BadRequestException('uma categoria não pode ser pai de si mesma');
    }
    let cursor: string | null = newParentId;
    const seen = new Set<string>();
    while (cursor) {
      if (cursor === id) {
        throw new BadRequestException(
          'parentId não pode ser um descendente da própria categoria',
        );
      }
      if (seen.has(cursor)) break; // proteção contra ciclo pré-existente
      seen.add(cursor);
      const node: { parentId: string | null } | null =
        await this.prisma.category.findUnique({
          where: { id: cursor },
          select: { parentId: true },
        });
      cursor = node?.parentId ?? null;
    }
  }

  private toSummary(row: CategoryRow) {
    return {
      id: row.id,
      name: row.name,
      slug: row.slug,
      parentId: row.parentId,
      projectId: row.projectId,
    };
  }

  private slugify(name: string): string {
    return name
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  private isSlugConflict(error: unknown): boolean {
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    );
  }

  private async throwSlugConflict(
    projectId: string,
    slug: string,
  ): Promise<never> {
    const suggestedSlug = await this.freeSlug(projectId, slug);
    throw new ConflictException({
      statusCode: 409,
      error: 'Conflict',
      message: 'já existe uma categoria com esse nome neste projeto',
      suggestedSlug,
    });
  }

  private async freeSlug(projectId: string, base: string): Promise<string> {
    const rows = await this.prisma.category.findMany({
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
