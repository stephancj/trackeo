import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import * as https from 'https';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GeofencesService } from './geofences.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { AlertsService } from '../alerts/alerts.service';
import { NotificationsService } from '../notifications/notifications.service';
import { UsersService } from '../users/users.service';
import { AlertType } from '../alerts/entities/alert.entity';
import { DeviceAssignment } from '../admin/device-assignment.entity';

interface AlertSettings {
  alertsEnabled: boolean;
  alertSos: boolean;
  alertLowBattery: boolean;
  alertSpeedLimit: boolean;
  alertViaPush: boolean;
  alertViaWhatsapp: boolean;
}

@Injectable()
export class GeofencesCheckerService {
  private readonly logger = new Logger(GeofencesCheckerService.name);

  constructor(
    private readonly geofencesService: GeofencesService,
    private readonly vehiclesService: VehiclesService,
    private readonly alertsService: AlertsService,
    private readonly notificationsService: NotificationsService,
    private readonly usersService: UsersService,
    @InjectRepository(DeviceAssignment)
    private readonly assignmentRepo: Repository<DeviceAssignment>,
  ) {}

  // Cache en mémoire pour éviter le spam et les requêtes DB.
  // Clé: "{vehicleId}_{geofenceId}", Valeur: boolean (true = inside)
  private readonly insideGeofencesCache = new Map<string, boolean>();

  // Cache du subscription ID OneSignal par userId (TTL: 60s)
  private readonly subIdCache = new Map<number, string | null>();
  private readonly subIdCacheTs = new Map<number, number>();

  // Cache du numéro de téléphone par userId (TTL: 60s)
  private readonly phoneCache = new Map<number, string | null>();
  private readonly phoneCacheTs = new Map<number, number>();

  // Cache des paramètres d'alerte par userId (TTL: 60s)
  private readonly alertSettingsCache = new Map<number, AlertSettings>();
  private readonly alertSettingsCacheTs = new Map<number, number>();
  private readonly SETTINGS_CACHE_TTL_MS = 60_000;

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

          // Alert settings belong to the fence owner, not the vehicle
          const userAlertSettings = await this.getUserAlertSettings(
            fence.userId,
          );
          if (!userAlertSettings.alertsEnabled) continue;

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

            if (!fence.alertOnEntry) continue;

            this.logger.log(`🚗 ${vehicle.name} ENTERED ${fence.name}`);

            await this.alertsService.createAlert(
              fence.userId,
              vehicle.id,
              AlertType.GEOFENCE_ENTER,
              `${vehicle.name} est entré dans la zone ${fence.name}`,
              vehicle.position.lat,
              vehicle.position.lon,
            );

            if (userAlertSettings.alertViaPush) {
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
            }

