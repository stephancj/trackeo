import 'dart:math' show cos, pow;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../history/views/history_view.dart';
import '../../../core/navigation/trackeo_route.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/views/vehicle_details_view.dart';
import '../../vehicles/providers/vehicles_provider.dart';
import '../../../core/providers/geocoding_provider.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  final _mapController = MapController();

  // Centre par défaut : Antananarivo
  static const _defaultCenter = LatLng(-18.9137, 47.5361);

  // Approximate logical-pixel height of the bottom vehicle card.
  // Used to offset the camera so the marker appears in the visible centre
  // above the card rather than behind it.
  static const _cardHeight = 290.0;

  // ── Fix gesture conflict ───────────────────────────────────────────────
  bool _markerJustTapped = false;

  // ── Smooth animation state ────────────────────────────────────────────
  // One AnimationController per vehicle — interpolates from last animated
  // position to the new GPS position over the polling interval (10 s).
  final Map<int, AnimationController> _animControllers = {};
  final Map<int, LatLng> _animatedPositions = {};
  final Map<int, double> _animatedCourses = {};

  // ── Tracking mode ("always-center" on selected vehicle) ───────────────
  bool _trackingMode = false;

  @override
  void dispose() {
    for (final ctrl in _animControllers.values) {
      ctrl.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  // ── Angle interpolation (shortest path) ──────────────────────────────
  // ── Camera helpers ────────────────────────────────────────────────────

  /// Moves the camera to [target] at [zoom].
  ///
  /// When [cardShowing] is true the camera is shifted south by half the
  /// vehicle-card height so the marker appears centred in the visible area
  /// above the card rather than at the mathematical centre of the full screen.
  ///
  /// Uses Mercator math: degreesLatPerPixel = 360·cos(φ) / (256·2^zoom)
  void _moveToTarget(LatLng target, double zoom, {bool cardShowing = false}) {
    if (!cardShowing) {
      _mapController.move(target, zoom);
      return;
    }
    final latRad = target.latitude * pi / 180;
    final degreesPerPixel = 360.0 * cos(latRad) / (256.0 * pow(2.0, zoom));
    // Shift south (smaller lat) so target rises into the visible centre.
    final adjustedLat = target.latitude - (_cardHeight / 2.0) * degreesPerPixel;
    _mapController.move(LatLng(adjustedLat, target.longitude), zoom);
  }

  double _lerpAngle(double from, double to, double t) {
    double diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return from + diff * t;
  }

  // ── Called on every poll result ───────────────────────────────────────
  void _onVehiclesUpdated(List<Vehicle> vehicles) {
    for (final v in vehicles) {
      if (v.position == null) continue;
      final newPos = LatLng(v.position!.lat, v.position!.lon);
      final newCourse = v.position!.course.toDouble();

      final oldPos = _animatedPositions[v.id];
      if (oldPos == null) {
        // First position — place directly with no animation.
        _animatedPositions[v.id] = newPos;
        _animatedCourses[v.id] = newCourse;
        continue;
      }

      // Skip if position hasn't meaningfully changed (~1 cm threshold).
      final dlat = (newPos.latitude - oldPos.latitude).abs();
      final dlon = (newPos.longitude - oldPos.longitude).abs();
      if (dlat < 1e-7 && dlon < 1e-7) continue;

      // Cancel any in-progress animation and start a fresh one
      // from the CURRENT animated position → new GPS position.
      _animControllers[v.id]?.stop();
      _animControllers[v.id]?.dispose();

      final fromPos = oldPos;
      final fromCourse = _animatedCourses[v.id] ?? newCourse;

      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      );
      _animControllers[v.id] = ctrl;

      ctrl.addListener(() {
        final t = Curves.easeInOut.transform(ctrl.value);
        final animPos = LatLng(
          fromPos.latitude + (newPos.latitude - fromPos.latitude) * t,
          fromPos.longitude + (newPos.longitude - fromPos.longitude) * t,
        );
        final animCourse = _lerpAngle(fromCourse, newCourse, t);

        setState(() {
          _animatedPositions[v.id] = animPos;
          _animatedCourses[v.id] = animCourse;
        });

        // Follow selected vehicle if tracking mode is on.
        // Use cardShowing:true because the vehicle card is always visible
        // when a vehicle is being tracked.
        final selectedId = ref.read(selectedVehicleIdProvider);
        if (_trackingMode && selectedId == v.id) {
          _moveToTarget(
            animPos,
            _mapController.camera.zoom,
            cardShowing: true,
          );
        }
      });

      ctrl.forward();
    }

    // Clean up state for vehicles no longer present in the list.
    final currentIds = vehicles.map((v) => v.id).toSet();
    final removed =
        _animControllers.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in removed) {
      _animControllers[id]?.dispose();
      _animControllers.remove(id);
      _animatedPositions.remove(id);
      _animatedCourses.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // H4 — Écoute les données ET les erreurs (erreurs gérées dans VehiclesNotifier).
    ref.listen(vehiclesProvider, (_, next) {
      next.when(
        data: _onVehiclesUpdated,
        error: (_, __) {
          // VehiclesNotifier conserve les données précédentes en cas d'erreur réseau.
          // Aucune action supplémentaire requise.
        },
        loading: () {},
      );
    });

    final vehiclesAsync = ref.watch(vehiclesProvider);
    final mapFilter = ref.watch(mapFilterProvider);
    final allVehicles = vehiclesAsync.valueOrNull ?? [];
    final vehicles = switch (mapFilter) {
      VehicleFilter.moving =>
        allVehicles.where((v) => v.status == VehicleStatus.online).toList(),
      VehicleFilter.idle =>
        allVehicles.where((v) => v.status == VehicleStatus.idle).toList(),
      VehicleFilter.offline =>
        allVehicles.where((v) => v.status == VehicleStatus.offline).toList(),
      VehicleFilter.all => allVehicles,
    };
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
              onTap: (tapPos, latLng) {
                if (_markerJustTapped) {
                  _markerJustTapped = false;
                  return;
                }
                ref.read(selectedVehicleIdProvider.notifier).state = null;
                if (_trackingMode) setState(() => _trackingMode = false);
              },
              // Disable tracking when the user manually pans / zooms the map.
              onPositionChanged: (_, hasGesture) {
                if (hasGesture && _trackingMode) {
                  setState(() => _trackingMode = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppMapTiles.voyager,
                subdomains: AppMapTiles.subdomains,
                retinaMode: true,
                userAgentPackageName: 'mg.trackeo.app',
              ),
              MarkerLayer(
                markers: vehicles
                    .where((v) => v.position != null)
                    .map((v) => _buildMarker(v, selected))
                    .toList(),
              ),
            ],
          ),

          // ── Gradient de lisibilité — sombre en haut, fondu vers transparent ─
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + 180,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
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
              data: (v) => _MapFilterRow(vehicles: v, allVehicles: allVehicles),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
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
                // Recenter — glows primary when tracking is active
                GestureDetector(
                  onTap: () => _recenter(selected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _trackingMode && selected != null
                          ? AppColors.primary
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.gps_fixed,
                      color: _trackingMode && selected != null
                          ? Colors.white
                          : AppColors.primary,
                      size: 22,
                    ),
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
                onClose: () {
                  ref.read(selectedVehicleIdProvider.notifier).state = null;
                  setState(() => _trackingMode = false);
                },
                onHistoryTap: () => Navigator.push(
                  context,
                  TrackeoRoute(
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
    if (selected != null) {
      // Use the current animated position if available.
      final pos = _animatedPositions[selected.id] ??
          (selected.position != null
              ? LatLng(selected.position!.lat, selected.position!.lon)
              : null);
      if (pos != null) {
        // Card is open → offset camera so the marker sits in visible centre.
        _moveToTarget(pos, 15, cardShowing: true);
        setState(() => _trackingMode = true);
        return;
      }
    }
    // No selection — center on the whole fleet (full-screen, no card).
    setState(() => _trackingMode = false);
    final vehiclesAsync = ref.read(vehiclesProvider);
    vehiclesAsync.whenData((vehicles) {
      final withPos = vehicles.where((v) => v.position != null).toList();
      if (withPos.isEmpty) return;
      if (withPos.length == 1) {
        final p = _animatedPositions[withPos.first.id] ??
            LatLng(withPos.first.position!.lat, withPos.first.position!.lon);
        _mapController.move(p, 14);
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
    // Use the smoothly animated position; fall back to raw GPS on first render.
    final markerPos =
        _animatedPositions[vehicle.id] ?? LatLng(pos.lat, pos.lon);
    final course = _animatedCourses[vehicle.id] ?? pos.course.toDouble();
    final isSelected = selected?.id == vehicle.id;
    final size = isSelected ? 52.0 : 42.0;

    return Marker(
      point: markerPos,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          _markerJustTapped = true;
          ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
          // Auto-enable tracking; card will appear → apply south offset.
          setState(() => _trackingMode = true);
          _moveToTarget(markerPos, 14, cardShowing: true);
        },
        child: Transform.rotate(
          angle: course * (pi / 180),
          child: Container(
            decoration: BoxDecoration(
              color: switch (vehicle.status) {
                VehicleStatus.online => AppColors.primary,
                VehicleStatus.idle => AppColors.statusIdle,
                VehicleStatus.offline => AppColors.statusOffline,
              },
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.navigation,
              color: Colors.white,
              size: isSelected ? 28 : 22,
            ),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher un véhicule...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
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
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de filtre : All Vehicles / Moving / Idle (filtre local carte uniquement)
class _MapFilterRow extends ConsumerWidget {
  final List<Vehicle> vehicles;
  final List<Vehicle> allVehicles;
  const _MapFilterRow({required this.vehicles, required this.allVehicles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);
    final moving =
        allVehicles.where((v) => v.status == VehicleStatus.online).length;
    final idle =
        allVehicles.where((v) => v.status == VehicleStatus.idle).length;
    final offline =
        allVehicles.where((v) => v.status == VehicleStatus.offline).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'Tous',
            selected: filter == VehicleFilter.all,
            onTap: () =>
                ref.read(mapFilterProvider.notifier).state = VehicleFilter.all,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'En route ($moving)',
            selected: filter == VehicleFilter.moving,
            onTap: () => ref.read(mapFilterProvider.notifier).state =
                VehicleFilter.moving,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Arrêté ($idle)',
            selected: filter == VehicleFilter.idle,
            onTap: () =>
                ref.read(mapFilterProvider.notifier).state = VehicleFilter.idle,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Hors ligne ($offline)',
            selected: filter == VehicleFilter.offline,
            onTap: () => ref.read(mapFilterProvider.notifier).state =
                VehicleFilter.offline,
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

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
            ),
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
class _VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;
  final VoidCallback onClose;
  final VoidCallback onHistoryTap;

  const _VehicleCard({
    required this.vehicle,
    required this.onClose,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = vehicle.position;
    final updatedAgo = pos != null ? _timeAgo(pos.deviceTime) : null;

    AsyncValue<String?>? addressAsync;
    if (pos != null) {
      addressAsync = ref.watch(
        reverseGeocodeProvider(LatLng(pos.lat, pos.lon)),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
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
                    if (pos != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: addressAsync != null
                                ? addressAsync.when(
                                    data: (address) => Text(
                                      address ??
                                          pos.address ??
                                          'Position inconnue',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    loading: () => const Text(
                                      'Localisation...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    error: (err, _) => const Text(
                                      'Position inconnue',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Position inconnue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
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
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
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
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  if (updatedAgo != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Mis à jour $updatedAgo',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
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
                  label: 'Vitesse',
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
                  label: 'Batterie',
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
                  label: 'Statut',
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
              // Détails — vert rempli
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    TrackeoRoute(
                      builder: (_) => VehicleDetailsView(vehicle: vehicle),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 17),
                  label: const Text(
                    'Détails',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    'Historique',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(
                      color: AppColors.divider,
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    if (diff.inSeconds < 60) return 'il y a ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
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
