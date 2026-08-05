import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { MigrationInterface, QueryRunner } from 'typeorm';

export class SecurityPaymentsTrips1775600000000 implements MigrationInterface {
  name = 'SecurityPaymentsTrips1775600000000';
  async up(queryRunner: QueryRunner) {
    const candidates = [
      resolve(process.cwd(), 'migrations/015_security_payments_trips.sql'),
      resolve(
        process.cwd(),
        'apps/api/migrations/015_security_payments_trips.sql',
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
    if (!path) throw new Error('015_security_payments_trips.sql introuvable');
    await queryRunner.query(readFileSync(path, 'utf8'));
  }
  async down(queryRunner: QueryRunner) {
    await queryRunner.query(
      'DROP TABLE IF EXISTS trips, payments, public_tracking_links, incident_events, security_incidents CASCADE',
    );
  }
}
