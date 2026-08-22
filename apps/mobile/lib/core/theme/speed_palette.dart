import 'package:flutter/material.dart';

/// Une bande de la palette de vitesse (couleur + libellé + plage affichée).
class SpeedBand {
  final double maxKmh; // borne haute exclue (double.infinity pour la dernière)
  final Color color;
  final String label;
  final String range;
  const SpeedBand(this.maxKmh, this.color, this.label, this.range);
}

/// Palette de vitesse partagée (trace Historique + trace d'alerte).
///
/// Palette froide pour la circulation normale, chaude uniquement lorsqu'une
/// vitesse demande de l'attention. Les bornes affichées correspondent exactement
/// aux comparaisons (borne haute exclue).
const List<SpeedBand> kSpeedBands = [
  SpeedBand(3, Color(0xFF98A2B3), 'Arrêté', '< 3'),
  SpeedBand(20, Color(0xFF4ECB8D), 'Au pas', '3–19'),
  SpeedBand(50, Color(0xFF20A4B8), 'Urbain', '20–49'),
  SpeedBand(80, Color(0xFF3E7DD8), 'Route', '50–79'),
  SpeedBand(120, Color(0xFFE99A28), 'Rapide', '80–119'),
  SpeedBand(double.infinity, Color(0xFFD94B4B), 'Excès', '≥ 120'),
];

SpeedBand speedBand(double kmh) {
  for (final b in kSpeedBands) {
    if (kmh < b.maxKmh) return b;
  }
  return kSpeedBands.last;
}

/// Couleur correspondant à une vitesse en km/h.
Color speedColor(double kmh) => speedBand(kmh).color;
