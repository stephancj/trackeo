import { Controller, Get, Param, ParseIntPipe } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { Device } from './device.entity';

@Controller('devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Get()
  findAll(): Promise<Device[]> {
    return this.devicesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number): Promise<Device> {
    return this.devicesService.findOne(id);
  }
}
