import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { PlanFeature } from './plan-feature.entity';

export enum FeatureValueType {
  BOOLEAN = 'boolean',
  NUMBER = 'number',
  STRING = 'string',
}

@Entity({ name: 'features' })
export class Feature {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100, unique: true })
  code: string;

  @Column({ length: 150 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ length: 100, default: 'general' })
  category: string;

  @Column({ name: 'value_type', length: 20, default: FeatureValueType.BOOLEAN })
  valueType: FeatureValueType;

  @Column({ type: 'varchar', length: 50, nullable: true })
  unit: string | null;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'display_order', default: 0 })
  displayOrder: number;

  @OneToMany(() => PlanFeature, (planFeature) => planFeature.feature)
  planFeatures: PlanFeature[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
