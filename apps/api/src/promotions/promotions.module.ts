import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Subscription } from '../admin/subscription.entity';
import { EntitlementsModule } from '../entitlements/entitlements.module';
import { Plan } from '../entitlements/plan.entity';
import { User } from '../users/user.entity';
import { Coupon } from './entities/coupon.entity';
import { CouponRedemption } from './entities/coupon-redemption.entity';
import { Referral } from './entities/referral.entity';
import { PromotionsController } from './promotions.controller';
import { PromotionsService } from './promotions.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Coupon,
      Referral,
      CouponRedemption,
      User,
      Subscription,
      Plan,
    ]),
    EntitlementsModule,
  ],
  controllers: [PromotionsController],
  providers: [PromotionsService],
  exports: [PromotionsService],
})
export class PromotionsModule {}
