import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  Matches,
} from 'class-validator';

export class RegisterDto {
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @IsString()
  @MinLength(8, { message: 'Mot de passe trop court (8 caractères minimum)' })
  password: string;

  @IsString()
  @Matches(/^(?:\+?261|0)\d{9}$/, {
    message: 'Numéro invalide (ex : +261341234567)',
  })
  phone: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  referralCode?: string;
}
