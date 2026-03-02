import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_models.dart';
import '../repositories/reports_repository.dart';

// (vehicleId, period) → ActivitySummary
final activitySummaryProvider = FutureProvider.autoDispose
    .family<ActivitySummary, (int, String)>((ref, params) {
  final (vehicleId, period) = params;
  return ref
      .read(reportsRepositoryProvider)
      .getActivitySummary(vehicleId, period);
});

// (vehicleId, fromMs, toMs) → List<TripLogEntry>
// Epoch milliseconds are used as family params to ensure structural equality.
final tripLogProvider = FutureProvider.autoDispose
    .family<List<TripLogEntry>, (int, int, int)>((ref, params) {
  final (vehicleId, fromMs, toMs) = params;
  return ref.read(reportsRepositoryProvider).getTripLog(
        vehicleId,
        DateTime.fromMillisecondsSinceEpoch(fromMs),
        DateTime.fromMillisecondsSinceEpoch(toMs),
      );
});

// (vehicleId, fromMs, toMs) → List<SpeedViolation>
final speedViolationsProvider = FutureProvider.autoDispose
    .family<List<SpeedViolation>, (int, int, int)>((ref, params) {
  final (vehicleId, fromMs, toMs) = params;
  return ref.read(reportsRepositoryProvider).getSpeedViolations(
        vehicleId,
        DateTime.fromMillisecondsSinceEpoch(fromMs),
        DateTime.fromMillisecondsSinceEpoch(toMs),
      );
});

// (vehicleId, fromMs, toMs) → List<IdleEpisode>
final idleTimeProvider = FutureProvider.autoDispose
    .family<List<IdleEpisode>, (int, int, int)>((ref, params) {
  final (vehicleId, fromMs, toMs) = params;
  return ref.read(reportsRepositoryProvider).getIdleTime(
        vehicleId,
        DateTime.fromMillisecondsSinceEpoch(fromMs),
        DateTime.fromMillisecondsSinceEpoch(toMs),
      );
});

// (vehicleId, period) → List<GeofenceActivityEntry>
final geofenceActivityProvider = FutureProvider.autoDispose
    .family<List<GeofenceActivityEntry>, (int, String)>((ref, params) {
  final (vehicleId, period) = params;
  return ref
      .read(reportsRepositoryProvider)
      .getGeofenceActivity(vehicleId, period);
});
