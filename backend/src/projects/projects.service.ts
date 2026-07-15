import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { ProcessedImage } from './image-pipeline';

type ProjectRow = {
  id: string;
  title: string;
  description: string | null;
  imageKey: string | null;
  archivedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  _count?: { contents: number; categories: number };
};

const COUNTS_SELECT = {
  _count: { select: { contents: true, categories: true } },
} as const;

const PROJECT_SELECT = {
  id: true,
  title: true,
  description: true,
  imageKey: true,
  archivedAt: true,
  createdAt: true,
  updatedAt: true,
  ...COUNTS_SELECT,
} as const;

export type ProjectStatus = 'active' | 'archived';

const mediaPrefix = (projectId: string) => `${projectId}/midias`;

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async list(_projectId: string, status: ProjectStatus = 'active') {
    const rows = await this.prisma.project.findMany({
      where: status === 'active' ? { archivedAt: null } : { archivedAt: { not: null } },
      orderBy: status === 'active' ? { updatedAt: 'desc' } : { archivedAt: 'desc' },
      select: PROJECT_SELECT,
    });
    return rows.map((row) => this.toSummary(row));
  }

  async create(dto: CreateProjectDto, image?: ProcessedImage) {
    // O storage não é transacional: o objeto órfão é desfeito no catch.
    let imageKey: string | null = null;
    try {
      const row = await this.prisma.$transaction(async (tx) => {
        const created = await tx.project.create({
          data: {
            title: dto.title,
            description: dto.description,
          },
        });
        if (image) {
          imageKey = await this.storage.put(
            image.buffer,
            image.contentType,
            mediaPrefix(created.id),
          );
          await tx.project.update({
            where: { id: created.id },
            data: { imageKey },
          });
        }
        // `Content.categoryId` é NOT NULL e cai na "Geral" por default: sem
        // esta categoria, todo POST de conteúdo do projeto falha.
        await tx.category.create({
          data: {
            projectId: created.id,
            name: 'Geral',
            slug: 'geral',
            parentId: null,
          },
        });
        return { ...created, imageKey };
      });
      return this.toSummary({
        ...row,
        _count: { contents: 0, categories: 1 },
      });
    } catch (error) {
      if (imageKey) await this.storage.delete(imageKey);
      throw error;
    }
  }

  async find(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      select: PROJECT_SELECT,
    });
    if (!project) throw new NotFoundException();
    return this.toSummary(project);
  }

  async update(id: string, dto: UpdateProjectDto, image?: ProcessedImage) {
    const current = await this.prisma.project.findUnique({ where: { id } });
    if (!current) throw new NotFoundException();

    const removeImage = dto.removeImage === 'true' && !image;
    let imageKey = current.imageKey;
    if (image) {
      imageKey = await this.storage.put(
        image.buffer,
        image.contentType,
        mediaPrefix(id),
      );
    } else if (removeImage) {
      imageKey = null;
    }

    const oldImageKey = current.imageKey;
    const shouldDeleteOldImage =
      oldImageKey !== null && oldImageKey !== imageKey;

    const row = await this.prisma.project.update({
      where: { id },
      data: {
        ...(dto.title !== undefined ? { title: dto.title } : {}),
        ...(dto.description !== undefined
          ? { description: dto.description }
          : {}),
        ...(image || removeImage ? { imageKey } : {}),
      },
      select: PROJECT_SELECT,
    });

    if (shouldDeleteOldImage) {
      await this.storage.delete(oldImageKey);
    }

    return this.toSummary(row);
  }

  async archive(id: string) {
    const current = await this.prisma.project.findUnique({ where: { id } });
    if (!current) throw new NotFoundException();
    if (current.archivedAt) return this.find(id);

    const row = await this.prisma.project.update({
      where: { id },
      data: { archivedAt: new Date() },
      select: PROJECT_SELECT,
    });
    return this.toSummary(row);
  }

  async unarchive(id: string) {
    const current = await this.prisma.project.findUnique({ where: { id } });
    if (!current) throw new NotFoundException();
    if (!current.archivedAt) return this.find(id);

    const row = await this.prisma.project.update({
      where: { id },
      data: { archivedAt: null },
      select: PROJECT_SELECT,
    });
    return this.toSummary(row);
  }

  /**
   * Exclusão física em cascata — só permitida com o projeto já arquivado
   * (o usuário passa por "arquivar" antes; ver `archive`). Uma vez
   * arquivado, apaga tudo (conteúdos → categorias → projeto) numa única
   * `$transaction`, contornando o `onDelete: Restrict` do schema (que segue
   * intacto para o fluxo normal — só esta rota, com o projeto já arquivado,
   * cascateia explicitamente).
   */
  async remove(id: string) {
    const current = await this.prisma.project.findUnique({ where: { id } });
    if (!current) throw new NotFoundException();

    if (!current.archivedAt) {
      throw new ConflictException({
        statusCode: 409,
        error: 'Conflict',
        message: 'arquive o projeto antes de excluir',
      });
    }

    await this.prisma.$transaction([
      this.prisma.content.deleteMany({ where: { projectId: id } }),
      this.prisma.category.deleteMany({ where: { projectId: id } }),
      this.prisma.project.delete({ where: { id } }),
    ]);

    if (current.imageKey) {
      await this.storage.delete(current.imageKey);
    }
  }

  /** Lê o binário guardado (usado pela rota de serving, que fixa o content-type). */
  async getImage(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      select: { imageKey: true },
    });
    if (!project || !project.imageKey) throw new NotFoundException();
    const object = await this.storage.get(project.imageKey);
    if (!object) throw new NotFoundException();
    return object;
  }

  private toSummary(row: ProjectRow) {
    return {
      id: row.id,
      title: row.title,
      ...(row.description !== null ? { description: row.description } : {}),
      imageUrl: row.imageKey ? `/v1/projects/${row.id}/image` : null,
      archivedAt: row.archivedAt ? row.archivedAt.toISOString() : null,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      contentCount: row._count?.contents ?? 0,
      categoryCount: row._count?.categories ?? 0,
    };
  }
}
