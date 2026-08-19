import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_shell.dart';
import '../../../core/layout/responsive_layout.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/vehicle_model.dart';
import '../providers/vehicles_provider.dart';
import 'widgets/vehicle_card.dart';
import 'widgets/vehicle_card_skeleton.dart';
import 'vehicle_details_view.dart';
import 'add_vehicle_view.dart';
import '../../history/views/history_view.dart';
import '../../../../core/navigation/trackeo_route.dart';

class FleetListView extends ConsumerStatefulWidget {
  const FleetListView({super.key});

  @override
  ConsumerState<FleetListView> createState() => _FleetListViewState();
}

class _FleetListViewState extends ConsumerState<FleetListView> {
  Future<void> _addVehicle() async {
    final vehicle = await Navigator.push<Vehicle>(
      context,
      TrackeoRoute(builder: (_) => const AddVehicleView()),
    );
    if (vehicle == null || !mounted) return;
    ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
    if (vehicle.position != null) {
      ref.read(activeTabProvider.notifier).state = 1;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${vehicle.name} est prêt dans votre flotte.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final allVehicles = vehiclesAsync.valueOrNull ?? const <Vehicle>[];
    final user = ref.watch(authProvider).user;
    final firstName = _firstName(user?.name, user?.email);

    if (vehiclesAsync.hasValue && allVehicles.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _EmptyFleetScreen(
            firstName: firstName,
            onAddVehicle: _addVehicle,
          ),
        ),
      );
    }

