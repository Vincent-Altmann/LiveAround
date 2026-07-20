import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class DeleteAccountDto {
  // Optionnel uniquement pour les anciens comptes de developpement sans mot
  // de passe ; exige et verifie des qu'un mot de passe existe.
  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password?: string;
}
