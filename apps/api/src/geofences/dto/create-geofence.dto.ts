import {
  IsString,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsArray,
} from 'class-validator';

export class CreateGeofenceDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  deviceIds?: number[];

  @IsNumber()
  centerLat: number;

  @IsNumber()
  centerLon: number;

  @IsNumber()
  radiusM: number;

  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  alertOnEntry?: boolean;

  @IsOptional()
  @IsBoolean()
  alertOnExit?: boolean;

  @IsOptional()
  @IsBoolean()
  alertViaWhatsapp?: boolean;
}

export class UpdateGeofenceDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  deviceIds?: number[];

  @IsOptional()
  @IsNumber()
  centerLat?: number;

  @IsOptional()
  @IsNumber()
  centerLon?: number;

  @IsOptional()
  @IsNumber()
  radiusM?: number;

  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  alertOnEntry?: boolean;

  @IsOptional()
  @IsBoolean()
  alertOnExit?: boolean;

  @IsOptional()
  @IsBoolean()
  alertViaWhatsapp?: boolean;
}
