import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeviceAssignment } from '../admin/device-assignment.entity';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { PositionsModule } from '../positions/positions.module';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { Trip } from './trip.entity';
import { TripsController } from './trips.controller';
import { TripsService } from './trips.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Trip, DeviceAssignment]),
    PositionsModule,
    VehiclesModule,
    EntitlementsModule,
  ],
  controllers: [TripsController],
  providers: [TripsService],
  exports: [TripsService],
})
export class TripsModule {}
