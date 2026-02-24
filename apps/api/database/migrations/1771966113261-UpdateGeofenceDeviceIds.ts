import { MigrationInterface, QueryRunner } from "typeorm";

export class UpdateGeofenceDeviceIds1771966113261 implements MigrationInterface {
    name = 'UpdateGeofenceDeviceIds1771966113261'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "geofences" DROP COLUMN "device_id"`);
        await queryRunner.query(`ALTER TABLE "geofences" ADD "device_ids" integer array NOT NULL DEFAULT '{}'`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "geofences" DROP COLUMN "device_ids"`);
        await queryRunner.query(`ALTER TABLE "geofences" ADD "device_id" integer`);
    }

}
