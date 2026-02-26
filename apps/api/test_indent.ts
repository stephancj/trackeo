import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { Device } from './src/devices/device.entity';
import { Position } from './src/positions/position.entity';

const dataSource = new DataSource({
    type: 'postgres',
});
