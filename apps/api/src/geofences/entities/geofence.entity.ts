import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'geofences' })
export class Geofence {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 255 })
  name: string;

  @Column({ name: 'user_id' })
  userId: number;

  @Column({ name: 'device_ids', type: 'int', array: true, default: [] })
  deviceIds: number[];

  @Column({ name: 'center_lat', type: 'double precision' })
  centerLat: number;

  @Column({ name: 'center_lon', type: 'double precision' })
  centerLon: number;

  @Column({ name: 'radius_m' })
  radiusM: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
