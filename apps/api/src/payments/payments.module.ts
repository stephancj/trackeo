import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Subscription } from '../admin/subscription.entity';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { Plan } from '../entitlements/plan.entity';
import { UsersModule } from '../users/users.module';
import { Payment } from './payment.entity';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Payment, Plan, Subscription]),
    UsersModule,
    EntitlementsModule,
  ],
  controllers: [PaymentsController],
  providers: [PaymentsService],
})
export class PaymentsModule {}
