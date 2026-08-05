import { MigrationInterface, QueryRunner } from 'typeorm';

export class PapiPaymentReference1775700000000 implements MigrationInterface {
  name = 'PapiPaymentReference1775700000000';

  async up(queryRunner: QueryRunner) {
    await queryRunner.query(
      'ALTER TABLE payments ADD COLUMN IF NOT EXISTS papi_payment_reference VARCHAR(100)',
    );
    await queryRunner.query(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_payments_papi_payment_reference ON payments(papi_payment_reference) WHERE papi_payment_reference IS NOT NULL',
    );
  }

  async down(queryRunner: QueryRunner) {
    await queryRunner.query(
      'DROP INDEX IF EXISTS uq_payments_papi_payment_reference',
    );
    await queryRunner.query(
      'ALTER TABLE payments DROP COLUMN IF EXISTS papi_payment_reference',
    );
  }
}
