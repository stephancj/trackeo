import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_ui.dart';
import '../../../core/navigation/app_shell.dart';
import '../../../core/utils/app_time.dart';
import '../../vehicles/providers/vehicles_provider.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../models/report_models.dart';
import '../providers/reports_provider.dart';
import 'widgets/report_skeletons.dart';
import '../repositories/reports_repository.dart';
import '../../../core/platform/report_download.dart';
import '../../../core/navigation/trackeo_route.dart';
import 'trip_playback_view.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDuration(int minutes) {
  if (minutes < 60) return '${minutes}min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}min';
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Jui',
    'Jul',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];
  final d = toMgTime(dt);
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]}, $h:$m';
}

String _fmtDist(double km) {
  if (km < 1) return '${(km * 1000).toInt()} m';
  return '${km.toStringAsFixed(1)} km';
}

// ── Main View ─────────────────────────────────────────────────────────────────

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  String _period = '7d';
  int _reportIndex = 0;
  int? _selectedVehicleId;

  ({DateTime from, DateTime to}) get _dateRange {
    final now = DateTime.now();
    late DateTime from;
    if (_period == 'today') {
      from = DateTime(now.year, now.month, now.day);
    } else if (_period == '30d') {
      from = now.subtract(const Duration(days: 30));
    } else {
      from = now.subtract(const Duration(days: 7));
    }
    return (from: from, to: now);
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];

    // Auto-select first vehicle once the list loads
    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedVehicleId == null) {
          setState(() => _selectedVehicleId = vehicles.first.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rapports'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comprendre vos déplacements',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Choisissez une période et le niveau de détail utile.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 14),
                    if (vehicles.length > 1) ...[
                      _VehiclePicker(
                        vehicles: vehicles,
                        selectedId: _selectedVehicleId,
                        onChanged: (id) =>
                            setState(() => _selectedVehicleId = id),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _PeriodPicker(
                      selected: _period,
                      onChanged: (p) => setState(() => _period = p),
                    ),
                    const SizedBox(height: 12),
                    _ReportTypePicker(
                      selectedIndex: _reportIndex,
                      onChanged: (index) =>
                          setState(() => _reportIndex = index),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenu du rapport sélectionné ─────────────────────────────
          Expanded(
            child: _selectedVehicleId == null
                ? const _EmptyVehicle()
                : switch (_reportIndex) {
                    1 => _TripLogTab(
                        vehicleId: _selectedVehicleId!,
                        dateRange: _dateRange,
                      ),
                    2 => _SpeedTab(
                        vehicleId: _selectedVehicleId!,
                        dateRange: _dateRange,
                      ),
                    3 => _IdleTab(
                        vehicleId: _selectedVehicleId!,
                        dateRange: _dateRange,
                      ),
                    4 => _GeofenceTab(
                        vehicleId: _selectedVehicleId!,
                        period: _period,
                      ),
                    _ => _ActivityTab(
                        vehicleId: _selectedVehicleId!,
                        period: _period,
                      ),
                  },
          ),
        ],
      ),
    );
  }
}

// ── Type de rapport ──────────────────────────────────────────────────────────

