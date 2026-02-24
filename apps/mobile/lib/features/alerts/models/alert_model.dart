import 'package:equatable/equatable.dart';

class AlertModel extends Equatable {
  final String id;
  final int deviceId;
  final int ownerId;
  final String type;
  final String? message;
  final String status;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.deviceId,
    required this.ownerId,
    required this.type,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'] as String,
    deviceId: json['deviceId'] as int,
    ownerId: json['ownerId'] as int,
    type: json['type'] as String,
    message: json['message'] as String?,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    deviceId,
    ownerId,
    type,
    message,
    status,
    createdAt,
  ];
}
