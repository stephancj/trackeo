import {
  Controller,
  Get,
  Patch,
  Body,
  Param,
  Query,
  ParseIntPipe,
  UseGuards,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { VehiclesService } from './vehicles.service';
import { PositionsService } from '../positions/positions.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Device } from '../devices/device.entity';

@Controller('vehicles')
@UseGuards(JwtAuthGuard)
export class VehiclesController {
  constructor(
    private readonly vehiclesService: VehiclesService,
    private readonly positionsService: PositionsService,
  ) {}

  /**
   * GET /api/vehicles
   * Retourne tous les véhicules enrichis (nom, plaque, statut, position, batterie).
   * Utilisé par la Fleet List et la carte.
   */
  @Get()
  findAll() {
    return this.vehiclesService.findAll();
  }

  /**
   * GET /api/vehicles/:id
   * Détails complets d'un seul véhicule.
   */
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.vehiclesService.findOne(id);
  }

  /**
   * PATCH /api/vehicles/:id
   * Mise à jour des informations d'un véhicule (ex: nom).
   */
  @Patch(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() data: Partial<Device>) {
    return this.vehiclesService.update(id, data);
  }

  /**
   * GET /api/vehicles/:id/position
   * Dernière position — endpoint de polling Flutter (toutes les 10s).
   */
  @Get(':id/position')
  async getLastPosition(@Param('id', ParseIntPipe) id: number) {
    const position = await this.vehiclesService.getLastPosition(id);
    if (!position) {
      throw new NotFoundException(
        `Aucune position trouvée pour le véhicule #${id}`,
      );
    }
    return position;
  }

  /**
   * GET /api/vehicles/:id/history?from=ISO&to=ISO&limit=1000
   * Historique des positions pour tracer le trajet (polyligne Flutter).
   */
  @Get(':id/history')
  getHistory(
    @Param('id', ParseIntPipe) id: number,
    @Query('from') from: string,
    @Query('to') to: string,
    @Query('limit') limit?: string,
  ) {
    if (!from || !to) {
      throw new BadRequestException(
        'Les paramètres "from" et "to" sont requis (ISO 8601)',
      );
    }

    const fromDate = new Date(from);
    const toDate = new Date(to);

    if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
      throw new BadRequestException(
        'Format de date invalide — utiliser ISO 8601 (ex: 2024-01-01T00:00:00Z)',
      );
    }

    if (fromDate >= toDate) {
      throw new BadRequestException('"from" doit être antérieur à "to"');
    }

    const limitNum = limit ? Math.min(parseInt(limit, 10), 5000) : 1000;

    return this.positionsService.getHistory(id, fromDate, toDate, limitNum);
  }
}
