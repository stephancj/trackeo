import 'package:equatable/equatable.dart';

class Geofence extends Equatable {
  final int id;
  final String name;
  final List<int>? deviceIds;
  final double centerLat;
  final double centerLon;
  final double radiusM;
  final bool isActive;
  final int userId;

  const Geofence({
    required this.id,
    required this.name,
    this.deviceIds,
    required this.centerLat,
    required this.centerLon,
    required this.radiusM,
    required this.isActive,
    required this.userId,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    id: json['id'] as int,
    name: json['name'] as String,
    deviceIds: (json['deviceIds'] as List?)?.map((e) => e as int).toList(),
    centerLat: (json['centerLat'] as num).toDouble(),
    centerLon: (json['centerLon'] as num).toDouble(),
    radiusM: (json['radiusM'] as num).toDouble(),
    isActive: json['isActive'] as bool? ?? true,
    userId: json['userId'] as int,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    deviceIds,
    centerLat,
    centerLon,
    radiusM,
    isActive,
    userId,
  ];
}
