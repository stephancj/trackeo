import { Transform } from 'class-transformer';
import { IsEmail, MaxLength } from 'class-validator';

export class JoinWaitlistDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail({}, { message: 'Adresse email invalide' })
  @MaxLength(320)
  email: string;
}
