import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum CouponRewardType {
  FREE_PLAN_GIFT = 'FREE_PLAN_GIFT',
  FREE_SUBSCRIPTION_DAYS = 'FREE_SUBSCRIPTION_DAYS',
  PERCENTAGE_DISCOUNT = 'PERCENTAGE_DISCOUNT',
  FIXED_DISCOUNT = 'FIXED_DISCOUNT',
  VEHICLE_QUOTA_BONUS = 'VEHICLE_QUOTA_BONUS',
}

@Entity({ name: 'coupons' })
export class Coupon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 50, unique: true })
  code: string;

  @Column({
    type: 'varchar',
    name: 'reward_type',
    length: 50,
  })
  rewardType: CouponRewardType;

  @Column({
    type: 'numeric',
    name: 'reward_value',
    precision: 12,
    scale: 2,
    default: 0,
  })
  rewardValue: string;

  /** ID du plan offert (pour FREE_PLAN_GIFT) */
  @Column({ name: 'granted_plan_id', type: 'uuid', nullable: true })
  grantedPlanId: string | null;

  /** ID du plan éligible (pour les réductions) */
  @Column({ name: 'target_plan_id', type: 'uuid', nullable: true })
  targetPlanId: string | null;

  @Column({
    type: 'numeric',
    name: 'min_plan_price',
    precision: 12,
    scale: 2,
    default: 0,
  })
  minPlanPrice: string;

  @Column({ name: 'max_redemptions', type: 'integer', nullable: true })
  maxRedemptions: number | null;

  @Column({ name: 'redemptions_count', type: 'integer', default: 0 })
  redemptionsCount: number;

  @Column({ name: 'max_redemptions_per_user', type: 'integer', default: 1 })
  maxRedemptionsPerUser: number;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt: Date | null;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
