import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_model.dart';
import '../repositories/vehicle_repository.dart';

// ── Polling sans flash loading ─────────────────────────────────────────────
//
// Problème avec FutureProvider + invalidateSelf() :
//   invalidateSelf() remet le provider en état AsyncLoading à chaque refresh
//   → les marqueurs de la carte disparaissent pendant 100-500ms.
//
// Solution : AsyncNotifier dont _refresh() met à jour `state` directement
//   avec AsyncValue.data(...) sans jamais repasser par AsyncLoading.
//   Le premier chargement (build()) affiche bien un spinner, mais les
//   rafraîchissements suivants sont transparents pour l'UI.

/// Notifier qui gère la liste des véhicules avec polling silencieux.
class VehiclesNotifier extends AutoDisposeAsyncNotifier<List<Vehicle>> {
  Timer? _timer;
  // H5 — Évite les requêtes concurrentes si un refresh prend > 10 s.
  bool _isFetching = false;

  @override
  Future<List<Vehicle>> build() async {
    // Premier chargement — loading affiché normalement
    final vehicles = await ref.read(vehicleRepositoryProvider).getVehicles();

    // Démarrer le polling silencieux (sans repasser par loading)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
    ref.onDispose(() => _timer?.cancel());

    return vehicles;
  }

  /// Rafraîchit les données sans modifier l'état vers loading.
  /// Les marqueurs restent visibles pendant toute la durée du fetch.
  /// Guard _isFetching : ignore l'appel si une requête est déjà en cours.
  Future<void> _refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final vehicles = await ref.read(vehicleRepositoryProvider).getVehicles();
      // Mise à jour directe → pas de flash loading
      state = AsyncValue.data(vehicles);
    } catch (e, st) {
      // En cas d'erreur réseau, garder les données précédentes visibles
      final previous = state.valueOrNull;
      if (previous != null) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> updateVehicle(int id, Map<String, dynamic> data) async {
    final updated = await ref
        .read(vehicleRepositoryProvider)
        .updateVehicle(id, data);
    // Silent update of the list
    final currentVehicles = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentVehicles.map((v) => v.id == id ? updated : v).toList(),
    );
  }
}

/// Provider principal — remplace l'ancien FutureProvider.autoDispose.
/// L'API publique est identique : AsyncValue of List of Vehicle.
final vehiclesProvider =
    AsyncNotifierProvider.autoDispose<VehiclesNotifier, List<Vehicle>>(
      VehiclesNotifier.new,
    );

// ── Filtres ─────────────────────────────────────────────────────────────────

enum VehicleFilter { all, moving, idle, offline }

/// Filtre de la Fleet List (onglet List) — indépendant de la carte
final vehicleFilterProvider = StateProvider<VehicleFilter>(
  (ref) => VehicleFilter.all,
);

/// Filtre de la carte (onglet Map) — état local à la carte, sans impact sur la liste
final mapFilterProvider = StateProvider<VehicleFilter>(
  (ref) => VehicleFilter.all,
);

final vehicleSearchProvider = StateProvider<String>((ref) => '');

/// Véhicules filtrés par statut et recherche textuelle.
final filteredVehiclesProvider = Provider<AsyncValue<List<Vehicle>>>((ref) {
  final all = ref.watch(vehiclesProvider);
  final filter = ref.watch(vehicleFilterProvider);
  final search = ref.watch(vehicleSearchProvider).toLowerCase().trim();

  return all.whenData((vehicles) {
    var result = vehicles;

    if (filter == VehicleFilter.moving) {
      result = result.where((v) => v.status == VehicleStatus.online).toList();
    } else if (filter == VehicleFilter.idle) {
      result = result.where((v) => v.status == VehicleStatus.idle).toList();
    } else if (filter == VehicleFilter.offline) {
      result = result.where((v) => v.status == VehicleStatus.offline).toList();
    }

    if (search.isNotEmpty) {
      result = result
          .where(
            (v) =>
                v.name.toLowerCase().contains(search) ||
                (v.plate?.toLowerCase().contains(search) ?? false) ||
                v.serialNumber.toLowerCase().contains(search),
          )
          .toList();
    }

    return result;
  });
});

// ── Sélection (carte) ────────────────────────────────────────────────────────

/// Stocke uniquement l'ID du véhicule sélectionné.
/// Avantage : quand vehiclesProvider se rafraîchit (polling 10s),
/// le véhicule sélectionné se met à jour automatiquement avec les
/// dernières données (position, vitesse, batterie) sans flash.
final selectedVehicleIdProvider = StateProvider<int?>((ref) => null);

/// Véhicule sélectionné, dérivé en temps réel depuis vehiclesProvider.
/// Toujours frais — jamais de données périmées dans la popup.
final selectedVehicleProvider = Provider<Vehicle?>((ref) {
  final id = ref.watch(selectedVehicleIdProvider);
  if (id == null) return null;
  final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? [];
  final matched = vehicles.where((v) => v.id == id);
  return matched.isEmpty ? null : matched.first;
});
