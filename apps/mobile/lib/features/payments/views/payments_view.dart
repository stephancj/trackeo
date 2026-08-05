import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/payment_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../entitlements/providers/entitlements_provider.dart';
import '../providers/payments_provider.dart';

class PaymentsView extends ConsumerStatefulWidget {
  const PaymentsView({super.key});
  @override
  ConsumerState<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends ConsumerState<PaymentsView> {
  String? loadingPlan;
  Future<void> checkout(Map<String, dynamic> plan) async {
    setState(() => loadingPlan = plan['id'] as String);
    try {
      final result = await ref
          .read(paymentsRepositoryProvider)
          .checkout(plan['id'] as String);
      await openPaymentUrl(result['paymentLink'] as String);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Impossible de démarrer le paiement. Vérifiez la configuration PAPI.')));
      }
    } finally {
      if (mounted) setState(() => loadingPlan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(purchasablePlansProvider);
    final current = ref.watch(entitlementsProvider).valueOrNull?.planCode;
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Abonnement')),
        body: plans.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Plans indisponibles.')),
          data: (items) =>
              ListView(padding: const EdgeInsets.all(16), children: [
            Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(20)),
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: AppColors.primary),
                      SizedBox(height: 12),
                      Text('Choisissez votre niveau de protection',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text(
                          'Paiement sécurisé par PAPI.mg. Le plan est activé après confirmation serveur.',
                          style: TextStyle(color: Colors.white70, height: 1.4))
                    ])),
            const SizedBox(height: 16),
            ...items.where((p) => NumberFormatHelper.amount(p) > 0).map((plan) {
              final code = plan['code'];
              final active = code == current;
              return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                          color: active ? AppColors.primary : AppColors.divider,
                          width: active ? 2 : 1),
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(plan['name'] as String,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800))),
                          if (active) const Chip(label: Text('Plan actuel'))
                        ]),
                        Text(
                            '${NumberFormatHelper.amount(plan).toStringAsFixed(0)} MGA / mois',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(plan['description'] as String? ?? '',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: active || loadingPlan != null
                                    ? null
                                    : () => checkout(plan),
                                child: Text(loadingPlan == plan['id']
                                    ? 'Préparation…'
                                    : active
                                        ? 'Actif'
                                        : 'Choisir ${plan['name']}')))
                      ]));
            }),
          ]),
        ));
  }
}

class NumberFormatHelper {
  static double amount(Map<String, dynamic> plan) =>
      double.tryParse('${plan['priceMonthly']}') ?? 0;
}
