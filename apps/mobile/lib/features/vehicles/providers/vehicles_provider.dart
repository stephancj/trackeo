import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

/// Liste de tous les véhicules — se rafraîchit automatiquement toutes les 10s.
/// Pattern : invalide lui-même après le délai → re-fetch propre.
final vehiclesProvider =
    FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final timer = Timer(
    const Duration(seconds: 10),
    () => ref.invalidateSelf(),
  );
  ref.onDispose(timer.cancel);

  return ref.read(vehicleRepositoryProvider).getVehicles();
});

// ── Filtres ────────────────────────────────────────────────────────────────

enum VehicleFilter { all, moving, idle }

final vehicleFilterProvider =
    StateProvider<VehicleFilter>((ref) => VehicleFilter.all);

final vehicleSearchProvider = StateProvider<String>((ref) => '');

/// Véhicules filtrés par statut et recherche textuelle.
final filteredVehiclesProvider =
    Provider<AsyncValue<List<Vehicle>>>((ref) {
  final all = ref.watch(vehiclesProvider);
  final filter = ref.watch(vehicleFilterProvider);
  final search = ref.watch(vehicleSearchProvider).toLowerCase().trim();

  return all.whenData((vehicles) {
    var result = vehicles;

    if (filter == VehicleFilter.moving) {
      result = result.where((v) => v.status == VehicleStatus.online).toList();
    } else if (filter == VehicleFilter.idle) {
      result = result.where((v) => v.status == VehicleStatus.idle).toList();
    }

    if (search.isNotEmpty) {
      result = result
          .where((v) =>
              v.name.toLowerCase().contains(search) ||
              v.plate.toLowerCase().contains(search))
          .toList();
    }

    return result;
  });
});

// ── Sélection (carte) ─────────────────────────────────────────────────────

/// Véhicule sélectionné sur la carte pour afficher le bottom sheet.
final selectedVehicleProvider = StateProvider<Vehicle?>((ref) => null);
