import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum ReferralStatus {
  PENDING = 'pending',
  QUALIFIED = 'qualified',
  REWARDED = 'rewarded',
}

@Entity({ name: 'referrals' })
export class Referral {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'referrer_id' })
  referrerId: number;

  @Column({ name: 'referee_id', unique: true })
  refereeId: number;

  @Column({ name: 'code_used', length: 30 })
  codeUsed: string;

  @Column({
    type: 'varchar',
    length: 30,
    default: ReferralStatus.PENDING,
  })
  status: ReferralStatus;

  @Column({ name: 'referrer_reward_type', length: 50, default: 'FREE_SUBSCRIPTION_DAYS' })
  referrerRewardType: string;

  @Column({
    type: 'numeric',
    name: 'referrer_reward_value',
    precision: 12,
    scale: 2,
    default: 30,
  })
  referrerRewardValue: string;

  @Column({ name: 'referee_reward_type', length: 50, default: 'PERCENTAGE_DISCOUNT' })
  refereeRewardType: string;

  @Column({
    type: 'numeric',
    name: 'referee_reward_value',
    precision: 12,
    scale: 2,
    default: 20,
  })
  refereeRewardValue: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
