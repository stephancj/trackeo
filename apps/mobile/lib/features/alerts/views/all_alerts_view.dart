import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../models/alert_model.dart';
import '../providers/alerts_provider.dart';
import '../../vehicles/providers/vehicles_provider.dart';
import 'widgets/alert_skeletons.dart';
import 'widgets/alert_detail_sheet.dart';

class AllAlertsView extends ConsumerStatefulWidget {
  const AllAlertsView({super.key});

  @override
  ConsumerState<AllAlertsView> createState() => _AllAlertsViewState();
}

class _AllAlertsViewState extends ConsumerState<AllAlertsView> {
  // 'all' | 'open'
  String _statusFilter = 'all';
  // 'all' | 'geofence' | 'speed_limit' | 'low_battery'
  String _typeFilter = 'all';

  bool _matchesType(AlertModel a) {
    switch (_typeFilter) {
      case 'geofence':
        return a.type == 'geofence_enter' || a.type == 'geofence_exit';
      case 'speed_limit':
        return a.type == 'speed_limit';
      case 'low_battery':
        return a.type == 'low_battery';
      default:
        return true;
    }
  }

  String _dayLabel(DateTime dt) {
    final d = toMgTime(dt);
    final now = toMgTime(DateTime.now());
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryDark),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            return const _EmptyState(
              title: 'Aucune activité',
              subtitle: 'Vos véhicules sont dans leurs zones.',
            );
          }

          final openCount = alerts.where((a) => a.status == 'open').length;
          final filtered = alerts
              .where((a) =>
                  (_statusFilter == 'all' || a.status == 'open') &&
                  _matchesType(a))
              .toList();

          return Column(
            children: [
              _buildFilters(openCount),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(alertsProvider.notifier).silentRefresh(),
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            _EmptyState(
                              title: 'Aucun résultat',
                              subtitle: 'Aucune alerte ne correspond au filtre.',
                            ),
                          ],
                        )
                      : _buildGroupedList(filtered),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(int openCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _filterChip(
                label: 'Toutes',
                selected: _statusFilter == 'all',
                onTap: () => setState(() => _statusFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _filterChip(
                label: openCount > 0 ? 'Non lues ($openCount)' : 'Non lues',
                selected: _statusFilter == 'open',
                onTap: () => setState(() => _statusFilter = 'open'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: 'Tous types',
                  selected: _typeFilter == 'all',
                  onTap: () => setState(() => _typeFilter = 'all'),
                  subtle: true,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Zones',
                  icon: Icons.radar_rounded,
                  selected: _typeFilter == 'geofence',
                  onTap: () => setState(() => _typeFilter = 'geofence'),
                  subtle: true,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Vitesse',
                  icon: Icons.speed_rounded,
                  selected: _typeFilter == 'speed_limit',
                  onTap: () => setState(() => _typeFilter = 'speed_limit'),
                  subtle: true,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Batterie',
                  icon: Icons.battery_alert_rounded,
                  selected: _typeFilter == 'low_battery',
                  onTap: () => setState(() => _typeFilter = 'low_battery'),
                  subtle: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    bool subtle = false,
  }) {
    final bg = selected ? AppColors.primary : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: EdgeInsets.symmetric(
            horizontal: subtle ? 12 : 16, vertical: subtle ? 7 : 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.divider.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la liste regroupée par jour (en-têtes "Aujourd'hui", "Hier"…).
  Widget _buildGroupedList(List<AlertModel> alerts) {
    final children = <Widget>[];
    String? currentDay;
    for (final alert in alerts) {
      final label = _dayLabel(alert.createdAt);
      if (label != currentDay) {
        currentDay = label;
        children.add(Padding(
          padding: EdgeInsets.only(
              left: 4, right: 4, top: children.isEmpty ? 0 : 18, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
        ));
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _AlertCard(alert: alert),
      ));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: children,
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

  String? _vehicleName(WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull;
    if (vehicles == null) return null;
    for (final v in vehicles) {
      if (v.id == alert.deviceId) return v.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = alert.status == 'open';
    final color = _dotColor(alert.type);
    final vehicleName = _vehicleName(ref);

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
                  if (vehicleName != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.directions_car_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicleName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
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
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
