import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreatePaymentDto, PapiNotificationDto } from './payments.dto';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}
  @Post('checkout') @UseGuards(JwtAuthGuard) checkout(
    @Body() dto: CreatePaymentDto,
    @Request() req: { user: { id: number } },
  ) {
    return this.payments.create(req.user.id, dto);
  }
  @Get('plans') @UseGuards(JwtAuthGuard) plans() {
    return this.payments.listPlans();
  }
  @Get() @UseGuards(JwtAuthGuard) history(
    @Request() req: { user: { id: number } },
  ) {
    return this.payments.history(req.user.id);
  }
  @Get(':reference/status') @UseGuards(JwtAuthGuard) status(
    @Param('reference') reference: string,
    @Request() req: { user: { id: number } },
  ) {
    return this.payments.status(req.user.id, reference);
  }
  @Post('papi/notification') @HttpCode(200) notification(
    @Body() dto: PapiNotificationDto,
  ) {
    return this.payments.handleNotification(dto);
  }
}
