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

  @Column({
    name: 'verification_token_hash',
    type: 'char',
    length: 64,
    nullable: true,
    select: false,
  })
  verificationTokenHash: string | null;

  @Column({
    name: 'verification_expires_at',
    type: 'timestamptz',
    nullable: true,
  })
  verificationExpiresAt: Date | null;

  @Column({
    name: 'verification_sent_at',
    type: 'timestamptz',
    nullable: true,
  })
  verificationSentAt: Date | null;

  @Column({ name: 'verified_at', type: 'timestamptz', nullable: true })
  verifiedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @Column({ name: 'unsubscribed_at', type: 'timestamptz', nullable: true })
  unsubscribedAt: Date | null;
}
