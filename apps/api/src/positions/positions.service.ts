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

  // ── Detailed vehicle reports ─────────────────────────────────────────────

  /**
   * Trip log : reconstitue les trajets depuis tc_positions.
   * Un gap > GAP_MINUTES entre deux points consécutifs = nouvelle étape.
   * Chaque trajet = { startTime, endTime, startLat, startLon, endLat, endLon,
   *                   distanceKm, durationMin, maxSpeedKmh, pointCount }
   */
  async getTripLog(
    deviceId: number,
    from: Date,
    to: Date,
  ): Promise<
    {
      startTime: Date;
      endTime: Date;
      startLat: number;
      startLon: number;
      endLat: number;
      endLon: number;
      distanceKm: number;
      durationMin: number;
      maxSpeedKmh: number;
      pointCount: number;
    }[]
  > {
    const GAP_MS = 10 * 60 * 1000; // 10 min gap = new trip

    const positions = await this.positionRepo.find({
      where: { deviceId, deviceTime: Between(from, to), valid: true },
      order: { deviceTime: 'ASC' },
      take: 10000,
    });

    if (positions.length === 0) return [];

    const trips: ReturnType<typeof this.getTripLog> extends Promise<infer T>
      ? T
      : never = [];
    let segStart = 0;

    const flush = (start: number, end: number) => {
      const seg = positions.slice(start, end + 1);
      if (seg.length < 2) return;
      let dist = 0;
      let maxSpd = 0;
      for (let i = 1; i < seg.length; i++) {
        const d = this.haversine(
          seg[i - 1].latitude,
          seg[i - 1].longitude,
          seg[i].latitude,
          seg[i].longitude,
        );
        if (d < 5) dist += d;
        const spd = Math.round((seg[i].speed ?? 0) * 1.852 * 10) / 10;
        if (spd > maxSpd) maxSpd = spd;
      }
      if (dist < 0.1) return; // skip micro-movements < 100m
      const durationMin = Math.round(
        (seg[seg.length - 1].deviceTime.getTime() - seg[0].deviceTime.getTime()) /
          60000,
      );
      trips.push({
        startTime: seg[0].deviceTime,
        endTime: seg[seg.length - 1].deviceTime,
        startLat: seg[0].latitude,
        startLon: seg[0].longitude,
        endLat: seg[seg.length - 1].latitude,
        endLon: seg[seg.length - 1].longitude,
        distanceKm: Math.round(dist * 10) / 10,
        durationMin,
        maxSpeedKmh: maxSpd,
        pointCount: seg.length,
      });
    };

    for (let i = 1; i < positions.length; i++) {
      const gap =
        positions[i].deviceTime.getTime() -
        positions[i - 1].deviceTime.getTime();
      if (gap > GAP_MS) {
        flush(segStart, i - 1);
        segStart = i;
      }
    }
    flush(segStart, positions.length - 1);

    return trips;
  }

  /**
   * Speed violations : épisodes où speed > threshold km/h.
   * Les positions consécutives dépassant le seuil sont regroupées en un seul épisode.
   */
  async getSpeedViolations(
    deviceId: number,
    from: Date,
    to: Date,
    thresholdKmh = 120,
  ): Promise<
    {
      startTime: Date;
      endTime: Date;
      lat: number;
      lon: number;
      maxSpeedKmh: number;
      durationSec: number;
    }[]
  > {
    const positions = await this.positionRepo.find({
      where: { deviceId, deviceTime: Between(from, to), valid: true },
      order: { deviceTime: 'ASC' },
      take: 10000,
    });

    const violations: Awaited<ReturnType<typeof this.getSpeedViolations>> = [];
    let inViolation = false;
    let episodeStart: (typeof positions)[0] | null = null;
    let maxSpd = 0;

    for (const pos of positions) {
      const spd = (pos.speed ?? 0) * 1.852;
      if (spd > thresholdKmh) {
        if (!inViolation) {
          inViolation = true;
          episodeStart = pos;
          maxSpd = spd;
        } else if (spd > maxSpd) {
          maxSpd = spd;
        }
      } else {
        if (inViolation && episodeStart) {
          const dur = Math.round(
            (pos.deviceTime.getTime() - episodeStart.deviceTime.getTime()) / 1000,
          );
          violations.push({
            startTime: episodeStart.deviceTime,
            endTime: pos.deviceTime,
            lat: episodeStart.latitude,
            lon: episodeStart.longitude,
            maxSpeedKmh: Math.round(maxSpd * 10) / 10,
            durationSec: dur,
          });
          inViolation = false;
          episodeStart = null;
          maxSpd = 0;
        }
      }
    }
    // Close open episode at end of range
    if (inViolation && episodeStart && positions.length > 0) {
      const last = positions[positions.length - 1];
      violations.push({
        startTime: episodeStart.deviceTime,
        endTime: last.deviceTime,
        lat: episodeStart.latitude,
        lon: episodeStart.longitude,
        maxSpeedKmh: Math.round(maxSpd * 10) / 10,
        durationSec: Math.round(
          (last.deviceTime.getTime() - episodeStart.deviceTime.getTime()) / 1000,
        ),
      });
    }

    return violations;
  }

  /**
   * Idle time : épisodes où vitesse < 2 km/h avec gap < 5 min entre points.
   * Filtre les épisodes < 3 min (arrêts à un feu rouge).
   */
  async getIdleTime(
    deviceId: number,
    from: Date,
    to: Date,
  ): Promise<
    {
      startTime: Date;
      endTime: Date;
      lat: number;
      lon: number;
      durationMin: number;
    }[]
  > {
    const IDLE_SPEED_KMH = 2;
    const MAX_GAP_MS = 5 * 60 * 1000;
    const MIN_DURATION_MS = 3 * 60 * 1000;

    const positions = await this.positionRepo.find({
      where: { deviceId, deviceTime: Between(from, to), valid: true },
      order: { deviceTime: 'ASC' },
      take: 10000,
    });

    const episodes: Awaited<ReturnType<typeof this.getIdleTime>> = [];
    let inIdle = false;
    let idleStart: (typeof positions)[0] | null = null;

    for (let i = 0; i < positions.length; i++) {
      const pos = positions[i];
      const spd = (pos.speed ?? 0) * 1.852;
      const isIdle = spd < IDLE_SPEED_KMH;

      // Check gap from previous point
      let gapOk = true;
      if (i > 0) {
        const gap = pos.deviceTime.getTime() - positions[i - 1].deviceTime.getTime();
        if (gap > MAX_GAP_MS) gapOk = false;
      }

      if (isIdle && gapOk) {
        if (!inIdle) {
          inIdle = true;
          idleStart = pos;
        }
      } else {
        if (inIdle && idleStart) {
          const dur = positions[i - 1].deviceTime.getTime() - idleStart.deviceTime.getTime();
          if (dur >= MIN_DURATION_MS) {
            episodes.push({
              startTime: idleStart.deviceTime,
              endTime: positions[i - 1].deviceTime,
              lat: idleStart.latitude,
              lon: idleStart.longitude,
              durationMin: Math.round(dur / 60000),
            });
          }
          inIdle = false;
          idleStart = null;
        }
      }
    }
    // Close open episode
    if (inIdle && idleStart && positions.length > 0) {
      const last = positions[positions.length - 1];
      const dur = last.deviceTime.getTime() - idleStart.deviceTime.getTime();
      if (dur >= MIN_DURATION_MS) {
        episodes.push({
          startTime: idleStart.deviceTime,
          endTime: last.deviceTime,
          lat: idleStart.latitude,
          lon: idleStart.longitude,
          durationMin: Math.round(dur / 60000),
        });
      }
    }

    return episodes;
  }

  /**
   * Activity summary : résumé agrégé sur une période
   * (distance, temps de conduite, idle time, vitesse max, violations, nb trajets)
   */
  async getActivitySummary(
    deviceId: number,
    from: Date,
    to: Date,
    speedThresholdKmh = 120,
  ): Promise<{
    distanceKm: number;
    drivingMinutes: number;
    idleMinutes: number;
    maxSpeedKmh: number;
    tripCount: number;
    speedViolationCount: number;
    pointCount: number;
  }> {
    const [distSummary, trips, violations, idleEpisodes] = await Promise.all([
      this.getDistanceSummary(deviceId, from, to),
      this.getTripLog(deviceId, from, to),
      this.getSpeedViolations(deviceId, from, to, speedThresholdKmh),
      this.getIdleTime(deviceId, from, to),
    ]);

    const drivingMinutes = trips.reduce((sum, t) => sum + t.durationMin, 0);
    const idleMinutes = idleEpisodes.reduce((sum, e) => sum + e.durationMin, 0);

    return {
      distanceKm: distSummary.distanceKm,
      drivingMinutes,
      idleMinutes,
      maxSpeedKmh: distSummary.maxSpeedKmh,
      tripCount: trips.length,
      speedViolationCount: violations.length,
      pointCount: distSummary.pointCount,
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
