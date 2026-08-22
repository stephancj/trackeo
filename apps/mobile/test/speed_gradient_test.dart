import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vehicles/models/vehicle_model.dart';
import 'package:mobile/features/vehicles/utils/speed_gradient.dart';

VehiclePosition _p(double lat, double lon, double speed, int sec) =>
    VehiclePosition(
      lat: lat,
      lon: lon,
      speedKmh: speed,
      course: 0,
      deviceTime: DateTime.utc(2026, 6, 18, 10).add(Duration(seconds: sec)),
    );

void main() {
  const stopped = Color(0xFF98A2B3);

  test('un déplacement réel corrige un traceur bloqué à 0 km/h', () {
    final points = [
      _p(-18.9000, 47.5000, 0, 0),
      _p(-18.9025, 47.5000, 0, 30),
    ];

    expect(smoothedSpeedKmh(points, 1), greaterThan(20));
    expect(buildSpeedTraceSegments(points).single.band.color, isNot(stopped));
  });

  test('le bruit GPS inférieur à 12 m reste affiché comme un arrêt', () {
    final points = [
      _p(-18.90000, 47.50000, 0, 0),
      _p(-18.90004, 47.50004, 0, 30),
    ];

    expect(buildSpeedTraceSegments(points).single.band.color, stopped);
  });

  test('la médiane locale élimine un pic de vitesse isolé', () {
    final points = [
      _p(-18.9000, 47.5000, 42, 0),
      _p(-18.9005, 47.5000, 42, 10),
      _p(-18.9010, 47.5000, 175, 20),
      _p(-18.9015, 47.5000, 42, 30),
    ];

    expect(smoothedSpeedKmh(points, 2), 42);
  });

  test('les portions consécutives de même bande sont regroupées', () {
    final points = [
      _p(-18.9000, 47.5000, 30, 0),
      _p(-18.9005, 47.5000, 32, 10),
      _p(-18.9010, 47.5000, 35, 20),
      _p(-18.9015, 47.5000, 95, 30),
      _p(-18.9020, 47.5000, 100, 40),
    ];

    final segments = buildSpeedTraceSegments(points);
    expect(segments, hasLength(2));
    expect(segments.first.points.length, 3);
    expect(segments.last.points.first, points[2]);
  });
}
