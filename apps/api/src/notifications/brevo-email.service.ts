import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';

export interface TransactionalEmailPayload {
  to: string;
  toName?: string;
  subject: string;
  htmlContent: string;
  textContent: string;
  tag: string;
  idempotencyKey?: string;
}

export interface BrandedEmailContent {
  eyebrow: string;
  title: string;
  intro: string;
  details?: Array<{ label: string; value: string }>;
  actionLabel?: string;
  actionUrl?: string;
  notice?: string;
}

interface BrevoSendResponse {
  messageId?: string;
}

@Injectable()
export class BrevoEmailService {
  private readonly logger = new Logger(BrevoEmailService.name);

  async send(payload: TransactionalEmailPayload): Promise<string> {
    const apiKey = process.env.BREVO_API_KEY;
    const senderEmail = process.env.BREVO_SENDER_EMAIL;
    const senderName = process.env.BREVO_SENDER_NAME ?? 'iooeh';

    if (!apiKey || !senderEmail) {
      this.logger.error('Brevo email configuration is incomplete');
      throw new ServiceUnavailableException(
        'L’envoi d’email est temporairement indisponible.',
      );
    }

    let response: Response;
    try {
      response = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          accept: 'application/json',
          'api-key': apiKey,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          sender: { email: senderEmail, name: senderName },
          to: [{ email: payload.to, name: payload.toName }],
          replyTo: process.env.BREVO_REPLY_TO_EMAIL
            ? { email: process.env.BREVO_REPLY_TO_EMAIL, name: senderName }
            : undefined,
          subject: payload.subject,
          htmlContent: payload.htmlContent,
          textContent: payload.textContent,
          tags: [payload.tag],
          headers: payload.idempotencyKey
            ? { 'Idempotency-Key': payload.idempotencyKey }
            : undefined,
        }),
        signal: AbortSignal.timeout(10_000),
      });
    } catch (error) {
      this.logger.error(
        'Brevo request failed',
        error instanceof Error ? error.stack : undefined,
      );
      throw new ServiceUnavailableException(
        'L’envoi d’email est temporairement indisponible.',
      );
    }

    if (!response.ok) {
      const details = await response.text();
      this.logger.error(`Brevo ${response.status}: ${details}`);
      throw new ServiceUnavailableException(
        'L’envoi d’email est temporairement indisponible.',
      );
    }

    const result = (await response.json()) as BrevoSendResponse;
    if (!result.messageId) {
      this.logger.error('Brevo response did not include a messageId');
      throw new ServiceUnavailableException(
        'L’envoi d’email est temporairement indisponible.',
      );
    }

    return result.messageId;
  }

  renderBranded(content: BrandedEmailContent): {
    htmlContent: string;
    textContent: string;
  } {
    const safe = (value: string) => this.escapeHtml(value);
    const detailsHtml = content.details?.length
      ? `<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 24px;background:#f4f5f3;border-radius:14px">${content.details
          .map(
            ({ label, value }) =>
              `<tr><td style="padding:11px 16px;color:#747789;font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.7px">${safe(label)}</td><td align="right" style="padding:11px 16px;color:#333549;font-size:14px;font-weight:700">${safe(value)}</td></tr>`,
          )
          .join('')}</table>`
      : '';
    const actionHtml =
      content.actionLabel && content.actionUrl
        ? `<a href="${safe(content.actionUrl)}" style="display:inline-block;padding:15px 22px;border-radius:12px;background:#4ecb8d;color:#15231b;font-size:15px;font-weight:800;text-decoration:none">${safe(content.actionLabel)}</a>`
        : '';
    const noticeHtml = content.notice
      ? `<p style="margin:24px 0 0;color:#858899;font-size:12px;line-height:1.65">${safe(content.notice)}</p>`
      : '';
    const textDetails =
      content.details?.map(({ label, value }) => `${label} : ${value}`).join('\n') ??
      '';

    return {
      htmlContent: `<!doctype html><html lang="fr"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;background:#eef0ed;color:#333549;font-family:Arial,Helvetica,sans-serif"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:32px 14px;background:#eef0ed"><tr><td align="center"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:580px;background:#ffffff;border-radius:22px;overflow:hidden"><tr><td style="padding:34px 36px 26px;background:#333549"><div style="color:#ffffff;font-size:26px;font-weight:900;letter-spacing:-1px">iooeh<span style="color:#4ecb8d">●</span></div><p style="margin:22px 0 0;color:#7ee0ae;font-size:12px;font-weight:800;letter-spacing:1.8px;text-transform:uppercase">${safe(content.eyebrow)}</p></td></tr><tr><td style="padding:34px 36px"><h1 style="margin:0 0 14px;color:#333549;font-size:29px;line-height:1.18;letter-spacing:-.7px">${safe(content.title)}</h1><p style="margin:0 0 24px;color:#626577;font-size:16px;line-height:1.7">${safe(content.intro)}</p>${detailsHtml}${actionHtml}${noticeHtml}</td></tr><tr><td style="padding:20px 36px;background:#f7f8f6;color:#9295a2;font-size:11px;line-height:1.6">iooeh · La sérénité de savoir où se trouve votre véhicule.<br>Madagascar</td></tr></table></td></tr></table></body></html>`,
      textContent: [
        `iooeh — ${content.eyebrow}`,
        '',
        content.title,
        '',
        content.intro,
        textDetails ? `\n${textDetails}` : '',
        content.actionLabel && content.actionUrl
          ? `\n${content.actionLabel} : ${content.actionUrl}`
          : '',
        content.notice ? `\n${content.notice}` : '',
      ].join('\n'),
    };
  }

  escapeHtml(value: string): string {
    return value.replace(
      /[&<>'"]/g,
      (character) =>
        ({
          '&': '&amp;',
          '<': '&lt;',
          '>': '&gt;',
          "'": '&#39;',
          '"': '&quot;',
        })[character]!,
    );
  }
}
