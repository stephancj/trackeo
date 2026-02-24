import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/providers/vehicles_provider.dart';
import '../../vehicles/views/widgets/battery_indicator.dart';
import '../../vehicles/views/widgets/status_badge.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final _mapController = MapController();

  // Centre par défaut : Antananarivo
  static const _defaultCenter = LatLng(-18.9137, 47.5361);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final selected = ref.watch(selectedVehicleProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Carte ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
              onTap: (_, __) =>
                  ref.read(selectedVehicleProvider.notifier).state = null,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'mg.trackeo.app',
              ),
              vehiclesAsync.when(
                data: (vehicles) => MarkerLayer(
                  markers: vehicles
                      .where((v) => v.position != null)
                      .map((v) => _buildMarker(v, selected))
                      .toList(),
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // ── Barre de recherche flottante ───────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 66,
            child: _MapSearchBar(),
          ),

          // ── Icône layers ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 6)
                ],
              ),
              child: const Icon(Icons.layers_outlined,
                  color: AppColors.primaryDark, size: 20),
            ),
          ),

          // ── Chips de filtre ────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 16,
            right: 16,
            child: vehiclesAsync.when(
              data: (v) => _MapFilterRow(vehicles: v),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
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

          // ── Card véhicule sélectionné ──────────────────────────────────
          if (selected != null)
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: _VehicleCard(
                vehicle: selected,
                onClose: () => ref
                    .read(selectedVehicleProvider.notifier)
                    .state = null,
              ),
            ),
        ],
      ),
    );
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
          ref.read(selectedVehicleProvider.notifier).state = vehicle;
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
                    color: Colors.black.withOpacity(0.2),
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

// ── Widgets internes ────────────────────────────────────────────────────────

class _MapSearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        onChanged: (v) =>
            ref.read(vehicleSearchProvider.notifier).state = v,
        decoration: const InputDecoration(
          hintText: 'Find vehicle or driver...',
          prefixIcon:
              Icon(Icons.search, color: AppColors.textHint, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

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

    return Row(
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
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08), blurRadius: 4)
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Card infos du véhicule sélectionné sur la carte
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onClose;

  const _VehicleCard({required this.vehicle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final pos = vehicle.position;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.directions_car,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.primaryDark)),
                    if (pos?.address != null)
                      Text(pos!.address!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('LIVE',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close,
                    size: 20, color: AppColors.textHint),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              _StatItem(
                value: '${pos?.speedKmh.toInt() ?? 0}',
                unit: 'km/h',
                label: 'Speed',
              ),
              _vDivider(),
              _StatItem(
                value: pos?.battery != null ? '${pos!.battery}%' : '--',
                unit: 'Battery',
                label: 'Battery',
                child: pos?.battery != null
                    ? BatteryIndicator(battery: pos!.battery)
                    : null,
              ),
              _vDivider(),
              _StatItem(
                value: vehicle.status.label,
                unit: 'Status',
                label: 'Status',
                child: StatusBadge(status: vehicle.status),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call Driver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    disabledForegroundColor:
                        AppColors.primary.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(height: 44, width: 1, color: AppColors.divider);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Widget? child;

  const _StatItem({
    required this.value,
    required this.unit,
    required this.label,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          child ??
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
