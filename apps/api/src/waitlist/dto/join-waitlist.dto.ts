import { Transform } from 'class-transformer';
import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class JoinWaitlistDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail(
    { allow_utf8_local_part: false, require_tld: true },
    { message: 'Adresse email invalide' },
  )
  @MaxLength(320)
  email: string;

  @IsString()
  @MinLength(1, { message: 'La vérification anti-robot est requise' })
  @MaxLength(2048)
  captchaToken: string;
}
