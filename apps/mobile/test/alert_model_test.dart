import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/models/alert_model.dart';

void main() {
  group('AlertModel.fromJson — localisation', () {
    Map<String, dynamic> base() => {
          'id': 'a1',
          'deviceId': 10,
          'ownerId': 7,
          'type': 'speed_limit',
          'message': '142 km/h (limite 120 km/h) · Analakely',
          'status': 'open',
          'createdAt': '2026-06-18T10:00:00.000Z',
        };

    test('lit lat/lon quand présents → hasLocation', () {
      final a = AlertModel.fromJson({
        ...base(),
        'lat': -18.91234,
        'lon': 47.52345,
      });
      expect(a.hasLocation, isTrue);
      expect(a.lat, closeTo(-18.91234, 1e-9));
      expect(a.lon, closeTo(47.52345, 1e-9));
    });

    test('lat/lon absents (anciennes alertes) → pas de localisation', () {
      final a = AlertModel.fromJson(base());
      expect(a.hasLocation, isFalse);
      expect(a.lat, isNull);
      expect(a.lon, isNull);
    });

    test('lat/lon entiers (num) → convertis en double', () {
      final a = AlertModel.fromJson({...base(), 'lat': 0, 'lon': 47});
      expect(a.lat, 0.0);
      expect(a.lon, 47.0);
      expect(a.hasLocation, isTrue);
    });
  });
}
