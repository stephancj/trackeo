import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../models/alert_model.dart';
import '../providers/alerts_provider.dart';
import 'widgets/alert_skeletons.dart';
import 'widgets/alert_detail_sheet.dart';

class AllAlertsView extends ConsumerWidget {
  const AllAlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: alertsState.whenOrNull(
              data: (alerts) => Text(
                'Toutes les activités (${alerts.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ) ??
            const Text(
              'Toutes les activités',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 3-dot menu: Marquer tout comme lu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryDark),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'mark_read') {
                await ref.read(alertsProvider.notifier).markAllRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les alertes marquées comme lues'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Marquer tout comme lu'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: alertsState.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: AlertListSkeleton(count: 8),
        ),
        error: (e, _) => Center(
          child: Text('Erreur: $e',
              style: const TextStyle(color: AppColors.statusAlert)),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AlertCard(alert: alerts[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends ConsumerWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  Color _dotColor(String type) {
    switch (type) {
      case 'geofence_enter':
        return Colors.green;
      case 'geofence_exit':
        return Colors.orange;
      case 'low_battery':
        return AppColors.batteryLow;
      case 'speed_limit':
        return AppColors.statusAlert;
      default:
        return AppColors.primary;
    }
  }

  String _title(String type) {
    switch (type) {
      case 'geofence_enter':
        return 'Entrée dans la zone';
      case 'geofence_exit':
        return 'Sortie de la zone';
      case 'low_battery':
        return 'Batterie faible';
      case 'speed_limit':
        return 'Excès de vitesse';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = alert.status == 'open';
    final color = _dotColor(alert.type);

    return GestureDetector(
      onTap: () => AlertDetailSheet.show(context, ref, alert),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOpen ? color.withValues(alpha: 0.04) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen ? color.withValues(alpha: 0.25) : AppColors.divider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot indicator
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: isOpen ? color : AppColors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title(alert.type),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isOpen ? FontWeight.w700 : FontWeight.w500,
                            color: isOpen
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Nouveau',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (alert.message != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      alert.message!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOpen
                            ? AppColors.textHint
                            : AppColors.textHint.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Timestamp
            Text(
              timeago.format(alert.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isOpen
                    ? AppColors.textHint
                    : AppColors.textHint.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green, size: 36),
          ),
          const SizedBox(height: 18),
          const Text(
            'Aucune activité',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos véhicules sont dans leurs zones.',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
