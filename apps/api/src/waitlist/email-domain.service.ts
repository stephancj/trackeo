import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { resolve4, resolve6, resolveMx } from 'node:dns/promises';
import { domainToASCII } from 'node:url';

type DnsError = Error & { code?: string };

@Injectable()
export class EmailDomainService {
  async assertDeliverable(email: string): Promise<void> {
    const domain = domainToASCII(email.slice(email.lastIndexOf('@') + 1))
      .toLowerCase()
      .replace(/\.$/, '');

    if (!domain || !domain.includes('.') || domain.length > 253) {
      throw this.invalidEmail();
    }

    try {
      const mxRecords = await this.lookupMx(domain);

      // Un enregistrement MX nul indique explicitement que le domaine
      // n'accepte aucun email (RFC 7505).
      if (mxRecords.length > 0) {
        if (mxRecords.some(({ exchange }) => exchange && exchange !== '.')) {
          return;
        }
        throw this.invalidEmail();
      }
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      if (!this.isMissingRecord(error)) throw this.dnsUnavailable();
    }

    // La livraison vers l'adresse A/AAAA reste valide lorsqu'aucun MX n'est
    // publié. On conserve ce fallback pour ne pas refuser de vrais domaines.
    const addressResults = await Promise.allSettled([
      this.lookupIpv4(domain),
      this.lookupIpv6(domain),
    ]);

    if (
      addressResults.some(
        (result) => result.status === 'fulfilled' && result.value.length > 0,
      )
    ) {
      return;
    }

    if (
      addressResults.every(
        (result) =>
          result.status === 'fulfilled' || this.isMissingRecord(result.reason),
      )
    ) {
      throw this.invalidEmail();
    }

    throw this.dnsUnavailable();
  }

  protected lookupMx(domain: string) {
    return resolveMx(domain);
  }

  protected lookupIpv4(domain: string) {
    return resolve4(domain);
  }

  protected lookupIpv6(domain: string) {
    return resolve6(domain);
  }

  private isMissingRecord(error: unknown): boolean {
    const code = (error as DnsError | undefined)?.code;
    return code === 'ENODATA' || code === 'ENOTFOUND';
  }

  private invalidEmail(): BadRequestException {
    return new BadRequestException(
      'Le domaine de cette adresse email ne peut pas recevoir de messages.',
    );
  }

  private dnsUnavailable(): ServiceUnavailableException {
    return new ServiceUnavailableException(
      'La vérification de l’adresse email est temporairement indisponible.',
    );
  }
}
