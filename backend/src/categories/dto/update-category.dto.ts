import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateCategoryDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  // `null` explícito move a categoria para raiz (zera o pai); campo ausente
  // preserva o `parentId` atual — mesma semântica de "omitido preserva" do
  // `categoryId` em UpdateContentDto.
  @IsOptional()
  @IsString()
  parentId?: string | null;
}
