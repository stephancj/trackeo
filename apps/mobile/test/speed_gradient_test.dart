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
      deviceTime: DateTime.utc(2026, 6, 18, 10, 0).add(Duration(seconds: sec)),
    );

void main() {
  const gray = Color(0xFF9CA3AF);

  test('vitesse rapportée 0 mais déplacement réel ⇒ PAS gris (bug signalé)', () {
    // ~278 m vers le sud en 30 s ⇒ ~33 km/h, alors que le traceur rapporte 0.
    final pts = [
      _p(-18.9000, 47.5000, 0, 0),
      _p(-18.9025, 47.5000, 0, 30),
    ];
    final colors = speedGradientColors(pts);
    expect(colors.length, 2);
    expect(colors[1], isNot(gray),
        reason: 'le déplacement réel doit primer sur la vitesse rapportée à 0');
  });

  test('réellement immobile (pas de déplacement) ⇒ gris', () {
    final pts = [
      _p(-18.9000, 47.5000, 0, 0),
      _p(-18.90001, 47.50001, 0, 30), // ~1.5 m
    ];
    final colors = speedGradientColors(pts);
    expect(colors[1], gray);
  });

  test('vitesse rapportée correcte conservée si > déplacement', () {
    // Traceur dit 80 km/h, points proches (gap GPS) ⇒ on garde 80, pas gris.
    final pts = [
      _p(-18.9000, 47.5000, 80, 0),
      _p(-18.90005, 47.5000, 80, 5),
    ];
    final colors = speedGradientColors(pts);
    expect(colors[1], isNot(gray));
  });
}
