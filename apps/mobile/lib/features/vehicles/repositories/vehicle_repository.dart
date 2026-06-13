import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../history/models/day_activity_model.dart';
import '../models/vehicle_model.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles();
  Future<VehiclePosition?> getLastPosition(int vehicleId);
  Future<List<VehiclePosition>> getHistory(
    int vehicleId,
    DateTime from,
    DateTime to,
  );
  Future<List<DayActivity>> getActiveDays(
    int vehicleId,
    DateTime from,
    DateTime to,
  );
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data);
}

class RemoteVehicleRepository implements VehicleRepository {
  final Dio _dio;
  const RemoteVehicleRepository(this._dio);

  @override
  Future<List<Vehicle>> getVehicles() async {
    final response = await _dio.get<List<dynamic>>('/vehicles');
    return (response.data ?? [])
        .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VehiclePosition?> getLastPosition(int vehicleId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/vehicles/$vehicleId/position',
      );
      return VehiclePosition.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<VehiclePosition>> getHistory(
    int vehicleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/vehicles/$vehicleId/history',
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    return (response.data ?? [])
        .map((json) => VehiclePosition.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DayActivity>> getActiveDays(
    int vehicleId,
    DateTime from,
    DateTime to,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vehicles/$vehicleId/history/active-days',
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    final days = (response.data?['days'] as List<dynamic>?) ?? [];
    return days
        .map((json) => DayActivity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/vehicles/$id',
      data: data,
    );
    return Vehicle.fromJson(response.data!);
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return RemoteVehicleRepository(ref.watch(dioProvider));
});
