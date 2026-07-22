import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class LoginDto {
  @ValidateIf((dto: LoginDto) => !dto.email)
  @IsString()
  @IsNotEmpty({ message: 'Email ou téléphone requis' })
  identifier?: string;

  /** Compatibilité avec l'interface admin existante. */
  @ValidateIf((dto: LoginDto) => !dto.identifier)
  @IsEmail({}, { message: 'Email invalide' })
  email?: string;

  @IsString()
  @MinLength(6, { message: 'Mot de passe trop court (6 caractères minimum)' })
  password: string;
}
