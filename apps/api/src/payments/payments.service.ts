import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID, timingSafeEqual } from 'node:crypto';
import { In, Repository } from 'typeorm';
import { Subscription, SubscriptionStatus } from '../admin/subscription.entity';
import { EntitlementsService } from '../entitlements/entitlements.service';
import { Plan } from '../entitlements/plan.entity';
import { UsersService } from '../users/users.service';
import { PromotionsService } from '../promotions/promotions.service';
import { CreatePaymentDto, PapiNotificationDto } from './payments.dto';
import { Payment, PaymentStatus } from './payment.entity';

@Injectable()
export class PaymentsService {
  private readonly endpoint = 'https://app.papi.mg/dashboard/api/payment-links';
  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepo: Repository<Payment>,
    @InjectRepository(Plan) private readonly planRepo: Repository<Plan>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepo: Repository<Subscription>,
    private readonly users: UsersService,
    private readonly entitlements: EntitlementsService,
    private readonly promotionsService: PromotionsService,
  ) {}

  async create(userId: number, dto: CreatePaymentDto) {
    await this.entitlements.assertFeature(userId, 'online_payments');
    const apiKey = process.env.PAPI_API_KEY;
    if (!apiKey)
      throw new ServiceUnavailableException(
        'Le paiement PAPI n’est pas encore configuré.',
      );
    const [plan, user] = await Promise.all([
      this.planRepo.findOne({ where: { id: dto.planId, isActive: true } }),
      this.users.findById(userId),
    ]);
    if (!plan || !user)
      throw new NotFoundException('Plan ou utilisateur introuvable.');

    let amount = Math.round(Number(plan.priceMonthly));
    if (dto.couponCode) {
      const discount = await this.promotionsService.validateCouponForCheckout(
        dto.couponCode,
        dto.planId,
        userId,
      );
      amount = discount.finalAmount;
    }

    if (amount < 300)
      throw new BadRequestException(
        'Ce plan ou ce montant ne nécessite pas de paiement PAPI.',
      );
    const reference = `IOOEH-${randomUUID()}`;
    const publicApp = process.env.PUBLIC_APP_URL ?? 'https://app.iooeh.com';
    const publicApi = process.env.PUBLIC_API_URL ?? 'https://api.iooeh.com';
    let payment = await this.paymentRepo.save(
      this.paymentRepo.create({
        userId,
        planId: plan.id,
        reference,
        amount,
        currency: 'MGA',
        status: PaymentStatus.CREATED,
        provider: dto.provider ?? null,
      }),
    );
    const testMode = process.env.PAPI_TEST_MODE !== 'false';
    const payload = {
      amount,
      clientName: user.name || user.email,
      reference,
      description: `Abonnement iooeh ${plan.name}`.slice(0, 255),
      successUrl: `${publicApp}/payment/return?reference=${encodeURIComponent(reference)}&status=success`,
      failureUrl: `${publicApp}/payment/return?reference=${encodeURIComponent(reference)}&status=failed`,
      notificationUrl: `${publicApi}/payments/papi/notification`,
      validDuration: 30,
      ...(dto.provider ? { provider: dto.provider } : {}),
      payerEmail: user.email,
      ...(user.phone ? { payerPhone: user.phone } : {}),
      isTestMode: testMode,
      ...(testMode ? { testReason: 'Validation intégration iooeh' } : {}),
    };
    const response = await fetch(this.endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Token: apiKey },
      body: JSON.stringify(payload),
    });
    const raw: unknown = await response.json().catch(() => null);
    if (
      !response.ok ||
      typeof raw !== 'object' ||
      raw === null ||
      !('data' in raw)
    ) {
      payment.status = PaymentStatus.FAILED;
      payment.failureMessage = `PAPI HTTP ${response.status}`;
      await this.paymentRepo.save(payment);
      throw new BadGatewayException(
        'PAPI n’a pas pu créer le lien de paiement.',
      );
    }
    const data = (raw as { data: Record<string, unknown> }).data;
    if (
      typeof data.paymentLink !== 'string' ||
      typeof data.notificationToken !== 'string'
    )
      throw new BadGatewayException('Réponse PAPI incomplète.');
    payment.status = PaymentStatus.PENDING;
    payment.paymentLink = data.paymentLink;
    payment.papiNotificationToken = data.notificationToken;
    payment.expiresAt =
      typeof data.linkExpirationDateTime === 'number'
        ? new Date(data.linkExpirationDateTime * 1000)
        : new Date(Date.now() + 30 * 60_000);
    payment = await this.paymentRepo.save(payment);
    return {
      id: payment.id,
      reference,
      paymentLink: payment.paymentLink,
      expiresAt: payment.expiresAt,
    };
  }

  async handleNotification(dto: PapiNotificationDto) {
    // PAPI distingue sa référence interne (`paymentReference`) de la référence
    // fournie par le marchand (`merchantPaymentReference`). Notre ligne locale
    // est toujours indexée par cette dernière.
    const merchantReference =
      dto.merchantPaymentReference?.trim() ||
      (dto.paymentReference.startsWith('IOOEH-')
        ? dto.paymentReference.trim()
        : null);
    if (!merchantReference)
      throw new BadRequestException(
        'Référence marchand PAPI manquante ou invalide.',
      );
    const payment = await this.paymentRepo
      .createQueryBuilder('payment')
      .addSelect('payment.papiNotificationToken')
      .where('payment.reference = :reference', {
        reference: merchantReference,
      })
      .getOne();
    if (
      !payment ||
      !payment.papiNotificationToken ||
      !this.safeEqual(payment.papiNotificationToken, dto.notificationToken)
    )
      throw new BadRequestException('Notification PAPI invalide.');
    if (
      Number(dto.amount) !== payment.amount ||
      dto.currency !== payment.currency
    )
      throw new BadRequestException('Montant ou devise incohérent.');
    if (
      payment.status === PaymentStatus.SUCCESS &&
      dto.paymentStatus === 'SUCCESS'
    )
      return { received: true };
    payment.paymentMethod = dto.paymentMethod ?? null;
    payment.papiMerchantReference = merchantReference;
    payment.papiPaymentReference = dto.paymentReference;
    payment.rawNotification = {
      ...(dto as unknown as Record<string, unknown>),
      notificationToken: '[redacted]',
    };
    if (dto.paymentStatus === 'SUCCESS') {
      payment.status = PaymentStatus.SUCCESS;
      payment.paidAt ??= new Date();
      await this.activateSubscription(payment);
    } else if (dto.paymentStatus === 'FAILED') {
      payment.status = PaymentStatus.FAILED;
      payment.failureMessage = dto.message ?? null;
      await this.suspendSubscription(payment);
    } else payment.status = PaymentStatus.PENDING;
    await this.paymentRepo.save(payment);
    return { received: true };
  }
  async status(userId: number, reference: string) {
    const p = await this.paymentRepo.findOne({ where: { userId, reference } });
    if (!p) throw new NotFoundException('Paiement introuvable.');
    return {
      reference: p.reference,
      status: p.status,
      amount: p.amount,
      currency: p.currency,
      paidAt: p.paidAt,
      planId: p.planId,
    };
  }
  async history(userId: number) {
    return this.paymentRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }
  listPlans() {
    return this.planRepo.find({
      where: { isActive: true },
      order: { displayOrder: 'ASC' },
    });
  }
  private async activateSubscription(payment: Payment) {
    const plan = await this.planRepo.findOneByOrFail({ id: payment.planId });
    const sub = await this.entitlements.ensureDefaultSubscription(
      payment.userId,
    );
    sub.planId = plan.id;
    sub.plan = plan.code;
    sub.status = SubscriptionStatus.ACTIVE;
    sub.trialEndsAt = null;
    const next = new Date();
    next.setMonth(next.getMonth() + 1);
    sub.nextBillingDate = next;
    await this.subscriptionRepo.save(sub);
    this.entitlements.invalidate(payment.userId);
    await this.promotionsService.qualifyReferralOnPayment(payment.userId, payment.id);
  }

  private async suspendSubscription(payment: Payment) {
    const sub = await this.subscriptionRepo.findOne({ where: { userId: payment.userId } });
    if (sub && sub.status === SubscriptionStatus.ACTIVE && sub.planId === payment.planId) {
      sub.status = SubscriptionStatus.SUSPENDED;
      sub.notes = (sub.notes ? sub.notes + '\n' : '') + `Suspendu suite à l'échec du paiement ${payment.reference}`;
      await this.subscriptionRepo.save(sub);
      this.entitlements.invalidate(payment.userId);
    }
  }

  private safeEqual(a: string, b: string) {
    const aa = Buffer.from(a);
    const bb = Buffer.from(b);
    return aa.length === bb.length && timingSafeEqual(aa, bb);
  }

  async listAdminPayments(page = 1, limit = 50) {
    const [payments, total] = await this.paymentRepo.findAndCount({
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });
    if (payments.length === 0) return { data: [], meta: { total, page, limit, totalPages: 0 } };

    const userIds = [...new Set(payments.map((p) => p.userId))];
    const planIds = [...new Set(payments.map((p) => p.planId))];

    const [usersList, plansList] = await Promise.all([
      this.users.findAll(),
      this.planRepo.find({ where: { id: In(planIds) } }),
    ]);

    const userMap = new Map(usersList.map((u) => [u.id, u]));
    const planMap = new Map(plansList.map((p) => [p.id, p]));

    const data = payments.map((p) => {
      const u = userMap.get(p.userId);
      const plan = planMap.get(p.planId);
      return {
        ...p,
        userName: u?.name || u?.email || `Utilisateur #${p.userId}`,
        userEmail: u?.email || '',
        planName: plan?.name || 'Plan',
        planCode: plan?.code || '',
      };
    });

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
