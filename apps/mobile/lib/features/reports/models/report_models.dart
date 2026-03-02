import 'package:equatable/equatable.dart';

class ActivitySummary extends Equatable {
  final double distanceKm;
  final int drivingMinutes;
  final int idleMinutes;
  final double maxSpeedKmh;
  final int tripCount;
  final int speedViolationCount;
  final int pointCount;

  const ActivitySummary({
    required this.distanceKm,
    required this.drivingMinutes,
    required this.idleMinutes,
    required this.maxSpeedKmh,
    required this.tripCount,
    required this.speedViolationCount,
    required this.pointCount,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) =>
      ActivitySummary(
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        drivingMinutes: (json['drivingMinutes'] as num?)?.toInt() ?? 0,
        idleMinutes: (json['idleMinutes'] as num?)?.toInt() ?? 0,
        maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
        tripCount: (json['tripCount'] as num?)?.toInt() ?? 0,
        speedViolationCount:
            (json['speedViolationCount'] as num?)?.toInt() ?? 0,
        pointCount: (json['pointCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [
        distanceKm,
        drivingMinutes,
        idleMinutes,
        maxSpeedKmh,
        tripCount,
        speedViolationCount,
        pointCount,
      ];
}

class TripLogEntry extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;
  final double distanceKm;
  final int durationMin;
  final double maxSpeedKmh;
  final int pointCount;

  const TripLogEntry({
    required this.startTime,
    required this.endTime,
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.distanceKm,
    required this.durationMin,
    required this.maxSpeedKmh,
    required this.pointCount,
  });

  factory TripLogEntry.fromJson(Map<String, dynamic> json) => TripLogEntry(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        startLat: (json['startLat'] as num).toDouble(),
        startLon: (json['startLon'] as num).toDouble(),
        endLat: (json['endLat'] as num).toDouble(),
        endLon: (json['endLon'] as num).toDouble(),
        distanceKm: (json['distanceKm'] as num).toDouble(),
        durationMin: (json['durationMin'] as num).toInt(),
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
        pointCount: (json['pointCount'] as num).toInt(),
      );

  @override
  List<Object?> get props => [startTime, endTime, distanceKm, durationMin];
}

class SpeedViolation extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final double lat;
  final double lon;
  final double maxSpeedKmh;
  final int durationSec;

  const SpeedViolation({
    required this.startTime,
    required this.endTime,
    required this.lat,
    required this.lon,
    required this.maxSpeedKmh,
    required this.durationSec,
  });

  factory SpeedViolation.fromJson(Map<String, dynamic> json) => SpeedViolation(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
        durationSec: (json['durationSec'] as num).toInt(),
      );

  @override
  List<Object?> get props => [startTime, maxSpeedKmh, durationSec];
}

class IdleEpisode extends Equatable {
  final DateTime startTime;
  final DateTime endTime;
  final double lat;
  final double lon;
  final int durationMin;

  const IdleEpisode({
    required this.startTime,
    required this.endTime,
    required this.lat,
    required this.lon,
    required this.durationMin,
  });

  factory IdleEpisode.fromJson(Map<String, dynamic> json) => IdleEpisode(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        durationMin: (json['durationMin'] as num).toInt(),
      );

  @override
  List<Object?> get props => [startTime, durationMin];
}

class GeofenceActivityEntry extends Equatable {
  final int geofenceId;
  final String geofenceName;
  final bool isActive;
  final double centerLat;
  final double centerLon;
  final int radiusM;
  final int enterCount;
  final int exitCount;
  final int totalEvents;
  final DateTime? lastEventAt;
  final String? lastEventType; // 'geofence_enter' | 'geofence_exit' | null

  const GeofenceActivityEntry({
    required this.geofenceId,
    required this.geofenceName,
    required this.isActive,
    required this.centerLat,
    required this.centerLon,
    required this.radiusM,
    required this.enterCount,
    required this.exitCount,
    required this.totalEvents,
    this.lastEventAt,
    this.lastEventType,
  });

  factory GeofenceActivityEntry.fromJson(Map<String, dynamic> json) =>
      GeofenceActivityEntry(
        geofenceId: (json['geofenceId'] as num).toInt(),
        geofenceName: json['geofenceName'] as String,
        isActive: json['isActive'] as bool? ?? true,
        centerLat: (json['centerLat'] as num).toDouble(),
        centerLon: (json['centerLon'] as num).toDouble(),
        radiusM: (json['radiusM'] as num).toInt(),
        enterCount: (json['enterCount'] as num?)?.toInt() ?? 0,
        exitCount: (json['exitCount'] as num?)?.toInt() ?? 0,
        totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
        lastEventAt: json['lastEventAt'] != null
            ? DateTime.parse(json['lastEventAt'] as String)
            : null,
        lastEventType: json['lastEventType'] as String?,
      );

  @override
  List<Object?> get props =>
      [geofenceId, enterCount, exitCount, lastEventAt];
}
