import 'package:equatable/equatable.dart';

enum VehicleStatus { online, idle, offline }

extension VehicleStatusX on VehicleStatus {
  // L3 fix : labels en français (utilisés par StatusBadge)
  String get label => switch (this) {
    VehicleStatus.online => 'En route',
    VehicleStatus.idle => 'Arrêté',
    VehicleStatus.offline => 'Hors ligne',
  };
}

/// H2 — Parse une date ISO 8601 sans crash si le format est invalide.
DateTime _parseDateTimeSafe(String s) {
  try {
    return DateTime.parse(s);
  } catch (_) {
    // Valeur sentinelle epoch 0 — la UI affiche "Inconnu" pour lastUpdate null
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class VehiclePosition extends Equatable {
  final double lat;
  final double lon;
  final double speedKmh;
  final double course;
  final String? address;
  final int? battery;
  final bool? ignition;
  final int? rssi;
  final DateTime deviceTime;

  const VehiclePosition({
    required this.lat,
    required this.lon,
    required this.speedKmh,
    required this.course,
    this.address,
    this.battery,
    this.ignition,
    this.rssi,
    required this.deviceTime,
  });

  factory VehiclePosition.fromJson(Map<String, dynamic> json) =>
      VehiclePosition(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        speedKmh: (json['speedKmh'] as num).toDouble(),
        course: (json['course'] as num).toDouble(),
        address: json['address'] as String?,
        battery: json['battery'] as int?,
        ignition: json['ignition'] as bool?,
        rssi: json['rssi'] as int?,
        deviceTime: _parseDateTimeSafe(json['deviceTime'] as String),
      );

  @override
  List<Object?> get props => [lat, lon, deviceTime];
}

class Vehicle extends Equatable {
  final int id;
  final String name;
  final String serialNumber;
  final String? plate;
  final String? imageUrl;
  final VehicleStatus status;
  final DateTime? lastUpdate;
  final VehiclePosition? position;

  const Vehicle({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.plate,
    this.imageUrl,
    required this.status,
    this.lastUpdate,
    this.position,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'online' => VehicleStatus.online,
      'idle' => VehicleStatus.idle,
      _ => VehicleStatus.offline,
    };

    return Vehicle(
      id: json['id'] as int,
      name: json['name'] as String,
      serialNumber: json['serialNumber'] as String,
      plate: json['plate'] as String?,
      imageUrl: json['imageUrl'] as String?,
      status: status,
      lastUpdate: json['lastUpdate'] != null
          ? _parseDateTimeSafe(json['lastUpdate'] as String)
          : null,
      position: json['position'] != null
          ? VehiclePosition.fromJson(json['position'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isMoving => status == VehicleStatus.online;

  @override
  List<Object?> get props => [id, serialNumber, plate];
}
