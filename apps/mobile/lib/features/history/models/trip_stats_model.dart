import 'dart:math';
import '../../vehicles/models/vehicle_model.dart';

/// Statistiques calculées depuis une liste de positions GPS.
/// Distance via formule de Haversine, durée et vitesse max directement.
class TripStats {
  final double distanceKm;
  final Duration duration;
  final double topSpeedKmh;
  final VehiclePosition? startPosition;
  final VehiclePosition? endPosition;

  const TripStats({
    required this.distanceKm,
    required this.duration,
    required this.topSpeedKmh,
    this.startPosition,
    this.endPosition,
  });

  bool get isEmpty => distanceKm == 0 && duration == Duration.zero;

  factory TripStats.fromPositions(List<VehiclePosition> positions) {
    if (positions.isEmpty) {
      return const TripStats(
        distanceKm: 0,
        duration: Duration.zero,
        topSpeedKmh: 0,
      );
    }

    if (positions.length == 1) {
      return TripStats(
        distanceKm: 0,
        duration: Duration.zero,
        topSpeedKmh: positions.first.speedKmh,
        startPosition: positions.first,
        endPosition: positions.first,
      );
    }

    double totalKm = 0;
    double topSpeed = 0;

    for (int i = 1; i < positions.length; i++) {
      totalKm += _haversineKm(
        positions[i - 1].lat,
        positions[i - 1].lon,
        positions[i].lat,
        positions[i].lon,
      );
      if (positions[i].speedKmh > topSpeed) topSpeed = positions[i].speedKmh;
    }
    if (positions.first.speedKmh > topSpeed) topSpeed = positions.first.speedKmh;

    final dur =
        positions.last.deviceTime.difference(positions.first.deviceTime);

    return TripStats(
      distanceKm: totalKm,
      duration: dur,
      topSpeedKmh: topSpeed,
      startPosition: positions.first,
      endPosition: positions.last,
    );
  }

  // ── Formule de Haversine ─────────────────────────────────────────────────

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Rayon terrestre en km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ── Formatters ───────────────────────────────────────────────────────────

  String get formattedDistance {
    if (distanceKm < 1) return '${(distanceKm * 1000).toInt()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (duration.inSeconds < 60) return '< 1 min';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min';
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get formattedTopSpeed => '${topSpeedKmh.toInt()} km/h';
}
