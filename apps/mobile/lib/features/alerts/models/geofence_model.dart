import 'package:equatable/equatable.dart';

class Geofence extends Equatable {
  final int id;
  final String name;
  final List<int>? deviceIds;
  final double centerLat;
  final double centerLon;
  final double radiusM;
  final String type;
  final bool isActive;
  final int userId;
  final bool alertOnEntry;
  final bool alertOnExit;
  final bool alertViaWhatsapp;

  const Geofence({
    required this.id,
    required this.name,
    this.deviceIds,
    required this.centerLat,
    required this.centerLon,
    required this.radiusM,
    this.type = 'custom',
    required this.isActive,
    required this.userId,
    this.alertOnEntry = true,
    this.alertOnExit = true,
    this.alertViaWhatsapp = false,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
    id: json['id'] as int,
    name: json['name'] as String,
    deviceIds: (json['deviceIds'] as List?)?.map((e) => e as int).toList(),
    centerLat: (json['centerLat'] as num).toDouble(),
    centerLon: (json['centerLon'] as num).toDouble(),
    radiusM: (json['radiusM'] as num).toDouble(),
    type: json['type'] as String? ?? 'custom',
    isActive: json['isActive'] as bool? ?? true,
    userId: json['userId'] as int,
    alertOnEntry: json['alertOnEntry'] as bool? ?? true,
    alertOnExit: json['alertOnExit'] as bool? ?? true,
    alertViaWhatsapp: json['alertViaWhatsapp'] as bool? ?? false,
  );

  Geofence copyWith({
    int? id,
    String? name,
    List<int>? deviceIds,
    double? centerLat,
    double? centerLon,
    double? radiusM,
    String? type,
    bool? isActive,
    int? userId,
    bool? alertOnEntry,
    bool? alertOnExit,
    bool? alertViaWhatsapp,
  }) =>
      Geofence(
        id: id ?? this.id,
        name: name ?? this.name,
        deviceIds: deviceIds ?? this.deviceIds,
        centerLat: centerLat ?? this.centerLat,
        centerLon: centerLon ?? this.centerLon,
        radiusM: radiusM ?? this.radiusM,
        type: type ?? this.type,
        isActive: isActive ?? this.isActive,
        userId: userId ?? this.userId,
        alertOnEntry: alertOnEntry ?? this.alertOnEntry,
        alertOnExit: alertOnExit ?? this.alertOnExit,
        alertViaWhatsapp: alertViaWhatsapp ?? this.alertViaWhatsapp,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    deviceIds,
    centerLat,
    centerLon,
    radiusM,
    type,
    isActive,
    userId,
    alertOnEntry,
    alertOnExit,
    alertViaWhatsapp,
  ];
}
