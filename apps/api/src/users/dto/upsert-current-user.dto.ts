import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UpsertCurrentUserDto {
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  deviceId!: string;

  @IsOptional()
  @IsEmail()
  @MaxLength(160)
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  displayName?: string;
}
