import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/speed_palette.dart';

void main() {
  const gray = Color(0xFF9CA3AF);
  const amber = Color(0xFFFBBF24);
  const green = Color(0xFF4ECB8D);
  const blue = Color(0xFF5B8DEF);
  const orange = Color(0xFFF59E0B);
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

    test('au pas jusqu\'à 10 : 9 ⇒ ambre, 11 ⇒ vert (lent)', () {
      expect(speedColor(9), amber);
      expect(speedColor(11), green);
    });

    test('urbain jusqu\'à 50 : 45 ⇒ bleu, 55 ⇒ orange (route)', () {
      expect(speedColor(45), blue);
      expect(speedColor(55), orange);
    });

    test('excès > 100 ⇒ rouge', () {
      expect(speedColor(135), red);
    });
  });
}
