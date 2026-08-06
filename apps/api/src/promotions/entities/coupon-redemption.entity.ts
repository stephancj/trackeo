import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
} from 'typeorm';

@Entity({ name: 'coupon_redemptions' })
export class CouponRedemption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: number;

  @Column({ name: 'coupon_id', type: 'uuid', nullable: true })
  couponId: string | null;

  @Column({ name: 'referral_id', type: 'uuid', nullable: true })
  referralId: string | null;

  @Column({ name: 'reward_type', length: 50 })
  rewardType: string;

  @Column({
    type: 'numeric',
    name: 'reward_value',
    precision: 12,
    scale: 2,
    default: 0,
  })
  rewardValue: string;

  @Column({ name: 'applied_to_payment_id', type: 'uuid', nullable: true })
  appliedToPaymentId: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
