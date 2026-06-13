import 'package:equatable/equatable.dart';

/// Niveau d'activité d'un jour — pilote l'intensité du point dans le calendrier.
enum ActivityLevel { none, low, medium, high }

/// Activité d'un véhicule pour un jour donné (calendrier d'activité historique).
class DayActivity extends Equatable {
  /// Jour local, sans composante horaire (00:00).
  final DateTime date;
  final double distanceKm;
  final int points;

  const DayActivity({
    required this.date,
    required this.distanceKm,
    required this.points,
  });

  factory DayActivity.fromJson(Map<String, dynamic> json) {
    final raw = (json['date'] as String).split('-'); // 'YYYY-MM-DD'
    return DayActivity(
      date: DateTime(
        int.parse(raw[0]),
        int.parse(raw[1]),
        int.parse(raw[2]),
      ),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  /// Vrai mouvement ce jour-là ? (ignore un véhicule garé qui ne fait que
  /// reporter sa position sans bouger).
  bool get hasMovement => distanceKm >= 0.3;

  /// Intensité visuelle, par distance parcourue.
  ActivityLevel get level {
    if (!hasMovement) return ActivityLevel.none;
    if (distanceKm < 5) return ActivityLevel.low;
    if (distanceKm < 25) return ActivityLevel.medium;
    return ActivityLevel.high;
  }

  @override
  List<Object?> get props => [date, distanceKm, points];
}
