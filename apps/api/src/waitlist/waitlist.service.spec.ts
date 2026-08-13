import { WaitlistSubscriber } from './waitlist-subscriber.entity';
import { WaitlistService } from './waitlist.service';

describe('WaitlistService double opt-in', () => {
  const createService = (existing: WaitlistSubscriber | null = null) => {
    const repository = {
      findOne: jest.fn().mockResolvedValue(existing),
      create: jest.fn((value) => value),
      save: jest.fn((value) =>
        Promise.resolve({ id: 'subscriber-id', ...value }),
      ),
      update: jest.fn().mockResolvedValue({ affected: 1 }),
    };
    const emails = {
      send: jest.fn().mockResolvedValue('<message-id>'),
      escapeHtml: jest.fn((value: string) => value),
      renderBranded: jest.fn().mockReturnValue({
        htmlContent: '<p>Confirmez</p>',
        textContent: 'Confirmez',
      }),
    };

    return {
      service: new WaitlistService(repository as never, emails as never),
      repository,
      emails,
    };
  };

  it('stores a pending subscriber and sends a verification email', async () => {
    const { service, repository, emails } = createService();

    await expect(service.join('person@example.com')).resolves.toEqual({
      ok: true,
      verificationRequired: true,
    });

    expect(repository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        email: 'person@example.com',
        status: 'pending',
        verificationTokenHash: expect.stringMatching(/^[a-f0-9]{64}$/),
      }),
    );
    expect(emails.send).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'person@example.com',
        tag: 'waitlist-verification',
      }),
    );
  });

  it('does not disclose or resend an already verified subscription', async () => {
    const verified = {
      id: 'subscriber-id',
      email: 'person@example.com',
      status: 'subscribed',
      verifiedAt: new Date(),
    } as WaitlistSubscriber;
    const { service, emails } = createService(verified);

    await service.join(verified.email);

    expect(emails.send).not.toHaveBeenCalled();
  });

  it('activates a pending subscriber with a valid token', async () => {
    const pending = {
      id: 'subscriber-id',
      email: 'person@example.com',
      status: 'pending',
    } as WaitlistSubscriber;
    const { service, repository } = createService(pending);

    await expect(service.confirm('a'.repeat(43))).resolves.toEqual({
      ok: true,
    });
    expect(repository.update).toHaveBeenCalledWith(
      pending.id,
      expect.objectContaining({
        status: 'subscribed',
        verificationTokenHash: null,
      }),
    );
  });

  it('returns a generic failure for an invalid or expired token', async () => {
    const { service } = createService();

    await expect(service.confirm('a'.repeat(43))).resolves.toEqual({
      ok: false,
    });
  });
});
