import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateAlertSettingsDto {
  @IsOptional()
  @IsBoolean()
  alertsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  alertSos?: boolean;

  @IsOptional()
  @IsBoolean()
  alertLowBattery?: boolean;

  @IsOptional()
  @IsBoolean()
  alertSpeedLimit?: boolean;

  @IsOptional()
  @IsBoolean()
  alertViaPush?: boolean;

  @IsOptional()
  @IsBoolean()
  alertViaWhatsapp?: boolean;
}
