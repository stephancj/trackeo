import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'public_tracking_links' })
export class PublicTrackingLink {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'owner_id' }) ownerId: number;
  @Column({ name: 'device_id' }) deviceId: number;
  @Column({ name: 'token_hash', type: 'varchar', length: 64, unique: true })
  tokenHash: string;
  @Column({ name: 'expires_at', type: 'timestamptz' }) expiresAt: Date;
  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt: Date | null;
  @Column({ name: 'view_count', default: 0 }) viewCount: number;
  @Column({ name: 'last_viewed_at', type: 'timestamptz', nullable: true })
  lastViewedAt: Date | null;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
