import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Device } from '../devices/device.entity';
import { Position } from '../positions/position.entity';
import { User } from '../users/user.entity';

export default (): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USER ?? 'trackeo',
  password: process.env.DB_PASS ?? 'Password_1234',
  database: process.env.DB_NAME ?? 'traccar_db',
  entities: [Device, Position, User],
  // migrations exclues du runtime — lancées manuellement via `npm run migration:run`
  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
});
