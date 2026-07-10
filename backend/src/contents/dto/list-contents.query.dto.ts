import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export const SORT_FIELDS = ['updatedAt', 'createdAt', 'name'] as const;
export type SortField = (typeof SORT_FIELDS)[number];

export const SORT_ORDERS = ['asc', 'desc'] as const;
export type SortOrder = (typeof SORT_ORDERS)[number];

export class ListContentsQueryDto {
  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @IsIn(SORT_FIELDS)
  sort: SortField = 'updatedAt';

  @IsOptional()
  @IsIn(SORT_ORDERS)
  order: SortOrder = 'desc';

  @IsOptional()
  @IsString()
  cursor?: string;

  // `limit` chega como string (querystring); `Type(() => Number)` converte
  // antes do `@IsInt`/`@Min`/`@Max` — fora da faixa 1–100 ou não-inteiro =
  // 400 pela ValidationPipe global, sem clamp silencioso (Decisão 8 do
  // prd.md de docs/08).
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 20;
}
