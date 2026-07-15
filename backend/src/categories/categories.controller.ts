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
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';

@Controller('categories')
export class CategoriesController {
  constructor(private readonly categories: CategoriesService) {}

  @Get()
  list(@Headers('x-project-id') projectId?: string) {
    return this.categories.list(projectOf(projectId));
  }

  @Post()
  create(
    @Body() dto: CreateCategoryDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.categories.create(projectOf(projectId), dto);
  }

  @Put(':id')
  @HttpCode(200)
  update(
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.categories.update(projectOf(projectId), id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string, @Headers('x-project-id') projectId?: string) {
    return this.categories.remove(projectOf(projectId), id);
  }
}
