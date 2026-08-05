import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Geofence } from './entities/geofence.entity';
import {
  CreateGeofenceDto,
  UpdateGeofenceDto,
} from './dto/create-geofence.dto';
import { EntitlementsService } from '../entitlements/entitlements.service';

@Injectable()
export class GeofencesService {
  constructor(
    @InjectRepository(Geofence)
    private readonly geofencesRepository: Repository<Geofence>,
    private readonly entitlementsService: EntitlementsService,
  ) {}

  async create(
    userId: number,
    createGeofenceDto: CreateGeofenceDto,
  ): Promise<Geofence> {
    await this.entitlementsService.assertFeature(userId, 'geofence_alerts');
    await this.entitlementsService.assertCanAddGeofence(userId);
    if (createGeofenceDto.alertViaWhatsapp) {
      await this.entitlementsService.assertFeature(
        userId,
        'whatsapp_notifications',
      );
    }
    const geofence = this.geofencesRepository.create({
      ...createGeofenceDto,
      userId,
    });
    return this.geofencesRepository.save(geofence);
  }

  async findAllForUser(userId: number): Promise<Geofence[]> {
    return this.geofencesRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findAllActive(): Promise<Geofence[]> {
    return this.geofencesRepository.find({
      where: { isActive: true },
    });
  }

  async findOne(id: number, userId: number): Promise<Geofence> {
    const geofence = await this.geofencesRepository.findOne({
      where: { id, userId },
    });
    if (!geofence) {
      throw new NotFoundException(`Geofence #${id} not found`);
    }
    return geofence;
  }

  async update(
    id: number,
    userId: number,
    updateGeofenceDto: UpdateGeofenceDto,
  ): Promise<Geofence> {
    if (updateGeofenceDto.alertViaWhatsapp) {
      await this.entitlementsService.assertFeature(
        userId,
        'whatsapp_notifications',
      );
    }
    const geofence = await this.findOne(id, userId);
    Object.assign(geofence, updateGeofenceDto);
    return this.geofencesRepository.save(geofence);
  }

  async remove(id: number, userId: number): Promise<void> {
    const geofence = await this.findOne(id, userId);
    await this.geofencesRepository.remove(geofence);
  }

  /** Admin — toutes les geofences sans filtre utilisateur */
  async findAll(): Promise<Geofence[]> {
    return this.geofencesRepository.find({ order: { createdAt: 'DESC' } });
  }

  /** Geofences liées à un device donné (deviceIds @> [deviceId]) */
  async findByDeviceId(deviceId: number): Promise<Geofence[]> {
    return this.geofencesRepository
      .createQueryBuilder('g')
      .where(':deviceId = ANY(g.device_ids)', { deviceId })
      .orderBy('g.created_at', 'DESC')
      .getMany();
  }

  /** Compte les geofences d'un user donné */
  async countForUser(userId: number): Promise<number> {
    return this.geofencesRepository.count({ where: { userId } });
  }

  /** Admin — supprime une geofence sans vérification d'ownership */
  async removeByIdAdmin(id: string): Promise<void> {
    const result = await this.geofencesRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException(`Geofence ${id} not found`);
    }
  }
}
