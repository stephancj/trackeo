import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/history/models/trip_model.dart';
import 'package:mobile/features/vehicles/models/vehicle_model.dart';

/// Helper : position à un instant donné (minutes depuis minuit) et une vitesse.
VehiclePosition _p(int minute, double lat, double lon, {double speed = 30}) {
  return VehiclePosition(
    lat: lat,
    lon: lon,
    speedKmh: speed,
    course: 0,
    deviceTime: DateTime(2026, 6, 18, 0, 0).add(Duration(minutes: minute)),
  );
}

void main() {
  group('DayTrips.fromPositions', () {
    test('liste vide → aucun trajet', () {
      final day = DayTrips.fromPositions(const []);
      expect(day.isEmpty, isTrue);
      expect(day.tripCount, 0);
      expect(day.drivingTime, Duration.zero);
    });

    test('segmente deux trajets séparés par un arrêt > 10 min', () {
      // Trajet 1 : 08:00 → 08:20, puis arrêt ~3 h, trajet 2 : 11:30 → 11:50.
      // Coordonnées espacées pour dépasser le filtre 100 m.
      final positions = [
        _p(8 * 60, -18.9100, 47.5200),
        _p(8 * 60 + 10, -18.9000, 47.5300),
        _p(8 * 60 + 20, -18.8900, 47.5400),
        _p(11 * 60 + 30, -18.8900, 47.5400),
        _p(11 * 60 + 40, -18.8800, 47.5500),
        _p(11 * 60 + 50, -18.8700, 47.5600),
      ];
      final day = DayTrips.fromPositions(positions);

      expect(day.tripCount, 2, reason: 'gap de 3 h ⇒ 2 trajets');
      expect(day.stopCount, 1);
      expect(day.trips[0].index, 1);
      expect(day.trips[1].index, 2);
    });

    test('drivingTime = somme des durées de trajet, PAS dernier − premier point',
        () {
      // Deux trajets de 20 min chacun (points espacés de 10 min, cadence GPS
      // réaliste), séparés par ~3 h d'arrêt.
      // Amplitude de la journée = 11:50 − 08:00 = 3 h 50.
      // Conduite réelle = 40 min. C'est le bug corrigé (lot 2).
      final positions = [
        _p(8 * 60, -18.9100, 47.5200),
        _p(8 * 60 + 10, -18.9000, 47.5300),
        _p(8 * 60 + 20, -18.8900, 47.5400),
        _p(11 * 60 + 30, -18.8900, 47.5400),
        _p(11 * 60 + 40, -18.8800, 47.5500),
        _p(11 * 60 + 50, -18.8700, 47.5600),
      ];
      final day = DayTrips.fromPositions(positions);

      expect(day.drivingTime, const Duration(minutes: 40),
          reason: 'somme des 2 trajets de 20 min');
      expect(day.parkedTime, const Duration(minutes: 190),
          reason: 'arrêt de 3 h 10 entre les trajets');
      // Garde-fou anti-régression : surtout pas l'amplitude (3 h 50 = 230 min).
      expect(day.drivingTime.inMinutes, isNot(230));
    });

    test('filtre le jitter GPS à l\'arrêt (< 100 m)', () {
      // Points quasi immobiles sur 30 min → aucun trajet significatif.
      final positions = [
        _p(9 * 60, -18.9000, 47.5300),
        _p(9 * 60 + 10, -18.90001, 47.53001),
        _p(9 * 60 + 20, -18.90002, 47.53000),
        _p(9 * 60 + 30, -18.90001, 47.53002),
      ];
      final day = DayTrips.fromPositions(positions);
      expect(day.isEmpty, isTrue, reason: 'déplacement < 100 m ⇒ stationné');
    });

    test('jitter à l\'arrêt : distance cumulée > 100 m mais sur place ⇒ PAS un '
        'trajet (bug signalé)', () {
      // Véhicule stationné qui reporte toutes les 2 min, GPS qui oscille entre
      // 2 points distants de ~30 m. Sur 12 points : ~330 m cumulés (> seuil
      // historique de 100 m) MAIS bounding box ~30 m → ne doit PAS être un trajet.
      const a = -18.9000;
      const b = -18.89973; // ~30 m au nord
      final positions = [
        for (var k = 0; k < 12; k++)
          _p(9 * 60 + k * 2, k.isEven ? a : b, 47.5300, speed: 1),
      ];
      final day = DayTrips.fromPositions(positions);
      expect(day.isEmpty, isTrue,
          reason: 'déplacement net ~30 m ⇒ stationné, malgré ~330 m cumulés');
      expect(day.tripCount, 0);
    });

    test('vitesse moyenne = distance / temps de conduite', () {
      // 1 trajet d'1 h, points toutes les 10 min (cadence réaliste), de
      // -18.90 à -18.80 (~11 km vers le nord).
      final positions = [
        for (var k = 0; k <= 6; k++)
          _p(8 * 60 + k * 10, -18.9000 + k * (0.10 / 6), 47.5000,
              speed: k == 3 ? 60 : 40),
      ];
      final day = DayTrips.fromPositions(positions);
      expect(day.tripCount, 1);
      // ~11 km en 1 h ⇒ moyenne ~11 km/h ; vérifie surtout la cohérence > 0.
      expect(day.avgSpeedKmh, greaterThan(0));
      expect(day.topSpeedKmh, 60);
    });
  });
}
