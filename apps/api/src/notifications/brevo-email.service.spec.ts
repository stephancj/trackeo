import { ServiceUnavailableException } from '@nestjs/common';
import { BrevoEmailService } from './brevo-email.service';

describe('BrevoEmailService', () => {
  const originalEnv = process.env;
  const originalFetch = global.fetch;

  beforeEach(() => {
    process.env = {
      ...originalEnv,
      BREVO_API_KEY: 'test-key',
      BREVO_SENDER_EMAIL: 'notifications@iooeh.com',
      BREVO_SENDER_NAME: 'iooeh',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('sends a transactional email through the Brevo API', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue({ messageId: '<message-id>' }),
    });

    await expect(
      new BrevoEmailService().send({
        to: 'person@example.com',
        subject: 'Confirmez votre adresse',
        htmlContent: '<p>Confirmez</p>',
        textContent: 'Confirmez',
        tag: 'waitlist-verification',
        idempotencyKey: 'idempotency-key',
      }),
    ).resolves.toBe('<message-id>');

    expect(global.fetch).toHaveBeenCalledWith(
      'https://api.brevo.com/v3/smtp/email',
      expect.objectContaining({ method: 'POST' }),
    );
  });

  it('fails closed when Brevo is not configured', async () => {
    delete process.env.BREVO_API_KEY;

    await expect(
      new BrevoEmailService().send({
        to: 'person@example.com',
        subject: 'Test',
        htmlContent: '<p>Test</p>',
        textContent: 'Test',
        tag: 'test',
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('renders a branded responsive email and escapes user content', () => {
    const rendered = new BrevoEmailService().renderBranded({
      eyebrow: 'Sécurité',
      title: '<Connexion>',
      intro: 'Nouvelle connexion & contrôle',
      actionLabel: 'Ouvrir iooeh',
      actionUrl: 'https://app.iooeh.com/?a=1&b=2',
    });

    expect(rendered.htmlContent).toContain('iooeh');
    expect(rendered.htmlContent).toContain('#4ecb8d');
    expect(rendered.htmlContent).toContain('&lt;Connexion&gt;');
    expect(rendered.htmlContent).not.toContain('<Connexion>');
    expect(rendered.textContent).toContain('Ouvrir iooeh');
  });
});
