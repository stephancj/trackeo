import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../history/views/history_view.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/providers/vehicles_provider.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final _mapController = MapController();

  // Centre par défaut : Antananarivo
  static const _defaultCenter = LatLng(-18.9137, 47.5361);

  // ── Fix gesture conflict ───────────────────────────────────────────────
  // flutter_map appelle MapOptions.onTap même quand on tape sur un marqueur.
  // Ce flag empêche l'onTap de la carte d'effacer la sélection juste après
  // qu'un marqueur ait été tapé.
  bool _markerJustTapped = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    // vehiclesAsync.valueOrNull : jamais de MarkerLayer vide pendant le polling.
    // Les marqueurs restent visibles même quand les données se rafraîchissent.
    final vehicles = vehiclesAsync.valueOrNull ?? [];
    final selected = ref.watch(selectedVehicleProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // ── Carte ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
              onTap: (_, _) {
                // Ne pas effacer la sélection si un marqueur vient d'être tapé
                if (_markerJustTapped) {
                  _markerJustTapped = false;
                  return;
                }
                ref.read(selectedVehicleIdProvider.notifier).state = null;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mg.trackeo.app',
              ),
              // Fix : valueOrNull → jamais de flash "liste vide" pendant le polling
              MarkerLayer(
                markers: vehicles
                    .where((v) => v.position != null)
                    .map((v) => _buildMarker(v, selected))
                    .toList(),
              ),
            ],
          ),

          // ── Indicateur de chargement ───────────────────────────────────
          if (vehiclesAsync.isLoading)
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

          // ── Header : logo Trackeo + cloche ─────────────────────────────
          Positioned(
            top: topPad + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                // Bell
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.primaryDark, size: 20),
                ),
              ],
            ),
          ),

          // ── Barre de recherche ─────────────────────────────────────────
          Positioned(
            top: topPad + 62,
            left: 16,
            right: 16,
            child: _MapSearchBar(),
          ),

          // ── Chips de filtre ────────────────────────────────────────────
          Positioned(
            top: topPad + 122,
            left: 16,
            right: 16,
            child: vehiclesAsync.when(
              data: (v) => _MapFilterRow(vehicles: v),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),

          // ── Boutons droite : Layers + Recenter ─────────────────────────
          Positioned(
            bottom: selected != null ? 295 : 90,
            right: 16,
            child: Column(
              children: [
                // Layers (dark)
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
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.layers,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(height: 10),
                // Recenter (white circle)
                GestureDetector(
                  onTap: () => _recenter(selected),
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
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.gps_fixed,
                        color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ── Card véhicule sélectionné ──────────────────────────────────
          if (selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _VehicleCard(
                vehicle: selected,
                onClose: () =>
                    ref.read(selectedVehicleIdProvider.notifier).state = null,
                onHistoryTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryView(
                      vehicleId: selected.id,
                      vehicleName: selected.name,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _recenter(Vehicle? selected) {
    // Priorité 1 : véhicule sélectionné
    if (selected?.position != null) {
      _mapController.move(
        LatLng(selected!.position!.lat, selected.position!.lon),
        15,
      );
      return;
    }
    // Priorité 2 : centrer sur tous les véhicules
    final vehiclesAsync = ref.read(vehiclesProvider);
    vehiclesAsync.whenData((vehicles) {
      final withPos = vehicles.where((v) => v.position != null).toList();
      if (withPos.isEmpty) return;
      if (withPos.length == 1) {
        _mapController.move(
          LatLng(withPos.first.position!.lat, withPos.first.position!.lon),
          14,
        );
      } else {
        final avgLat =
            withPos.map((v) => v.position!.lat).reduce((a, b) => a + b) /
                withPos.length;
        final avgLon =
            withPos.map((v) => v.position!.lon).reduce((a, b) => a + b) /
                withPos.length;
        _mapController.move(LatLng(avgLat, avgLon), 12);
      }
    });
  }

  Marker _buildMarker(Vehicle vehicle, Vehicle? selected) {
    final pos = vehicle.position!;
    final isSelected = selected?.id == vehicle.id;
    final size = isSelected ? 52.0 : 42.0;

    return Marker(
      point: LatLng(pos.lat, pos.lon),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          // Positionner le flag AVANT la mise à jour de l'état pour que
          // MapOptions.onTap (qui peut être appelé dans le même cycle) l'ignore.
          _markerJustTapped = true;
          ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
          _mapController.move(LatLng(pos.lat, pos.lon), 14);
        },
        child: Transform.rotate(
          angle: pos.course * (pi / 180),
          child: Container(
            decoration: BoxDecoration(
              color: vehicle.status == VehicleStatus.online
                  ? AppColors.primary
                  : AppColors.statusOffline,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white, width: isSelected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.navigation,
                color: Colors.white, size: isSelected ? 28 : 22),
          ),
        ),
      ),
    );
  }
}

// ── Widgets internes ─────────────────────────────────────────────────────────

/// Barre de recherche avec icône filtre (tune) à droite
class _MapSearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.search, color: AppColors.textHint, size: 20),
          ),
          Expanded(
            child: TextField(
              onChanged: (v) =>
                  ref.read(vehicleSearchProvider.notifier).state = v,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Find vehicle or driver...',
                hintStyle:
                    TextStyle(color: AppColors.textHint, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          // Séparateur vertical
          Container(width: 1, height: 24, color: AppColors.divider),
          // Icône filtre
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.tune_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Chips de filtre : All Vehicles / Moving / Idle
class _MapFilterRow extends ConsumerWidget {
  final List<Vehicle> vehicles;
  const _MapFilterRow({required this.vehicles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(vehicleFilterProvider);
    final moving =
        vehicles.where((v) => v.status == VehicleStatus.online).length;
    final idle =
        vehicles.where((v) => v.status == VehicleStatus.idle).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All Vehicles',
            selected: filter == VehicleFilter.all,
            onTap: () => ref
                .read(vehicleFilterProvider.notifier)
                .state = VehicleFilter.all,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Moving ($moving)',
            selected: filter == VehicleFilter.moving,
            onTap: () => ref
                .read(vehicleFilterProvider.notifier)
                .state = VehicleFilter.moving,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Idle ($idle)',
            selected: filter == VehicleFilter.idle,
            onTap: () => ref
                .read(vehicleFilterProvider.notifier)
                .state = VehicleFilter.idle,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Vehicle Card ─────────────────────────────────────────────────────────────

/// Card bottom sheet quand un véhicule est sélectionné — design Figma exact.
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onClose;
  final VoidCallback onHistoryTap;

  const _VehicleCard({
    required this.vehicle,
    required this.onClose,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = vehicle.position;
    final updatedAgo = pos != null ? _timeAgo(pos.deviceTime) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône voiture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car_outlined,
                    color: AppColors.textSecondary, size: 26),
              ),
              const SizedBox(width: 12),
              // Nom + adresse
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (pos?.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              pos!.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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
              const SizedBox(width: 8),
              // LIVE badge (outlined) + "Updated Xs ago" + bouton close
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(Icons.close,
                            size: 20, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  if (updatedAgo != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Updated $updatedAgo',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Stats ────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Speed
                _StatBox(
                  label: 'Speed',
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${pos?.speedKmh.toInt() ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const TextSpan(
                          text: ' km/h',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: AppColors.divider),
                // Battery
                _StatBox(
                  label: 'Battery',
                  child: pos?.battery != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.battery_charging_full_rounded,
                              color: _batteryColor(pos!.battery!),
                              size: 20,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${pos.battery}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          '--',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: AppColors.textHint,
                          ),
                        ),
                ),
                Container(width: 1, color: AppColors.divider),
                // Status
                _StatBox(
                  label: 'Status',
                  child: Text(
                    vehicle.status.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _statusColor(vehicle.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Boutons ─────────────────────────────────────────────────
          Row(
            children: [
              // Call Driver — vert rempli
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_rounded, size: 17),
                  label: const Text(
                    'Call Driver',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // History — contour gris
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.history_rounded, size: 17),
                  label: const Text(
                    'History',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(
                        color: AppColors.divider, width: 1.5),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(VehicleStatus status) => switch (status) {
        VehicleStatus.online => AppColors.statusOnline,
        VehicleStatus.idle => AppColors.statusIdle,
        VehicleStatus.offline => AppColors.statusOffline,
      };

  Color _batteryColor(int battery) {
    if (battery > 50) return AppColors.batteryGood;
    if (battery > 20) return AppColors.batteryMedium;
    return AppColors.batteryLow;
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Colonne stat individuelle (Speed / Battery / Status)
class _StatBox extends StatelessWidget {
  final String label;
  final Widget child;

  const _StatBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
