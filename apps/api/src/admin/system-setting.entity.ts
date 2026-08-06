import { Entity, Column, PrimaryColumn } from 'typeorm';

@Entity('system_settings')
export class SystemSetting {
  @PrimaryColumn()
  key: string;

  @Column({ type: 'jsonb', nullable: true })
  value: any;

  @Column({ type: 'varchar', nullable: true })
  description: string | null;

  @Column({ type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
}
