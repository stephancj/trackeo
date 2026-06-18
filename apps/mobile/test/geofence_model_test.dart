import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/models/geofence_model.dart';
import 'package:mobile/features/alerts/models/geofence_type.dart';

void main() {
  group('Geofence.copyWith', () {
    final base = Geofence(
      id: 1,
      name: 'Domicile',
      deviceIds: const [10, 11],
      centerLat: -18.9,
      centerLon: 47.5,
      radiusM: 500,
      type: 'home',
      isActive: true,
      userId: 7,
      alertOnEntry: true,
      alertOnExit: false,
      alertViaWhatsapp: true,
    );

    test('ne change que isActive et préserve le reste (fix toggleGeofence)', () {
      final toggled = base.copyWith(isActive: false);
      expect(toggled.isActive, isFalse);
      // Les champs autrefois perdus par la reconstruction manuelle :
      expect(toggled.alertOnExit, isFalse);
      expect(toggled.alertViaWhatsapp, isTrue);
      expect(toggled.type, 'home');
      expect(toggled.deviceIds, [10, 11]);
      expect(toggled.name, 'Domicile');
      expect(toggled.radiusM, 500);
    });

    test('fromJson lit type, avec repli sur custom', () {
      final withType = Geofence.fromJson({
        'id': 2,
        'name': 'Bureau',
        'centerLat': -18.8,
        'centerLon': 47.4,
        'radiusM': 300,
        'type': 'work',
        'userId': 7,
      });
      expect(withType.type, 'work');

      final noType = Geofence.fromJson({
        'id': 3,
        'name': 'X',
        'centerLat': 0,
        'centerLon': 0,
        'radiusM': 100,
        'userId': 7,
      });
      expect(noType.type, 'custom');
    });
  });

  group('geofenceTypeInfo', () {
    test('résout les clés connues', () {
      expect(geofenceTypeInfo('home').label, 'Domicile');
      expect(geofenceTypeInfo('work').label, 'Bureau');
    });

    test('repli sur "Autre" pour une clé inconnue', () {
      expect(geofenceTypeInfo('inconnu').key, 'custom');
    });
  });
}
