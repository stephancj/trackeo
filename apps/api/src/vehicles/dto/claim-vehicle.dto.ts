import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class ClaimVehicleDto {
  @IsString()
  @MinLength(4, { message: 'Identifiant de l’appareil trop court' })
  @MaxLength(128)
  serialNumber: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  plate?: string;
}
