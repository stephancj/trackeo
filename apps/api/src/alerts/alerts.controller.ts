/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument */
import {
  Controller,
  Get,
  Patch,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AlertsService } from './alerts.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('alerts')
@UseGuards(JwtAuthGuard)
export class AlertsController {
  constructor(private readonly alertsService: AlertsService) {}

  @Get()
  findAll(@Request() req) {
    const userId = req.user.id;
    return this.alertsService.findAllForUser(userId);
  }

  /** Marque toutes les alertes ouvertes de l'utilisateur comme lues */
  @Patch('mark-all-read')
  markAllRead(@Request() req) {
    return this.alertsService.markAllReadForUser(req.user.id as number);
  }

  /** Acquitte une alerte spécifique de l'utilisateur */
  @Patch(':id/ack')
  ackAlert(@Param('id') id: string, @Request() req) {
    return this.alertsService.ackAlertForUser(id, req.user.id as number);
  }
}
