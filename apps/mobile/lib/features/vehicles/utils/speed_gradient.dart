import 'dart:math';
import '../models/vehicle_model.dart';
import '../../../core/theme/speed_palette.dart';

/// Portion continue d'un trajet appartenant à une même bande de vitesse.
class SpeedTraceSegment {
  final List<VehiclePosition> points;
  final SpeedBand band;

  const SpeedTraceSegment({required this.points, required this.band});
}

/// Construit des portions de couleur solides réellement attachées aux segments
/// GPS. Contrairement à `gradientColors`, la couleur ne dépend ni de la forme du
/// trajet ni du cadrage de la carte.
List<SpeedTraceSegment> buildSpeedTraceSegments(
  List<VehiclePosition> points,
) {
  if (points.length < 2) return const [];

  final result = <SpeedTraceSegment>[];
  var currentBand = speedBand(smoothedSpeedKmh(points, 1));
  var currentPoints = <VehiclePosition>[points.first, points[1]];

  for (var i = 2; i < points.length; i++) {
    final band = speedBand(smoothedSpeedKmh(points, i));
    if (identical(band, currentBand)) {
      currentPoints.add(points[i]);
      continue;
    }
    result.add(SpeedTraceSegment(points: currentPoints, band: currentBand));
    currentBand = band;
    currentPoints = [points[i - 1], points[i]];
  }
  result.add(SpeedTraceSegment(points: currentPoints, band: currentBand));
  return result;
}

/// Vitesse utilisée à la fois par la trace et le lecteur. La médiane locale
/// élimine un pic GPS isolé sans décaler durablement les changements de vitesse.
double smoothedSpeedKmh(List<VehiclePosition> pts, int pointIndex) {
  if (pts.length < 2) return pts.isEmpty ? 0 : pts.first.speedKmh;
  final endingAt = pointIndex.clamp(1, pts.length - 1);
  final values = <double>[
    if (endingAt > 1) _segmentSpeedKmh(pts, endingAt - 1),
    _segmentSpeedKmh(pts, endingAt),
    if (endingAt < pts.length - 1) _segmentSpeedKmh(pts, endingAt + 1),
  ]..sort();
  return values[values.length ~/ 2];
}

double _segmentSpeedKmh(List<VehiclePosition> pts, int i) {
  final p = pts[i];
  if (p.speedKmh >= 3) return p.speedKmh;

  final q = pts[i - 1];
  final dtSeconds = p.deviceTime.difference(q.deviceTime).inMilliseconds / 1000;
  if (dtSeconds <= 0 || dtSeconds > 300) return p.speedKmh;

  final distanceKm = _haversineKm(q.lat, q.lon, p.lat, p.lon);
  if (distanceKm * 1000 < 12) return p.speedKmh;

  final derived = distanceKm / (dtSeconds / 3600);
  return derived <= 180 ? derived : p.speedKmh;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
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
