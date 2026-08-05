import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlertTheft1775600000001 implements MigrationInterface {
  name = 'AlertTheft1775600000001';
  async up(queryRunner: QueryRunner) {
    await queryRunner.query(`DO $$
      DECLARE enum_name TEXT;
      BEGIN
        SELECT typname INTO enum_name FROM pg_type
        WHERE typname IN ('alerts_type_enum', 'alert_type')
        ORDER BY CASE WHEN typname = 'alerts_type_enum' THEN 0 ELSE 1 END LIMIT 1;
        IF enum_name IS NOT NULL THEN
          EXECUTE format('ALTER TYPE %I ADD VALUE IF NOT EXISTS %L', enum_name, 'theft');
        END IF;
      END $$`);
  }
  async down() {
    // Une valeur enum PostgreSQL ne peut être retirée sans recréer le type.
  }
}
