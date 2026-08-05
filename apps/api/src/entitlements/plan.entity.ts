import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { PlanFeature } from './plan-feature.entity';

@Entity({ name: 'plans' })
export class Plan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 50, unique: true })
  code: string;

  @Column({ length: 100 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({
    name: 'price_monthly',
    type: 'numeric',
    precision: 12,
    scale: 2,
    default: 0,
  })
  priceMonthly: string;

  @Column({ length: 3, default: 'MGA' })
  currency: string;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'display_order', default: 0 })
  displayOrder: number;

  @OneToMany(() => PlanFeature, (planFeature) => planFeature.plan, {
    cascade: false,
  })
  planFeatures: PlanFeature[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
