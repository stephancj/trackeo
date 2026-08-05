import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WaitlistController } from './waitlist.controller';
import { WaitlistService } from './waitlist.service';
import { WaitlistSubscriber } from './waitlist-subscriber.entity';

@Module({
  imports: [TypeOrmModule.forFeature([WaitlistSubscriber])],
  controllers: [WaitlistController],
  providers: [WaitlistService],
})
export class WaitlistModule {}
