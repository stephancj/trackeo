import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../entitlements/providers/entitlements_provider.dart';
import '../providers/payments_provider.dart';

class PaymentReturnView extends ConsumerStatefulWidget {
  final String reference;
  final String hintedStatus;

  const PaymentReturnView({
    super.key,
    required this.reference,
    required this.hintedStatus,
  });

  @override
  ConsumerState<PaymentReturnView> createState() => _PaymentReturnViewState();
}

class _PaymentReturnViewState extends ConsumerState<PaymentReturnView> {
  String status = 'pending';
  Timer? timer;
  int attempts = 0;

  @override
  void initState() {
    super.initState();
    status = widget.hintedStatus == 'failed' ? 'failed' : 'pending';
    _check();
  }

  Future<void> _check() async {
    if (widget.reference.isEmpty || status == 'failed') return;
    try {
      final data =
          await ref.read(paymentsRepositoryProvider).status(widget.reference);
      if (!mounted) return;
      setState(() => status = data['status'] as String? ?? 'pending');
      if (status == 'success') {
        ref.invalidate(entitlementsProvider);
        return;
      }
    } catch (_) {}
    if (++attempts < 20 && mounted) {
      timer = Timer(const Duration(seconds: 2), _check);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final success = status == 'success';
    final failed = status == 'failed';
    final color = success
        ? AppColors.primary
        : failed
            ? AppColors.statusAlert
            : AppColors.statusIdle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .12),
                  ),
                  child: Icon(
                    success
                        ? Icons.check_rounded
                        : failed
                            ? Icons.close_rounded
                            : Icons.hourglass_top_rounded,
                    size: 42,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  success
                      ? 'Paiement confirmé'
                      : failed
                          ? 'Paiement non abouti'
                          : 'Confirmation en cours',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  success
                      ? 'Votre abonnement est maintenant actif.'
                      : failed
                          ? 'Aucun débit confirmé. Vous pouvez réessayer.'
                          : 'Nous attendons la confirmation sécurisée de PAPI.mg.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (_) => false),
                  child: const Text('Retour à l’application'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
