import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { ContentsService } from './contents.service';
import { CreateContentDto } from './dto/create-content.dto';
import { UpdateContentDto } from './dto/update-content.dto';

/** Escopo de tenant vem do header `x-project-id` (auth real chega no I4). */
const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';

@Controller('contents')
export class ContentsController {
  constructor(private readonly contents: ContentsService) {}

  @Get()
  list(@Headers('x-project-id') projectId?: string) {
    return this.contents.list(projectOf(projectId));
  }

  @Post()
  create(
    @Body() dto: CreateContentDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.create(projectOf(projectId), dto);
  }

  @Get(':id')
  find(@Param('id') id: string, @Headers('x-project-id') projectId?: string) {
    return this.contents.find(projectOf(projectId), id);
  }

  @Put(':id')
  @HttpCode(200)
  update(
    @Param('id') id: string,
    @Body() dto: UpdateContentDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.update(projectOf(projectId), id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string, @Headers('x-project-id') projectId?: string) {
    return this.contents.remove(projectOf(projectId), id);
  }
}
