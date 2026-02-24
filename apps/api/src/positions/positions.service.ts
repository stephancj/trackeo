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
  ) { }

  /** Dernière position connue d'un device */
  async getLastPosition(deviceId: number): Promise<PositionDto> {
    const pos = await this.positionRepo.findOne({
      where: { deviceId },
      order: { deviceTime: 'DESC' },
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
