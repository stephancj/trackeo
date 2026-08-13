import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { TurnstileService } from './turnstile.service';

describe('TurnstileService', () => {
  const originalEnv = process.env;
  const originalFetch = global.fetch;

  beforeEach(() => {
    process.env = {
      ...originalEnv,
      TURNSTILE_SECRET_KEY: 'test-secret',
      TURNSTILE_ALLOWED_HOSTNAMES: 'iooeh.com,www.iooeh.com',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('accepts a valid waitlist token from an allowed hostname', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue({
        success: true,
        action: 'waitlist',
        hostname: 'iooeh.com',
      }),
    });

    await expect(
      new TurnstileService().verify('token'),
    ).resolves.toBeUndefined();
  });

  it('rejects an invalid token', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: jest.fn().mockResolvedValue({
        success: false,
        'error-codes': ['invalid-input-response'],
      }),
    });

    await expect(new TurnstileService().verify('token')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('fails closed when the secret is missing', async () => {
    delete process.env.TURNSTILE_SECRET_KEY;

    await expect(new TurnstileService().verify('token')).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
