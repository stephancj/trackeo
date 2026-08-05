import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'incident_events' })
export class IncidentEvent {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'incident_id', type: 'uuid' }) incidentId: string;
  @Column({ name: 'actor_id', type: 'integer', nullable: true }) actorId:
    | number
    | null;
  @Column({ type: 'varchar', length: 50 }) action: string;
  @Column({ type: 'text', nullable: true }) note: string | null;
  @Column({ type: 'jsonb', nullable: true }) metadata: Record<
    string,
    unknown
  > | null;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
