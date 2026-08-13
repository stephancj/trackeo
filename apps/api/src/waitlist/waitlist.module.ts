import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsModule } from '../notifications/notifications.module';
import { EmailDomainService } from './email-domain.service';
import { WaitlistController } from './waitlist.controller';
import { TurnstileService } from './turnstile.service';
import { WaitlistService } from './waitlist.service';
import { WaitlistSubscriber } from './waitlist-subscriber.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([WaitlistSubscriber]),
    NotificationsModule,
  ],
  controllers: [WaitlistController],
  providers: [WaitlistService, TurnstileService, EmailDomainService],
})
export class WaitlistModule {}
