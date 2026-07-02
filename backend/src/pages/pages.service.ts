import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePageDto } from './dto/create-page.dto';
import { UpdatePageDto } from './dto/update-page.dto';

const SPEC_VERSION = 1;

@Injectable()
export class PagesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(projectId: string) {
    const pages = await this.prisma.page.findMany({
      where: { projectId },
      orderBy: { updatedAt: 'desc' },
      select: { id: true, name: true, screenTarget: true, updatedAt: true },
    });
    return pages;
  }

  async create(projectId: string, dto: CreatePageDto) {
    // O spec nasce válido: root column vazio, id do spec = id da página.
    const id = crypto.randomUUID();
    const spec = {
      specVersion: SPEC_VERSION,
      kind: 'page',
      id,
      name: dto.name,
      screenTarget: dto.screenTarget,
      root: { id: `nd_root_${id}`, type: 'column' },
    };
    const page = await this.prisma.page.create({
      data: {
        id,
        projectId,
        name: dto.name,
        screenTarget: dto.screenTarget,
        spec,
      },
      select: { id: true, name: true, screenTarget: true, updatedAt: true },
    });
    return page;
  }

  async find(projectId: string, id: string) {
    const page = await this.prisma.page.findFirst({
      where: { id, projectId },
    });
    if (!page) throw new NotFoundException();
    return {
      id: page.id,
      name: page.name,
      screenTarget: page.screenTarget,
      spec: page.spec,
      updatedAt: page.updatedAt,
    };
  }

  async update(projectId: string, id: string, dto: UpdatePageDto) {
    if (dto.spec !== undefined && dto.spec['specVersion'] !== SPEC_VERSION) {
      throw new BadRequestException(
        `spec.specVersion precisa ser ${SPEC_VERSION}`,
      );
    }
    const result = await this.prisma.page.updateMany({
      where: { id, projectId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.spec !== undefined
          ? { spec: dto.spec as Prisma.InputJsonValue }
          : {}),
      },
    });
    if (result.count === 0) throw new NotFoundException();
  }

  async remove(projectId: string, id: string) {
    const result = await this.prisma.page.deleteMany({
      where: { id, projectId },
    });
    if (result.count === 0) throw new NotFoundException();
  }
}
