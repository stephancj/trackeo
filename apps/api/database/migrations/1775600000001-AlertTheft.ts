import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlertTheft1775600000001 implements MigrationInterface {
  name = 'AlertTheft1775600000001';
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(
      "ALTER TYPE alerts_type_enum ADD VALUE IF NOT EXISTS 'theft'",
    );
  }
  async down() {
    // Une valeur enum PostgreSQL ne peut être retirée sans recréer le type.
  }
}
