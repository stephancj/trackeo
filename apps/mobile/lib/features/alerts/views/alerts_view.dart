import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../providers/alerts_provider.dart';
import '../providers/geofences_provider.dart';
import '../models/geofence_model.dart';
import '../models/alert_model.dart';
import 'create_geofence_view.dart';
import 'all_alerts_view.dart';
import 'widgets/alert_skeletons.dart';
import 'widgets/alert_detail_sheet.dart';
import '../../vehicles/providers/vehicles_provider.dart';
import '../../../core/providers/geocoding_provider.dart';

// Local _reverseGeocodeProvider removed in favor of global reverseGeocodeProvider

class AlertsView extends ConsumerStatefulWidget {
  const AlertsView({super.key});

  @override
  ConsumerState<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends ConsumerState<AlertsView> {
  @override
  Widget build(BuildContext context) {
    final geofencesState = ref.watch(geofencesProvider);
    final alertsState = ref.watch(alertsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alertes & Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'ZONES ACTIVES',
              action: '+ Ajouter',
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGeofenceView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            geofencesState.when(
              data: (geofences) {
                if (geofences.isEmpty) {
                  return _buildGeofencesEmptyState();
                }
                return SizedBox(
                  height: 230,
                  child: CarouselView(
                    itemExtent: MediaQuery.of(context).size.width * 1,
                    shrinkExtent: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.only(right: 16),
                    children: geofences.map((gf) {
                      return _buildActiveGeofenceCard(gf);
                    }).toList(),
                  ),
                );
              },
              loading: () => const GeofenceCarouselSkeleton(),
              error: (e, st) => _buildErrorState('$e'),
            ),
            const SizedBox(height: 32),

            _buildActivitySectionHeader(),
            const SizedBox(height: 12),
            alertsState.when(
              data: (alerts) => _buildRecentActivityList(alerts),
              loading: () => const AlertListSkeleton(),
              error: (e, st) => _buildErrorState('$e'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? action,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// En-tête "RECENT ACTIVITY" avec menu 3-points.
  Widget _buildActivitySectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ACTIVITÉ RÉCENTE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(
          height: 28,
          width: 28,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'mark_read') {
                await ref.read(alertsProvider.notifier).markAllRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les alertes marquées comme lues'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'view_all') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AllAlertsView()),
                );
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
              const PopupMenuItem(
                value: 'view_all',
                child: Row(
                  children: [
                    Icon(Icons.list_alt_rounded,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Voir tout'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Returns a comma-separated list of vehicle names for the geofence,
  /// or null if no filter is applied (= all vehicles).
  String? _vehicleNamesFor(Geofence geofence) {
    final ids = geofence.deviceIds;
    if (ids == null || ids.isEmpty) return null;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    return vehiclesAsync.whenOrNull(
          data: (vehicles) {
            final names = vehicles
                .where((v) => ids.contains(v.id))
                .map((v) => v.name)
                .toList();
            if (names.isEmpty) {
              return '${ids.length} véhicule${ids.length > 1 ? 's' : ''}';
            }
            return names.join(', ');
          },
        ) ??
        '${ids.length} véhicule${ids.length > 1 ? 's' : ''}';
  }

  Widget _buildActiveGeofenceCard(Geofence geofence) {
    final vehicleNames = _vehicleNamesFor(geofence);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateGeofenceView(geofence: geofence),
        ),
      ),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showQuickActionsSheet(geofence);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Map mockup
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          geofence.centerLat,
                          geofence.centerLon,
                        ),
                        initialZoom: _calculateZoom(
                          geofence.radiusM,
                          geofence.centerLat,
                        ),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.trackeo.mobile',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                geofence.centerLat,
                                geofence.centerLon,
                              ),
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 2,
                              radius: geofence.radiusM,
                              useRadiusInMeter: true,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                geofence.centerLat,
                                geofence.centerLon,
                              ),
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              geofence.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.work_rounded, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final addressAsync = ref.watch(
                              reverseGeocodeProvider(
                                LatLng(geofence.centerLat, geofence.centerLon),
                              ),
                            );
                            return addressAsync.when(
                              data: (addr) => Text(
                                addr ?? geofence.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const Text(
                                'Localisation...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              error: (_, __) => Text(
                                geofence.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Rayon ${geofence.radiusM.toInt()} m',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '•',
                              style: TextStyle(color: AppColors.textHint),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              geofence.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (vehicleNames != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car_rounded,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  vehicleNames,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: geofence.isActive,
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      ref
                          .read(geofencesProvider.notifier)
                          .toggleGeofence(geofence, v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // end Container
    ); // end GestureDetector
  }

  void _showQuickActionsSheet(Geofence geofence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GeofenceActionsSheet(geofence: geofence),
    );
  }

  Widget _buildRecentActivityList(List<AlertModel> alerts) {
    if (alerts.isEmpty) {
      return _buildActivityEmptyState();
    }

    const maxVisible = 5;
    final displayed = alerts.take(maxVisible).toList();
    final hasMore = alerts.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < displayed.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, indent: 32, color: AppColors.divider),
                _buildActivityItem(displayed[i]),
              ],
            ],
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllAlertsView()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voir tout (${alerts.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _alertDotColor(String type) {
    switch (type) {
      case 'geofence_enter':
        return Colors.green;
      case 'geofence_exit':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _alertTitle(String type) {
    switch (type) {
      case 'geofence_enter':
        return 'Entrée dans la zone';
      case 'geofence_exit':
        return 'Sortie de la zone';
      default:
        return type;
    }
  }

  Widget _buildGeofencesEmptyState() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateGeofenceView()),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primary.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aucune zone',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Appuyez ici pour créer votre première zone et recevoir des alertes à l\'entrée ou la sortie.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '+ Créer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tout est calme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aucune alerte récente.\nVos véhicules sont dans leurs zones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AlertModel alert) {
    final isOpen = alert.status == 'open';
    final dotColor = isOpen ? _alertDotColor(alert.type) : AppColors.textHint;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => AlertDetailSheet.show(context, ref, alert),
      child: Container(
        // Légère teinte de fond pour les alertes non lues
        color: isOpen
            ? _alertDotColor(alert.type).withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur lu/non-lu
            Container(
              margin: const EdgeInsets.only(top: 5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
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
                          _alertTitle(alert.type),
                          style: TextStyle(
                            fontSize: 14,
                            // Gras si non lu, normal si lu
                            fontWeight: isOpen
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isOpen
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _alertDotColor(alert.type)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Nouveau',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _alertDotColor(alert.type),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message ?? 'Aucun détail',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOpen
                          ? AppColors.textHint
                          : AppColors.textHint.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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

  double _calculateZoom(double radiusM, double lat) {
    // We want the circle to take up about 60% of the map's height (140px)
    // So 84 pixels should represent the diameter (2 * radius)
    final double metersPerPixel = (2 * radiusM) / 84;
    // zoom = log2(156543.03392 * cos(lat) / metersPerPixel)
    final double zoom =
        math.log(
          156543.03392 * math.cos(lat * math.pi / 180) / metersPerPixel,
        ) /
        math.ln2;
    return zoom.clamp(3.0, 18.0);
  }
}

// ── Quick-action bottom sheet ────────────────────────────────────────────────

class _GeofenceActionsSheet extends ConsumerStatefulWidget {
  final Geofence geofence;
  const _GeofenceActionsSheet({required this.geofence});

  @override
  ConsumerState<_GeofenceActionsSheet> createState() =>
      _GeofenceActionsSheetState();
}

class _GeofenceActionsSheetState extends ConsumerState<_GeofenceActionsSheet> {
  late Set<int> _selectedIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<int>.from(widget.geofence.deviceIds ?? []);
  }

  Future<void> _applyVehicles() async {
    setState(() => _isSaving = true);
    await ref.read(geofencesProvider.notifier).updateGeofence(
      widget.geofence.id,
      {'deviceIds': _selectedIds.toList()},
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer la zone ?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Supprimer la zone "${widget.geofence.name}" ?\nCette action est irréversible.',
          style: const TextStyle(color: AppColors.textHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(geofencesProvider.notifier)
          .deleteGeofence(widget.geofence.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.geofence.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Rayon ${widget.geofence.radiusM.toInt()} m',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'VÉHICULES SURVEILLÉS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedIds.isEmpty
                ? 'Tous les véhicules (aucun filtre)'
                : '${_selectedIds.length} véhicule${_selectedIds.length > 1 ? 's' : ''} sélectionné${_selectedIds.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 10),
          vehiclesAsync.when(
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const Text(
                  'Aucun véhicule disponible',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vehicles.map((v) {
                  final selected = _selectedIds.contains(v.id);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(v.id);
                        } else {
                          _selectedIds.add(v.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider.withValues(alpha: 0.5),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.directions_car_rounded,
                            size: 16,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            v.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ),
                          if (v.plate != null && v.plate!.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            Text(
                              '· ${v.plate}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 36,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          // Apply button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _applyVehicles,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Appliquer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // Delete button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _confirmDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Supprimer la zone',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
