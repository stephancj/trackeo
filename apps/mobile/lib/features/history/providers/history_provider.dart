import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/repositories/vehicle_repository.dart';

/// Date sélectionnée dans l'écran historique (initialisée à aujourd'hui).
final historyDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Positions GPS pour un véhicule [vehicleId] à la date de [historyDateProvider].
/// Utilise autoDispose + family : chaque vehicleId a son propre cache,
/// libéré automatiquement quand l'écran est fermé.
final historyPositionsProvider =
    FutureProvider.autoDispose.family<List<VehiclePosition>, int>(
  (ref, vehicleId) async {
    final date = ref.watch(historyDateProvider);
    final from = date; // 00:00:00
    final to = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return ref
        .read(vehicleRepositoryProvider)
        .getHistory(vehicleId, from, to);
  },
);
