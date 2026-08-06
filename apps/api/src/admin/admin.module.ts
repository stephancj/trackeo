import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeviceAssignment } from './device-assignment.entity';
import { Subscription } from './subscription.entity';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { UsersModule } from '../users/users.module';
import { DevicesModule } from '../devices/devices.module';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { GeofencesModule } from '../geofences/geofences.module';
import { AlertsModule } from '../alerts/alerts.module';
import { PositionsModule } from '../positions/positions.module';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { Feature } from '../entitlements/feature.entity';
import { Plan } from '../entitlements/plan.entity';
import { PlanFeature } from '../entitlements/plan-feature.entity';

import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      DeviceAssignment,
      Subscription,
      Feature,
      Plan,
      PlanFeature,
    ]),
    EntitlementsModule,
    UsersModule,
    DevicesModule,
    VehiclesModule,
    GeofencesModule,
    AlertsModule,
    PositionsModule,
    PaymentsModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
