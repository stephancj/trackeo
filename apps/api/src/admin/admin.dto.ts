import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
  IsNumber,
  IsArray,
  IsUUID,
  ValidateNested,
  IsDateString,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { UserRole } from '../users/user.entity';
import { FeatureValueType } from '../entitlements/feature.entity';
import { SubscriptionStatus } from './subscription.entity';

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class CreateFeatureDto {
  @IsString()
  code: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string | null;

  @IsString()
  category: string;

  @IsEnum(FeatureValueType)
  valueType: FeatureValueType;

  @IsOptional()
  @IsString()
  unit?: string | null;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsNumber()
  displayOrder?: number;
}

export class UpdateFeatureDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() description?: string | null;
  @IsOptional() @IsString() category?: string;
  @IsOptional() @IsEnum(FeatureValueType) valueType?: FeatureValueType;
  @IsOptional() @IsString() unit?: string | null;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsNumber() displayOrder?: number;
}

export class CreatePlanDto {
  @IsString() code: string;
  @IsString() name: string;
  @IsOptional() @IsString() description?: string | null;
  @IsNumber() @Min(0) priceMonthly: number;
  @IsString() currency: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsNumber() displayOrder?: number;
}

export class UpdatePlanDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() description?: string | null;
  @IsOptional() @IsNumber() @Min(0) priceMonthly?: number;
  @IsOptional() @IsString() currency?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsNumber() displayOrder?: number;
}

export class PlanFeatureInputDto {
  @IsUUID() featureId: string;
  @IsBoolean() enabled: boolean;
  @IsOptional() value?: boolean | number | string | null;
}

export class ReplacePlanFeaturesDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PlanFeatureInputDto)
  features: PlanFeatureInputDto[];
}

export class UpdateSubscriptionDto {
  @IsOptional() @IsUUID() planId?: string;
  @IsOptional() @IsString() plan?: string;
  @IsOptional() @IsEnum(SubscriptionStatus) status?: SubscriptionStatus;
  @IsOptional() @IsDateString() nextBillingDate?: string | null;
  @IsOptional() @IsDateString() trialEndsAt?: string | null;
  @IsOptional() @IsString() notes?: string | null;
}
