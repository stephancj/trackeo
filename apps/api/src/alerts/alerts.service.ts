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
}
