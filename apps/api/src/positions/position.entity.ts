import { Entity, Column, PrimaryGeneratedColumn, Index } from 'typeorm';

/**
 * Mappe la table `tc_positions` gérée par Traccar.
 * Lecture seule — synchronize: false.
 */
@Entity({ name: 'tc_positions' })
@Index(['deviceId', 'deviceTime'])
export class Position {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'deviceid' })
  deviceId: number;

  @Column({ name: 'servertime', type: 'timestamp with time zone' })
  serverTime: Date;

  @Column({ name: 'devicetime', type: 'timestamp with time zone' })
  deviceTime: Date;

  @Column({ name: 'fixtime', type: 'timestamp with time zone' })
  fixTime: Date;

  @Column({ type: 'boolean', default: true })
  valid: boolean;

  @Column({ type: 'double precision' })
  latitude: number;

  @Column({ type: 'double precision' })
  longitude: number;

  @Column({ type: 'double precision', default: 0 })
  altitude: number;

  /** Vitesse en km/h (Traccar stocke en nœuds → on convertit dans le service) */
  @Column({ type: 'double precision', default: 0 })
  speed: number;

  /** Cap en degrés (0-359) */
  @Column({ type: 'double precision', default: 0 })
  course: number;

  @Column({ type: 'double precision', nullable: true })
  accuracy: number;

  /** Attributs JSON (batterie, ignition, odometer…) */
  @Column({ type: 'varchar', nullable: true })
  attributes: string;

  @Column({ type: 'varchar', nullable: true })
  address: string;

  @Column({ nullable: true })
  network: string;
}
