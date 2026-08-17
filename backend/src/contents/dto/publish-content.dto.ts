import { IsOptional, IsString, MaxLength } from 'class-validator';

export class PublishContentDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}
