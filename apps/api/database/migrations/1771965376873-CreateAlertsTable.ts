import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAlertsTable1771965376873 implements MigrationInterface {
    name = 'CreateAlertsTable1771965376873';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `CREATE TYPE "public"."alerts_type_enum" AS ENUM('geofence_enter', 'geofence_exit')`,
        );
        await queryRunner.query(
            `CREATE TABLE "alerts" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "device_id" integer NOT NULL, "owner_id" integer NOT NULL, "type" "public"."alerts_type_enum" NOT NULL, "message" character varying, "status" character varying NOT NULL DEFAULT 'open', "created_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_60f895662df096bfcdfab7f4b96" PRIMARY KEY ("id"))`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "alerts"`);
        await queryRunner.query(`DROP TYPE "public"."alerts_type_enum"`);
    }
}
