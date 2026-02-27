import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Device } from './device.entity';

@Injectable()
export class DevicesService {
  constructor(
    @InjectRepository(Device)
    private readonly deviceRepo: Repository<Device>,
  ) {}

  findAll(): Promise<Device[]> {
    return this.deviceRepo.find({ order: { id: 'ASC' } });
  }

  async findOne(id: number): Promise<Device> {
    const device = await this.deviceRepo.findOneBy({ id });
    if (!device) throw new NotFoundException(`Device #${id} not found`);
    return device;
  }

  async update(id: number, data: Partial<Device>): Promise<Device> {
    const device = await this.findOne(id);
    if (data.name) device.name = data.name;
    if (data.uniqueId) device.uniqueId = data.uniqueId;
    if (data.attributes) {
      device.attributes = { ...(device.attributes || {}), ...data.attributes };
    }
    return this.deviceRepo.save(device);
  }
}
