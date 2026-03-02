import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, Repository } from 'typeorm';
import { Alert, AlertType } from './entities/alert.entity';
import { Geofence } from '../geofences/entities/geofence.entity';

export interface GeofenceActivityEntry {
  geofenceId: number;
  geofenceName: string;
  isActive: boolean;
  centerLat: number;
  centerLon: number;
  radiusM: number;
  enterCount: number;
  exitCount: number;
  totalEvents: number;
  lastEventAt: Date | null;
  lastEventType: AlertType | null;
}

@Injectable()
export class AlertsService {
  constructor(
    @InjectRepository(Alert)
    private readonly alertsRepository: Repository<Alert>,
    @InjectRepository(Geofence)
    private readonly geofenceRepository: Repository<Geofence>,
  ) {}

  async createAlert(
    ownerId: number,
    deviceId: number,
    type: AlertType,
    message: string,
  ): Promise<Alert> {
    const alert = this.alertsRepository.create({
      ownerId,
      deviceId,
      type,
      message,
      status: 'open',
    });
    return this.alertsRepository.save(alert);
  }

  async findActiveByDeviceAndType(
    deviceId: number,
    type: AlertType,
  ): Promise<Alert | null> {
    // Looks for the most recent alert of this type for the device
    return this.alertsRepository.findOne({
      where: { deviceId, type },
      order: { createdAt: 'DESC' },
    });
  }

  async findAllForUser(ownerId: number): Promise<Alert[]> {
    return this.alertsRepository.find({
      where: { ownerId },
      order: { createdAt: 'DESC' },
    });
  }

  /** Admin — toutes les alertes sans filtre utilisateur */
  async findAll(): Promise<Alert[]> {
    return this.alertsRepository.find({ order: { createdAt: 'DESC' } });
  }

  /** Admin — alertes d'un device spécifique (pour la page détail véhicule) */
  async findByDeviceId(deviceId: number, limit = 20): Promise<Alert[]> {
    return this.alertsRepository.find({
      where: { deviceId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  /** Count open alerts for a user */
  async countOpenForUser(ownerId: number): Promise<number> {
    return this.alertsRepository.count({ where: { ownerId, status: 'open' } });
  }

  /** Count open alerts for a device */
  async countOpenForDevice(deviceId: number): Promise<number> {
    return this.alertsRepository.count({
      where: { deviceId, status: 'open' },
    });
  }

  /** Admin — acquitter une alerte */
  async ackAlert(id: string): Promise<Alert> {
    const alert = await this.alertsRepository.findOne({ where: { id } });
    if (!alert) throw new Error(`Alert ${id} not found`);
    alert.status = 'acked';
    return this.alertsRepository.save(alert);
  }

  /**
   * Activité geofence pour un device sur une période.
   * Retourne les entrées/sorties par geofence en croisant les alertes avec les geofences.
   * Inclut les geofences liées au device ET les geofences globales (deviceIds vide = tous les véhicules).
   */
  async getGeofenceActivity(
    deviceId: number,
    from: Date,
    to: Date,
  ): Promise<GeofenceActivityEntry[]> {
    // 1. Get geofences linked to this device + global fences (empty deviceIds)
    const [linkedFences, allFences] = await Promise.all([
      this.geofenceRepository
        .createQueryBuilder('g')
        .where(':deviceId = ANY(g.device_ids)', { deviceId })
        .orderBy('g.created_at', 'DESC')
        .getMany(),
      this.geofenceRepository
        .createQueryBuilder('g')
        .where('cardinality(g.device_ids) = 0')
        .orderBy('g.created_at', 'DESC')
        .getMany(),
    ]);

    // Deduplicate by id
    const fenceMap = new Map<number, Geofence>();
    for (const f of [...allFences, ...linkedFences]) fenceMap.set(f.id, f);
    const fences = Array.from(fenceMap.values());

    if (fences.length === 0) return [];

    // 2. Get all geofence-type alerts for this device in the date range
    const alerts = await this.alertsRepository.find({
      where: {
        deviceId,
        type: In([AlertType.GEOFENCE_ENTER, AlertType.GEOFENCE_EXIT]),
        createdAt: Between(from, to),
      },
      order: { createdAt: 'DESC' },
    });

    // 3. Cross-reference: match alerts to geofences by name in message
    // Message format: "${vehicle.name} est entré dans la zone ${fence.name}"
    //                 "${vehicle.name} a quitté la zone ${fence.name}"
    return fences.map((fence) => {
      const fenceAlerts = alerts.filter((a) =>
        a.message?.includes(fence.name),
      );
      const enterCount = fenceAlerts.filter(
        (a) => a.type === AlertType.GEOFENCE_ENTER,
      ).length;
      const exitCount = fenceAlerts.filter(
        (a) => a.type === AlertType.GEOFENCE_EXIT,
      ).length;
      const lastAlert = fenceAlerts[0] ?? null;

      return {
        geofenceId: fence.id,
        geofenceName: fence.name,
        isActive: fence.isActive,
        centerLat: fence.centerLat,
        centerLon: fence.centerLon,
        radiusM: fence.radiusM,
        enterCount,
        exitCount,
        totalEvents: enterCount + exitCount,
        lastEventAt: lastAlert?.createdAt ?? null,
        lastEventType: lastAlert?.type ?? null,
      };
    });
  }
}
