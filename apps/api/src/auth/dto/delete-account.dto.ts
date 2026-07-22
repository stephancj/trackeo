import { IsString, MinLength } from 'class-validator';

export class DeleteAccountDto {
  @IsString()
  @MinLength(6, { message: 'Mot de passe invalide' })
  password: string;
}
