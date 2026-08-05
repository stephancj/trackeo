import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'trips' })
@Index('UQ_trips_device_start', ['deviceId', 'startTime'], { unique: true })
export class Trip {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'device_id' }) deviceId: number;
  @Column({ name: 'owner_id', type: 'integer', nullable: true }) ownerId:
    | number
    | null;
  @Column({ name: 'start_ts', type: 'timestamptz' }) startTime: Date;
  @Column({ name: 'end_ts', type: 'timestamptz' }) endTime: Date;
  @Column({ name: 'distance_km', type: 'double precision' }) distanceKm: number;
  @Column({ name: 'duration_s' }) durationSec: number;
  @Column({ name: 'max_speed_kmh', type: 'double precision' })
  maxSpeedKmh: number;
  @Column({ name: 'start_lat', type: 'double precision' }) startLat: number;
  @Column({ name: 'start_lon', type: 'double precision' }) startLon: number;
  @Column({ name: 'end_lat', type: 'double precision' }) endLat: number;
  @Column({ name: 'end_lon', type: 'double precision' }) endLon: number;
  @Column({ name: 'point_count' }) pointCount: number;
  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" }) path: Array<{
    lat: number;
    lon: number;
    at: string;
    speedKmh: number;
  }>;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
