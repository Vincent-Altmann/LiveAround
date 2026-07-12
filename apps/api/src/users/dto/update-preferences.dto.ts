import { Transform } from 'class-transformer';
import {
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class UpdatePreferencesDto {
  @IsOptional()
  @Transform(({ value }) => {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string' && value.length > 0) {
      return value.split(',').map((item) => item.trim());
    }
    return [];
  })
  @IsArray()
  @IsString({ each: true })
  preferredGenres?: string[];

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsNumber()
  @Min(1)
  @Max(200)
  preferredRadiusKm?: number;
}
