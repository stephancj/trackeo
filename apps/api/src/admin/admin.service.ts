import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeviceAssignment } from './device-assignment.entity';
import { UsersService } from '../users/users.service';
import { DevicesService } from '../devices/devices.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { GeofencesService } from '../geofences/geofences.service';
import { AlertsService } from '../alerts/alerts.service';
import { CreateUserDto, UpdateUserDto } from './admin.dto';
import { UserRole } from '../users/user.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(DeviceAssignment)
    private readonly assignmentRepo: Repository<DeviceAssignment>,
    private readonly usersService: UsersService,
    private readonly devicesService: DevicesService,
    private readonly vehiclesService: VehiclesService,
    private readonly geofencesService: GeofencesService,
    private readonly alertsService: AlertsService,
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
}
