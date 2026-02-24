import 'package:equatable/equatable.dart';

enum VehicleStatus { online, idle, offline }

extension VehicleStatusX on VehicleStatus {
  String get label => switch (this) {
        VehicleStatus.online => 'Moving',
        VehicleStatus.idle => 'Idle',
        VehicleStatus.offline => 'Offline',
      };
}

class VehiclePosition extends Equatable {
  final double lat;
  final double lon;
  final double speedKmh;
  final double course;
  final String? address;
  final int? battery;
  final DateTime deviceTime;

  const VehiclePosition({
    required this.lat,
    required this.lon,
    required this.speedKmh,
    required this.course,
    this.address,
    this.battery,
    required this.deviceTime,
  });

  factory VehiclePosition.fromJson(Map<String, dynamic> json) => VehiclePosition(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        speedKmh: (json['speedKmh'] as num).toDouble(),
        course: (json['course'] as num).toDouble(),
        address: json['address'] as String?,
        battery: json['battery'] as int?,
        deviceTime: DateTime.parse(json['deviceTime'] as String),
      );

  @override
  List<Object?> get props => [lat, lon, deviceTime];
}

class Vehicle extends Equatable {
  final int id;
  final String name;
  final String plate;
  final VehicleStatus status;
  final DateTime? lastUpdate;
  final VehiclePosition? position;

  const Vehicle({
    required this.id,
    required this.name,
    required this.plate,
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
      plate: json['plate'] as String,
      status: status,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
      position: json['position'] != null
          ? VehiclePosition.fromJson(
              json['position'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isMoving => status == VehicleStatus.online;

  @override
  List<Object?> get props => [id, plate];
}
