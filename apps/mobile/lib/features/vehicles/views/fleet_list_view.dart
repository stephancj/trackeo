import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/vehicle_model.dart';
import '../providers/vehicles_provider.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/vehicle_card_skeleton.dart';
import 'vehicle_details_view.dart';

class FleetListView extends ConsumerStatefulWidget {
  const FleetListView({super.key});

  @override
  ConsumerState<FleetListView> createState() => _FleetListViewState();
}

class _FleetListViewState extends ConsumerState<FleetListView> {
  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final filteredAsync = ref.watch(filteredVehiclesProvider);
    final filter = ref.watch(vehicleFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: vehiclesAsync.when(
                      data: (v) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mes Véhicules',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            '${v.where((x) => x.status != VehicleStatus.offline).length} véhicule(s) actif(s)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(height: 44),
                      error: (e, st) => const SizedBox(height: 44),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.tune,
                      color: AppColors.primaryDark,
                      size: 22,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Barre de recherche ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(),
            ),

            const SizedBox(height: 12),

            // ── Chips de filtre ────────────────────────────────────────────
            vehiclesAsync.when(
              data: (v) => SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterTab(
                      label: 'Tous (${v.length})',
                      isSelected: filter == VehicleFilter.all,
                      onTap: () => ref
                          .read(vehicleFilterProvider.notifier)
                          .state = VehicleFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label:
                          'En route (${v.where((x) => x.status == VehicleStatus.online).length})',
                      isSelected: filter == VehicleFilter.moving,
                      onTap: () => ref
                          .read(vehicleFilterProvider.notifier)
                          .state = VehicleFilter.moving,
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label:
                          'Arrêté (${v.where((x) => x.status == VehicleStatus.idle).length})',
                      isSelected: filter == VehicleFilter.idle,
                      onTap: () => ref
                          .read(vehicleFilterProvider.notifier)
                          .state = VehicleFilter.idle,
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label:
                          'Hors ligne (${v.where((x) => x.status == VehicleStatus.offline).length})',
                      isSelected: filter == VehicleFilter.offline,
                      onTap: () => ref
                          .read(vehicleFilterProvider.notifier)
                          .state = VehicleFilter.offline,
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 36),
              error: (e, st) => const SizedBox(height: 36),
            ),

            const SizedBox(height: 8),

            // ── Liste des véhicules ────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return _EmptyState(
                      hasFilter: filter != VehicleFilter.all ||
                          ref.watch(vehicleSearchProvider).isNotEmpty,
                      onClear: () {
                        ref.read(vehicleFilterProvider.notifier).state =
                            VehicleFilter.all;
                        ref.read(vehicleSearchProvider.notifier).state = '';
                      },
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(vehiclesProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 20),
                      itemCount: vehicles.length,
                      itemBuilder: (_, i) => VehicleCard(
                        vehicle: vehicles[i],
                        onTap: () {
                          ref.read(selectedVehicleIdProvider.notifier).state =
                              vehicles[i].id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VehicleDetailsView(vehicle: vehicles[i]),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const VehicleListSkeleton(),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(vehiclesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes ────────────────────────────────────────────────────────

// L4 — Barre de recherche avec debounce 300 ms pour éviter les rebuilds à chaque frappe.
class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(vehicleSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: TextField(
        onChanged: _onChanged,
        decoration: const InputDecoration(
          hintText: 'Rechercher par nom ou plaque...',
          prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDark
                : AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun véhicule trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Effacer les filtres',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les véhicules',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
