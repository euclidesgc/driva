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

  /**
   * O spec é JSON opaco (o kernel de validação é o `sdui_core`, em Dart).
   * Aqui só a checagem estrutural mínima: objeto com specVersion suportada.
   */
  @IsOptional()
  @IsObject()
  spec?: Record<string, unknown>;
}
