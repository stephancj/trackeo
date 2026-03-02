import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeviceAssignment } from './device-assignment.entity';
import {
  Subscription,
  SubscriptionPlan,
  SubscriptionStatus,
  PLAN_VEHICLE_LIMITS,
} from './subscription.entity';
import { UsersService } from '../users/users.service';
import { DevicesService } from '../devices/devices.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { GeofencesService } from '../geofences/geofences.service';
import { AlertsService } from '../alerts/alerts.service';
import { PositionsService } from '../positions/positions.service';
import { CreateUserDto, UpdateUserDto } from './admin.dto';
import { UserRole } from '../users/user.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(DeviceAssignment)
    private readonly assignmentRepo: Repository<DeviceAssignment>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepo: Repository<Subscription>,
    private readonly usersService: UsersService,
    private readonly devicesService: DevicesService,
    private readonly vehiclesService: VehiclesService,
    private readonly geofencesService: GeofencesService,
    private readonly alertsService: AlertsService,
    private readonly positionsService: PositionsService,
  ) {}

  // ── Users ────────────────────────────────────────────────────────────────

  async listUsers() {
    const [users, assignments] = await Promise.all([
      this.usersService.findAll(),
      this.assignmentRepo.find(),
    ]);

    const vehicleCountByUser = new Map<number, number>();
    for (const a of assignments) {
      vehicleCountByUser.set(
        a.userId,
        (vehicleCountByUser.get(a.userId) ?? 0) + 1,
      );
    }

    return users.map((u) => ({
      ...u,
      vehicleCount: vehicleCountByUser.get(u.id) ?? 0,
    }));
  }

  async createUser(dto: CreateUserDto) {
    return this.usersService.create({
      email: dto.email,
      password: dto.password,
      name: dto.name,
      role: dto.role ?? UserRole.USER,
    });
  }

  async updateUser(userId: number, dto: UpdateUserDto) {
    const user = await this.usersService.findByIdAdmin(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);
    return this.usersService.adminUpdate(userId, dto);
  }

  async deactivateUser(userId: number) {
    const user = await this.usersService.findByIdAdmin(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);
    return this.usersService.adminUpdate(userId, { isActive: false });
  }

  /** Admin — détail d'un utilisateur avec ses véhicules, alertes et geofences */
  async getUserDetail(userId: number) {
    const user = await this.usersService.findByIdAdmin(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const [vehicles, openAlertsCount, geofencesCount] = await Promise.all([
      this.vehiclesService.findAllForUser(userId),
      this.alertsService.countOpenForUser(userId),
      this.geofencesService.countForUser(userId),
    ]);

    return {
      ...user,
      vehicles,
      openAlertsCount,
      geofencesCount,
    };
  }

  // ── Vehicles (enriched — device + position + assignment) ─────────────────

  async listVehicles() {
    const [vehicles, assignments, users, allAlerts] = await Promise.all([
      this.vehiclesService.findAll(),
      this.assignmentRepo.find(),
      this.usersService.findAll(),
      this.alertsService.findAll(),
    ]);

    const userMap = new Map(users.map((u) => [u.id, u.name ?? u.email]));

    const openAlertsByDevice = new Map<number, number>();
    for (const a of allAlerts) {
      if (a.status === 'open') {
        openAlertsByDevice.set(
          a.deviceId,
          (openAlertsByDevice.get(a.deviceId) ?? 0) + 1,
        );
      }
    }

    return vehicles.map((v) => {
      const assignment = assignments.find((a) => a.deviceId === v.id);
      return {
        ...v,
        assignedUserId: assignment?.userId ?? null,
        assignedUserName: assignment ? (userMap.get(assignment.userId) ?? null) : null,
        openAlertsCount: openAlertsByDevice.get(v.id) ?? 0,
      };
    });
  }

  /** Admin — détail d'un véhicule avec alertes récentes, geofences liées et assignation */
  async getVehicleDetail(deviceId: number) {
    const [vehicle, recentAlerts, linkedGeofences, assignment] =
      await Promise.all([
        this.vehiclesService.findOne(deviceId),
        this.alertsService.findByDeviceId(deviceId, 20),
        this.geofencesService.findByDeviceId(deviceId),
        this.assignmentRepo.findOne({ where: { deviceId } }),
      ]);

    let assignedUser: import('../users/user.entity').User | null = null;
    if (assignment) {
      assignedUser = await this.usersService.findByIdAdmin(assignment.userId);
    }

    return {
      ...vehicle,
      assignedUserId: assignment?.userId ?? null,
      assignedUserName: assignedUser
        ? (assignedUser.name ?? assignedUser.email)
        : null,
      assignedUserPhone: assignedUser?.phone ?? null,
      recentAlerts,
      linkedGeofences,
    };
  }

  // ── Assignments ───────────────────────────────────────────────────────────

  async assignDevice(deviceId: number, userId: number) {
    await this.devicesService.findOne(deviceId);
    const user = await this.usersService.findByIdAdmin(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    const existing = await this.assignmentRepo.findOne({ where: { deviceId } });

    if (existing) {
      existing.userId = userId;
      await this.assignmentRepo.save(existing);
      return { deviceId, userId, updated: true };
    }

    await this.assignmentRepo.save(
      this.assignmentRepo.create({ deviceId, userId }),
    );
    return { deviceId, userId, updated: false };
  }

  async unassignDevice(deviceId: number) {
    const result = await this.assignmentRepo.delete({ deviceId });
    if (result.affected === 0) {
      throw new NotFoundException(`No assignment found for device ${deviceId}`);
    }
  }

  /** Retourne les IDs de devices assignés à un user donné */
  async getDeviceIdsForUser(userId: number): Promise<number[]> {
    const assignments = await this.assignmentRepo.find({ where: { userId } });
    return assignments.map((a) => a.deviceId);
  }

  // ── Geofences ────────────────────────────────────────────────────────────

  listGeofences() {
    return this.geofencesService.findAll();
  }

  removeGeofence(id: string) {
    return this.geofencesService.removeByIdAdmin(id);
  }

  // ── Alerts ───────────────────────────────────────────────────────────────

  listAlerts() {
    return this.alertsService.findAll();
  }

  ackAlert(id: string) {
    return this.alertsService.ackAlert(id);
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  /** Vue d'ensemble globale — stats agrégées pour le dashboard reports */
  async getReportsOverview() {
    const [users, vehicles, allAlerts] = await Promise.all([
      this.usersService.findAll(),
      this.vehiclesService.findAll(),
      this.alertsService.findAll(),
    ]);

    const statusCounts = { online: 0, idle: 0, offline: 0 };
    for (const v of vehicles) statusCounts[v.status]++;

    const alertsByType = allAlerts.reduce<Record<string, number>>((acc, a) => {
      acc[a.type] = (acc[a.type] ?? 0) + 1;
      return acc;
    }, {});

    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const alertsThisMonth = allAlerts.filter(
      (a) => new Date(a.createdAt) >= startOfMonth,
    ).length;

    const openAlerts = allAlerts.filter((a) => a.status === 'open').length;

    return {
      totalUsers: users.length,
      activeUsers: users.filter((u) => u.isActive).length,
      totalVehicles: vehicles.length,
      statusCounts,
      totalAlerts: allAlerts.length,
      openAlerts,
      alertsThisMonth,
      alertsByType,
    };
  }

  /**
   * Rapport par véhicule : distance, alertes, vitesse max sur la période.
   * `period` = 'today' | '7d' | '30d'
   */
  async getVehicleReports(period: 'today' | '7d' | '30d') {
    const now = new Date();
    let from: Date;
    if (period === 'today') {
      from = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    } else if (period === '7d') {
      from = new Date(now.getTime() - 7 * 24 * 3600 * 1000);
    } else {
      from = new Date(now.getTime() - 30 * 24 * 3600 * 1000);
    }

    const [vehicles, assignments, users, allAlerts] = await Promise.all([
      this.vehiclesService.findAll(),
      this.assignmentRepo.find(),
      this.usersService.findAll(),
      this.alertsService.findAll(),
    ]);

    const userMap = new Map(users.map((u) => [u.id, u.name ?? u.email]));
    const periodAlerts = allAlerts.filter(
      (a) => new Date(a.createdAt) >= from,
    );

    const results = await Promise.all(
      vehicles.map(async (v) => {
        const assignment = assignments.find((a) => a.deviceId === v.id);
        const distanceSummary = await this.positionsService
          .getDistanceSummary(v.id, from, now)
          .catch(() => ({ distanceKm: 0, pointCount: 0, maxSpeedKmh: 0 }));

        const alertCount = periodAlerts.filter(
          (a) => a.deviceId === v.id,
        ).length;

        return {
          id: v.id,
          name: v.name,
          plate: v.plate,
          status: v.status,
          lastUpdate: v.lastUpdate,
          assignedUserName: assignment
            ? (userMap.get(assignment.userId) ?? null)
            : null,
          distanceKm: distanceSummary.distanceKm,
          maxSpeedKmh: distanceSummary.maxSpeedKmh,
          pointCount: distanceSummary.pointCount,
          alertCount,
        };
      }),
    );

    return { from, to: now, period, vehicles: results };
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  /** Liste tous les users avec leur abonnement (crée un enregistrement free/trial si absent) */
  async listSubscriptions() {
    const [users, subs] = await Promise.all([
      this.usersService.findAll(),
      this.subscriptionRepo.find(),
    ]);

    const subMap = new Map(subs.map((s) => [s.userId, s]));

    return users.map((u) => {
      const sub = subMap.get(u.id);
      return {
        userId: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        isActive: u.isActive,
        subscription: sub ?? null,
      };
    });
  }

  /** Crée ou met à jour l'abonnement d'un user */
  async upsertSubscription(
    userId: number,
    data: {
      plan?: SubscriptionPlan;
      status?: SubscriptionStatus;
      nextBillingDate?: string | null;
      trialEndsAt?: string | null;
      notes?: string | null;
    },
  ) {
    const user = await this.usersService.findByIdAdmin(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);

    let sub = await this.subscriptionRepo.findOne({ where: { userId } });

    if (!sub) {
      sub = this.subscriptionRepo.create({
        userId,
        plan: SubscriptionPlan.FREE,
        status: SubscriptionStatus.TRIAL,
        vehicleLimit: PLAN_VEHICLE_LIMITS[SubscriptionPlan.FREE],
      });
    }

    if (data.plan) {
      sub.plan = data.plan;
      sub.vehicleLimit = PLAN_VEHICLE_LIMITS[data.plan];
    }
    if (data.status) sub.status = data.status;
    if (data.nextBillingDate !== undefined)
      sub.nextBillingDate = data.nextBillingDate
        ? new Date(data.nextBillingDate)
        : null;
    if (data.trialEndsAt !== undefined)
      sub.trialEndsAt = data.trialEndsAt ? new Date(data.trialEndsAt) : null;
    if (data.notes !== undefined) sub.notes = data.notes ?? null;

    return this.subscriptionRepo.save(sub);
  }

  // ── Detailed vehicle reports ──────────────────────────────────────────────

  private periodToDates(period: 'today' | '7d' | '30d'): { from: Date; to: Date } {
    const now = new Date();
    let from: Date;
    if (period === 'today') {
      from = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    } else if (period === '7d') {
      from = new Date(now.getTime() - 7 * 24 * 3600 * 1000);
    } else {
      from = new Date(now.getTime() - 30 * 24 * 3600 * 1000);
    }
    return { from, to: now };
  }

  async getVehicleActivitySummary(
    deviceId: number,
    period: 'today' | '7d' | '30d',
  ) {
    const { from, to } = this.periodToDates(period);
    const summary = await this.positionsService
      .getActivitySummary(deviceId, from, to)
      .catch(() => ({
        distanceKm: 0,
        drivingMinutes: 0,
        idleMinutes: 0,
        maxSpeedKmh: 0,
        tripCount: 0,
        speedViolationCount: 0,
        pointCount: 0,
      }));
    return { deviceId, period, from, to, ...summary };
  }

  async getVehicleTripLog(deviceId: number, from: Date, to: Date) {
    const trips = await this.positionsService
      .getTripLog(deviceId, from, to)
      .catch(() => []);
    return { deviceId, from, to, trips };
  }

  async getVehicleSpeedViolations(
    deviceId: number,
    from: Date,
    to: Date,
    thresholdKmh = 120,
  ) {
    const violations = await this.positionsService
      .getSpeedViolations(deviceId, from, to, thresholdKmh)
      .catch(() => []);
    return { deviceId, from, to, thresholdKmh, violations };
  }

  async getVehicleIdleTime(deviceId: number, from: Date, to: Date) {
    const episodes = await this.positionsService
      .getIdleTime(deviceId, from, to)
      .catch((): Awaited<ReturnType<typeof this.positionsService.getIdleTime>> => []);
    const totalIdleMinutes = episodes.reduce((s, e) => s + e.durationMin, 0);
    return { deviceId, from, to, totalIdleMinutes, episodes };
  }

  async getVehicleGeofenceActivity(deviceId: number, from: Date, to: Date) {
    const geofences = await this.alertsService
      .getGeofenceActivity(deviceId, from, to)
      .catch(() => []);
    return { deviceId, from, to, geofences };
  }
}
