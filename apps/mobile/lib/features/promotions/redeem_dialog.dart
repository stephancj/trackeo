import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entitlements/providers/entitlements_provider.dart';
import 'promotions_repository.dart';

class RedeemDialog extends ConsumerStatefulWidget {
  const RedeemDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const RedeemDialog(),
    );
  }

  @override
  ConsumerState<RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends ConsumerState<RedeemDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(promotionsRepositoryProvider);
      final result = await repo.redeemCode(code);
      
      setState(() {
        _successMessage = result['message'] as String? ?? 'Code appliqué avec succès !';
      });

      // Rafraîchir les droits utilisateur dans l'application
      ref.invalidate(entitlementsProvider);
    } catch (e) {
      String msg = 'Code invalide ou expiré.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      setState(() {
        _error = msg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.card_giftcard, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text('Code Promo / Parrainage'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saisissez un code coupon ou un code de parrainage pour bénéficier d’une offre sur votre compte.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Code Promo (ex: WELCOME20 ou REF-XXXXXX)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _controller.clear(),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRedeem,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Valider'),
        ),
      ],
    );
  }
}
