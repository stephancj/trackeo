import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/day_activity_model.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/repositories/vehicle_repository.dart';

/// Date sélectionnée dans l'écran historique (initialisée à aujourd'hui).
final historyDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Clé du calendrier d'activité : (véhicule, année, mois).
typedef ActivityMonthKey = (int vehicleId, int year, int month);

/// Activité jour par jour d'un mois donné — alimente le calendrier heatmap et
/// le saut "jour actif suivant/précédent". autoDispose : libéré à la fermeture.
final activeDaysProvider =
    FutureProvider.autoDispose.family<List<DayActivity>, ActivityMonthKey>(
  (ref, key) async {
    final (vehicleId, year, month) = key;
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59); // dernier jour du mois
    return ref
        .read(vehicleRepositoryProvider)
        .getActiveDays(vehicleId, from, to);
  },
);

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
