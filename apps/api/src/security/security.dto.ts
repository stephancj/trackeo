import {
  IsEnum,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { IncidentStatus } from './incident.entity';

export class CreateTrackingLinkDto {
  @IsInt() @Min(15) @Max(1440) durationMinutes: number;
}
export class UpdateIncidentDto {
  @IsEnum(IncidentStatus) status: IncidentStatus;
  @IsOptional() @IsString() note?: string;
}
export class ResolveIncidentDto {
  @IsOptional() @IsString() note?: string;
  @IsOptional() @IsIn(['resolved', 'false_alarm']) outcome?:
    | 'resolved'
    | 'false_alarm';
}