class _ReportTypePicker extends StatelessWidget {
  const _ReportTypePicker({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const labels = [
    'Résumé d’activité',
    'Trajets',
    'Excès de vitesse',
    'Inactivité',
    'Activité des zones',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedIndex,
      decoration: const InputDecoration(
        labelText: 'Rapport affiché',
        prefixIcon: Icon(Icons.assessment_outlined),
      ),
      items: List.generate(
        labels.length,
        (index) => DropdownMenuItem(
          value: index,
          child: Text(labels[index]),
        ),
      ),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

// ── Vehicle Picker ────────────────────────────────────────────────────────────

class _VehiclePicker extends StatelessWidget {
  final List<Vehicle> vehicles;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  const _VehiclePicker({
    required this.vehicles,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        prefixIcon: const Icon(Icons.directions_car_outlined, size: 20),
      ),
      child: DropdownButton<int>(
        value: selectedId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: vehicles
            .map((v) => DropdownMenuItem(
                  value: v.id,
                  child: Text(v.name, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (id) {
          if (id != null) onChanged(id);
        },
      ),
    );
  }
}

// ── Period Picker ─────────────────────────────────────────────────────────────

class _PeriodPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
              child: _Chip(
                  label: "Aujourd'hui",
                  value: 'today',
                  selected: selected,
                  onTap: onChanged)),
          Expanded(
              child: _Chip(
                  label: '7 jours',
                  value: '7d',
                  selected: selected,
                  onTap: onChanged)),
          Expanded(
              child: _Chip(
                  label: '30 jours',
                  value: '30d',
                  selected: selected,
                  onTap: onChanged)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyVehicle extends ConsumerWidget {
  const _EmptyVehicle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProductEmptyState(
      icon: Icons.directions_car_outlined,
      title: 'Aucun véhicule à analyser',
      message: 'Ajoutez un véhicule pour afficher ses trajets et ses rapports.',
      actionLabel: 'Aller aux véhicules',
      onAction: () => ref.read(activeTabProvider.notifier).state = 0,
    );
  }
}

class _EmptyList extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyList({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ProductEmptyState(
      icon: icon,
      title: 'Aucune donnée sur cette période',
      message: message,
      compact: true,
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Hero ─────────────────────────────────────────────────────────────

class _ActivityHero extends StatelessWidget {
  final ActivitySummary summary;
  const _ActivityHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2BA870), Color(0xFF13805A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2BA870).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 15, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                'DISTANCE PARCOURUE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtDist(summary.distanceKm),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroStat(
                Icons.map_outlined,
                '${summary.tripCount}',
                summary.tripCount > 1 ? 'trajets' : 'trajet',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              _heroStat(
                Icons.drive_eta_outlined,
                _fmtDuration(summary.drivingMinutes),
                'conduite',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.75)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Partial-data banner ───────────────────────────────────────────────────────

class _PartialBanner extends StatelessWidget {
  const _PartialBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB45309)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Période trop large : totaux partiels (limite atteinte). '
              'Choisissez une période plus courte pour un total exact.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Tab ──────────────────────────────────────────────────────────────

class _ActivityTab extends ConsumerWidget {
  final int vehicleId;
  final String period;

  const _ActivityTab({required this.vehicleId, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = activitySummaryProvider((vehicleId, period));
    final summaryAsync = ref.watch(providerKey);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerKey);
        try {
          await ref.read(providerKey.future);
        } catch (_) {}
      },
      color: AppColors.primary,
      child: summaryAsync.when(
        loading: () => const ActivityTabSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.statusAlert),
              const SizedBox(height: 8),
              Text('Erreur: $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        data: (summary) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (summary.partial) ...[
                const _PartialBanner(),
                const SizedBox(height: 12),
              ],
              _ActivityHero(summary: summary),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.pause_circle_outline,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Temps à l\'arrêt',
                    value: _fmtDuration(summary.idleMinutes),
                  ),
                  _StatCard(
                    icon: Icons.speed,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Vitesse max',
                    value: '${summary.maxSpeedKmh.toInt()} km/h',
                  ),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.statusAlert,
                    label: 'Excès de vitesse',
                    value: '${summary.speedViolationCount}',
                  ),
                  _StatCard(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF5B8DEF),
                    label: 'Points GPS',
                    value: '${summary.pointCount}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ), // end when()
    ); // end RefreshIndicator
  }
}

// ── Trip Log Tab ──────────────────────────────────────────────────────────────

class _TripLogTab extends ConsumerWidget {
  final int vehicleId;
  final ({DateTime from, DateTime to}) dateRange;

  const _TripLogTab({required this.vehicleId, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      vehicleId,
      dateRange.from.millisecondsSinceEpoch,
      dateRange.to.millisecondsSinceEpoch,
    );
    final providerKey = tripLogProvider(params);
    final tripsAsync = ref.watch(providerKey);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerKey);
        try {
          await ref.read(providerKey.future);
        } catch (_) {}
      },
      color: AppColors.primary,
      child: tripsAsync.when(
        loading: () => const ReportListSkeleton(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (trips) {
          if (trips.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                _EmptyList(
                  icon: Icons.route,
                  message: 'Aucun trajet sur cette période',
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: trips.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (_, i) => i == 0
                ? _ExportBar(vehicleId: vehicleId, range: dateRange)
                : _TripCard(trip: trips[i - 1], index: i),
          );
        },
      ),
    );
  }
}

class _ExportBar extends ConsumerStatefulWidget {
  final int vehicleId;
  final ({DateTime from, DateTime to}) range;
  const _ExportBar({required this.vehicleId, required this.range});
  @override
  ConsumerState<_ExportBar> createState() => _ExportBarState();
}

class _ExportBarState extends ConsumerState<_ExportBar> {
  String? loading;
  Future<void> download(String format) async {
    setState(() => loading = format);
    try {
      final bytes = await ref.read(reportsRepositoryProvider).exportTrips(
          widget.vehicleId, widget.range.from, widget.range.to, format);
      final ok = await saveReport(bytes, 'trajets-${widget.vehicleId}.$format',
          format == 'pdf' ? 'application/pdf' : 'text/csv');
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Téléchargement disponible dans la PWA web.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export indisponible pour ce plan.')));
      }
    } finally {
      if (mounted) setState(() => loading = null);
    }
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(
            child:
                Text('Exports', style: TextStyle(fontWeight: FontWeight.w800))),
        OutlinedButton.icon(
            onPressed: loading == null ? () => download('csv') : null,
            icon: const Icon(Icons.table_view_rounded, size: 17),
            label: const Text('CSV')),
        const SizedBox(width: 8),
        FilledButton.icon(
            onPressed: loading == null ? () => download('pdf') : null,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
            label: const Text('PDF'))
      ]);
}

class _TripCard extends StatelessWidget {
  final TripLogEntry trip;
  final int index;

