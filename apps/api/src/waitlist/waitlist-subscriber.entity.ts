import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'waitlist_subscribers' })
@Index('IDX_waitlist_subscribers_email', ['email'], { unique: true })
export class WaitlistSubscriber {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 320 })
  email: string;

  @Column({ length: 64, default: 'landing' })
  source: string;

  @Column({ length: 24, default: 'subscribed' })
  status: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'unsubscribed_at', type: 'timestamptz', nullable: true })
  unsubscribedAt: Date | null;
}
