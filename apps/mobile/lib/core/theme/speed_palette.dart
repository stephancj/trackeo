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
/// On distingue l'**arrêt réel** (< 1 km/h) du **roulage lent / bouchon**
/// (1–15 km/h) — fréquent à Antananarivo. Avant, tout ce qui était sous 5 km/h
/// s'affichait en gris « arrêté », ce qui faisait passer un véhicule au pas dans
/// les embouteillages pour stationné.
const List<SpeedBand> kSpeedBands = [
  SpeedBand(1, Color(0xFF9CA3AF), 'Arrêté', '< 1'),
  SpeedBand(15, Color(0xFFFBBF24), 'Au pas', '1–15'),
  SpeedBand(40, Color(0xFF4ECB8D), 'Lent', '15–40'),
  SpeedBand(70, Color(0xFF5B8DEF), 'Urbain', '40–70'),
  SpeedBand(100, Color(0xFFF59E0B), 'Route', '70–100'),
  SpeedBand(double.infinity, Color(0xFFEF4444), 'Excès', '> 100'),
];

/// Couleur correspondant à une vitesse en km/h.
Color speedColor(double kmh) {
  for (final b in kSpeedBands) {
    if (kmh < b.maxKmh) return b.color;
  }
  return kSpeedBands.last.color;
}
