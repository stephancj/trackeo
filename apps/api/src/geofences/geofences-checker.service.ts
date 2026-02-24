import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { GeofencesService } from './geofences.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { AlertsService } from '../alerts/alerts.service';
import { AlertType } from '../alerts/entities/alert.entity';

@Injectable()
export class GeofencesCheckerService {
  private readonly logger = new Logger(GeofencesCheckerService.name);

  constructor(
    private readonly geofencesService: GeofencesService,
    private readonly vehiclesService: VehiclesService,
    private readonly alertsService: AlertsService,
  ) {}

  @Cron('*/15 * * * * *') // Run every 15 seconds
  async checkGeofences() {
    this.logger.debug('Vérification des Geofences en cours...');
    try {
      const vehicles = await this.vehiclesService.findAll();
      // Optimization: We could get all active geofences instead of looping linearly
      // For MVP, we'll just query all geofences and check
      for (const vehicle of vehicles) {
        if (!vehicle.position || vehicle.status === 'offline') continue;

        // In a real app, geofences would be assigned by user, here we assume all geofences apply or we can check
        // Wait, Geofences have userId. Vehicles don't have owner ID in VehicleDto?
        // Let's get all active geofences in the system for this MVP

        // Wait, we need a method to get ALL active geofences in the system to check.
        const allGeofences = await this.geofencesService.findAllActive();

        for (const fence of allGeofences) {
          // If the geofence is linked to specific devices, check if this vehicle is included
          if (
            fence.deviceIds &&
            fence.deviceIds.length > 0 &&
            !fence.deviceIds.includes(vehicle.id)
          ) {
            continue;
          }

          // Check distance
          const distanceM = this.getDistanceFromLatLonInM(
            vehicle.position.lat,
            vehicle.position.lon,
            fence.centerLat,
            fence.centerLon,
          );

          const isInside = distanceM <= fence.radiusM;

          // Find latest alert for this device to determine its state (inside or outside?)
          // Actually, we can check the latest Alert event type (GEOFENCE_ENTER or GEOFENCE_EXIT)
          const lastEnter = await this.alertsService.findActiveByDeviceAndType(
            vehicle.id,
            AlertType.GEOFENCE_ENTER,
          );
          const lastExit = await this.alertsService.findActiveByDeviceAndType(
            vehicle.id,
            AlertType.GEOFENCE_EXIT,
          );

          const wasInside =
            lastEnter &&
            (!lastExit || lastEnter.createdAt > lastExit.createdAt);

          if (isInside && !wasInside) {
            this.logger.log(
              `🚗 Véhicule ${vehicle.name} ENTERED geofence ${fence.name}`,
            );
            await this.alertsService.createAlert(
              fence.userId,
              vehicle.id,
              AlertType.GEOFENCE_ENTER,
              `Le véhicule ${vehicle.name} est entré dans la zone ${fence.name}`,
            );
          } else if (!isInside && wasInside) {
            this.logger.log(
              `🚗 Véhicule ${vehicle.name} EXITED geofence ${fence.name}`,
            );
            await this.alertsService.createAlert(
              fence.userId,
              vehicle.id,
              AlertType.GEOFENCE_EXIT,
              `Le véhicule ${vehicle.name} est sorti de la zone ${fence.name}`,
            );
          }
        }
      }
    } catch (e) {
      this.logger.error('Erreur lors du check geofences', e);
    }
  }

  // Haversine formula
  private getDistanceFromLatLonInM(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ) {
    const R = 6371e3; // Radius of the earth in m
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) *
        Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number) {
    return deg * (Math.PI / 180);
  }
}
