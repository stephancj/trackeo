import 'dart:math';
import '../../vehicles/models/vehicle_model.dart';

/// Formate une durée en "Xh Ym" / "X min" / "< 1 min".
String formatTripDuration(Duration d) {
  if (d.inSeconds < 60) return '< 1 min';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String _formatKm(double km) {
  if (km < 1) return '${(km * 1000).toInt()} m';
  return '${km.toStringAsFixed(1)} km';
}

/// Un trajet = suite de positions consécutives séparée des autres par un arrêt.
/// Reconstruit côté client depuis les points bruts du jour, en cohérence avec la
/// segmentation backend (`PositionsService.getTripLog`, gap > 10 min).
class Trip {
  final int index; // 1-based, ordre chronologique
  final List<VehiclePosition> points;
  final double distanceKm;
  final Duration duration; // intra-trajet : fin − début du segment (réelle)
  final double topSpeedKmh;
  final double avgSpeedKmh;

  const Trip({
    required this.index,
    required this.points,
    required this.distanceKm,
    required this.duration,
    required this.topSpeedKmh,
    required this.avgSpeedKmh,
  });

  VehiclePosition get start => points.first;
  VehiclePosition get end => points.last;

  String get formattedDistance => _formatKm(distanceKm);
  String get formattedDuration => formatTripDuration(duration);
  String get formattedTopSpeed => '${topSpeedKmh.toInt()} km/h';
  String get formattedAvgSpeed => '${avgSpeedKmh.toInt()} km/h';
}

/// Arrêt entre deux trajets (position de fin du trajet précédent + durée immobile).
class TripStop {
  final VehiclePosition at;
  final Duration duration;
  const TripStop({required this.at, required this.duration});

  String get formattedDuration => formatTripDuration(duration);
}

/// Découpe une journée de positions GPS en trajets + arrêts, et agrège les
/// statistiques au niveau jour. La `drivingTime` est la SOMME des durées de
/// trajet — et non `dernier − premier point`, qui gonflerait la durée de tout
/// le temps stationné.
class DayTrips {
  final List<Trip> trips;
  final List<TripStop> stops; // length == trips.length - 1
  final double totalDistanceKm;
  final Duration drivingTime;
  final Duration parkedTime;
  final double topSpeedKmh;
  final double avgSpeedKmh; // distance totale / temps de conduite

  const DayTrips({
    required this.trips,
    required this.stops,
    required this.totalDistanceKm,
    required this.drivingTime,
    required this.parkedTime,
    required this.topSpeedKmh,
    required this.avgSpeedKmh,
  });

  bool get isEmpty => trips.isEmpty;
  int get tripCount => trips.length;
  int get stopCount => stops.length;
  VehiclePosition? get dayStart => trips.isEmpty ? null : trips.first.start;
  VehiclePosition? get dayEnd => trips.isEmpty ? null : trips.last.end;

  String get formattedDistance => _formatKm(totalDistanceKm);
  String get formattedDrivingTime => formatTripDuration(drivingTime);
  String get formattedParkedTime => formatTripDuration(parkedTime);
  String get formattedTopSpeed => '${topSpeedKmh.toInt()} km/h';
  String get formattedAvgSpeed => '${avgSpeedKmh.toInt()} km/h';

  factory DayTrips.fromPositions(
    List<VehiclePosition> raw, {
    Duration gap = const Duration(minutes: 10),
    // Déplacement net minimal (mètres) pour qu'un segment soit un vrai trajet.
    // On mesure la diagonale de la bounding box (et NON la distance cumulée),
    // sinon le jitter GPS d'un véhicule stationné s'accumule et crée un faux
    // trajet alors que le véhicule n'a pas bougé.
    double minTripSpanM = 150,
  }) {
    if (raw.isEmpty) {
      return const DayTrips(
        trips: [],
        stops: [],
        totalDistanceKm: 0,
        drivingTime: Duration.zero,
        parkedTime: Duration.zero,
        topSpeedKmh: 0,
        avgSpeedKmh: 0,
      );
    }

    // Tri chronologique défensif (l'API renvoie déjà trié, mais on ne suppose pas).
    final positions = [...raw]
      ..sort((a, b) => a.deviceTime.compareTo(b.deviceTime));

    // 1) Découpe en segments par gap temporel.
    final segments = <List<VehiclePosition>>[];
    var current = <VehiclePosition>[positions.first];
    for (var i = 1; i < positions.length; i++) {
      final dt = positions[i].deviceTime.difference(positions[i - 1].deviceTime);
      if (dt > gap) {
        segments.add(current);
        current = [positions[i]];
      } else {
        current.add(positions[i]);
      }
    }
    segments.add(current);

    // 2) Transforme chaque segment significatif en Trip.
    final trips = <Trip>[];
    for (final seg in segments) {
      if (seg.length < 2) continue;
      var dist = 0.0;
      var top = seg.first.speedKmh;
      var minLat = seg.first.lat, maxLat = seg.first.lat;
      var minLon = seg.first.lon, maxLon = seg.first.lon;
      for (var i = 0; i < seg.length; i++) {
        final p = seg[i];
        if (i > 0) {
          dist += _haversineKm(
            seg[i - 1].lat,
            seg[i - 1].lon,
            p.lat,
            p.lon,
          );
        }
        if (p.speedKmh > top) top = p.speedKmh;
        if (p.lat < minLat) minLat = p.lat;
        if (p.lat > maxLat) maxLat = p.lat;
        if (p.lon < minLon) minLon = p.lon;
        if (p.lon > maxLon) maxLon = p.lon;
      }

      // Déplacement net (diagonale de la bounding box, en mètres). Pour du
      // jitter à l'arrêt il reste minuscule ; pour un vrai trajet il est grand,
      // même si le véhicule revient à son point de départ.
      final spanM = _haversineKm(minLat, minLon, maxLat, maxLon) * 1000;
      if (spanM < minTripSpanM) continue; // stationné → pas un trajet

      final dur = seg.last.deviceTime.difference(seg.first.deviceTime);
      final hours = dur.inSeconds / 3600.0;
      final avg = hours > 0 ? dist / hours : 0.0;

      trips.add(Trip(
        index: trips.length + 1,
        points: seg,
        distanceKm: dist,
        duration: dur,
        topSpeedKmh: top,
        avgSpeedKmh: avg,
      ));
    }

    // 3) Arrêts entre trajets + agrégats jour.
    final stops = <TripStop>[];
    for (var i = 1; i < trips.length; i++) {
      stops.add(TripStop(
        at: trips[i - 1].end,
        duration: trips[i].start.deviceTime.difference(trips[i - 1].end.deviceTime),
      ));
    }

    final totalDist = trips.fold<double>(0, (s, t) => s + t.distanceKm);
    final driving = trips.fold<Duration>(Duration.zero, (s, t) => s + t.duration);
    final parked = stops.fold<Duration>(Duration.zero, (s, st) => s + st.duration);
    final topSpeed = trips.fold<double>(0, (s, t) => max(s, t.topSpeedKmh));
    final drivingHours = driving.inSeconds / 3600.0;
    final avgSpeed = drivingHours > 0 ? totalDist / drivingHours : 0.0;

    return DayTrips(
      trips: trips,
      stops: stops,
      totalDistanceKm: totalDist,
      drivingTime: driving,
      parkedTime: parked,
      topSpeedKmh: topSpeed,
      avgSpeedKmh: avgSpeed,
    );
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
