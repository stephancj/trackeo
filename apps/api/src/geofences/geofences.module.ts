import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GeofencesService } from './geofences.service';
import { GeofencesController } from './geofences.controller';
import { Geofence } from './entities/geofence.entity';
import { GeofencesCheckerService } from './geofences-checker.service';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { AlertsModule } from '../alerts/alerts.module';

@Module({
  imports: [TypeOrmModule.forFeature([Geofence]), VehiclesModule, AlertsModule],
  controllers: [GeofencesController],
  providers: [GeofencesService, GeofencesCheckerService],
  exports: [GeofencesService],
})
export class GeofencesModule {}
