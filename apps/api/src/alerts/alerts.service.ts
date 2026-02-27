import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Alert, AlertType } from './entities/alert.entity';

@Injectable()
export class AlertsService {
  constructor(
    @InjectRepository(Alert)
    private readonly alertsRepository: Repository<Alert>,
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
}
