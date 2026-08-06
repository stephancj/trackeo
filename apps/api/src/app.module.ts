import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { DevicesModule } from './devices/devices.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PositionsModule } from './positions/positions.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { AdminModule } from './admin/admin.module';
import { GeofencesModule } from './geofences/geofences.module';
import { AlertsModule } from './alerts/alerts.module';
import { NotificationsModule } from './notifications/notifications.module';
import databaseConfig from './config/database.config';
import { ScheduleModule } from '@nestjs/schedule';
import { WaitlistModule } from './waitlist/waitlist.module';
import { EntitlementsModule } from './entitlements/entitlements.module';
import { SecurityModule } from './security/security.module';
import { PaymentsModule } from './payments/payments.module';
import { TripsModule } from './trips/trips.module';
import { PromotionsModule } from './promotions/promotions.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      useFactory: () => databaseConfig(),
    }),
    ScheduleModule.forRoot(),
    DevicesModule,
    AuthModule,
    UsersModule,
    PositionsModule,
    VehiclesModule,
    AdminModule,
    GeofencesModule,
    AlertsModule,
    NotificationsModule,
    WaitlistModule,
    EntitlementsModule,
    SecurityModule,
    PaymentsModule,
    TripsModule,
    PromotionsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
