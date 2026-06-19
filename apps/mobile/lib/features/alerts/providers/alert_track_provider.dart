import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/repositories/vehicle_repository.dart';

/// Clé : (deviceId, fenêtre `from` epoch ms, fenêtre `to` epoch ms).
typedef AlertTrackKey = (int, int, int);

/// Positions GPS autour d'une alerte (fenêtre temporelle), pour tracer le
/// segment concerné sur la carte. Réutilise l'historique véhicule — aucune
/// donnée supplémentaire côté serveur. autoDispose : libéré à la fermeture.
final alertTrackProvider = FutureProvider.autoDispose
    .family<List<VehiclePosition>, AlertTrackKey>((ref, key) async {
  final (deviceId, fromMs, toMs) = key;
  return ref.read(vehicleRepositoryProvider).getHistory(
        deviceId,
        DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true),
        DateTime.fromMillisecondsSinceEpoch(toMs, isUtc: true),
      );
});
