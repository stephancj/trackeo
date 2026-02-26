import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../../core/providers/geocoding_provider.dart';
import '../models/trip_stats_model.dart';
import '../providers/history_provider.dart';

class HistoryView extends ConsumerStatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const HistoryView({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  final _mapController = MapController();
  static const _defaultCenter = LatLng(-18.9137, 47.5361);

  // Hauteur du panneau inférieur (~52 % de l'écran)
  static const double _panelRatio = 0.52;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionsAsync = ref.watch(
      historyPositionsProvider(widget.vehicleId),
    );
    final date = ref.watch(historyDateProvider);
    final screenH = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final panelH = screenH * _panelRatio;

    final positions = positionsAsync.valueOrNull ?? [];
    final stats = TripStats.fromPositions(positions);
    final points = positions.map((p) => LatLng(p.lat, p.lon)).toList();

    // Ajuster la carte quand les données arrivent
    ref.listen(historyPositionsProvider(widget.vehicleId), (_, next) {
      next.whenData((pts) {
        if (pts.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fitRoute(pts.map((p) => LatLng(p.lat, p.lon)).toList()),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Carte plein écran ─────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mg.trackeo.app',
              ),
              // Polyligne bleue du trajet
              if (points.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 4.5,
                      color: const Color(0xFF5B8DEF),
                    ),
                  ],
                ),
              // Marqueurs départ (vert) + arrivée (rose)
              if (points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    _endpointMarker(points.first, isStart: true),
                    if (points.length > 1)
                      _endpointMarker(points.last, isStart: false),
                  ],
                ),
            ],
          ),

          // ── Indicateur de chargement (fin du top) ────────────────────
          if (positionsAsync.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              ),
            ),

          // ── Header : retour + sélecteur de date ──────────────────────
          Positioned(
            top: topPad + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Bouton retour
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Sélecteur de date
                Expanded(child: _DateSelector(date: date)),
              ],
            ),
          ),

          // ── Boutons droite (layers + recenter) ───────────────────────
          Positioned(
            right: 16,
            bottom: panelH + 12,
            child: Column(
              children: [
                // Layers
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 10),
                // Recentrer
                GestureDetector(
                  onTap: () => points.length > 1
                      ? _fitRoute(points)
                      : points.isNotEmpty
                      ? _mapController.move(points.first, 14)
                      : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gps_fixed,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Panneau inférieur (résumé + timeline) ────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: panelH,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: positionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Impossible de charger le trajet.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.statusAlert,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                data: (_) => positions.isEmpty
                    ? _EmptyState(vehicleName: widget.vehicleName, date: date)
                    : _TripPanel(stats: stats),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Marker _endpointMarker(LatLng point, {required bool isStart}) {
    return Marker(
      point: point,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: isStart ? AppColors.primary : const Color(0xFFEF6C6C),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  void _fitRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 120, 40, 60),
      ),
    );
  }
}

// ── Date Selector ─────────────────────────────────────────────────────────────

class _DateSelector extends ConsumerWidget {
  final DateTime date;
  const _DateSelector({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = _isToday(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Jour précédent
          GestureDetector(
            onTap: () => _shift(ref, -1),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
                size: 26,
              ),
            ),
          ),
          // Date centrale
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isToday ? 'Today' : _dayName(date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Jour suivant (désactivé si aujourd'hui)
          GestureDetector(
            onTap: isToday ? null : () => _shift(ref, 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right,
                color: isToday ? AppColors.textHint : AppColors.textSecondary,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shift(WidgetRef ref, int days) {
    ref.read(historyDateProvider.notifier).state = date.add(
      Duration(days: days),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _dayName(DateTime d) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return w[d.weekday - 1];
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String vehicleName;
  final DateTime date;
  const _EmptyState({required this.vehicleName, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route, size: 32, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text(
            'No trips recorded',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No data found for $vehicleName on this date.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trip Summary Panel ────────────────────────────────────────────────────────

class _TripPanel extends StatelessWidget {
  final TripStats stats;
  const _TripPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header Trip Summary ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trip Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.primaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Stats ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _StatTile(
                    icon: Icons.directions_car_outlined,
                    iconColor: const Color(0xFF5B8DEF),
                    iconBg: const Color(0xFFEEF2FF),
                    label: 'DISTANCE',
                    value: stats.formattedDistance,
                  ),
                  Container(width: 1, color: AppColors.divider),
                  _StatTile(
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFF97316),
                    iconBg: const Color(0xFFFFF3E8),
                    label: 'DURATION',
                    value: stats.formattedDuration,
                  ),
                  Container(width: 1, color: AppColors.divider),
                  _StatTile(
                    icon: Icons.speed_outlined,
                    iconColor: const Color(0xFF9333EA),
                    iconBg: const Color(0xFFF5EEFF),
                    label: 'TOP SPEED',
                    value: stats.formattedTopSpeed,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Journey Timeline ──────────────────────────────────────────
          const Text(
            'JOURNEY TIMELINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          if (stats.startPosition != null)
            _JourneyTimeline(
              start: stats.startPosition!,
              end: stats.endPosition!,
            ),
        ],
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Sépare la valeur numérique de l'unité (ex: "12.4" + "km")
    final parts = value.split(' ');
    final numeric = parts.first;
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: numeric,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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

// ── Journey Timeline ──────────────────────────────────────────────────────────

class _JourneyTimeline extends StatelessWidget {
  final VehiclePosition start;
  final VehiclePosition end;

  const _JourneyTimeline({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          isStart: true,
          time: _hhmm(start.deviceTime),
          latLng: LatLng(start.lat, start.lon),
          fallback: start.address ?? 'Departure point',
        ),
        // Connecting line
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 2, height: 28, color: AppColors.divider),
          ),
        ),
        _TimelineItem(
          isStart: false,
          time: _hhmm(end.deviceTime),
          latLng: LatLng(end.lat, end.lon),
          fallback: end.address ?? 'Arrival point',
        ),
      ],
    );
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _TimelineItem extends ConsumerWidget {
  final bool isStart;
  final String time;
  final LatLng latLng;
  final String fallback;

  const _TimelineItem({
    required this.isStart,
    required this.time,
    required this.latLng,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressAsync = ref.watch(reverseGeocodeProvider(latLng));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dot (vert plein = départ, bleu creux = arrivée)
        SizedBox(
          width: 22,
          height: 22,
          child: isStart
              ? Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF5B8DEF),
                      width: 2.5,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        // Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: addressAsync.when(
                    data: (addr) => Text(
                      addr ?? fallback,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const Text(
                      'Resolving...',
                      style: TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    error: (_, __) => Text(
                      fallback,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
