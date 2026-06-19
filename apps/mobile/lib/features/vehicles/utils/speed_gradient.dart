import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../../../core/theme/speed_palette.dart';

/// Couleurs du dégradé d'une polyligne, basées sur la vitesse **effective** de
/// chaque point.
///
/// Certains traceurs rapportent 0 km/h alors que le véhicule roule (le segment
/// s'affichait alors en gris « Arrêté » malgré un déplacement visible). On prend
/// donc le **max** entre la vitesse rapportée et celle déduite du déplacement
/// réel depuis le point précédent (distance / temps).
List<Color> speedGradientColors(List<VehiclePosition> pts) {
  final colors = <Color>[];
  for (var i = 0; i < pts.length; i++) {
    colors.add(speedColor(_effectiveKmh(pts, i)));
  }
  return colors;
}

double _effectiveKmh(List<VehiclePosition> pts, int i) {
  final p = pts[i];
  var eff = p.speedKmh;
  if (i > 0) {
    final q = pts[i - 1];
    final dtH = p.deviceTime.difference(q.deviceTime).inMilliseconds / 3600000.0;
    if (dtH > 0) {
      final disp = _haversineKm(q.lat, q.lon, p.lat, p.lon) / dtH;
      // Ignore les sauts GPS aberrants (téléportation) ; garde la plus grande
      // des deux sources pour ne pas sous-estimer un véhicule qui roule.
      if (disp > eff && disp <= 250) eff = disp;
    }
  }
  return eff;
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
