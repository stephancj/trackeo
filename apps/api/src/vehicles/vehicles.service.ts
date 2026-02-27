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

  async update(id: number, data: Partial<Device>): Promise<VehicleDto> {
    const device = await this.devicesService.update(id, data);
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
        ignition: this.extractIgnition(pos.attributes),
        rssi: this.extractRssi(pos.attributes),
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
      try {
        const pos = await this.positionsService.getLastPosition(device.id);
        position = this.toVehiclePosition(pos);
        if (!lastSeen) lastSeen = pos.serverTime ?? pos.deviceTime;
      } catch {
        // offline
      }
    }

    return {
      id: device.id,
      name: device.name,
      serialNumber: device.uniqueId,
      plate: (device.attributes as any)?.plate || null,
      imageUrl: this.extractImageUrl(device),
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
      ignition: this.extractIgnition(pos.attributes),
      rssi: this.extractRssi(pos.attributes),
      deviceTime: pos.deviceTime,
    };
  }

  /**
   * Retourne une image personnalisée ou un mockup selon le nom.
   */
  private extractImageUrl(device: Device): string | null {
    if (device.attributes?.imageUrl) {
      return device.attributes.imageUrl as string;
    }

    const n = device.name.toLowerCase();
    if (n.includes('rav4'))
      return 'https://images.info-auto.fr/toyota-rav4-2019-1.jpg';
    if (n.includes('hilux'))
      return 'https://images.info-auto.fr/toyota-hilux-2021.jpg';
    // Fallback image generic 4x4
    return 'https://images.info-auto.fr/vehicule-generique.jpg';
  }

  /**
   * Statut combiné : device.lastUpdate (primaire) + tc_devices.status Traccar (secondaire).
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

  private extractBattery(
    attributes: Record<string, unknown> | null,
  ): number | null {
    if (!attributes) return null;
    const raw =
      attributes['battery'] ??
      attributes['batteryLevel'] ??
      attributes['io113'];
    if (typeof raw === 'number') {
      return raw <= 1 ? Math.round(raw * 100) : Math.round(raw);
    }
    return null;
  }

  private extractIgnition(
    attributes: Record<string, unknown> | null,
  ): boolean | null {
    if (!attributes) return null;
    const raw = attributes['ignition'] ?? attributes['acc'];
    if (typeof raw === 'boolean') return raw;
    if (typeof raw === 'number') return raw === 1;
    return null;
  }

  private extractRssi(
    attributes: Record<string, unknown> | null,
  ): number | null {
    if (!attributes) return null;
    // rssi : 0-31 (GSM) ou 0-100 (WiFi)
    const raw = attributes['rssi'] ?? attributes['signal'];
    if (typeof raw === 'number') return raw;
    return null;
  }
}
