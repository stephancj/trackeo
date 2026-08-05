import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AlertsModule } from '../alerts/alerts.module';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { UsersModule } from '../users/users.module';
import { VehiclesModule } from '../vehicles/vehicles.module';
import { IncidentEvent } from './incident-event.entity';
import { SecurityIncident } from './incident.entity';
import { SecurityController } from './security.controller';
import { SecurityService } from './security.service';
import { PublicTrackingLink } from './tracking-link.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      SecurityIncident,
      IncidentEvent,
      PublicTrackingLink,
    ]),
    VehiclesModule,
    AlertsModule,
    UsersModule,
    NotificationsModule,
    EntitlementsModule,
  ],
  controllers: [SecurityController],
  providers: [SecurityService],
  exports: [SecurityService],
})
export class SecurityModule {}
