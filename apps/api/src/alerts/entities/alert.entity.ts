import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
} from 'typeorm';

export enum AlertType {
  GEOFENCE_ENTER = 'geofence_enter',
  GEOFENCE_EXIT = 'geofence_exit',
  SOS = 'sos',
  LOW_BATTERY = 'low_battery',
  SPEED_LIMIT = 'speed_limit',
  SLEEP_MOVEMENT = 'sleep_movement',
  THEFT = 'theft',
}

@Entity({ name: 'alerts' })
export class Alert {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'device_id' })
  deviceId: number;

  @Column({ name: 'owner_id' })
  ownerId: number;

  @Column({ type: 'enum', enum: AlertType })
  type: AlertType;

  @Column({ nullable: true })
  message: string;

  @Column({ default: 'open' })
  status: string;

  /** Position où l'alerte s'est produite (ex. lieu de l'excès). Nullable. */
  @Column({ type: 'double precision', nullable: true })
  lat: number | null;

  @Column({ type: 'double precision', nullable: true })
  lon: number | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
