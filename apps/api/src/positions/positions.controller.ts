import {
  Controller,
  Get,
  Param,
  Query,
  ParseIntPipe,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { PositionsService } from './positions.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('positions')
@UseGuards(JwtAuthGuard)
export class PositionsController {
  constructor(private readonly positionsService: PositionsService) {}

  /**
   * GET /api/positions/last/:deviceId
   * Dernière position connue du device.
   */
  @Get('last/:deviceId')
  getLastPosition(@Param('deviceId', ParseIntPipe) deviceId: number) {
    return this.positionsService.getLastPosition(deviceId);
  }

  /**
   * GET /api/positions/history/:deviceId?from=ISO&to=ISO&limit=500
   * Historique sur une plage de dates.
   *
   * Exemple :
   *   /api/positions/history/1?from=2024-01-01T00:00:00Z&to=2024-01-01T23:59:59Z
   */
  @Get('history/:deviceId')
  getHistory(
    @Param('deviceId', ParseIntPipe) deviceId: number,
    @Query('from') from: string,
    @Query('to') to: string,
    @Query('limit') limit?: string,
  ) {
    if (!from || !to) {
      throw new BadRequestException('Les paramètres "from" et "to" sont requis');
    }

    const fromDate = new Date(from);
    const toDate = new Date(to);

    if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
      throw new BadRequestException('Format de date invalide (ISO 8601 requis)');
    }

    if (fromDate >= toDate) {
      throw new BadRequestException('"from" doit être antérieur à "to"');
    }

    const limitNum = limit ? parseInt(limit, 10) : 1000;

    return this.positionsService.getHistory(deviceId, fromDate, toDate, limitNum);
  }
}
