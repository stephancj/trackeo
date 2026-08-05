import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { MigrationInterface, QueryRunner } from 'typeorm';

export class ReconcileApiSchema1775500000001 implements MigrationInterface {
  name = 'ReconcileApiSchema1775500000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    const candidates = [
      resolve(process.cwd(), 'migrations/014_reconcile_api_schema.sql'),
      resolve(
        process.cwd(),
        'apps/api/migrations/014_reconcile_api_schema.sql',
      ),
    ];
    const path = candidates.find((candidate) => {
      try {
        readFileSync(candidate);
        return true;
      } catch {
        return false;
      }
    });
    if (!path) throw new Error('014_reconcile_api_schema.sql introuvable');
    await queryRunner.query(readFileSync(path, 'utf8'));
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE IF EXISTS waitlist_subscribers');
    await queryRunner.query(
      'ALTER TABLE alerts DROP COLUMN IF EXISTS lon, DROP COLUMN IF EXISTS lat',
    );
    await queryRunner.query('ALTER TABLE geofences DROP COLUMN IF EXISTS type');
    // Les valeurs enum sont conservées : PostgreSQL impose de recréer le type
    // pour les retirer, ce qui rendrait un rollback inutilement destructif.
  }
}
