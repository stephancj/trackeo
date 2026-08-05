import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/entitlements_provider.dart';

class FeatureGate extends ConsumerWidget {
  final List<String> anyOf;
  final Widget child;
  final String title;
  final String description;

  const FeatureGate({
    super.key,
    required this.anyOf,
    required this.child,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rights = ref.watch(entitlementsProvider);
    return rights.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => child,
      data: (entitlements) {
        if (anyOf.any(entitlements.has)) return child;
        return _LockedFeature(
          planName: entitlements.planName,
          title: title,
          description: description,
        );
      },
    );
  }
}

class _LockedFeature extends StatelessWidget {
  final String planName;
  final String title;
  final String description;

  const _LockedFeature({
    required this.planName,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.pastelGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 18),
                Text(title,
                    style: AppTextStyles.sectionTitle,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(description,
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text('Plan actuel : $planName',
                      style: AppTextStyles.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