            if (userAlertSettings.alertViaWhatsapp) {
              await this.sendWhatsAppIfEnabled(
                fence.userId,
                vehicle.name,
                fence.name,
                'enter',
              );
            }
          } else if (!isInside && wasInside) {
            this.insideGeofencesCache.set(cacheKey, false);

            if (!fence.alertOnExit) continue;

            this.logger.log(`🚗 ${vehicle.name} EXITED ${fence.name}`);

            await this.alertsService.createAlert(
              fence.userId,
              vehicle.id,
              AlertType.GEOFENCE_EXIT,
              `${vehicle.name} a quitté la zone ${fence.name}`,
              vehicle.position.lat,
              vehicle.position.lon,
            );

            if (userAlertSettings.alertViaPush) {
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

            if (userAlertSettings.alertViaWhatsapp) {
              await this.sendWhatsAppIfEnabled(
                fence.userId,
                vehicle.name,
                fence.name,
                'exit',
              );
            }
          }
        }
      }
    } catch (e) {
      this.logger.error('Erreur lors du check geofences', e);
    }
  }

  // Cache pour éviter le spam d'alertes (clé: vehicleId_alertType)
  private readonly lastAlertCache = new Map<string, Date>();

  // Cache pour suivre le début d'un excès de vitesse par véhicule
  private readonly speedExcessStartCache = new Map<
    number,
    { startTime: Date; lat: number; lon: number; maxSpeed: number }
  >();

  // Seuil d'excès de vitesse (km/h) — au-delà, une alerte est générée.
  private readonly SPEED_LIMIT_KMH = 120;

  @Cron('*/30 * * * * *')
  async checkVehicleAlerts() {
    this.logger.debug('Vérification des alertes véhicule...');
    try {
      const vehicles = await this.vehiclesService.findAll();

      // Build deviceId → userId map from assignments table
      const assignments = await this.assignmentRepo.find();
      const deviceUserMap = new Map(
        assignments.map((a) => [a.deviceId, a.userId]),
      );

      for (const vehicle of vehicles) {
        if (!vehicle.position || vehicle.status === 'offline') continue;

        const userId = deviceUserMap.get(vehicle.id);
        if (!userId) continue;

        const userAlertSettings = await this.getUserAlertSettings(userId);
        if (!userAlertSettings.alertsEnabled) continue;

        // Low Battery Alert
        if (
          userAlertSettings.alertLowBattery &&
          vehicle.position.battery != null &&
          vehicle.position.battery < 20
        ) {
          await this.sendAlertIfNotSpammed(
            userId,
            vehicle.id,
            vehicle.name,
            AlertType.LOW_BATTERY,
            `Batterie faible: ${vehicle.position.battery}%`,
            userAlertSettings,
            vehicle.position.lat,
            vehicle.position.lon,
          );
        }

        // Speed Limit Alert — track duration and location
        const speedKmh = vehicle.position.speedKmh;
        if (userAlertSettings.alertSpeedLimit && speedKmh != null) {
          if (speedKmh > this.SPEED_LIMIT_KMH) {
            // Update or start tracking this excess
            const existing = this.speedExcessStartCache.get(vehicle.id);
            if (!existing) {
              this.speedExcessStartCache.set(vehicle.id, {
                startTime: new Date(),
                lat: vehicle.position.lat,
                lon: vehicle.position.lon,
                maxSpeed: speedKmh,
              });
            } else {
              // Update max speed seen during this excess
              if (speedKmh > existing.maxSpeed) {
                existing.maxSpeed = speedKmh;
              }
            }

            const excess = this.speedExcessStartCache.get(vehicle.id)!;
            const durationMs = Date.now() - excess.startTime.getTime();
            const sustained = durationMs >= 60_000;
            const peakKmh = Math.round(excess.maxSpeed);
            const location = await this.reverseGeocode(excess.lat, excess.lon);

            // Message épuré : pic de vitesse, limite, lieu — et durée seulement
            // si l'excès dure (≥ 1 min). Pas de nom de véhicule (affiché par
            // l'UI), pas d'URL brute, pas d'heure (déjà dans le timestamp).
            let message = `${peakKmh} km/h (limite ${this.SPEED_LIMIT_KMH} km/h)`;
            if (location) message += ` · ${location}`;
            if (sustained) message += ` · sur ${this.formatDuration(durationMs)}`;

            await this.sendAlertIfNotSpammed(
              userId,
              vehicle.id,
              vehicle.name,
              AlertType.SPEED_LIMIT,
              message,
              userAlertSettings,
              excess.lat,
              excess.lon,
            );
          } else {
            // Speed back to normal — reset tracking
            this.speedExcessStartCache.delete(vehicle.id);
          }
        }
      }
    } catch (e) {
      this.logger.error('Erreur lors du check alerts véhicule', e);
    }
  }

  private formatDuration(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    if (minutes === 0) return `${seconds}s`;
    if (seconds === 0) return `${minutes}min`;
    return `${minutes}min ${seconds}s`;
  }

  private async sendAlertIfNotSpammed(
    userId: number,
    vehicleId: number,
    vehicleName: string,
    alertType: AlertType,
    message: string,
    settings: AlertSettings,
    lat?: number,
    lon?: number,
  ): Promise<void> {
    const cacheKey = `${vehicleId}_${alertType}`;
    const lastAlert = this.lastAlertCache.get(cacheKey);
    const now = new Date();

    // Éviter le spam: une alerte toutes les 5 secondes max
    if (lastAlert && now.getTime() - lastAlert.getTime() < 5 * 1000) {
      return;
    }

    this.lastAlertCache.set(cacheKey, now);
    this.logger.log(`🚨 ${vehicleName} ${alertType}: ${message}`);

    await this.alertsService.createAlert(
      userId,
      vehicleId,
      alertType,
      message,
      lat,
      lon,
    );

    if (settings.alertViaPush) {
      const subscriptionId = await this.getUserSubId(userId);
      const title =
        alertType === AlertType.LOW_BATTERY
          ? '🔋 Batterie faible'
          : '⚡ Excès de vitesse';
      // Préfixe le nom du véhicule : le push n'a pas de puce véhicule comme l'in-app.
      const pushBody = `${vehicleName} • ${message}`;
      await this.notificationsService.sendPush({
        externalUserId: userId.toString(),
        subscriptionId: subscriptionId ?? undefined,
        title,
        body: pushBody,
        data: {
          type: alertType,
          vehicleId: vehicleId.toString(),
        },
      });
    }

    if (settings.alertViaWhatsapp) {
      await this.sendWhatsAppIfEnabled(
        userId,
        vehicleName,
        message,
        alertType === AlertType.LOW_BATTERY ? 'enter' : 'exit',
      );
    }
  }

  /**
   * Retourne le subscription ID OneSignal de l'utilisateur.
   * Met en cache le résultat pour éviter les requêtes DB répétitives.
   */
  private async getUserSubId(userId: number): Promise<string | null> {
    const cachedTs = this.subIdCacheTs.get(userId) ?? 0;
    if (
      this.subIdCache.has(userId) &&
      Date.now() - cachedTs < this.SETTINGS_CACHE_TTL_MS
    ) {
      return this.subIdCache.get(userId) ?? null;
    }
    const user = await this.usersService.findById(userId);
    const subId = user?.onesignalSubId ?? null;
    this.subIdCache.set(userId, subId);
    this.subIdCacheTs.set(userId, Date.now());
    return subId;
  }

  /**
   * Retourne le numéro de téléphone de l'utilisateur.
   * Met en cache le résultat pour éviter les requêtes DB répétitives.
   */
  private async getUserPhone(userId: number): Promise<string | null> {
    const cachedTs = this.phoneCacheTs.get(userId) ?? 0;
    if (
      this.phoneCache.has(userId) &&
      Date.now() - cachedTs < this.SETTINGS_CACHE_TTL_MS
    ) {
      return this.phoneCache.get(userId) ?? null;
    }
    const user = await this.usersService.findById(userId);
    const phone = user?.phone ?? null;
    this.phoneCache.set(userId, phone);
    this.phoneCacheTs.set(userId, Date.now());
    return phone;
  }

  /**
   * Retourne les paramètres d'alerte de l'utilisateur.
   * Met en cache le résultat pour éviter les requêtes DB répétitives.
   */
  private async getUserAlertSettings(userId: number): Promise<AlertSettings> {
    const cachedTs = this.alertSettingsCacheTs.get(userId) ?? 0;
    if (
      this.alertSettingsCache.has(userId) &&
      Date.now() - cachedTs < this.SETTINGS_CACHE_TTL_MS
    ) {
      return this.alertSettingsCache.get(userId)!;
    }
    const user = await this.usersService.findById(userId);
    const settings: AlertSettings = {
      alertsEnabled: user?.alertsEnabled ?? true,
      alertSos: user?.alertSos ?? true,
      alertLowBattery: user?.alertLowBattery ?? true,
      alertSpeedLimit: user?.alertSpeedLimit ?? false,
      alertViaPush: user?.alertViaPush ?? true,
      alertViaWhatsapp: user?.alertViaWhatsapp ?? false,
    };
    this.alertSettingsCache.set(userId, settings);
    this.alertSettingsCacheTs.set(userId, Date.now());
    return settings;
  }

  /**
   * Envoie une notification WhatsApp si l'utilisateur a un numéro de téléphone configuré.
   */
  private async sendWhatsAppIfEnabled(
    userId: number,
    vehicleName: string,
    alertMessage: string,
    alertType: 'enter' | 'exit',
  ): Promise<void> {
    const phone = await this.getUserPhone(userId);
    if (!phone) {
      this.logger.warn(
        `User ${userId} n'a pas de numéro de téléphone pour WhatsApp`,
      );
      return;
    }
    await this.notificationsService.sendWhatsApp({
      phone,
      vehicleName,
      geofenceName: alertMessage,
      alertType,
    });
  }

  // Reverse geocoding cache: "lat,lon" (1 decimal) → address string
  private readonly geocodeCache = new Map<string, string>();

  private async reverseGeocode(lat: number, lon: number): Promise<string> {
    // Round to ~11km grid to maximize cache hits for nearby points
    const key = `${lat.toFixed(1)},${lon.toFixed(1)}`;
    if (this.geocodeCache.has(key)) return this.geocodeCache.get(key)!;

    try {
      const address = await new Promise<string>((resolve, reject) => {
        const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json&zoom=16`;
        https
          .get(url, { headers: { 'User-Agent': 'Trackeo/1.0' } }, (res) => {
            let data = '';
            res.on('data', (chunk) => (data += chunk));
            res.on('end', () => {
              try {
                const json = JSON.parse(data);
                const a = json.address ?? {};
                const parts = [
                  a.road ?? a.pedestrian ?? a.path,
                  a.suburb ?? a.neighbourhood ?? a.village ?? a.town ?? a.city,
                ].filter(Boolean);
                resolve(parts.length > 0 ? parts.join(', ') : json.display_name?.split(',')[0] ?? `${lat.toFixed(4)},${lon.toFixed(4)}`);
              } catch {
                resolve(`${lat.toFixed(4)},${lon.toFixed(4)}`);
              }
            });
          })
          .on('error', () => resolve(`${lat.toFixed(4)},${lon.toFixed(4)}`));
      });
      this.geocodeCache.set(key, address);
      return address;
    } catch {
      return `${lat.toFixed(4)},${lon.toFixed(4)}`;
    }
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
