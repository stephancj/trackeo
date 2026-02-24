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
}
