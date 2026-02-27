import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeviceAssignment } from './device-assignment.entity';
import { UsersService } from '../users/users.service';
import { DevicesService } from '../devices/devices.service';
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
    private readonly geofencesService: GeofencesService,
    private readonly alertsService: AlertsService,
  ) {}

  // ── Users ────────────────────────────────────────────────────────────────

  listUsers() {
    return this.usersService.findAll();
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
    const user = await this.usersService.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);
    return this.usersService.adminUpdate(userId, dto);
  }

  async deactivateUser(userId: number) {
    const user = await this.usersService.findById(userId);
    if (!user) throw new NotFoundException(`User ${userId} not found`);
    return this.usersService.adminUpdate(userId, { isActive: false });
  }

  // ── Devices ──────────────────────────────────────────────────────────────

  async listDevices() {
    const [devices, assignments] = await Promise.all([
      this.devicesService.findAll(),
      this.assignmentRepo.find(),
    ]);

    return devices.map((d) => ({
      id: d.id,
      name: d.name,
      uniqueId: d.uniqueId,
      status: d.status,
      lastUpdate: d.lastUpdate,
      assignedUserId:
        assignments.find((a) => a.deviceId === d.id)?.userId ?? null,
    }));
  }

  // ── Assignments ───────────────────────────────────────────────────────────

  async assignDevice(deviceId: number, userId: number) {
    await this.devicesService.findOne(deviceId);
    const user = await this.usersService.findById(userId);
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
}
