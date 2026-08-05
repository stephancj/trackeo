import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateTrackingLinkDto, UpdateIncidentDto } from './security.dto';
import { SecurityService } from './security.service';

@Controller()
export class SecurityController {
  constructor(private readonly security: SecurityService) {}
  @Post('vehicles/:id/sos') @UseGuards(JwtAuthGuard) sos(
    @Param('id', ParseIntPipe) id: number,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.createSos(req.user.id, id);
  }
  @Post('vehicles/:id/theft') @UseGuards(JwtAuthGuard) theft(
    @Param('id', ParseIntPipe) id: number,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.declareTheft(req.user.id, id);
  }
  @Get('incidents') @UseGuards(JwtAuthGuard) list(
    @Request() req: { user: { id: number } },
  ) {
    return this.security.listForUser(req.user.id);
  }
  @Get('incidents/:id/events') @UseGuards(JwtAuthGuard) events(
    @Param('id') id: string,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.timeline(id, req.user.id);
  }
  @Patch('incidents/:id/ack') @UseGuards(JwtAuthGuard) ack(
    @Param('id') id: string,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.acknowledge(id, req.user.id);
  }
  @Delete('incidents/:id/theft') @UseGuards(JwtAuthGuard) cancel(
    @Param('id') id: string,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.cancelTheft(id, req.user.id);
  }
  @Post('vehicles/:id/share-links') @UseGuards(JwtAuthGuard) share(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: CreateTrackingLinkDto,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.createTrackingLink(
      req.user.id,
      id,
      body.durationMinutes,
    );
  }
  @Get('vehicles/:id/share-links') @UseGuards(JwtAuthGuard) links(
    @Param('id', ParseIntPipe) id: number,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.listLinks(req.user.id, id);
  }
  @Delete('share-links/:id') @UseGuards(JwtAuthGuard) revoke(
    @Param('id') id: string,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.revokeLink(req.user.id, id);
  }
  @Get('public/tracking/:token') publicTrack(@Param('token') token: string) {
    return this.security.resolvePublic(token);
  }
  @Get('admin/incidents')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  adminList() {
    return this.security.listAll();
  }
  @Get('admin/incidents/:id/events')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  adminEvents(@Param('id') id: string) {
    return this.security.timeline(id);
  }
  @Patch('admin/incidents/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  adminUpdate(
    @Param('id') id: string,
    @Body() body: UpdateIncidentDto,
    @Request() req: { user: { id: number } },
  ) {
    return this.security.updateByAdmin(id, body.status, body.note, req.user.id);
  }
}
