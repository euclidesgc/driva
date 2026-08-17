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

    const rows = await this.prisma.content.findMany({
      where: { projectId, publishedVersionId: { not: null } },
      orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
      take: LIST_LIMIT,
      select: { id: true, name: true, slug: true, publishedAt: true },
    });
    return rows.flatMap((row) =>
      row.publishedAt
        ? [{ id: row.id, name: row.name, slug: row.slug, updatedAt: row.publishedAt }]
        : [],
    );
  }

  async findBySlug(
    publishableKey: string,
    slug: string,
  ): Promise<PublishedContent> {
    const projectId = await this.projectIdFor(publishableKey);

    const content = await this.prisma.content.findFirst({
      where: { projectId, slug, publishedVersionId: { not: null } },
      select: {
        id: true,
        name: true,
        slug: true,
        projectId: true,
        publishedAt: true,
        publishedVersionId: true,
      },
    });
    if (!content || !content.publishedVersionId || !content.publishedAt) {
      throw new NotFoundException();
    }

    const version = await this.prisma.contentVersion.findUnique({
      where: { id: content.publishedVersionId },
      select: { spec: true },
    });
    if (!version) throw new NotFoundException();

    return {
      id: content.id,
      name: content.name,
      slug: content.slug,
      projectId: content.projectId,
      // publishedAt, não o updatedAt da linha: o rascunho é tocado por
      // autosave sem que o publicado mude, e o ETag não pode invalidar o
      // cache público por uma edição que ninguém publicou.
      updatedAt: content.publishedAt,
      spec: version.spec,
    };
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
