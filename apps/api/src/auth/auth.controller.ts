/* eslint-disable @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-member-access */
import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  Get,
  UseGuards,
  Request,
  Patch,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateAlertSettingsDto } from './dto/update-alert-settings.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  /**
   * POST /api/auth/login
   * { "email": "admin@trackeo.mg", "password": "xxx" }
   * → { access_token, user }
   */
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  /**
   * POST /api/auth/register
   * Réservé à l'admin — à protéger en prod ou supprimer après setup.
   */
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  /**
   * GET /api/auth/me — Retourne l'utilisateur connecté
   */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  getProfile(@Request() req) {
    return req.user;
  }

  /**
   * POST /api/auth/push-token
   * { "subscriptionId": "f0817bf1-..." }
   * Enregistre le subscription ID OneSignal pour l'utilisateur connecté.
   * Permet d'envoyer des pushs via include_subscription_ids (sans External ID).
   */
  @Post('push-token')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async savePushToken(
    @Request() req,
    @Body() body: { subscriptionId: string },
  ) {
    // req.user est le User entity retourné par JwtStrategy.validate()
    await this.usersService.saveSubscriptionId(
      req.user.id as number,
      body.subscriptionId,
    );
    return { ok: true };
  }

  /**
   * PATCH /api/auth/profile
   * { "name": "John Doe", "phone": "+261341234567" }
   * Met à jour le profil de l'utilisateur connecté.
   */
  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Request() req, @Body() dto: UpdateProfileDto) {
    const updated = await this.usersService.updateUser(
      req.user.id as number,
      dto,
    );
    return updated;
  }

  /**
   * PATCH /api/auth/alert-settings
   * { "alertsEnabled": true, "alertSos": true, "alertLowBattery": true, ... }
   * Met à jour les paramètres d'alerte de l'utilisateur connecté.
   */
  @Patch('alert-settings')
  @UseGuards(JwtAuthGuard)
  async updateAlertSettings(
    @Request() req,
    @Body() dto: UpdateAlertSettingsDto,
  ) {
    const updated = await this.usersService.updateAlertSettings(
      req.user.id as number,
      dto,
    );
    return updated;
  }
}
