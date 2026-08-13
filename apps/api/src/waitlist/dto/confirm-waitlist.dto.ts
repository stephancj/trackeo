import { IsString, MaxLength, MinLength } from 'class-validator';

export class ConfirmWaitlistDto {
  @IsString()
  @MinLength(32)
  @MaxLength(128)
  token: string;
}
