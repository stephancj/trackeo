import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WaitlistSubscriber } from './waitlist-subscriber.entity';

@Injectable()
export class WaitlistService {
  constructor(
    @InjectRepository(WaitlistSubscriber)
    private readonly subscribers: Repository<WaitlistSubscriber>,
  ) {}

  async join(email: string): Promise<{ ok: true }> {
    await this.subscribers
      .createQueryBuilder()
      .insert()
      .into(WaitlistSubscriber)
      .values({
        email,
        source: 'landing',
        status: 'subscribed',
        unsubscribedAt: null,
      })
      .orIgnore()
      .execute();

    // Réponse identique pour une nouvelle adresse et un doublon : le formulaire
    // reste idempotent et ne permet pas de tester si une adresse est inscrite.
    return { ok: true };
  }
}
