import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeviceAssignment } from './device-assignment.entity';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { UsersModule } from '../users/users.module';
import { DevicesModule } from '../devices/devices.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DeviceAssignment]),
    UsersModule,
    DevicesModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService], // exporté pour VehiclesModule (filtrage par owner)
})
export class AdminModule {}
