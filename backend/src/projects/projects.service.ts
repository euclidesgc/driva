import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
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
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async list(_projectId: string) {
    const rows = await this.prisma.project.findMany({
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        title: true,
        description: true,
        imageKey: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    return rows.map((row) => this.toSummary(row));
  }

  async create(dto: CreateProjectDto, image?: ProcessedImage) {
    const imageKey = image
      ? await this.storage.put(image.buffer, image.contentType)
      : null;
    // A categoria raiz "Geral" nasce na MESMA transação do projeto (adendo
    // pós-feature-09 do prd.md de docs/08, item 3): como `Content.categoryId`
    // é NOT NULL e o default de escrita é a "Geral", todo projeto precisa
    // da sua "Geral" antes de qualquer POST de conteúdo. Alternativas
    // descartadas: trigger de banco (lógica escondida, difícil de
    // testar/versionar) e seed só na migração (não cobre projetos criados em
    // runtime).
    const row = await this.prisma.$transaction(async (tx) => {
      const created = await tx.project.create({
        data: {
          title: dto.title,
          description: dto.description,
          imageKey,
        },
      });
      await tx.category.create({
        data: {
          projectId: created.id,
          name: 'Geral',
          slug: 'geral',
          parentId: null,
        },
      });
      return created;
    });
    return this.toSummary(row);
  }

  async find(id: string) {
    const project = await this.prisma.project.findUnique({ where: { id } });
    if (!project) throw new NotFoundException();
    return this.toSummary(project);
  }

  async update(id: string, dto: UpdateProjectDto, image?: ProcessedImage) {
    const current = await this.prisma.project.findUnique({ where: { id } });
    if (!current) throw new NotFoundException();

    // Enviar `image` sempre prevalece sobre `removeImage` — robustez do
    // servidor mesmo que o cliente (que já valida exclusividade) mande os
    // dois por engano.
    const removeImage = dto.removeImage === 'true' && !image;
    let imageKey = current.imageKey;
    if (image) {
      imageKey = await this.storage.put(image.buffer, image.contentType);
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
    });

    if (shouldDeleteOldImage) {
      await this.storage.delete(oldImageKey);
    }

    return this.toSummary(row);
  }

  async remove(id: string) {
    const current = await this.prisma.project.findUnique({ where: { id } });
    if (!current) throw new NotFoundException();

    try {
      await this.prisma.project.delete({ where: { id } });
    } catch (error) {
      if (this.isRestrictViolation(error)) {
        throw new ConflictException({
          statusCode: 409,
          error: 'Conflict',
          message:
            'projeto tem conteúdos/categorias; esvazie ou mova antes de apagar',
        });
      }
      throw error;
    }

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
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private isRestrictViolation(error: unknown): boolean {
    // P2003: violação de FK — aqui, `Content.projectId`/`Category.projectId`
    // sob `onDelete: Restrict` (Decisão 1 do prd.md) impedindo o delete de um
    // projeto não-vazio. Nunca deixa o 500 cru do Postgres vazar.
    return (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2003'
    );
  }
}
