import {
  Controller,
  Get,
  Headers,
  NotFoundException,
  Param,
  Res,
} from '@nestjs/common';
import { Response } from 'express';
import { PublicService } from './public.service';

export const PUBLISHABLE_KEY_HEADER = 'x-driva-key';

@Controller('public/contents')
export class PublicController {
  constructor(private readonly published: PublicService) {}

  @Get()
  async list(@Headers(PUBLISHABLE_KEY_HEADER) publishableKey?: string) {
    const rows = await this.published.list(this.keyOf(publishableKey));
    return {
      data: rows.map((row) => ({
        id: row.id,
        name: row.name,
        slug: row.slug,
        updatedAt: row.updatedAt.toISOString(),
      })),
    };
  }

  @Get(':slug')
  async findBySlug(
    @Param('slug') slug: string,
    @Res() res: Response,
    @Headers(PUBLISHABLE_KEY_HEADER) publishableKey?: string,
    @Headers('if-none-match') ifNoneMatch?: string,
  ): Promise<void> {
    const content = await this.published.findBySlug(
      this.keyOf(publishableKey),
      slug,
    );
    const etag = this.published.etagOf(content);

    res.setHeader('ETag', etag);
    res.setHeader('Cache-Control', 'public, max-age=60, must-revalidate');

    if (ifNoneMatch === etag) {
      res.status(304).end();
      return;
    }

    res.status(200).json({
      id: content.id,
      name: content.name,
      slug: content.slug,
      updatedAt: content.updatedAt.toISOString(),
      spec: content.spec,
    });
  }

  private keyOf(header?: string): string {
    const key = header?.trim();
    if (!key) throw new NotFoundException();
    return key;
  }
}
