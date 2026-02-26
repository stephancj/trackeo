import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Mappe la table `tc_devices` gérée par Traccar.
 * synchronize: false → TypeORM ne modifie jamais ce schéma.
 */
@Entity({ name: 'tc_devices' })
export class Device {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 128 })
  name: string;

  /** Identifiant unique (IMEI, numéro de série…) */
  @Column({ name: 'uniqueid', length: 128, unique: true })
  uniqueId: string;

  /** online | offline | unknown */
  @Column({ length: 32, nullable: true })
  status: string;

  @Column({
    name: 'lastupdate',
    type: 'timestamp with time zone',
    nullable: true,
  })
  lastUpdate: Date;

  @Column({ nullable: true })
  positionid: number;

  @Column({ nullable: true })
  groupid: number;

  @Column({ default: false })
  disabled: boolean;

  @Column({
    name: 'attributes',
    type: 'text',
    nullable: true,
    transformer: {
      to: (value: any) => (value ? JSON.stringify(value) : null),
      from: (value: any) => {
        if (typeof value === 'string') {
          try {
            return JSON.parse(value);
          } catch {
            return value;
          }
        }
        return value;
      },
    },
  })
  attributes: Record<string, any>;
}
