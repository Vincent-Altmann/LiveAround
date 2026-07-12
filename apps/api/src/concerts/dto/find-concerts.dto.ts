import { Transform } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class FindConcertsDto {
  @Transform(({ value }) => Number(value))
  @IsNumber()
  latitude!: number;

  @Transform(({ value }) => Number(value))
  @IsNumber()
  longitude!: number;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsNumber()
  @Min(1)
  @Max(200)
  radiusKm = 25;

  @IsOptional()
  @Transform(({ value }) => {
    if (Array.isArray(value)) return value;
    if (typeof value === 'string' && value.length > 0) {
      return value.split(',').map((item) => item.trim());
    }
    return [];
  })
  @IsArray()
  genres: string[] = [];

  @IsOptional()
  @IsDateString()
  from?: string;

  @IsOptional()
  @IsDateString()
  to?: string;

  @IsOptional()
  @IsString()
  query?: string;
}
