import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { BrevoEmailService } from './brevo-email.service';

@Module({
  providers: [NotificationsService, BrevoEmailService],
  exports: [NotificationsService, BrevoEmailService],
})
export class NotificationsModule {}
