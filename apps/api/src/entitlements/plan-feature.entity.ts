import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Feature } from './feature.entity';
import { Plan } from './plan.entity';

@Entity({ name: 'plan_features' })
@Unique(['planId', 'featureId'])
export class PlanFeature {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'plan_id', type: 'uuid' })
  planId: string;

  @Column({ name: 'feature_id', type: 'uuid' })
  featureId: string;

  @Column({ default: true })
  enabled: boolean;

  @Column({ type: 'jsonb', nullable: true })
  value: boolean | number | string | null;

  @ManyToOne(() => Plan, (plan) => plan.planFeatures, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'plan_id' })
  plan: Plan;

  @ManyToOne(() => Feature, (feature) => feature.planFeatures, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'feature_id' })
  feature: Feature;
}
