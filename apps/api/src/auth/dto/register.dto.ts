import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { UserRole } from '../../users/user.entity';

export class RegisterDto {
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @IsString()
  @MinLength(8, { message: 'Mot de passe trop court (8 caractères minimum)' })
  password: string;

  @IsString()
  @IsOptional()
  name?: string;

  @IsEnum(UserRole)
  @IsOptional()
  role?: UserRole;
}
