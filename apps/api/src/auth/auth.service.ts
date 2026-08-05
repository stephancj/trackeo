import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../users/users.service';
import { User, UserRole } from '../users/user.entity';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtPayload } from './jwt.strategy';
import { EntitlementsService } from '../entitlements/entitlements.service';

export interface AuthResponse {
  access_token: string;
  user: {
    id: number;
    email: string;
    name: string | null;
    phone: string | null;
    role: string;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly entitlementsService: EntitlementsService,
  ) {}

  async login(dto: LoginDto): Promise<AuthResponse> {
    const user = await this.usersService.findByIdentifierWithPassword(
      dto.identifier ?? dto.email!,
    );

    if (!user) {
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Identifiant ou mot de passe incorrect');
    }

    return this.buildResponse(user);
  }

  async register(dto: RegisterDto): Promise<AuthResponse> {
    const user = await this.usersService.create({
      email: dto.email,
      password: dto.password,
      name: dto.name,
      phone: dto.phone,
      role: UserRole.USER,
    });
    await this.entitlementsService.ensureDefaultSubscription(user.id);
    return this.buildResponse(user);
  }

  async deleteAccount(userId: number, password: string): Promise<void> {
    await this.usersService.deleteAccount(userId, password);
  }

  private buildResponse(user: User): AuthResponse {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    };
  }
}
