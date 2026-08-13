import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { JoinWaitlistDto } from './dto/join-waitlist.dto';
import { ConfirmWaitlistDto } from './dto/confirm-waitlist.dto';
import { EmailDomainService } from './email-domain.service';
import { TurnstileService } from './turnstile.service';
import { WaitlistService } from './waitlist.service';

@Controller('waitlist')
export class WaitlistController {
  constructor(
    private readonly waitlistService: WaitlistService,
    private readonly turnstileService: TurnstileService,
    private readonly emailDomainService: EmailDomainService,
  ) {}

  /** POST /waitlist — inscription publique à l'annonce de lancement. */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async join(@Body() dto: JoinWaitlistDto) {
    await this.turnstileService.verify(dto.captchaToken);
    await this.emailDomainService.assertDeliverable(dto.email);
    return this.waitlistService.join(dto.email);
  }

  /** POST /waitlist/confirm — confirme la propriété de l'adresse email. */
  @Post('confirm')
  @HttpCode(HttpStatus.OK)
  confirm(@Body() dto: ConfirmWaitlistDto) {
    return this.waitlistService.confirm(dto.token);
  }
}
