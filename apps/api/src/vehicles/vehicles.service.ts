import { Injectable } from '@nestjs/common';
import { DevicesService } from '../devices/devices.service';
import { PositionsService } from '../positions/positions.service';
import { VehicleDto, VehiclePositionDto, VehicleStatus } from './vehicle.dto';

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
      devices.map((device) => this.buildVehicleDto(device.id)),
    );

    return results
      .filter((r): r is PromiseFulfilledResult<VehicleDto> => r.status === 'fulfilled')
      .map((r) => r.value);
  }

  /**
   * Retourne un véhicule enrichi par son ID.
   */
  async findOne(id: number): Promise<VehicleDto> {
    return this.buildVehicleDto(id);
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

  private async buildVehicleDto(deviceId: number): Promise<VehicleDto> {
    const device = await this.devicesService.findOne(deviceId);
    const position = await this.getLastPosition(deviceId);

    return {
      id: device.id,
      name: device.name,
      plate: device.uniqueId,
      status: this.computeStatus(device.status, device.lastUpdate, position?.speedKmh ?? 0),
      lastUpdate: device.lastUpdate,
      position,
    };
  }

  /**
   * Calcule le statut affiché dans le Figma :
   *   online  → en mouvement (vitesse > 1 km/h)
   *   idle    → connecté mais arrêté
   *   offline → déconnecté ou lastUpdate > 5 min
   */
  private computeStatus(
    traccarStatus: string | null,
    lastUpdate: Date | null,
    speedKmh: number,
  ): VehicleStatus {
    if (!lastUpdate || traccarStatus === 'offline') return 'offline';

    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (lastUpdate < fiveMinutesAgo) return 'offline';

    return speedKmh > 1 ? 'online' : 'idle';
  }

  /**
   * Extrait le % de batterie depuis les attributs JSON de Traccar.
   * Traccar peut stocker : { "battery": 85 } ou { "batteryLevel": 0.85 }
   */
  private extractBattery(attributes: Record<string, unknown> | null): number | null {
    if (!attributes) return null;

    const raw = attributes['battery'] ?? attributes['batteryLevel'] ?? attributes['io113'];
    if (typeof raw === 'number') {
      // Certains traceurs envoient 0–1, d'autres 0–100
      return raw <= 1 ? Math.round(raw * 100) : Math.round(raw);
    }
    return null;
  }
}
