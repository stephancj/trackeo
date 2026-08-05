import {
  Injectable,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
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

  /** Recherche par email ou téléphone (inclut le hash pour la validation). */
  findByIdentifierWithPassword(identifier: string): Promise<User | null> {
    const normalizedIdentifier = identifier.trim().toLowerCase();
    const normalizedPhone = this.normalizePhone(identifier);

    return this.userRepo
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('(LOWER(user.email) = :identifier OR user.phone = :phone)', {
        identifier: normalizedIdentifier,
        phone: normalizedPhone,
      })
      .andWhere('user.isActive = true')
      .getOne();
  }

  findByIdWithPassword(id: number): Promise<User | null> {
    return this.userRepo
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.id = :id', { id })
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
    phone?: string;
    role?: UserRole;
  }): Promise<User> {
    const email = data.email.trim().toLowerCase();
    const phone = data.phone ? this.normalizePhone(data.phone) : undefined;
    const existing = await this.userRepo
      .createQueryBuilder('user')
      .where('LOWER(user.email) = :email', { email })
      .orWhere(phone ? 'user.phone = :phone' : 'FALSE', { phone })
      .getOne();
    if (existing) {
      throw new ConflictException(
        existing.email.toLowerCase() === email
          ? 'Cette adresse email est déjà utilisée'
          : 'Ce numéro de téléphone est déjà utilisé',
      );
    }

    const hashed = await bcrypt.hash(data.password, 12);
    const user = this.userRepo.create({
      ...data,
      email,
      phone,
      password: hashed,
    });
    return this.userRepo.save(user);
  }

  /** Supprime le compte et ses données iooeh après confirmation du mot de passe. */
  async deleteAccount(userId: number, password: string): Promise<void> {
    const user = await this.findByIdWithPassword(userId);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      throw new UnauthorizedException('Mot de passe incorrect');
    }

    await this.userRepo.manager.transaction(async (manager) => {
      const subscriptionTable = await manager.query(
        "SELECT to_regclass('public.subscriptions') IS NOT NULL AS exists",
      );
      if (subscriptionTable[0]?.exists) {
        await manager.query('DELETE FROM subscriptions WHERE user_id = $1', [
          userId,
        ]);
      }
      await manager.query('DELETE FROM alerts WHERE owner_id = $1', [userId]);
      await manager.query('DELETE FROM geofences WHERE user_id = $1', [userId]);
      await manager.query('DELETE FROM device_assignments WHERE user_id = $1', [
        userId,
      ]);
      await manager.delete(User, userId);
    });
  }

  private normalizePhone(value: string): string {
    const compact = value.replace(/[\s().-]/g, '');
    if (compact.startsWith('+261')) return compact;
    if (compact.startsWith('261')) return `+${compact}`;
    if (/^0\d{9}$/.test(compact)) return `+261${compact.substring(1)}`;
    return compact;
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
    const updateData: { name?: string; phone?: string | null } = {
      name: data.name,
    };
    if (data.phone != null) {
      const phone = data.phone.trim() ? this.normalizePhone(data.phone) : null;
      if (phone) {
        const existing = await this.userRepo.findOneBy({ phone });
        if (existing && existing.id !== userId) {
          throw new ConflictException(
            'Ce numéro de téléphone est déjà utilisé',
          );
        }
      }
      updateData.phone = phone;
    }
    await this.userRepo.update(userId, updateData);
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
    data: {
      name?: string;
      phone?: string;
      role?: UserRole;
      isActive?: boolean;
    },
  ): Promise<User | null> {
    await this.userRepo.update(userId, data);
    return this.userRepo.findOneBy({ id: userId });
  }
}
