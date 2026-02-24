/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument */
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
} from '@nestjs/common';
import { GeofencesService } from './geofences.service';
import {
  CreateGeofenceDto,
  UpdateGeofenceDto,
} from './dto/create-geofence.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('geofences')
@UseGuards(JwtAuthGuard)
export class GeofencesController {
  constructor(private readonly geofencesService: GeofencesService) {}

  @Post()
  create(@Request() req, @Body() createGeofenceDto: CreateGeofenceDto) {
    const userId = req.user.id;
    return this.geofencesService.create(userId, createGeofenceDto);
  }

  @Get()
  findAll(@Request() req) {
    const userId = req.user.id;
    return this.geofencesService.findAllForUser(userId);
  }

  @Get(':id')
  findOne(@Request() req, @Param('id') id: string) {
    const userId = req.user.id;
    return this.geofencesService.findOne(+id, userId);
  }

  @Patch(':id')
  update(
    @Request() req,
    @Param('id') id: string,
    @Body() updateGeofenceDto: UpdateGeofenceDto,
  ) {
    const userId = req.user.id;
    return this.geofencesService.update(+id, userId, updateGeofenceDto);
  }

  @Delete(':id')
  remove(@Request() req, @Param('id') id: string) {
    const userId = req.user.id;
    return this.geofencesService.remove(+id, userId);
  }
}
