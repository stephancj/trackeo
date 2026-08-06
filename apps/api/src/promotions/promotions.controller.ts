import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { EntitlementsService } from '../entitlements/entitlements.service';
import { CreateCouponDto, RedeemCouponDto, ValidateCouponDto } from './promotions.dto';
import { PromotionsService } from './promotions.service';

@Controller('promotions')
export class PromotionsController {
  constructor(
    private readonly promotionsService: PromotionsService,
    private readonly entitlementsService: EntitlementsService,
  ) {}

  @Post('redeem')
  @UseGuards(JwtAuthGuard)
  async redeem(
    @Body() dto: RedeemCouponDto,
    @Request() req: { user: { id: number } },
  ) {
    return this.promotionsService.redeemCode(req.user.id, dto.code);
  }

  @Post('validate')
  @UseGuards(JwtAuthGuard)
  async validate(
    @Body() dto: ValidateCouponDto,
    @Request() req: { user: { id: number } },
  ) {
    return this.promotionsService.validateCouponForCheckout(
      dto.code,
      dto.planId,
      req.user.id,
    );
  }

  @Get('referral-info')
  @UseGuards(JwtAuthGuard)
  async getReferralInfo(@Request() req: { user: { id: number } }) {
    return this.promotionsService.getReferralInfo(req.user.id);
  }

  // ── Admin Endpoints ────────────────────────────────────────────────────────
  @Get('admin/coupons')
  @UseGuards(JwtAuthGuard)
  listCoupons() {
    return this.promotionsService.listCoupons();
  }

  @Post('admin/coupons')
  @UseGuards(JwtAuthGuard)
  createCoupon(@Body() dto: CreateCouponDto) {
    return this.promotionsService.createCoupon(dto);
  }

  @Delete('admin/coupons/:id')
  @UseGuards(JwtAuthGuard)
  deleteCoupon(@Param('id') id: string) {
    return this.promotionsService.deleteCoupon(id);
  }
}
