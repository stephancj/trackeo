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
import databaseConfig from './config/database.config';
import { ScheduleModule } from '@nestjs/schedule';

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
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