  const _TripCard({required this.trip, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: trip.id == null
          ? null
          : () => Navigator.push(context,
              TrackeoRoute(builder: (_) => TripPlaybackView(trip: trip))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Trajet $index',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmtDate(trip.startTime),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.trip_origin,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Départ  ${trip.startLat.toStringAsFixed(4)}, ${trip.startLon.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place, size: 14, color: AppColors.statusAlert),
                const SizedBox(width: 6),
                Text(
                  'Arrivée  ${trip.endLat.toStringAsFixed(4)}, ${trip.endLon.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TripStat(
                  icon: Icons.route,
                  label: _fmtDist(trip.distanceKm),
                ),
                const SizedBox(width: 16),
                _TripStat(
                  icon: Icons.timer_outlined,
                  label: _fmtDuration(trip.durationMin),
                ),
                const SizedBox(width: 16),
                _TripStat(
                  icon: Icons.speed,
                  label: '${trip.maxSpeedKmh.toInt()} km/h max',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TripStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Speed Violations Tab ──────────────────────────────────────────────────────

class _SpeedTab extends ConsumerWidget {
  final int vehicleId;
  final ({DateTime from, DateTime to}) dateRange;

  const _SpeedTab({required this.vehicleId, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      vehicleId,
      dateRange.from.millisecondsSinceEpoch,
      dateRange.to.millisecondsSinceEpoch,
    );
    final providerKey = speedViolationsProvider(params);
    final violationsAsync = ref.watch(providerKey);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerKey);
        try {
          await ref.read(providerKey.future);
        } catch (_) {}
      },
      color: AppColors.primary,
      child: violationsAsync.when(
        loading: () => const ReportListSkeleton(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (violations) {
          if (violations.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                _EmptyList(
                  icon: Icons.speed,
                  message: 'Aucun excès de vitesse sur cette période',
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: violations.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _SpeedCard(violation: violations[i]),
          );
        },
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final SpeedViolation violation;

  const _SpeedCard({required this.violation});

  @override
  Widget build(BuildContext context) {
    final durationMin = (violation.durationSec / 60).ceil();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusAlert.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.statusAlert.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${violation.maxSpeedKmh.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.statusAlert,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${violation.maxSpeedKmh.toInt()} km/h',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.statusAlert,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(violation.startTime),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  'Durée : ${_fmtDuration(durationMin)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.warning_amber_rounded,
              color: AppColors.statusAlert.withValues(alpha: 0.7), size: 20),
        ],
      ),
    );
  }
}

// ── Idle Time Tab ─────────────────────────────────────────────────────────────

class _IdleTab extends ConsumerWidget {
  final int vehicleId;
  final ({DateTime from, DateTime to}) dateRange;

  const _IdleTab({required this.vehicleId, required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      vehicleId,
      dateRange.from.millisecondsSinceEpoch,
      dateRange.to.millisecondsSinceEpoch,
    );
    final providerKey = idleTimeProvider(params);
    final idleAsync = ref.watch(providerKey);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerKey);
        try {
          await ref.read(providerKey.future);
        } catch (_) {}
      },
      color: AppColors.primary,
      child: idleAsync.when(
        loading: () => const ReportListSkeleton(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (episodes) {
          if (episodes.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                _EmptyList(
                  icon: Icons.pause_circle_outline,
                  message: 'Aucune période d\'inactivité sur cette période',
                ),
              ],
            );
          }

          final totalMin = episodes.fold(0, (acc, e) => acc + e.durationMin);

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: episodes.length + 1,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pause_circle_outline,
                          color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Text(
                        'Total inactif : ${_fmtDuration(totalMin)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${episodes.length} épisode${episodes.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return _IdleCard(episode: episodes[i - 1]);
            },
          );
        },
      ), // end idleAsync.when()
    ); // end RefreshIndicator
  }
}

class _IdleCard extends StatelessWidget {
  final IdleEpisode episode;

