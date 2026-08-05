import { MigrationInterface, QueryRunner } from 'typeorm';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export class CreateEntitlements1775500000000 implements MigrationInterface {
  name = 'CreateEntitlements1775500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const candidates = [
      resolve(process.cwd(), 'migrations/013_entitlements.sql'),
      resolve(process.cwd(), 'apps/api/migrations/013_entitlements.sql'),
    ];
    const path = candidates.find((candidate) => {
      try {
        readFileSync(candidate);
        return true;
      } catch {
        return false;
      }
    });
    if (!path) throw new Error('013_entitlements.sql introuvable');
    await queryRunner.query(readFileSync(path, 'utf8'));
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE subscriptions DROP COLUMN IF EXISTS plan_id',
    );
    await queryRunner.query('DROP TABLE IF EXISTS plan_features');
    await queryRunner.query('DROP TABLE IF EXISTS features');
    await queryRunner.query('DROP TABLE IF EXISTS plans');
  }
}
