import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { JoinWaitlistDto } from './dto/join-waitlist.dto';
import { WaitlistService } from './waitlist.service';

@Controller('waitlist')
export class WaitlistController {
  constructor(private readonly waitlistService: WaitlistService) {}

  /** POST /waitlist — inscription publique à l'annonce de lancement. */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  join(@Body() dto: JoinWaitlistDto) {
    return this.waitlistService.join(dto.email);
  }
}
