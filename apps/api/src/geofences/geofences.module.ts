import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GeofencesService } from './geofences.service';
import { GeofencesController } from './geofences.controller';
import { Geofence } from './entities/geofence.entity';
import { GeofencesCheckerService } from './geofences-checker.service';
import { DeviceAssignment } from '../admin/device-assignment.entity';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { AlertsModule } from '../alerts/alerts.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UsersModule } from '../users/users.module';
import { VehicleSleepMode } from '../vehicles/vehicle-sleep-mode.entity';
import { EntitlementsModule } from '../entitlements/entitlements.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Geofence, DeviceAssignment, VehicleSleepMode]),
    VehiclesModule,
    AlertsModule,
    NotificationsModule,
    UsersModule,
    EntitlementsModule,
  ],
  controllers: [GeofencesController],
  providers: [GeofencesService, GeofencesCheckerService],
  exports: [GeofencesService],
})
export class GeofencesModule {}
