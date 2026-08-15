import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type PublishedContent = {
  id: string;
  name: string;
  slug: string;
  projectId: string;
  updatedAt: Date;
  spec: unknown;
};

export type PublishedSummary = {
  id: string;
  name: string;
  slug: string;
  updatedAt: Date;
};

const LIST_LIMIT = 100;

@Injectable()
export class PublicService {
  constructor(private readonly prisma: PrismaService) {}

  async list(publishableKey: string): Promise<PublishedSummary[]> {
    const projectId = await this.projectIdFor(publishableKey);

    return this.prisma.content.findMany({
      where: { projectId },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      take: LIST_LIMIT,
      select: { id: true, name: true, slug: true, updatedAt: true },
    });
  }

  async findBySlug(
    publishableKey: string,
    slug: string,
  ): Promise<PublishedContent> {
    const projectId = await this.projectIdFor(publishableKey);

    const content = await this.prisma.content.findFirst({
      where: { projectId, slug },
      select: {
        id: true,
        name: true,
        slug: true,
        projectId: true,
        updatedAt: true,
        spec: true,
      },
    });
    if (!content) throw new NotFoundException();

    return content;
  }

  etagOf(content: PublishedContent): string {
    return `"${content.id}-${content.updatedAt.getTime()}"`;
  }

  // Chave inválida devolve 404, não 401: a resposta não distingue "chave
  // errada" de "conteúdo inexistente" para quem sonda de fora.
  private async projectIdFor(publishableKey: string): Promise<string> {
    const project = await this.prisma.project.findFirst({
      where: { publishableKey, archivedAt: null },
      select: { id: true },
    });
    if (!project) throw new NotFoundException();
    return project.id;
  }
}
