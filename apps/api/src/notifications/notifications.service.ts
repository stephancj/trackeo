import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { BrevoEmailService } from './brevo-email.service';

export interface PushPayload {
  /** ID externe de l'utilisateur cible (userId.toString()) */
  externalUserId: string;
  /**
   * Subscription ID OneSignal (UUID de la subscription navigateur).
   * Préféré à externalUserId : ne nécessite pas que OneSignal.login() ait
   * persisté le External ID côté serveur OneSignal.
   * Récupéré via OneSignal.User.PushSubscription.id et stocké en base.
   */
  subscriptionId?: string;
  title: string;
  body: string;
  /** Données supplémentaires accessibles dans l'app (navigation, etc.) */
  data?: Record<string, string>;
}

export interface WhatsAppPayload {
  phone: string;
  vehicleName: string;
  geofenceName: string;
  alertType: 'enter' | 'exit' | 'movement';
}

export interface EmailNotificationPayload {
  email: string;
  name?: string;
  title: string;
  body: string;
  actionUrl?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly emails: BrevoEmailService) {}

  /** Envoie une alerte transactionnelle par email via Brevo. */
  async sendEmail(payload: EmailNotificationPayload): Promise<void> {
    const actionUrl =
      payload.actionUrl ??
        process.env.PUBLIC_APP_URL ??
        'https://app.iooeh.com';
    const content = this.emails.renderBranded({
      eyebrow: 'Alerte véhicule',
      title: payload.title,
      intro: payload.body,
      actionLabel: 'Ouvrir iooeh',
      actionUrl,
      notice:
        'Vous recevez cet email car les alertes par email sont activées dans vos réglages iooeh.',
    });

    try {
      await this.emails.send({
        to: payload.email,
        toName: payload.name,
        subject: payload.title,
        ...content,
        tag: 'vehicle-alert',
        idempotencyKey: randomUUID(),
      });
    } catch (error) {
      // Une panne du canal email ne doit jamais interrompre les autres canaux
      // ni le traitement d'une alerte en base.
      this.logger.error(
        `Erreur Brevo pour user=${payload.email}`,
        error instanceof Error ? error.stack : undefined,
      );
    }
  }

  /**
   * Envoie une notification push via OneSignal REST API.
   * Utilise include_subscription_ids si subscriptionId est fourni (ciblage direct),
   * sinon bascule sur include_external_user_ids.
   * Ne lance pas d'exception si OneSignal est non configuré (MVP graceful).
   */
  async sendPush(payload: PushPayload): Promise<void> {
    const appId = process.env.ONESIGNAL_APP_ID;
    const apiKey = process.env.ONESIGNAL_API_KEY;

    if (!appId || !apiKey) {
      this.logger.warn(
        'OneSignal non configuré — ajoutez ONESIGNAL_APP_ID et ONESIGNAL_API_KEY dans .env',
      );
      return;
    }

    // Ciblage : préférer le subscription ID direct (ne dépend pas du External ID)
    const targeting = payload.subscriptionId
      ? { include_subscription_ids: [payload.subscriptionId] }
      : {
          include_external_user_ids: [payload.externalUserId],
          channel_for_external_user_ids: 'push',
        };

    try {
      const res = await fetch('https://onesignal.com/api/v1/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Basic ${apiKey}`,
        },
        body: JSON.stringify({
          app_id: appId,
          ...targeting,
          headings: { en: payload.title, fr: payload.title },
          contents: { en: payload.body, fr: payload.body },
          data: payload.data ?? {},
        }),
      });

      if (!res.ok) {
        const err = await res.text();
        this.logger.error(`OneSignal ${res.status}: ${err}`);
      } else {
        const json = (await res.json()) as { id?: string; errors?: string[] };
        if (json.errors?.length) {
          this.logger.warn(`OneSignal warnings: ${json.errors.join(', ')}`);
        } else {
          const mode = payload.subscriptionId ? 'subId' : 'extId';
          this.logger.log(
            `✅ Push envoyé → user=${payload.externalUserId} (${mode}) | ${payload.title}`,
          );
        }
      }
    } catch (e) {
      this.logger.error('Erreur réseau OneSignal', e);
    }
  }

  /**
   * Envoie une notification WhatsApp via Meta WhatsApp Business API.
   * Ne lance pas d'exception si WhatsApp n'est pas configuré (MVP graceful).
   */
  async sendWhatsApp(payload: WhatsAppPayload): Promise<void> {
    const token = process.env.WHATSAPP_API_TOKEN;
    const phoneId = process.env.WHATSAPP_PHONE_ID;

    if (!token || !phoneId) {
      this.logger.warn(
        'WhatsApp non configuré — ajoutez WHATSAPP_API_TOKEN et WHATSAPP_PHONE_ID dans .env',
      );
      return;
    }

    const message =
      payload.alertType === 'movement'
        ? `🚨 *Alerte iooeh*\n\n${payload.vehicleName}: ${payload.geofenceName}.\n\n🔔 Ouvrez l'app pour vérifier sa position.`
        : `🚗 *Alerte iooeh*\n\n${payload.vehicleName} ${
            payload.alertType === 'enter' ? 'est entré dans' : 'a quitté'
          } la zone "${payload.geofenceName}".\n\n🔔 Connectez-vous à l'app pour plus de détails.`;

    const formattedPhone = this.formatPhoneForWhatsApp(payload.phone);

    try {
      const res = await fetch(
        `https://graph.facebook.com/v18.0/${phoneId}/messages`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            messaging_product: 'whatsapp',
            to: formattedPhone,
            type: 'text',
            text: { body: message },
          }),
        },
      );

      if (!res.ok) {
        const err = await res.text();
        this.logger.error(`WhatsApp ${res.status}: ${err}`);
      } else {
        this.logger.log(
          `✅ WhatsApp envoyé → ${formattedPhone} | ${payload.alertType} ${payload.geofenceName}`,
        );
      }
    } catch (e) {
      this.logger.error('Erreur réseau WhatsApp', e);
    }
  }

  private formatPhoneForWhatsApp(phone: string): string {
    const digits = phone.replace(/\D/g, '');
    if (digits.startsWith('261')) {
      return digits;
    }
    if (digits.startsWith('0')) {
      return '261' + digits.slice(1);
    }
    if (digits.length === 9) {
      return '261' + digits;
    }
    return digits;
  }
}
