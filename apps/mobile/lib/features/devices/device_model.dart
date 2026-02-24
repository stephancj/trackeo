import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final int id;
  final String name;
  final String uniqueId;
  final String? status;
  final DateTime? lastUpdate;

  const Device({
    required this.id,
    required this.name,
    required this.uniqueId,
    this.status,
    this.lastUpdate,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as int,
        name: json['name'] as String,
        uniqueId: json['uniqueId'] as String,
        status: json['status'] as String?,
        lastUpdate: json['lastUpdate'] != null
            ? DateTime.parse(json['lastUpdate'] as String)
            : null,
      );

  bool get isOnline => status == 'online';

  @override
  List<Object?> get props => [id, uniqueId];
}
