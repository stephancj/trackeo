import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  /** Recherche par email (inclut le hash password pour la validation) */
  findByEmailWithPassword(email: string): Promise<User | null> {
    return this.userRepo
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.email = :email', { email })
      .andWhere('user.isActive = true')
      .getOne();
  }

  findById(id: number): Promise<User | null> {
    return this.userRepo.findOneBy({ id, isActive: true });
  }

  /** Admin — recherche sans filtre isActive (inclut les comptes désactivés) */
  findByIdAdmin(id: number): Promise<User | null> {
    return this.userRepo.findOneBy({ id });
  }

  async create(data: {
    email: string;
    password: string;
    name?: string;
    role?: UserRole;
  }): Promise<User> {
    const existing = await this.userRepo.findOneBy({ email: data.email });
    if (existing) throw new ConflictException('Email already in use');

    const hashed = await bcrypt.hash(data.password, 12);
    const user = this.userRepo.create({
      ...data,
      password: hashed,
    });
    return this.userRepo.save(user);
  }

  /** Enregistre le subscription ID OneSignal pour ciblage push direct. */
  async saveSubscriptionId(userId: number, subId: string): Promise<void> {
    await this.userRepo.update(userId, { onesignalSubId: subId });
  }

  /** Met à jour le profil utilisateur (name, phone). */
  async updateUser(
    userId: number,
    data: { name?: string; phone?: string },
  ): Promise<User | null> {
    await this.userRepo.update(userId, data);
    return this.findById(userId);
  }

  /** Met à jour les paramètres d'alerte de l'utilisateur. */
  async updateAlertSettings(
    userId: number,
    data: {
      alertsEnabled?: boolean;
      alertSos?: boolean;
      alertLowBattery?: boolean;
      alertSpeedLimit?: boolean;
      alertViaPush?: boolean;
      alertViaWhatsapp?: boolean;
    },
  ): Promise<User | null> {
    await this.userRepo.update(userId, data);
    return this.findById(userId);
  }

  findAll(): Promise<User[]> {
    return this.userRepo.find({ order: { createdAt: 'DESC' } });
  }

  /** Admin — mise à jour étendue (role, isActive inclus) */
  async adminUpdate(
    userId: number,
    data: { name?: string; phone?: string; role?: UserRole; isActive?: boolean },
  ): Promise<User | null> {
    await this.userRepo.update(userId, data);
    return this.userRepo.findOneBy({ id: userId });
  }
}
