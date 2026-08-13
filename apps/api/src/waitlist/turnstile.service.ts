import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';

interface TurnstileVerificationResponse {
  success: boolean;
  hostname?: string;
  action?: string;
  'error-codes'?: string[];
}

@Injectable()
export class TurnstileService {
  private readonly logger = new Logger(TurnstileService.name);

  async verify(token: string): Promise<void> {
    const secret = process.env.TURNSTILE_SECRET_KEY;

    if (!secret) {
      this.logger.error('TURNSTILE_SECRET_KEY is not configured');
      throw new ServiceUnavailableException(
        'La vérification anti-robot est temporairement indisponible.',
      );
    }

    let result: TurnstileVerificationResponse;

    try {
      const response = await fetch(
        'https://challenges.cloudflare.com/turnstile/v0/siteverify',
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ secret, response: token }),
          signal: AbortSignal.timeout(8_000),
        },
      );

      if (!response.ok) {
        throw new Error(`Siteverify returned HTTP ${response.status}`);
      }

      result = (await response.json()) as TurnstileVerificationResponse;
    } catch (error) {
      this.logger.error(
        'Turnstile Siteverify request failed',
        error instanceof Error ? error.stack : undefined,
      );
      throw new ServiceUnavailableException(
        'La vérification anti-robot est temporairement indisponible.',
      );
    }

    const allowedHostnames = (process.env.TURNSTILE_ALLOWED_HOSTNAMES ?? '')
      .split(',')
      .map((hostname) => hostname.trim().toLowerCase())
      .filter(Boolean);
    const hasAllowedHostname =
      allowedHostnames.length === 0 ||
      (typeof result.hostname === 'string' &&
        allowedHostnames.includes(result.hostname.toLowerCase()));

    if (
      !result.success ||
      result.action !== 'waitlist' ||
      !hasAllowedHostname
    ) {
      this.logger.warn(
        `Turnstile rejected waitlist submission (${(result['error-codes'] ?? []).join(', ') || 'invalid metadata'})`,
      );
      throw new BadRequestException(
        'La vérification anti-robot a échoué. Veuillez réessayer.',
      );
    }
  }
}
