import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Unique,
} from 'typeorm';

/**
 * Table `device_assignments` — propre à l'API (pas une table Traccar).
 * Lie un device Traccar (tc_devices.id) à un owner (users.id).
 * Un device ne peut être lié qu'à un seul owner à la fois.
 */
@Entity({ name: 'device_assignments' })
@Unique(['deviceId'])
export class DeviceAssignment {
  @PrimaryGeneratedColumn()
  id: number;

  /** ID du device dans tc_devices */
  @Column({ name: 'device_id' })
  deviceId: number;

  /** ID de l'owner dans la table users */
  @Column({ name: 'user_id' })
  userId: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
