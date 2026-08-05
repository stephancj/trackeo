import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum IncidentType {
  SOS = 'sos',
  THEFT = 'theft',
  SLEEP_MOVEMENT = 'sleep_movement',
  GEOFENCE_CRITICAL = 'geofence_critical',
}
export enum IncidentStatus {
  OPEN = 'open',
  ACKNOWLEDGED = 'acknowledged',
  IN_PROGRESS = 'in_progress',
  ESCALATED = 'escalated',
  RESOLVED = 'resolved',
  CANCELLED = 'cancelled',
  FALSE_ALARM = 'false_alarm',
}

@Entity({ name: 'security_incidents' })
export class SecurityIncident {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'owner_id' }) ownerId: number;
  @Column({ name: 'device_id' }) deviceId: number;
  @Column({ name: 'alert_id', type: 'uuid', nullable: true }) alertId:
    | string
    | null;
  @Column({
    name: 'source_event_id',
    type: 'bigint',
    nullable: true,
    unique: true,
  })
  sourceEventId: string | null;
  @Column({ type: 'varchar', length: 40 }) type: IncidentType;
  @Column({ type: 'varchar', length: 40, default: IncidentStatus.OPEN })
  status: IncidentStatus;
  @Column({ type: 'varchar', length: 20, default: 'critical' })
  severity: string;
  @Column({ type: 'text', nullable: true }) title: string | null;
  @Column({ type: 'text', nullable: true }) description: string | null;
  @Column({ type: 'double precision', nullable: true }) lat: number | null;
  @Column({ type: 'double precision', nullable: true }) lon: number | null;
  @Column({ name: 'assigned_to', type: 'integer', nullable: true }) assignedTo:
    | number
    | null;
  @Column({ name: 'cancel_until', type: 'timestamptz', nullable: true })
  cancelUntil: Date | null;
  @Column({ name: 'escalate_at', type: 'timestamptz', nullable: true })
  escalateAt: Date | null;
  @Column({ name: 'acknowledged_at', type: 'timestamptz', nullable: true })
  acknowledgedAt: Date | null;
  @Column({ name: 'escalated_at', type: 'timestamptz', nullable: true })
  escalatedAt: Date | null;
  @Column({ name: 'resolved_at', type: 'timestamptz', nullable: true })
  resolvedAt: Date | null;
  @Column({ name: 'resolution_note', type: 'text', nullable: true })
  resolutionNote: string | null;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
