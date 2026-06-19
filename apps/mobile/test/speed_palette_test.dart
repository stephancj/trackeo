import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/speed_palette.dart';

void main() {
  const gray = Color(0xFF9CA3AF);
  const amber = Color(0xFFFBBF24);
  const green = Color(0xFF4ECB8D);
  const red = Color(0xFFEF4444);

  group('speedColor — distinguer arrêt et bouchon', () {
    test('< 1 km/h ⇒ gris (arrêté)', () {
      expect(speedColor(0), gray);
      expect(speedColor(0.9), gray);
    });

    test('2 et 4 km/h (au pas / bouchon) ⇒ ambre, PAS gris (bug signalé)', () {
      expect(speedColor(2), amber);
      expect(speedColor(4), amber);
      expect(speedColor(4), isNot(gray));
    });

    test('frontières : 14 ⇒ ambre, 16 ⇒ vert', () {
      expect(speedColor(14), amber);
      expect(speedColor(16), green);
    });

    test('excès > 100 ⇒ rouge', () {
      expect(speedColor(135), red);
    });
  });
}
