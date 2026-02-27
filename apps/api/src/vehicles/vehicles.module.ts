import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DevicesModule } from '../devices/devices.module';
import { PositionsModule } from '../positions/positions.module';
import { DeviceAssignment } from '../admin/device-assignment.entity';
import { VehiclesService } from './vehicles.service';
import { VehiclesController } from './vehicles.controller';

@Module({
  imports: [
    DevicesModule, // fournit DevicesService
    PositionsModule, // fournit PositionsService
    TypeOrmModule.forFeature([DeviceAssignment]),
  ],
  controllers: [VehiclesController],
  providers: [VehiclesService],
  exports: [VehiclesService],
})
export class VehiclesModule {}
