import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Headers,
  HttpCode,
  Param,
  Post,
  Put,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import type { Response } from 'express';
import { ProjectsService } from './projects.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { MAX_UPLOAD_BYTES, processUploadedImage } from './image-pipeline';

/** Escopo de tenant vem do header `x-project-id`, no mesmo padrão de `contents`. */
const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';

// Rate-limit dedicado ao upload (create/update com imagem) — mais restritivo
// que o default global, pois reencode com sharp é a rota mais cara em CPU.
const UPLOAD_THROTTLE = { default: { limit: 10, ttl: 60_000 } };

@Controller('projects')
export class ProjectsController {
  constructor(private readonly projects: ProjectsService) {}

  @Get()
  list(@Headers('x-project-id') projectId?: string) {
    return this.projects.list(projectOf(projectId));
  }

  @Post()
  @UseGuards(ThrottlerGuard)
  @Throttle(UPLOAD_THROTTLE)
  @UseInterceptors(
    FileInterceptor('image', { limits: { fileSize: MAX_UPLOAD_BYTES } }),
  )
  async create(
    @Body() dto: CreateProjectDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const image = file
      ? await processUploadedImage(file.buffer)
      : undefined;
    return this.projects.create(dto, image);
  }

  @Get(':id')
  find(@Param('id') id: string) {
    return this.projects.find(id);
  }

  @Put(':id')
  @HttpCode(200)
  @UseGuards(ThrottlerGuard)
  @Throttle(UPLOAD_THROTTLE)
  @UseInterceptors(
    FileInterceptor('image', { limits: { fileSize: MAX_UPLOAD_BYTES } }),
  )
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateProjectDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file && dto.removeImage === 'true') {
      throw new BadRequestException(
        'não é possível enviar `image` e `removeImage` juntos',
      );
    }
    const image = file
      ? await processUploadedImage(file.buffer)
      : undefined;
    return this.projects.update(id, dto, image);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.projects.remove(id);
  }

  /**
   * Serving seguro da imagem: content-type fixado no valor detectado pelo
   * pipeline no momento do upload (nunca inferido do nome do arquivo/key) +
   * `X-Content-Type-Options: nosniff` — o browser nunca reinterpreta o
   * binário como outro tipo (ex.: HTML/SVG disfarçado).
   */
  @Get(':id/image')
  @Header('X-Content-Type-Options', 'nosniff')
  async getImage(@Param('id') id: string, @Res() res: Response) {
    const { buffer, contentType } = await this.projects.getImage(id);
    res.setHeader('Content-Type', contentType);
    res.send(buffer);
  }
}
