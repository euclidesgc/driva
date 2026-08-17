import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { ContentsService } from './contents.service';
import { CreateContentDto } from './dto/create-content.dto';
import { ListContentsQueryDto } from './dto/list-contents.query.dto';
import { ListVersionsQueryDto } from './dto/list-versions.query.dto';
import { PublishContentDto } from './dto/publish-content.dto';
import { UpdateContentDto } from './dto/update-content.dto';

const projectOf = (header?: string) =>
  header && header.trim().length > 0 ? header.trim() : 'default';

@Controller('contents')
export class ContentsController {
  constructor(private readonly contents: ContentsService) {}

  @Get()
  list(
    @Query() query: ListContentsQueryDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.list(projectOf(projectId), query);
  }

  @Post()
  create(
    @Body() dto: CreateContentDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.create(projectOf(projectId), dto);
  }

  @Get(':id/versions')
  listVersions(
    @Param('id') id: string,
    @Query() query: ListVersionsQueryDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.listVersions(projectOf(projectId), id, query);
  }

  @Get(':id/versions/:version')
  findVersion(
    @Param('id') id: string,
    @Param('version', ParseIntPipe) version: number,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.findVersion(projectOf(projectId), id, version);
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

  @Post(':id/publish')
  @HttpCode(200)
  publish(
    @Param('id') id: string,
    @Body() dto: PublishContentDto,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.publish(projectOf(projectId), id, dto);
  }

  @Post(':id/unpublish')
  @HttpCode(200)
  unpublish(
    @Param('id') id: string,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.unpublish(projectOf(projectId), id);
  }

  @Post(':id/versions/:version/restore')
  @HttpCode(200)
  restoreVersion(
    @Param('id') id: string,
    @Param('version', ParseIntPipe) version: number,
    @Headers('x-project-id') projectId?: string,
  ) {
    return this.contents.restoreVersion(projectOf(projectId), id, version);
  }
}
