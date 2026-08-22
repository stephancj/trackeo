import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/speed_palette.dart';

void main() {
  const stopped = Color(0xFF98A2B3);
  const walking = Color(0xFF4ECB8D);
  const urban = Color(0xFF20A4B8);
  const road = Color(0xFF3E7DD8);
  const fast = Color(0xFFE99A28);
  const excess = Color(0xFFD94B4B);

  group('speedColor utilise des bornes exactes et monotones', () {
    test('arrêt et circulation lente', () {
      expect(speedColor(0), stopped);
      expect(speedColor(2.99), stopped);
      expect(speedColor(3), walking);
      expect(speedColor(19.99), walking);
    });

    test('circulation urbaine et route', () {
      expect(speedColor(20), urban);
      expect(speedColor(49.99), urban);
      expect(speedColor(50), road);
      expect(speedColor(79.99), road);
    });

    test('orange avant le seuil et rouge à partir de 120 km/h', () {
      expect(speedColor(80), fast);
      expect(speedColor(119.99), fast);
      expect(speedColor(120), excess);
      expect(speedColor(160), excess);
    });
  });
}
