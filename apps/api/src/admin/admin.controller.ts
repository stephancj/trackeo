import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { AdminService } from './admin.service';
import { CreateUserDto, UpdateUserDto } from './admin.dto';

/**
 * Routes admin — accessibles uniquement aux users avec role = 'admin'.
 * Toutes les routes sont protégées par JwtAuthGuard + RolesGuard.
 *
 *   GET    /api/admin/users
 *   POST   /api/admin/users
 *   PATCH  /api/admin/users/:id
 *   DELETE /api/admin/users/:id        (désactivation)
 *   GET    /api/admin/vehicles
 *   POST   /api/admin/devices/:deviceId/assign/:userId
 *   DELETE /api/admin/devices/:deviceId/assign
 *   GET    /api/admin/geofences
 *   DELETE /api/admin/geofences/:id
 *   GET    /api/admin/alerts
 *   PATCH  /api/admin/alerts/:id       (ack)
 */
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  // ── Users ────────────────────────────────────────────────────────────────

  @Get('users')
  listUsers() {
    return this.adminService.listUsers();
  }

  @Get('users/:id')
  getUserDetail(@Param('id', ParseIntPipe) id: number) {
    return this.adminService.getUserDetail(id);
  }

  @Post('users')
  createUser(@Body() dto: CreateUserDto) {
    return this.adminService.createUser(dto);
  }

  @Patch('users/:id')
  updateUser(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateUserDto,
  ) {
    return this.adminService.updateUser(id, dto);
  }

  /** Désactivation douce — ne supprime pas le compte */
  @Delete('users/:id')
  @HttpCode(HttpStatus.OK)
  deactivateUser(@Param('id', ParseIntPipe) id: number) {
    return this.adminService.deactivateUser(id);
  }

  // ── Vehicles (enriched view — replaces raw devices list) ─────────────────

  @Get('vehicles')
  listVehicles() {
    return this.adminService.listVehicles();
  }

  @Get('vehicles/:id')
  getVehicleDetail(@Param('id', ParseIntPipe) id: number) {
    return this.adminService.getVehicleDetail(id);
  }

  // ── Device assignments ────────────────────────────────────────────────────

  @Post('devices/:deviceId/assign/:userId')
  @HttpCode(HttpStatus.OK)
  assignDevice(
    @Param('deviceId', ParseIntPipe) deviceId: number,
    @Param('userId', ParseIntPipe) userId: number,
  ) {
    return this.adminService.assignDevice(deviceId, userId);
  }

  @Delete('devices/:deviceId/assign')
  @HttpCode(HttpStatus.NO_CONTENT)
  unassignDevice(@Param('deviceId', ParseIntPipe) deviceId: number) {
    return this.adminService.unassignDevice(deviceId);
  }

  // ── Geofences ────────────────────────────────────────────────────────────

  @Get('geofences')
  listGeofences() {
    return this.adminService.listGeofences();
  }

  @Delete('geofences/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeGeofence(@Param('id') id: string) {
    return this.adminService.removeGeofence(id);
  }

  // ── Alerts ───────────────────────────────────────────────────────────────

  @Get('alerts')
  listAlerts() {
    return this.adminService.listAlerts();
  }

  @Patch('alerts/:id')
  @HttpCode(HttpStatus.OK)
  ackAlert(@Param('id') id: string) {
    return this.adminService.ackAlert(id);
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  @Get('reports/overview')
  getReportsOverview() {
    return this.adminService.getReportsOverview();
  }

  @Get('reports/vehicles')
  getVehicleReports(
    @Query('period') period: 'today' | '7d' | '30d' = '7d',
  ) {
    return this.adminService.getVehicleReports(period);
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  @Get('subscriptions')
  listSubscriptions() {
    return this.adminService.listSubscriptions();
  }

  @Patch('subscriptions/:userId')
  @HttpCode(HttpStatus.OK)
  upsertSubscription(
    @Param('userId', ParseIntPipe) userId: number,
    @Body()
    body: {
      plan?: string;
      status?: string;
      nextBillingDate?: string | null;
      trialEndsAt?: string | null;
      notes?: string | null;
    },
  ) {
    return this.adminService.upsertSubscription(userId, body as Parameters<AdminService['upsertSubscription']>[1]);
  }
}
