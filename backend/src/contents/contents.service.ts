import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateContentDto } from './dto/create-content.dto';
import { UpdateContentDto } from './dto/update-content.dto';

const SPEC_VERSION = 1;

type ContentRow = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  updatedAt: Date;
};

@Injectable()
export class ContentsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(projectId: string) {
    const rows = await this.prisma.content.findMany({
      where: { projectId },
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        updatedAt: true,
      },
    });
    return rows.map((row) => this.toSummary(row));
  }

  async create(projectId: string, dto: CreateContentDto) {
    try {
      // O id é CUID2 cunhado pelo Prisma no insert; o spec precisa referenciar
      // esse mesmo id, então nasce após a linha existir e é preenchido em
      // seguida (o backend não interpreta o spec — só o monta válido de saída).
      const row = await this.prisma.$transaction(async (tx) => {
        const created = await tx.content.create({
          data: {
            projectId,
            name: dto.name,
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
    try {
      const result = await this.prisma.content.updateMany({
        where: { id, projectId },
        data: {
          ...(dto.name !== undefined ? { name: dto.name } : {}),
          ...(dto.slug !== undefined ? { slug: dto.slug } : {}),
          ...(dto.description !== undefined
            ? { description: dto.description }
            : {}),
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

  private toSummary(row: ContentRow) {
    return {
      id: row.id,
      name: row.name,
      slug: row.slug,
      ...(row.description !== null ? { description: row.description } : {}),
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
