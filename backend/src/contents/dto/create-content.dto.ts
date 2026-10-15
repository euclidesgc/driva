import {
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export const CONTENT_KINDS = ['content', 'component'] as const;
export type ContentKind = (typeof CONTENT_KINDS)[number];

export class CreateContentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  @Matches(/^[a-z][a-z0-9-]*$/, {
    message: 'slug precisa casar ^[a-z][a-z0-9-]*$',
  })
  slug: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  description?: string;

  @IsOptional()
  @IsIn(CONTENT_KINDS)
  kind?: ContentKind;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  categoryId?: string;
}
