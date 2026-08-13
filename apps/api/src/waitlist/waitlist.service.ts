import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { MoreThan, Repository } from 'typeorm';
import { BrevoEmailService } from '../notifications/brevo-email.service';
import { WaitlistSubscriber } from './waitlist-subscriber.entity';

@Injectable()
export class WaitlistService {
  private readonly verificationTtlMs = 30 * 60_000;
  private readonly resendCooldownMs = 2 * 60_000;

  constructor(
    @InjectRepository(WaitlistSubscriber)
    private readonly subscribers: Repository<WaitlistSubscriber>,
    private readonly emails: BrevoEmailService,
  ) {}

  async join(email: string): Promise<{ ok: true; verificationRequired: true }> {
    const now = new Date();
    let subscriber = await this.subscribers.findOne({ where: { email } });

    // Réponse identique pour une adresse déjà confirmée : ne permet pas de
    // tester publiquement si elle appartient à la waitlist.
    if (subscriber?.status === 'subscribed' && subscriber.verifiedAt) {
      return { ok: true, verificationRequired: true };
    }

    if (
      subscriber?.verificationSentAt &&
      now.getTime() - subscriber.verificationSentAt.getTime() <
        this.resendCooldownMs
    ) {
      return { ok: true, verificationRequired: true };
    }

    const token = randomBytes(32).toString('base64url');
    const tokenHash = this.hashToken(token);
    const expiresAt = new Date(now.getTime() + this.verificationTtlMs);

    subscriber ??= this.subscribers.create({
      email,
      source: 'landing',
      status: 'pending',
      unsubscribedAt: null,
      verifiedAt: null,
      verificationSentAt: null,
    });
    subscriber.status = 'pending';
    subscriber.unsubscribedAt = null;
    subscriber.verificationTokenHash = tokenHash;
    subscriber.verificationExpiresAt = expiresAt;
    subscriber = await this.subscribers.save(subscriber);

    const landingUrl = (
      process.env.PUBLIC_LANDING_URL ?? 'https://iooeh.com'
    ).replace(/\/$/, '');
    const confirmationUrl = `${landingUrl}/waitlist/confirm#token=${encodeURIComponent(token)}`;

    try {
      const content = this.emails.renderBranded({
        eyebrow: 'Liste d’attente',
        title: 'Confirmez votre adresse email.',
        intro:
          'Un dernier clic confirme que cette adresse vous appartient et empêche son inscription par un tiers ou un robot.',
        actionLabel: 'Confirmer mon inscription',
        actionUrl: confirmationUrl,
        notice:
          'Ce lien expire dans 30 minutes. Si vous n’êtes pas à l’origine de cette demande, ignorez simplement cet email.',
      });
      await this.emails.send({
        to: email,
        subject: 'Confirmez votre inscription à la liste iooeh',
        ...content,
        tag: 'waitlist-verification',
        idempotencyKey: randomUUID(),
      });
    } catch (error) {
      await this.subscribers.update(subscriber.id, {
        verificationTokenHash: null,
        verificationExpiresAt: null,
      });
      throw error;
    }

    await this.subscribers.update(subscriber.id, {
      verificationSentAt: now,
    });
    return { ok: true, verificationRequired: true };
  }

  async confirm(token: string): Promise<{ ok: boolean }> {
    const tokenHash = this.hashToken(token);
    const subscriber = await this.subscribers.findOne({
      where: {
        verificationTokenHash: tokenHash,
        status: 'pending',
        verificationExpiresAt: MoreThan(new Date()),
      },
    });

    if (!subscriber) return { ok: false };

    await this.subscribers.update(subscriber.id, {
      status: 'subscribed',
      verifiedAt: new Date(),
      verificationTokenHash: null,
      verificationExpiresAt: null,
    });
    return { ok: true };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

}
