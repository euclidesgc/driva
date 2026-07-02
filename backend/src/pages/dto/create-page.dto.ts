import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreatePageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  screenTarget: string;
}
