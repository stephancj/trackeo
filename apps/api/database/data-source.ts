/**
 * DataSource TypeORM — utilisé uniquement pour les migrations CLI.
 * L'app elle-même utilise database.config.ts via AppModule.
 *
 * Usage :
 *   npx typeorm-ts-node-commonjs migration:run -d database/data-source.ts
 *   npx typeorm-ts-node-commonjs migration:revert -d database/data-source.ts
 */
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: parseInt(process.env.DB_PORT ?? '5432', 10),
  username: process.env.DB_USER ?? 'trackeo',
  password: process.env.DB_PASS ?? 'Password_1234',
  database: process.env.DB_NAME ?? 'traccar_db',
  // Uniquement nos entités propres (pas les tc_*)
  entities: ['src/**/*.entity.ts'],
  migrations: ['database/migrations/*.ts'],
  synchronize: false,
  logging: true,
});
