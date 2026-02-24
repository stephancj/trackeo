import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { AdminService } from './admin.service';
import { CreateUserDto } from './admin.dto';

/**
 * Routes admin — accessibles uniquement aux users avec role = 'admin'.
 * Toutes les routes sont protégées par JwtAuthGuard + RolesGuard.
 *
 * Exemples d'appels curl :
 *
 *   # Lister les users
 *   curl -H "Authorization: Bearer <token>" http://localhost:3000/api/admin/users
 *
 *   # Créer un owner
 *   curl -X POST -H "Authorization: Bearer <token>" \
 *        -H "Content-Type: application/json" \
 *        -d '{"email":"owner@test.com","password":"motdepasse","name":"Jean"}' \
 *        http://localhost:3000/api/admin/users
 *
 *   # Lister les devices avec statut d'assignation
 *   curl -H "Authorization: Bearer <token>" http://localhost:3000/api/admin/devices
 *
 *   # Assigner le device 1 au user 2
 *   curl -X POST -H "Authorization: Bearer <token>" \
 *        http://localhost:3000/api/admin/devices/1/assign/2
 *
 *   # Désassigner le device 1
 *   curl -X DELETE -H "Authorization: Bearer <token>" \
 *        http://localhost:3000/api/admin/devices/1/assign
 */
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ── Users ────────────────────────────────────────────────────────────────

  /** Liste tous les comptes (id, email, name, role, isActive, createdAt) */
  @Get('users')
  listUsers() {
    return this.adminService.listUsers();
  }

  /** Créer un compte owner (ou admin). Mot de passe hashé automatiquement. */
  @Post('users')
  createUser(@Body() dto: CreateUserDto) {
    return this.adminService.createUser(dto);
  }

  // ── Devices ──────────────────────────────────────────────────────────────

  /** Liste tous les devices Traccar avec leur user assigné (null si non assigné) */
  @Get('devices')
  listDevices() {
    return this.adminService.listDevices();
  }

  /** Lier un device Traccar à un owner. Remplace l'assignation existante. */
  @Post('devices/:deviceId/assign/:userId')
  @HttpCode(HttpStatus.OK)
  assignDevice(
    @Param('deviceId', ParseIntPipe) deviceId: number,
    @Param('userId', ParseIntPipe) userId: number,
  ) {
    return this.adminService.assignDevice(deviceId, userId);
  }

  /** Retirer l'assignation d'un device */
  @Delete('devices/:deviceId/assign')
  @HttpCode(HttpStatus.NO_CONTENT)
  unassignDevice(@Param('deviceId', ParseIntPipe) deviceId: number) {
    return this.adminService.unassignDevice(deviceId);
  }
}
