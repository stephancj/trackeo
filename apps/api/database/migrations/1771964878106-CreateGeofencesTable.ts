import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateGeofencesTable1771964878106 implements MigrationInterface {
    name = 'CreateGeofencesTable1771964878106';

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `CREATE TABLE "geofences" ("id" SERIAL NOT NULL, "name" character varying(255) NOT NULL, "user_id" integer NOT NULL, "device_id" integer, "center_lat" double precision NOT NULL, "center_lon" double precision NOT NULL, "radius_m" integer NOT NULL, "is_active" boolean NOT NULL DEFAULT true, "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_1c858c4e20c26a6e5b2a1a10c82" PRIMARY KEY ("id"))`,
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "geofences"`);
    }
}