    // Un seul véhicule → pas de recherche ni de filtres : écran épuré et premium.
    if (vehiclesAsync.hasValue && allVehicles.length == 1) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _SingleVehicleScreen(
            vehicle: allVehicles.first,
            onAddVehicle: _addVehicle,
            firstName: firstName,
          ),
        ),
      );
    }

    final filteredAsync = ref.watch(filteredVehiclesProvider);
    final filter = ref.watch(vehicleFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardGreeting(firstName: firstName, onAdd: _addVehicle),
            const SizedBox(height: 16),
            vehiclesAsync.when(
              data: (vehicles) => _FleetOverview(vehicles: vehicles),
              loading: () => const _FleetOverviewSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Vos véhicules',
                        style: AppTextStyles.sectionTitle),
                  ),
                  Text(
                    '${allVehicles.length} au total',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Barre de recherche ─────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchBar(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Chips de filtre ────────────────────────────────────────────
            vehiclesAsync.when(
              data: (v) => SizedBox(
                height: 44,
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
              loading: () => const SizedBox(height: 44),
              error: (e, st) => const SizedBox(height: 44),
            ),

            const SizedBox(height: 8),

            // ── Liste des véhicules ────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return _EmptyState(
                      hasVehicles: allVehicles.isNotEmpty,
                      hasFilter: filter != VehicleFilter.all ||
                          ref.watch(vehicleSearchProvider).isNotEmpty,
                      onAdd: _addVehicle,
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
                    child: context.isDesktop || context.isTablet
                        ? GridView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 450,
                              mainAxisExtent: 180,
                              crossAxisSpacing: 0,
                              mainAxisSpacing: 0,
                            ),
                            itemCount: vehicles.length,
                            itemBuilder: (_, i) => _SlideInCard(
                              index: i,
                              key: ValueKey(vehicles[i].id),
                              child: VehicleCard(
                                vehicle: vehicles[i],
                                onTap: () {
                                  ref.read(selectedVehicleIdProvider.notifier).state =
                                      vehicles[i].id;
                                  if (!context.isDesktop) {
                                    Navigator.push(
                                      context,
                                      TrackeoRoute(
                                        builder: (context) =>
                                            VehicleDetailsView(vehicle: vehicles[i]),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            itemCount: vehicles.length,
                            itemBuilder: (_, i) => _SlideInCard(
                              index: i,
                              key: ValueKey(vehicles[i].id),
                              child: VehicleCard(
                                vehicle: vehicles[i],
                                onTap: () {
                                  ref.read(selectedVehicleIdProvider.notifier).state =
                                      vehicles[i].id;
                                  if (!context.isDesktop) {
                                    Navigator.push(
                                      context,
                                      TrackeoRoute(
                                        builder: (context) =>
                                            VehicleDetailsView(vehicle: vehicles[i]),
                                      ),
                                    );
                                  }
                                },
                              ),
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

String _firstName(String? name, String? email) {
  final source = name?.trim().isNotEmpty == true
      ? name!.trim()
      : (email?.split('@').first ?? '');
  if (source.isEmpty) return '';
  final value = source.split(RegExp(r'[\s._-]+')).first;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String _getTimeBasedGreeting(String firstName) {
  final hour = DateTime.now().hour;
  final salutation = (hour >= 18 || hour < 5) ? 'Bonsoir' : 'Bonjour';
  return firstName.isEmpty ? salutation : '$salutation, $firstName';
}

class _DashboardGreeting extends StatelessWidget {
  final String firstName;
  final VoidCallback onAdd;
  final String subtitle;

  const _DashboardGreeting({
    required this.firstName,
    required this.onAdd,
    this.subtitle = 'Voici l’état de vos véhicules.',
  });

  @override
  Widget build(BuildContext context) {
    final greeting = _getTimeBasedGreeting(firstName);
    final initial = firstName.isEmpty ? 'I' : firstName[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.1,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Ajouter un véhicule',
            onPressed: onAdd,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.pastelGreen,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _FleetOverview extends StatelessWidget {
  final List<Vehicle> vehicles;

  const _FleetOverview({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final moving =
        vehicles.where((v) => v.status == VehicleStatus.online).length;
    final idle = vehicles.where((v) => v.status == VehicleStatus.idle).length;
    final offline =
        vehicles.where((v) => v.status == VehicleStatus.offline).length;

    final (title, subtitle, icon) =
        switch ((vehicles.isEmpty, offline, moving)) {
      (true, _, _) => (
          'Votre flotte commence ici',
          'Ajoutez un véhicule pour suivre sa position.',
          Icons.add_road_rounded,
        ),
      (false, > 0, _) => (
          '$offline ${offline == 1 ? 'véhicule à vérifier' : 'véhicules à vérifier'}',
          'Aucune position récente reçue.',
          Icons.wifi_off_rounded,
        ),
      (false, 0, > 0) => (
          '$moving ${moving == 1 ? 'véhicule en mouvement' : 'véhicules en mouvement'}',
          'Les positions sont mises à jour automatiquement.',
          Icons.near_me_rounded,
        ),
      _ => (
          'Tout est calme',
          'Vos véhicules sont connectés et à l’arrêt.',
          Icons.check_rounded,
        ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (vehicles.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _OverviewMetric(label: 'En route', value: moving),
                      _OverviewMetric(label: 'Arrêtés', value: idle),
                      _OverviewMetric(label: 'Hors ligne', value: offline),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final int value;

  const _OverviewMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetOverviewSkeleton extends StatelessWidget {
  const _FleetOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _SingleVehicleOverview extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onOpenMap;

  const _SingleVehicleOverview({
    required this.vehicle,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon, accent) = switch (vehicle.status) {
      VehicleStatus.online => (
          '${vehicle.name} est en route',
          '${vehicle.position?.speedKmh.toInt() ?? 0} km/h · position actualisée automatiquement',
          Icons.near_me_rounded,
          AppColors.primary,
        ),
      VehicleStatus.idle => (
          '${vehicle.name} est à l’arrêt',
          vehicle.sleepMode?.active == true
              ? 'La veille antivol surveille le véhicule.'
              : 'Le véhicule est connecté et ne se déplace pas.',
          vehicle.sleepMode?.active == true
              ? Icons.lock_outline_rounded
              : Icons.local_parking_rounded,
          AppColors.primary,
        ),
      VehicleStatus.offline => (
          'Connexion à rétablir',
          'Aucune position récente reçue de ${vehicle.name}.',
          Icons.wifi_off_rounded,
          const Color(0xFFFFC067),
        ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onOpenMap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text(
              'Voir sur la carte',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFleetScreen extends StatelessWidget {
  final String firstName;
  final VoidCallback onAddVehicle;

  const _EmptyFleetScreen({
    required this.firstName,
    required this.onAddVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _DashboardGreeting(
          firstName: firstName,
          onAdd: onAddVehicle,
          subtitle: 'Commencez par associer votre traceur.',
        ),
        const SizedBox(height: 28),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.pastelGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppColors.primaryDark,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ajoutez votre premier véhicule',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 24,
                  height: 1.15,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Munissez-vous de l’IMEI à 15 chiffres indiqué sur le traceur ou son emballage.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddVehicle,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un véhicule'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 17, color: AppColors.textHint),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'L’association est sécurisée et ne prend qu’une minute.',
                  style: AppTextStyles.bodySecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
  final bool hasVehicles;
  final bool hasFilter;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.hasVehicles,
    required this.hasFilter,
    required this.onClear,
    required this.onAdd,
  });

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
          Text(
            hasVehicles ? 'Aucun résultat' : 'Ajoutez votre premier véhicule',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasVehicles
                ? 'Modifiez votre recherche ou vos filtres.'
                : 'Utilisez l’IMEI inscrit sur le traceur ou son emballage.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (!hasVehicles) ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 50),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter mon véhicule'),
            ),
          ],
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

// ── Staggered entrance animation ────────────────────────────────────────────

class _SlideInCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _SlideInCard({super.key, required this.child, required this.index});

  @override
  State<_SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<_SlideInCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.quint));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Pas de stagger si l'utilisateur a demandé de réduire les animations.
    if (AppMotion.reduce(context)) {
      _ctrl.value = 1.0;
    } else {
      final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 330));
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
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

// ── Écran véhicule unique ───────────────────────────────────────────────────
// Quand l'utilisateur n'a qu'un seul véhicule : aucune barre de recherche ni
// filtre. À la place, une carte mise en avant et des raccourcis utiles qui
// remplissent l'espace utilement plutôt que de laisser un écran vide.

class _SingleVehicleScreen extends ConsumerWidget {
  final Vehicle vehicle;
  final VoidCallback onAddVehicle;
  final String firstName;

  const _SingleVehicleScreen({
    required this.vehicle,
    required this.onAddVehicle,
    required this.firstName,
  });

  String get _statusLine {
    switch (vehicle.status) {
      case VehicleStatus.online:
        final spd = vehicle.position?.speedKmh.toInt() ?? 0;
        return 'En mouvement · $spd km/h';
      case VehicleStatus.idle:
        return vehicle.lastUpdate != null
            ? 'Arrêté ${timeago.format(vehicle.lastUpdate!, locale: 'fr')}'
            : 'Arrêté';
      case VehicleStatus.offline:
        return vehicle.lastUpdate != null
            ? 'Hors ligne ${timeago.format(vehicle.lastUpdate!, locale: 'fr')}'
            : 'Hors ligne';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(vehiclesProvider),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _DashboardGreeting(
            firstName: firstName,
            onAdd: onAddVehicle,
            subtitle: 'Voici l’état de votre véhicule.',
          ),
          const SizedBox(height: 16),
          _SingleVehicleOverview(
            vehicle: vehicle,
            onOpenMap: () {
              ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
              ref.read(activeTabProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child:
                      Text('Votre véhicule', style: AppTextStyles.sectionTitle),
                ),
                Text(_statusLine, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Carte véhicule (mise en avant)
          _SlideInCard(
            index: 0,
            child: VehicleCard(
              vehicle: vehicle,
              onTap: () {
                ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
                Navigator.push(
                  context,
                  TrackeoRoute(
                    builder: (context) => VehicleDetailsView(vehicle: vehicle),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Raccourcis
          _SlideInCard(
            index: 1,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text('RACCOURCIS', style: AppTextStyles.caps),
            ),
          ),
          _SlideInCard(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.map_outlined,
                          label: 'Carte',
                          bg: AppColors.pastelGreen,
                          color: AppColors.primary,
                          onTap: () {
                            ref.read(selectedVehicleIdProvider.notifier).state =
                                vehicle.id;
                            ref.read(activeTabProvider.notifier).state = 1;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.route_outlined,
                          label: 'Historique',
                          bg: AppColors.pastelBlue,
                          color: AppColors.statusIdle,
                          onTap: () => Navigator.push(
                            context,
                            TrackeoRoute(
                              builder: (_) => HistoryView(
                                vehicleId: vehicle.id,
                                vehicleName: vehicle.name,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.insights_outlined,
                          label: 'Rapports',
                          bg: AppColors.pastelBlue,
                          color: AppColors.statusIdle,
                          onTap: () =>
                              ref.read(activeTabProvider.notifier).state = 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionTile(
                          icon: Icons.notifications_outlined,
                          label: 'Alertes',
                          bg: AppColors.pastelRed,
                          color: AppColors.statusAlert,
                          onTap: () =>
                              ref.read(activeTabProvider.notifier).state = 2,
                        ),
                      ),
                    ],
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

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _press, curve: AppMotion.quint),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(color: widget.bg, shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
