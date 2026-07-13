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

  // Presente -> move o conteúdo de categoria (validado: existe E é do mesmo
  // projeto). Omitido -> preserva a categoria atual, NÃO força "Geral"
  // (Decisão 3 do prd.md de docs/08 — só o POST tem esse fallback).
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  categoryId?: string;
}
