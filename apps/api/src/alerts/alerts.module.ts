import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AlertsService } from './alerts.service';
import { AlertsController } from './alerts.controller';
import { Alert } from './entities/alert.entity';
import { Geofence } from '../geofences/entities/geofence.entity';
import { DeviceAssignment } from '../admin/device-assignment.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Alert, Geofence, DeviceAssignment])],
  controllers: [AlertsController],
  providers: [AlertsService],
  exports: [AlertsService],
})
export class AlertsModule {}
