import { Injectable, Logger } from '@nestjs/common';

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

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

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
}
