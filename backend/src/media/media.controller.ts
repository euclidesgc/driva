import {
  BadRequestException,
  Controller,
  Get,
  Header,
  Headers,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import type { Response } from 'express';
import {
  MEDIA_PROXY_CACHE_CONTROL,
  MEDIA_PROXY_THROTTLE,
} from './media.constants';
import { MediaService } from './media.service';

@Controller('media')
export class MediaController {
  constructor(private readonly media: MediaService) {}

  @Get('proxy')
  @UseGuards(ThrottlerGuard)
  @Throttle(MEDIA_PROXY_THROTTLE)
  @Header('X-Content-Type-Options', 'nosniff')
  async proxy(
    @Query('url') url: string | undefined,
    @Res() res: Response,
    @Headers('if-none-match') ifNoneMatch?: string,
  ): Promise<void> {
    if (!url || !url.trim()) {
      throw new BadRequestException('parâmetro `url` é obrigatório.');
    }

    const media = await this.media.fetch(url);

    res.setHeader('Content-Type', media.contentType);
    res.setHeader('ETag', media.etag);
    res.setHeader('Cache-Control', MEDIA_PROXY_CACHE_CONTROL);

    if (ifNoneMatch === media.etag) {
      res.status(304).end();
      return;
    }

    res.status(200).send(media.body);
  }
}
