import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, Repository } from 'typeorm';
import { Alert, AlertType } from './entities/alert.entity';
import { Geofence } from '../geofences/entities/geofence.entity';
import { DeviceAssignment } from '../admin/device-assignment.entity';

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
    @InjectRepository(DeviceAssignment)
    private readonly assignmentRepo: Repository<DeviceAssignment>,
  ) {}

  /** Résout les device IDs actuellement assignés à un utilisateur */
  private async getAssignedDeviceIds(userId: number): Promise<number[]> {
    const assignments = await this.assignmentRepo.find({ where: { userId } });
    return assignments.map((a) => a.deviceId);
  }

  async createAlert(
    ownerId: number,
    deviceId: number,
    type: AlertType,
    message: string,
    lat?: number,
    lon?: number,
  ): Promise<Alert> {
    const alert = this.alertsRepository.create({
      ownerId,
      deviceId,
      type,
      message,
      status: 'open',
      lat: lat ?? null,
      lon: lon ?? null,
    });
    return this.alertsRepository.save(alert);
  }

  /**
   * Met à jour le message d'une alerte (épisode d'excès en cours : pic/durée
   * évoluent sans créer une nouvelle alerte). Ne change pas le statut.
   */
  async updateAlertMessage(id: string, message: string): Promise<void> {
    await this.alertsRepository.update({ id }, { message });
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

  /**
   * Retourne les alertes des véhicules ACTUELLEMENT assignés à l'utilisateur.
   * Filtre par device_assignments (pas par ownerId) pour que les alertes
   * suivent le véhicule, même en cas de réassignation.
   */
  async findAllForUser(userId: number): Promise<Alert[]> {
    const deviceIds = await this.getAssignedDeviceIds(userId);
    if (deviceIds.length === 0) return [];
    return this.alertsRepository.find({
      where: { deviceId: In(deviceIds) },
      order: { createdAt: 'DESC' },
    });
  }

  /** Admin — toutes les alertes sans filtre utilisateur */
  async findAll(): Promise<Alert[]> {
    return this.alertsRepository.find({ order: { createdAt: 'DESC' } });
  }

  /** Admin — alertes paginées */
  async findAllPaginated(page: number, limit: number): Promise<[Alert[], number]> {
    return this.alertsRepository.findAndCount({
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
  }

  /** Admin — alertes d'un device spécifique (pour la page détail véhicule) */
  async findByDeviceId(deviceId: number, limit = 20): Promise<Alert[]> {
    return this.alertsRepository.find({
      where: { deviceId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  /** Count open alerts for a user — based on currently assigned vehicles */
  async countOpenForUser(userId: number): Promise<number> {
    const deviceIds = await this.getAssignedDeviceIds(userId);
    if (deviceIds.length === 0) return 0;
    return this.alertsRepository.count({
      where: { deviceId: In(deviceIds), status: 'open' },
    });
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
   * Acquitte une alerte d'un utilisateur (vérifie que le device appartient à l'user).
   * Retourne l'alerte mise à jour.
   */
  async ackAlertForUser(alertId: string, userId: number): Promise<Alert> {
    const deviceIds = await this.getAssignedDeviceIds(userId);
    const alert = await this.alertsRepository.findOne({
      where: { id: alertId },
    });
    if (!alert || !deviceIds.includes(alert.deviceId)) {
      throw new NotFoundException(`Alerte introuvable`);
    }
    alert.status = 'acked';
    return this.alertsRepository.save(alert);
  }

  /**
   * Marque toutes les alertes ouvertes des véhicules assignés à l'utilisateur comme lues.
   * Retourne le nombre d'alertes mises à jour.
   */
  async markAllReadForUser(userId: number): Promise<{ updated: number }> {
    const deviceIds = await this.getAssignedDeviceIds(userId);
    if (deviceIds.length === 0) return { updated: 0 };
    const result = await this.alertsRepository
      .createQueryBuilder()
      .update(Alert)
      .set({ status: 'acked' })
      .where('device_id = ANY(:deviceIds)', { deviceIds })
      .andWhere('status = :status', { status: 'open' })
      .execute();
    return { updated: result.affected ?? 0 };
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
      const fenceAlerts = alerts.filter((a) => a.message?.includes(fence.name));
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