  const _IdleCard({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pause_circle_outline,
                color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDuration(episode.durationMin),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(episode.startTime),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '→ ${_fmtDate(episode.endTime)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Geofence Activity Tab ─────────────────────────────────────────────────────

class _GeofenceTab extends ConsumerWidget {
  final int vehicleId;
  final String period;

  const _GeofenceTab({required this.vehicleId, required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerKey = geofenceActivityProvider((vehicleId, period));
    final geofencesAsync = ref.watch(providerKey);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerKey);
        try {
          await ref.read(providerKey.future);
        } catch (_) {}
      },
      color: AppColors.primary,
      child: geofencesAsync.when(
        loading: () => const ReportListSkeleton(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (geofences) {
          if (geofences.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                _EmptyList(
                  icon: Icons.location_on_outlined,
                  message: 'Aucune zone géographique configurée',
                ),
              ],
            );
          }

          // Sort: most active first, then alphabetical
          final sorted = [...geofences]..sort((a, b) {
              final cmp = b.totalEvents.compareTo(a.totalEvents);
              return cmp != 0 ? cmp : a.geofenceName.compareTo(b.geofenceName);
            });

          final totalEvents = geofences.fold(0, (s, g) => s + g.totalEvents);

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length + 1,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        '$totalEvents événement${totalEvents > 1 ? 's' : ''} au total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${geofences.length} zone${geofences.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return _GeofenceCard(entry: sorted[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _GeofenceCard extends StatelessWidget {
  final GeofenceActivityEntry entry;

  const _GeofenceCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasActivity = entry.totalEvents > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.geofenceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!entry.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Inactif',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textHint),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (hasActivity) ...[
                  Row(
                    children: [
                      _EventBadge(
                        label:
                            '${entry.enterCount} entrée${entry.enterCount > 1 ? 's' : ''}',
                        color: AppColors.statusOnline,
                      ),
                      const SizedBox(width: 8),
                      _EventBadge(
                        label:
                            '${entry.exitCount} sortie${entry.exitCount > 1 ? 's' : ''}',
                        color: AppColors.statusAlert,
                      ),
                    ],
                  ),
                  if (entry.lastEventAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dernier : ${_fmtDate(entry.lastEventAt!)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ] else
                  const Text(
                    'Aucune activité sur cette période',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (hasActivity)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.totalEvents}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _EventBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
