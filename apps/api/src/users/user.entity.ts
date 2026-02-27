import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum UserRole {
  ADMIN = 'admin',
  USER = 'user',
}

/**
 * Table `users` — gérée par l'API NestJS (migration TypeORM).
 * Indépendante du schéma Traccar (tc_*).
 */
@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 255, unique: true })
  email: string;

  /** Hash bcrypt — jamais exposé dans les réponses API */
  @Column({ length: 255, select: false })
  password: string;

  @Column({ length: 255, nullable: true })
  name: string;

  @Column({ length: 50, nullable: true })
  phone: string | null;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.USER,
  })
  role: UserRole;

  /** Subscription ID OneSignal (web push) — enregistré par le client après init SDK */
  @Column({
    type: 'varchar',
    name: 'onesignal_sub_id',
    length: 255,
    nullable: true,
  })
  onesignalSubId: string | null;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  /** Alert settings */
  @Column({ name: 'alerts_enabled', default: true })
  alertsEnabled: boolean;

  @Column({ name: 'alert_sos', default: true })
  alertSos: boolean;

  @Column({ name: 'alert_low_battery', default: true })
  alertLowBattery: boolean;

  @Column({ name: 'alert_speed_limit', default: false })
  alertSpeedLimit: boolean;

  @Column({ name: 'alert_via_push', default: true })
  alertViaPush: boolean;

  @Column({ name: 'alert_via_whatsapp', default: false })
  alertViaWhatsapp: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
