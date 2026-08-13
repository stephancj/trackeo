import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { EmailDomainService } from './email-domain.service';

class TestEmailDomainService extends EmailDomainService {
  mxResult: Array<{ exchange: string; priority: number }> | Error = [];
  ipv4Result: string[] | Error = [];
  ipv6Result: string[] | Error = [];

  protected override lookupMx() {
    return this.resolve(this.mxResult);
  }

  protected override lookupIpv4() {
    return this.resolve(this.ipv4Result);
  }

  protected override lookupIpv6() {
    return this.resolve(this.ipv6Result);
  }

  private resolve<T>(result: T | Error): Promise<T> {
    return result instanceof Error
      ? Promise.reject(result)
      : Promise.resolve(result);
  }
}

const dnsError = (code: string) => Object.assign(new Error(code), { code });

describe('EmailDomainService', () => {
  it('accepts a domain with a mail exchanger', async () => {
    const service = new TestEmailDomainService();
    service.mxResult = [{ exchange: 'mail.example.com', priority: 10 }];

    await expect(
      service.assertDeliverable('person@example.com'),
    ).resolves.toBeUndefined();
  });

  it('accepts an A record when the domain has no MX record', async () => {
    const service = new TestEmailDomainService();
    service.mxResult = dnsError('ENODATA');
    service.ipv4Result = ['192.0.2.1'];

    await expect(
      service.assertDeliverable('person@example.com'),
    ).resolves.toBeUndefined();
  });

  it('rejects a domain that has no mail or address record', async () => {
    const service = new TestEmailDomainService();
    service.mxResult = dnsError('ENOTFOUND');
    service.ipv4Result = dnsError('ENOTFOUND');
    service.ipv6Result = dnsError('ENODATA');

    await expect(
      service.assertDeliverable('person@does-not-exist.invalid'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('reports a temporary DNS failure without accepting the address', async () => {
    const service = new TestEmailDomainService();
    service.mxResult = dnsError('ETIMEOUT');

    await expect(
      service.assertDeliverable('person@example.com'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
