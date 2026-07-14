import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UpsertCurrentUserDto {
  // Conserve pour compatibilite avec d'anciens clients, mais ignore :
  // l'identite provient desormais du jeton de session verifie.
  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  deviceId?: string;

  @IsOptional()
  @IsEmail()
  @MaxLength(160)
  email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  displayName?: string;
}
