import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Position } from './position.entity';
import { PositionsService } from './positions.service';
import { PositionsController } from './positions.controller';
import { DeviceAssignment } from '../admin/device-assignment.entity';
import { EntitlementsModule } from '../entitlements/entitlements.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Position, DeviceAssignment]),
    EntitlementsModule,
  ],
  controllers: [PositionsController],
  providers: [PositionsService],
  exports: [PositionsService],
})
export class PositionsModule {}
