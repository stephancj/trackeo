import 'package:equatable/equatable.dart';

/// H2 — Parse une date ISO 8601 sans crash si le format est invalide.
DateTime _parseDateTimeSafe(String s) {
  try {
    return DateTime.parse(s);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

class AlertModel extends Equatable {
  final String id;
  final int deviceId;
  final int ownerId;
  final String type;
  final String? message;
  final String status;
  final double? lat;
  final double? lon;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.deviceId,
    required this.ownerId,
    required this.type,
    this.message,
    required this.status,
    this.lat,
    this.lon,
    required this.createdAt,
  });

  /// True si l'alerte porte une position affichable sur la carte.
  bool get hasLocation => lat != null && lon != null;

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'] as String,
    deviceId: json['deviceId'] as int,
    ownerId: json['ownerId'] as int,
    type: json['type'] as String,
    message: json['message'] as String?,
    status: json['status'] as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lon: (json['lon'] as num?)?.toDouble(),
    createdAt: _parseDateTimeSafe(json['createdAt'] as String),
  );

  AlertModel copyWith({
    String? id,
    int? deviceId,
    int? ownerId,
    String? type,
    String? message,
    String? status,
    double? lat,
    double? lon,
    DateTime? createdAt,
  }) =>
      AlertModel(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        ownerId: ownerId ?? this.ownerId,
        type: type ?? this.type,
        message: message ?? this.message,
        status: status ?? this.status,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [
    id,
    deviceId,
    ownerId,
    type,
    message,
    status,
    lat,
    lon,
    createdAt,
  ];
}
