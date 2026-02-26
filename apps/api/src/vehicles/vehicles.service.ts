import { Injectable } from '@nestjs/common';
import { DevicesService } from '../devices/devices.service';
import { PositionsService, PositionDto } from '../positions/positions.service';
import { VehicleDto, VehiclePositionDto, VehicleStatus } from './vehicle.dto';
import { Device } from '../devices/device.entity';

@Injectable()
export class VehiclesService {
  constructor(
    private readonly devicesService: DevicesService,
    private readonly positionsService: PositionsService,
  ) {}

  /**
   * Retourne tous les véhicules enrichis avec leur dernière position.
   * Utilisé par le Fleet List et la carte.
   */
  async findAll(): Promise<VehicleDto[]> {
    const devices = await this.devicesService.findAll();

    const results = await Promise.allSettled(
      devices.map((device) => this.buildVehicleDto(device)),
    );

    return results
      .filter(
        (r): r is PromiseFulfilledResult<VehicleDto> =>
          r.status === 'fulfilled',
      )
      .map((r) => r.value);
  }

  /**
   * Retourne un véhicule enrichi par son ID.
   */
  async findOne(id: number): Promise<VehicleDto> {
    const device = await this.devicesService.findOne(id);
    return this.buildVehicleDto(device);
  }

  /**
   * Dernière position d'un véhicule — endpoint de polling (toutes les 10s).
   */
  async getLastPosition(deviceId: number): Promise<VehiclePositionDto | null> {
    try {
      const pos = await this.positionsService.getLastPosition(deviceId);
      return {
        lat: pos.lat,
        lon: pos.lon,
        speedKmh: pos.speedKmh,
        course: pos.course,
        address: pos.address,
        battery: this.extractBattery(pos.attributes),
        deviceTime: pos.deviceTime,
      };
    } catch {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers privés
  // ──────────────────────────────────────────────────────────────────────────

  private async buildVehicleDto(device: Device): Promise<VehicleDto> {
    let position: VehiclePositionDto | null = null;
    // device.lastUpdate = mis à jour par Traccar à chaque position reçue (référence de fraîcheur)
    // pos.serverTime    = heure de réception de cette position spécifique (peut être périmé
    //                     si tc_devices.positionid n'a pas été mis à jour par Traccar)
    // → on garde device.lastUpdate en priorité, pos.serverTime en fallback si null
    let lastSeen: Date | null = device.lastUpdate;

    if (device.positionid) {
      const pos = await this.positionsService.getPositionById(
        device.positionid,
      );
      if (pos) {
        position = this.toVehiclePosition(pos);
        if (!lastSeen) lastSeen = pos.serverTime ?? pos.deviceTime;
      }
    } else {
      // Fallback : cherche la dernière position par serverTime (UTC garanti par Traccar)
      try {
        const pos = await this.positionsService.getLastPosition(device.id);
        position = this.toVehiclePosition(pos);
        if (!lastSeen) lastSeen = pos.serverTime ?? pos.deviceTime;
      } catch {
        // Aucune position pour ce device → offline
      }
    }

    return {
      id: device.id,
      name: device.name,
      plate: device.uniqueId,
      status: this.computeStatus(
        position?.speedKmh ?? 0,
        lastSeen,
        device.status,
      ),
      lastUpdate: device.lastUpdate,
      position,
    };
  }

  private toVehiclePosition(pos: PositionDto): VehiclePositionDto {
    return {
      lat: pos.lat,
      lon: pos.lon,
      speedKmh: pos.speedKmh,
      course: pos.course,
      address: pos.address,
      battery: this.extractBattery(pos.attributes),
      deviceTime: pos.deviceTime,
    };
  }

  /**
   * Statut combiné : device.lastUpdate (primaire) + tc_devices.status Traccar (secondaire).
   *
   *   offline → lastUpdate ≥ 10min  OU  pas de lastUpdate
   *             OU  Traccar dit 'offline' (utile pour trackers TCP persistants)
   *   online  → lastUpdate < 10min  ET  vitesse > 1 km/h
   *   idle    → lastUpdate < 10min  ET  vitesse ≤ 1 km/h
   *
   * Note : pour OsmAnd/HTTP, Traccar peut garder 'online' longtemps après
   * déconnexion → dans ce cas notre seuil 10min prime.
   */
  private computeStatus(
    speedKmh: number,
    lastUpdate: Date | null,
    traccarStatus?: string | null,
  ): VehicleStatus {
    const OFFLINE_THRESHOLD_S = 600;
    if (!lastUpdate) return 'offline';
    const secondsAgo = (Date.now() - new Date(lastUpdate).getTime()) / 1000;
    if (secondsAgo > OFFLINE_THRESHOLD_S) return 'offline';
    if (traccarStatus === 'offline') return 'offline';
    return speedKmh > 1 ? 'online' : 'idle';
  }

  /**
   * Extrait le % de batterie depuis les attributs JSON de Traccar.
   * Traccar peut stocker : { "battery": 85 } ou { "batteryLevel": 0.85 }
   */
  private extractBattery(
    attributes: Record<string, unknown> | null,
  ): number | null {
    if (!attributes) return null;

    const raw =
      attributes['battery'] ??
      attributes['batteryLevel'] ??
      attributes['io113'];
    if (typeof raw === 'number') {
      // Certains traceurs envoient 0–1, d'autres 0–100
      return raw <= 1 ? Math.round(raw * 100) : Math.round(raw);
    }
    return null;
  }
}
