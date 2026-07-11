import { IsString, MinLength } from 'class-validator';

export class ReportConcertDto {
  @IsString()
  @MinLength(8)
  reason!: string;
}

