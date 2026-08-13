import { IsString, Length, MinLength, MaxLength } from 'class-validator';

export class ResetPasswordDto {
  @IsString()
  @Length(32, 128)
  token: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password: string;
}
