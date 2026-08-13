import { BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { User, UserRole } from '../users/user.entity';

describe('AuthService email flows', () => {
  const user = {
    id: 42,
    email: 'person@example.com',
    name: 'Personne Test',
    phone: null,
    role: UserRole.USER,
    emailVerifiedAt: null,
    emailVerificationSentAt: null,
    passwordResetSentAt: null,
  } as User;

  const createService = () => {
    const users = {
      create: jest.fn().mockResolvedValue({ ...user }),
      setEmailVerificationToken: jest.fn().mockResolvedValue(undefined),
      findByEmailVerificationToken: jest.fn(),
      markEmailVerified: jest.fn().mockResolvedValue(undefined),
      findByEmailForEmailFlow: jest.fn(),
      setPasswordResetToken: jest.fn().mockResolvedValue(undefined),
      findByPasswordResetToken: jest.fn(),
      resetPassword: jest.fn().mockResolvedValue(undefined),
    };
    const emails = {
      renderBranded: jest.fn().mockReturnValue({
        htmlContent: '<p>iooeh</p>',
        textContent: 'iooeh',
      }),
      send: jest.fn().mockResolvedValue('<message-id>'),
    };
    const entitlements = {
      ensureDefaultSubscription: jest.fn().mockResolvedValue(undefined),
    };
    const promotions = {
      processRegistrationReferral: jest.fn().mockResolvedValue(undefined),
    };
    const service = new AuthService(
      users as never,
      { sign: jest.fn() } as never,
      entitlements as never,
      promotions as never,
      emails as never,
    );
    return { service, users, emails };
  };

  it('registers without opening a session and sends the activation email', async () => {
    const { service, users, emails } = createService();

    await expect(
      service.register({
        email: user.email,
        password: 'password-123',
        name: user.name!,
        phone: '+261341234567',
      }),
    ).resolves.toEqual({
      ok: true,
      verificationRequired: true,
      email: user.email,
    });

    expect(users.setEmailVerificationToken).toHaveBeenCalledWith(
      user.id,
      expect.stringMatching(/^[a-f0-9]{64}$/),
      expect.any(Date),
    );
    expect(emails.send).toHaveBeenCalledWith(
      expect.objectContaining({
        to: user.email,
        tag: 'account-verification',
      }),
    );
  });

  it('consumes a valid verification token', async () => {
    const { service, users } = createService();
    users.findByEmailVerificationToken.mockResolvedValue({ ...user });

    await expect(service.verifyEmail('a'.repeat(43))).resolves.toEqual({
      ok: true,
    });
    expect(users.markEmailVerified).toHaveBeenCalledWith(user.id);
  });

  it('rejects an invalid or expired verification token', async () => {
    const { service, users } = createService();
    users.findByEmailVerificationToken.mockResolvedValue(null);

    await expect(service.verifyEmail('a'.repeat(43))).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('keeps password recovery responses generic for unknown emails', async () => {
    const { service, users, emails } = createService();
    users.findByEmailForEmailFlow.mockResolvedValue(null);

    await expect(service.forgotPassword('unknown@example.com')).resolves.toEqual(
      { ok: true },
    );
    expect(emails.send).not.toHaveBeenCalled();
  });

  it('stores a hashed reset token and sends a one-time link', async () => {
    const { service, users, emails } = createService();
    users.findByEmailForEmailFlow.mockResolvedValue({
      ...user,
      emailVerifiedAt: new Date(),
    });

    await service.forgotPassword(user.email);

    expect(users.setPasswordResetToken).toHaveBeenCalledWith(
      user.id,
      expect.stringMatching(/^[a-f0-9]{64}$/),
      expect.any(Date),
    );
    expect(emails.send).toHaveBeenCalledWith(
      expect.objectContaining({ tag: 'password-reset' }),
    );
  });
});
