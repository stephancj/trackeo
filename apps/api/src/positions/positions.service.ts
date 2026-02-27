import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Position } from './position.entity';

export interface PositionDto {
  id: number;
  deviceId: number;
  lat: number;
  lon: number;
  altitude: number;
  speedKmh: number; // Converti depuis nœuds
  course: number;
  valid: boolean;
  deviceTime: Date;
  serverTime: Date;
  attributes: Record<string, unknown> | null;
  address: string | null;
}

@Injectable()
export class PositionsService {
  constructor(
    @InjectRepository(Position)
    private readonly positionRepo: Repository<Position>,
  ) {}

  /** Position par ID (référence directe depuis tc_devices.positionid) */
  async getPositionById(id: number): Promise<PositionDto | null> {
    const pos = await this.positionRepo.findOneBy({ id });
    return pos ? this.toDto(pos) : null;
  }

  /** Dernière position connue d'un device (fallback si positionid absent) */
  async getLastPosition(deviceId: number): Promise<PositionDto> {
    const pos = await this.positionRepo.findOne({
      where: { deviceId },
      order: { serverTime: 'DESC' }, // serverTime = heure Traccar (UTC garanti), deviceTime peut être en heure locale
    });

    if (!pos) {
      throw new NotFoundException(
        `Aucune position trouvée pour le device #${deviceId}`,
      );
    }

    return this.toDto(pos);
  }

  /** Historique des positions entre deux dates */
  async getHistory(
    deviceId: number,
    from: Date,
    to: Date,
    limit = 1000,
  ): Promise<PositionDto[]> {
    const positions = await this.positionRepo.find({
      where: {
        deviceId,
        deviceTime: Between(from, to),
        valid: true,
      },
      order: { deviceTime: 'ASC' },
      take: limit,
    });

    return positions.map((pos) => this.toDto(pos));
  }

  /**
   * Calcule la distance totale parcourue (km) par un device sur une période.
   * Utilise la formule Haversine. Filtre les sauts > 5 km (GPS glitch).
   */
  async getDistanceSummary(
    deviceId: number,
    from: Date,
    to: Date,
  ): Promise<{ distanceKm: number; pointCount: number; maxSpeedKmh: number }> {
    const positions = await this.positionRepo.find({
      where: { deviceId, deviceTime: Between(from, to), valid: true },
      order: { deviceTime: 'ASC' },
      take: 10000,
    });

    let distanceKm = 0;
    let maxSpeedKmh = 0;

    for (let i = 1; i < positions.length; i++) {
      const prev = positions[i - 1];
      const curr = positions[i];
      const d = this.haversine(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
      if (d < 5) distanceKm += d; // skip GPS glitches > 5 km
      const spd = Math.round((curr.speed ?? 0) * 1.852 * 10) / 10;
      if (spd > maxSpeedKmh) maxSpeedKmh = spd;
    }

    return {
      distanceKm: Math.round(distanceKm * 10) / 10,
      pointCount: positions.length,
      maxSpeedKmh,
    };
  }

  private haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  /** Convertit l'entité en DTO propre (nœuds → km/h, JSON attributes…) */
  private toDto(pos: Position): PositionDto {
    let attributes: Record<string, unknown> | null = null;
    try {
      if (pos.attributes) {
        attributes = JSON.parse(pos.attributes) as Record<string, unknown>;
      }
    } catch {
      // attributes mal formé → on ignore
    }

    return {
      id: pos.id,
      deviceId: pos.deviceId,
      lat: pos.latitude,
      lon: pos.longitude,
      altitude: pos.altitude ?? 0,
      speedKmh: Math.round((pos.speed ?? 0) * 1.852 * 10) / 10, // knots → km/h
      course: pos.course ?? 0,
      valid: pos.valid,
      deviceTime: pos.deviceTime,
      serverTime: pos.serverTime,
      attributes,
      address: pos.address ?? null,
    };
  }
}
