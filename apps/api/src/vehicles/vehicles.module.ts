import { Module } from '@nestjs/common';
import { DevicesModule } from '../devices/devices.module';
import { PositionsModule } from '../positions/positions.module';
import { VehiclesService } from './vehicles.service';
import { VehiclesController } from './vehicles.controller';

@Module({
  imports: [
    DevicesModule,   // fournit DevicesService
    PositionsModule, // fournit PositionsService
  ],
  controllers: [VehiclesController],
  providers: [VehiclesService],
  exports: [VehiclesService],
})
export class VehiclesModule {}
