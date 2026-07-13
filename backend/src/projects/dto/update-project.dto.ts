import {
  IsBooleanString,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class UpdateProjectDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  description?: string;

  /**
   * Flag textual do multipart (`"true"`) que remove a imagem atual sem
   * enviar outra. Exclusividade com `image` já é validada no cliente; o
   * service ainda assim é robusto (imagem enviada junto prevalece — ver
   * `projects.service.ts`).
   */
  @IsOptional()
  @IsBooleanString()
  removeImage?: string;
}
