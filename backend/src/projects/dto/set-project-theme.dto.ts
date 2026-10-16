import { IsObject, ValidateIf } from 'class-validator';

export class SetProjectThemeDto {
  @ValidateIf((dto: SetProjectThemeDto) => dto.theme !== null)
  @IsObject({ message: 'theme precisa ser um objeto ou null' })
  theme!: Record<string, unknown> | null;
}
