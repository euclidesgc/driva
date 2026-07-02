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
import { CreatePageDto } from './dto/create-page.dto';
import { UpdatePageDto } from './dto/update-page.dto';
import { PagesService } from './pages.service';

/** Escopo de tenant vem do header `x-project-id` (auth real chega no I4). */
const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';

@Controller('pages')
export class PagesController {
  constructor(private readonly pages: PagesService) {}

  @Get()
  list(@Headers('x-project-id') projectId?: string) {
    return this.pages.list(projectOf(projectId));
  }

  @Post()
  create(
    @Body() dto: CreatePageDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.pages.create(projectOf(projectId), dto);
  }

  @Get(':id')
  find(@Param('id') id: string, @Headers('x-project-id') projectId?: string) {
    return this.pages.find(projectOf(projectId), id);
  }

  @Put(':id')
  @HttpCode(200)
  update(
    @Param('id') id: string,
    @Body() dto: UpdatePageDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.pages.update(projectOf(projectId), id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(
    @Param('id') id: string,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.pages.remove(projectOf(projectId), id);
  }
}
