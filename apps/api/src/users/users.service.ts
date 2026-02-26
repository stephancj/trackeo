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

  findAll(): Promise<User[]> {
    return this.userRepo.find({ order: { createdAt: 'DESC' } });
  }
}
