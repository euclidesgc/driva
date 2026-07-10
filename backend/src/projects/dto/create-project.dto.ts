import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateProjectDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  description?: string;

  // `image` é um `file` do multipart, tratado pelo `FileInterceptor` e pelo
  // pipeline de segurança (`image-pipeline.ts`) — não entra no DTO.
}
