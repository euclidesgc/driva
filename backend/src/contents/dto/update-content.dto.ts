import {
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class UpdateContentDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  @Matches(/^[a-z][a-z0-9-]*$/, {
    message: 'slug precisa casar ^[a-z][a-z0-9-]*$',
  })
  slug?: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  description?: string;

  @IsOptional()
  @IsObject()
  spec?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  categoryId?: string;

  /// Presente, o save também marca um ponto no histórico — o "commit" do
  /// editor. String vazia não conta: um checkpoint sem nota é indistinguível
  /// de qualquer outro save e polui o histórico sem informar nada.
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(280)
  checkpointNote?: string;
}
