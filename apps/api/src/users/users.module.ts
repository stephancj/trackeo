import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './user.entity';
import { UsersService } from './users.service';
import { EntitlementsModule } from '../entitlements/entitlements.module';

@Module({
  imports: [TypeOrmModule.forFeature([User]), EntitlementsModule],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
