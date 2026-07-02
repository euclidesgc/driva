import { IsNotEmpty, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdatePageDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  /**
   * O spec é JSON opaco (o kernel de validação é o `sdui_core`, em Dart).
   * Aqui só a checagem estrutural mínima: objeto com specVersion suportada.
   */
  @IsOptional()
  @IsObject()
  spec?: Record<string, unknown>;
}
