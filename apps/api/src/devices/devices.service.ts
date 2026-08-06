import {
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
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

  findAllPaginated(page: number, limit: number): Promise<[Device[], number]> {
    return this.deviceRepo.findAndCount({
      order: { id: 'ASC' },
      skip: (page - 1) * limit,
      take: limit,
    });
  }

  findByUniqueId(uniqueId: string): Promise<Device | null> {
    return this.deviceRepo.findOneBy({ uniqueId });
  }

  async provision(data: {
    uniqueId: string;
    name: string;
    plate?: string;
  }): Promise<Device> {
    const baseUrl = process.env.TRACCAR_API_URL?.replace(/\/$/, '');
    const email = process.env.TRACCAR_API_EMAIL;
    const password = process.env.TRACCAR_API_PASSWORD;
    if (!baseUrl || !email || !password) {
      throw new ServiceUnavailableException(
        'Activation automatique indisponible. Contactez le support iooeh.',
      );
    }

    const response = await fetch(`${baseUrl}/api/devices`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${email}:${password}`).toString('base64')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: data.name,
        uniqueId: data.uniqueId,
        attributes: data.plate ? { plate: data.plate } : {},
      }),
    }).catch(() => null);

    if (!response?.ok) {
      throw new ServiceUnavailableException(
        'Le traceur n’a pas pu être activé. Réessayez ou contactez le support.',
      );
    }

    const device = await this.findByUniqueId(data.uniqueId);
    if (!device) {
      throw new ServiceUnavailableException(
        'Traceur activé mais temporairement indisponible. Réessayez.',
      );
    }
    return device;
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
