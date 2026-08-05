import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'vehicle_sleep_modes' })
export class VehicleSleepMode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'device_id', unique: true })
  deviceId: number;

  @Column({ name: 'owner_id' })
  ownerId: number;

  @Column({ default: true })
  active: boolean;

  @Column({ name: 'armed_lat', type: 'double precision' })
  armedLat: number;

  @Column({ name: 'armed_lon', type: 'double precision' })
  armedLon: number;

  @Column({ name: 'movement_threshold_m', default: 100 })
  movementThresholdM: number;

  @Column({ name: 'triggered_at', type: 'timestamptz', nullable: true })
  triggeredAt: Date | null;

  @Column({ name: 'last_distance_m', type: 'double precision', default: 0 })
  lastDistanceM: number;

  @CreateDateColumn({ name: 'armed_at', type: 'timestamptz' })
  armedAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
