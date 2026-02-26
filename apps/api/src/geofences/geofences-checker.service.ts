import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { GeofencesService } from './geofences.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { AlertsService } from '../alerts/alerts.service';
import { NotificationsService } from '../notifications/notifications.service';
import { UsersService } from '../users/users.service';
import { AlertType } from '../alerts/entities/alert.entity';

@Injectable()
export class GeofencesCheckerService {
  private readonly logger = new Logger(GeofencesCheckerService.name);

  constructor(
    private readonly geofencesService: GeofencesService,
    private readonly vehiclesService: VehiclesService,
    private readonly alertsService: AlertsService,
    private readonly notificationsService: NotificationsService,
    private readonly usersService: UsersService,
  ) {}

  // Cache en mémoire pour éviter le spam et les requêtes DB.
  // Clé: "{vehicleId}_{geofenceId}", Valeur: boolean (true = inside)
  private readonly insideGeofencesCache = new Map<string, boolean>();

  // Cache du subscription ID OneSignal par userId (évite un SELECT à chaque alerte)
  private readonly subIdCache = new Map<number, string | null>();

  @Cron('*/15 * * * * *')
  async checkGeofences() {
    this.logger.debug('Vérification des Geofences en cours...');
    try {
      const vehicles = await this.vehiclesService.findAll();
      const allGeofences = await this.geofencesService.findAllActive();

      for (const vehicle of vehicles) {
        if (!vehicle.position || vehicle.status === 'offline') continue;

        for (const fence of allGeofences) {
          if (
            fence.deviceIds &&
            fence.deviceIds.length > 0 &&
            !fence.deviceIds.includes(vehicle.id)
          ) {
            continue;
          }

          const distanceM = this.getDistanceFromLatLonInM(
            vehicle.position.lat,
            vehicle.position.lon,
            fence.centerLat,
            fence.centerLon,
          );

          const isInside = distanceM <= fence.radiusM;
          const cacheKey = `${vehicle.id}_${fence.id}`;
          const wasInside = this.insideGeofencesCache.get(cacheKey) ?? false;

          if (isInside && !wasInside) {
            this.insideGeofencesCache.set(cacheKey, true);
            this.logger.log(`🚗 ${vehicle.name} ENTERED ${fence.name}`);

            await this.alertsService.createAlert(
              fence.userId,
              vehicle.id,
              AlertType.GEOFENCE_ENTER,
              `${vehicle.name} est entré dans la zone ${fence.name}`,
            );

            const subscriptionId = await this.getUserSubId(fence.userId);
            await this.notificationsService.sendPush({
              externalUserId: fence.userId.toString(),
              subscriptionId: subscriptionId ?? undefined,
              title: '🟢 Entrée de zone',
              body: `${vehicle.name} est entré dans la zone "${fence.name}"`,
              data: {
                type: 'geofence_enter',
                vehicleId: vehicle.id.toString(),
                geofenceName: fence.name,
              },
            });
          } else if (!isInside && wasInside) {
            this.insideGeofencesCache.set(cacheKey, false);
            this.logger.log(`🚗 ${vehicle.name} EXITED ${fence.name}`);

            await this.alertsService.createAlert(
              fence.userId,
              vehicle.id,
              AlertType.GEOFENCE_EXIT,
              `${vehicle.name} a quitté la zone ${fence.name}`,
            );

            const subscriptionId = await this.getUserSubId(fence.userId);
            await this.notificationsService.sendPush({
              externalUserId: fence.userId.toString(),
              subscriptionId: subscriptionId ?? undefined,
              title: '🔴 Sortie de zone',
              body: `${vehicle.name} a quitté la zone "${fence.name}"`,
              data: {
                type: 'geofence_exit',
                vehicleId: vehicle.id.toString(),
                geofenceName: fence.name,
              },
            });
          }
        }
      }
    } catch (e) {
      this.logger.error('Erreur lors du check geofences', e);
    }
  }

  /**
   * Retourne le subscription ID OneSignal de l'utilisateur.
   * Met en cache le résultat pour éviter les requêtes DB répétitives.
   * Cache invalidé au redémarrage du serveur — acceptable en MVP.
   */
  private async getUserSubId(userId: number): Promise<string | null> {
    if (this.subIdCache.has(userId)) {
      return this.subIdCache.get(userId) ?? null;
    }
    const user = await this.usersService.findById(userId);
    const subId = user?.onesignalSubId ?? null;
    this.subIdCache.set(userId, subId);
    return subId;
  }

  private getDistanceFromLatLonInM(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ) {
    const R = 6371e3;
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
