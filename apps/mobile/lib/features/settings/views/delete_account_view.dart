import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class DeleteAccountView extends ConsumerStatefulWidget {
  const DeleteAccountView({super.key});

  @override
  ConsumerState<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends ConsumerState<DeleteAccountView> {
  final _passwordController = TextEditingController();
  bool _understandsConsequences = false;
  bool _obscurePassword = true;
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    FocusScope.of(context).unfocus();
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Saisissez votre mot de passe actuel');
      return;
    }
    if (!_understandsConsequences) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .deleteAccount(_passwordController.text);
    } on DioException catch (exception) {
      final data = exception.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Suppression impossible. Vérifiez votre connexion.';
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _error = message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _error = 'Suppression impossible. Réessayez dans quelques instants.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _understandsConsequences &&
        _passwordController.text.length >= 6 &&
        !_isDeleting;

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Supprimer mon compte'),
          automaticallyImplyLeading: !_isDeleting,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.pastelRed,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.delete_forever_outlined,
                      color: AppColors.statusAlert,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cette action est définitive',
                    style: AppTextStyles.pageTitleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Une fois votre compte supprimé, nous ne pourrons pas restaurer vos données.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _ConsequenceRow(
                    icon: Icons.route_outlined,
                    text:
                        'Vos zones et votre historique d’alertes seront effacés.',
                  ),
                  const SizedBox(height: 16),
                  const _ConsequenceRow(
                    icon: Icons.directions_car_outlined,
                    text: 'Vos véhicules seront dissociés de ce compte.',
                  ),
                  const SizedBox(height: 16),
                  const _ConsequenceRow(
                    icon: Icons.notifications_off_outlined,
                    text: 'Vous ne recevrez plus de notifications Trackeo.',
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Confirmez avec votre mot de passe',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isDeleting,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) {
                      if (canDelete) _deleteAccount();
                    },
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      errorText: _error,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Afficher le mot de passe'
                            : 'Masquer le mot de passe',
                        onPressed: _isDeleting
                            ? null
                            : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _understandsConsequences,
                    onChanged: _isDeleting
                        ? null
                        : (value) => setState(
                              () => _understandsConsequences = value ?? false,
                            ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.statusAlert,
                    title: const Text(
                      'Je comprends que mes données seront supprimées définitivement.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: canDelete ? _deleteAccount : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statusAlert,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.statusAlert.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Supprimer définitivement',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.maybePop(context),
                      child: const Text('Conserver mon compte'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsequenceRow extends StatelessWidget {
  const _ConsequenceRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, size: 19, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
