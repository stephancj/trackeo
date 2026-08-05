import { PaymentsService } from './payments.service';
import { Payment, PaymentStatus } from './payment.entity';

describe('PaymentsService PAPI notifications', () => {
  it('looks up the local payment with merchantPaymentReference', async () => {
    const payment = {
      reference: 'IOOEH-60f4db35-3d1f-416a-be79-d460f10422e0',
      amount: 29000,
      currency: 'MGA',
      status: PaymentStatus.PENDING,
      papiNotificationToken: 'notification-secret',
    } as Payment;
    const queryBuilder = {
      addSelect: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      getOne: jest.fn().mockResolvedValue(payment),
    };
    const paymentRepo = {
      createQueryBuilder: jest.fn().mockReturnValue(queryBuilder),
      save: jest.fn().mockResolvedValue(payment),
    };
    const service = new PaymentsService(
      paymentRepo as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
    );

    await service.handleNotification({
      paymentStatus: 'PENDING',
      currency: 'MGA',
      amount: 29000,
      merchantPaymentReference: payment.reference,
      paymentReference: '60f4db35-3d1f-416a-be79-d460f10422e0',
      notificationToken: 'notification-secret',
    });

    expect(queryBuilder.where).toHaveBeenCalledWith(
      'payment.reference = :reference',
      { reference: payment.reference },
    );
    expect(payment.papiMerchantReference).toBe(payment.reference);
    expect(payment.papiPaymentReference).toBe(
      '60f4db35-3d1f-416a-be79-d460f10422e0',
    );
  });
});
