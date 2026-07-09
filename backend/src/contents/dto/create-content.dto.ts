import {
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

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

  // Omitido -> cai na categoria "Geral" do projeto (semeada por projeto).
  // Presente -> validado no service (existe E é do mesmo projeto); inválido
  // ou de outro projeto -> 400 (Decisão 3 do prd.md de docs/08).
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  categoryId?: string;
}
