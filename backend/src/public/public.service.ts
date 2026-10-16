import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type PublishedContent = {
  id: string;
  name: string;
  slug: string;
  projectId: string;
  updatedAt: Date;
  spec: unknown;
  theme: unknown | null;
  themeUpdatedAt: Date | null;
};

export type PublishedSummary = {
  id: string;
  name: string;
  slug: string;
  updatedAt: Date;
};

type PublishingProject = {
  id: string;
  theme: Prisma.JsonValue | null;
  themeUpdatedAt: Date | null;
};

const LIST_LIMIT = 100;

@Injectable()
export class PublicService {
  constructor(private readonly prisma: PrismaService) {}

  async list(publishableKey: string): Promise<PublishedSummary[]> {
    const { id: projectId } = await this.projectFor(publishableKey);

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
    const project = await this.projectFor(publishableKey);

    const content = await this.prisma.content.findFirst({
      where: { projectId: project.id, slug, publishedVersionId: { not: null } },
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
      theme: project.theme,
      themeUpdatedAt: project.themeUpdatedAt,
    };
  }

  // Sem tema gravado o ETag fica no formato anterior ao tema, para os apps
  // já em produção continuarem recebendo 304 dos caches que guardaram.
  etagOf(content: PublishedContent): string {
    const published = `${content.id}-${content.updatedAt.getTime()}`;
    if (!content.themeUpdatedAt) return `"${published}"`;
    return `"${published}-t${content.themeUpdatedAt.getTime()}"`;
  }

  // Chave inválida devolve 404, não 401: a resposta não distingue "chave
  // errada" de "conteúdo inexistente" para quem sonda de fora.
  private async projectFor(publishableKey: string): Promise<PublishingProject> {
    const project = await this.prisma.project.findFirst({
      where: { publishableKey, archivedAt: null },
      select: { id: true, theme: true, themeUpdatedAt: true },
    });
    if (!project) throw new NotFoundException();
    return project;
  }
}
