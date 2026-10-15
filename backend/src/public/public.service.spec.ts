import type { PrismaService } from '../prisma/prisma.service';
import { PublicService, type PublishedContent } from './public.service';

const PUBLISHED_AT = new Date('2026-10-10T12:00:00.000Z');
const THEME_AT = new Date('2026-10-12T08:30:00.000Z');

const aPublished = (
  overrides: Partial<PublishedContent> = {},
): PublishedContent => ({
  id: 'content-1',
  name: 'Home',
  slug: 'home',
  projectId: 'project-1',
  updatedAt: PUBLISHED_AT,
  spec: { specVersion: 1, kind: 'content' },
  theme: null,
  themeUpdatedAt: null,
  ...overrides,
});

function serviceReading(contentRow: Record<string, unknown>) {
  const prisma = {
    project: {
      findFirst: jest.fn().mockResolvedValue({
        id: 'project-1',
        theme: { colors: { primary: '#FF0000' } },
        themeUpdatedAt: THEME_AT,
      }),
    },
    content: { findFirst: jest.fn().mockResolvedValue(contentRow) },
    contentVersion: {
      findUnique: jest.fn().mockResolvedValue({ spec: { specVersion: 1 } }),
    },
  };
  return new PublicService(prisma as unknown as PrismaService);
}

const publishedRow = (updatedAt: Date) => ({
  id: 'content-1',
  name: 'Home',
  slug: 'home',
  projectId: 'project-1',
  publishedAt: PUBLISHED_AT,
  publishedVersionId: 'version-1',
  updatedAt,
  draftUpdatedAt: updatedAt,
});

describe('PublicService.etagOf', () => {
  const service = new PublicService({} as PrismaService);

  it('sem themeUpdatedAt devolve o formato anterior ao tema', () => {
    const etag = service.etagOf(aPublished());

    expect(etag).toBe(`"content-1-${PUBLISHED_AT.getTime()}"`);
  });

  it('com themeUpdatedAt acrescenta o sufixo -t com o horário do tema', () => {
    const etag = service.etagOf(aPublished({ themeUpdatedAt: THEME_AT }));

    expect(etag).toBe(
      `"content-1-${PUBLISHED_AT.getTime()}-t${THEME_AT.getTime()}"`,
    );
  });

  it('dois horários de tema diferentes dão ETags diferentes', () => {
    const before = service.etagOf(aPublished({ themeUpdatedAt: THEME_AT }));
    const after = service.etagOf(
      aPublished({ themeUpdatedAt: new Date(THEME_AT.getTime() + 1) }),
    );

    expect(after).not.toBe(before);
  });

  it('salvar o rascunho (updatedAt da linha) não muda o ETag do publicado', async () => {
    const beforeDraft = serviceReading(
      publishedRow(new Date('2026-10-13T00:00:00.000Z')),
    );
    const afterDraft = serviceReading(
      publishedRow(new Date('2026-10-14T00:00:00.000Z')),
    );

    const etagBefore = beforeDraft.etagOf(
      await beforeDraft.findBySlug('drv_pub_1', 'home'),
    );
    const etagAfter = afterDraft.etagOf(
      await afterDraft.findBySlug('drv_pub_1', 'home'),
    );

    expect(etagAfter).toBe(etagBefore);
    expect(etagBefore).toBe(
      `"content-1-${PUBLISHED_AT.getTime()}-t${THEME_AT.getTime()}"`,
    );
  });
});
