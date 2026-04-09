import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../vehicles/providers/vehicles_provider.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../models/report_models.dart';
import '../providers/reports_provider.dart';
import 'widgets/report_skeletons.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDuration(int minutes) {
  if (minutes < 60) return '${minutes}min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}min';
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jui',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
  ];
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]}, $h:$m';
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

class _ReportsViewState extends ConsumerState<ReportsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _period = '7d';
  int? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          // ── Vehicle picker (only shown when multiple vehicles) ──────────
          if (vehicles.length > 1)
            _VehiclePicker(
              vehicles: vehicles,
              selectedId: _selectedVehicleId,
              onChanged: (id) => setState(() => _selectedVehicleId = id),
            ),

          // ── Period chips ──────────────────────────────────────────────
          _PeriodPicker(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),

          // ── Tab bar ───────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Activité'),
                Tab(text: 'Trajets'),
                Tab(text: 'Vitesse'),
                Tab(text: 'Inactivité'),
                Tab(text: 'Zones'),
              ],
            ),
          ),

          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: _selectedVehicleId == null
                ? const _EmptyVehicle()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ActivityTab(
                        vehicleId: _selectedVehicleId!,
                        period: _period,
                      ),
                      _TripLogTab(
                        vehicleId: _selectedVehicleId!,
                        dateRange: _dateRange,
                      ),
                      _SpeedTab(
                        vehicleId: _selectedVehicleId!,
                        dateRange: _dateRange,
                      ),
                      _IdleTab(
                        vehicleId: _selectedVehicleId!,
                        dateRange: _dateRange,
                      ),
                      _GeofenceTab(
                        vehicleId: _selectedVehicleId!,
                        period: _period,
                      ),
                    ],
                  ),
          ),
        ],
      ),
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
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                    child: Text(v.name,
                        style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (id) {
            if (id != null) onChanged(id);
          },
        ),
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
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _Chip(label: "Aujourd'hui", value: 'today', selected: selected, onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(label: '7 jours', value: '7d', selected: selected, onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(label: '30 jours', value: '30d', selected: selected, onTap: onChanged),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyVehicle extends StatelessWidget {
  const _EmptyVehicle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Aucun véhicule assigné',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyList({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
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
        try { await ref.read(providerKey.future); } catch (_) {}
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.route,
                  iconColor: AppColors.primary,
                  label: 'Distance totale',
                  value: _fmtDist(summary.distanceKm),
                ),
                _StatCard(
                  icon: Icons.map_outlined,
                  iconColor: const Color(0xFF5B8DEF),
                  label: 'Trajets',
                  value: '${summary.tripCount}',
                ),
                _StatCard(
                  icon: Icons.drive_eta_outlined,
                  iconColor: const Color(0xFF4ECB8D),
                  label: 'Temps de conduite',
                  value: _fmtDuration(summary.drivingMinutes),
                ),
                _StatCard(
                  icon: Icons.pause_circle_outline,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Temps inactif',
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
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${summary.pointCount} points GPS enregistrés',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),   // end when()
  );     // end RefreshIndicator
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
        try { await ref.read(providerKey.future); } catch (_) {}
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
            itemCount: trips.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _TripCard(trip: trips[i], index: i + 1),
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripLogEntry trip;
  final int index;

  const _TripCard({required this.trip, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
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
        try { await ref.read(providerKey.future); } catch (_) {}
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
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
        border: Border.all(
            color: AppColors.statusAlert.withValues(alpha: 0.3)),
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
        try { await ref.read(providerKey.future); } catch (_) {}
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

          final totalMin =
              episodes.fold(0, (acc, e) => acc + e.durationMin);

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
          itemCount: episodes.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
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
      ),    // end idleAsync.when()
    );      // end RefreshIndicator
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
        try { await ref.read(providerKey.future); } catch (_) {}
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
          final sorted = [...geofences]
            ..sort((a, b) {
              final cmp = b.totalEvents.compareTo(a.totalEvents);
              return cmp != 0 ? cmp : a.geofenceName.compareTo(b.geofenceName);
            });

          final totalEvents = geofences.fold(0, (s, g) => s + g.totalEvents);

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                        label: '${entry.enterCount} entrée${entry.enterCount > 1 ? 's' : ''}',
                        color: AppColors.statusOnline,
                      ),
                      const SizedBox(width: 8),
                      _EventBadge(
                        label: '${entry.exitCount} sortie${entry.exitCount > 1 ? 's' : ''}',
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
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (hasActivity)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
