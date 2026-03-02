import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/report_models.dart';

abstract class ReportsRepository {
  Future<ActivitySummary> getActivitySummary(int vehicleId, String period);
  Future<List<TripLogEntry>> getTripLog(
      int vehicleId, DateTime from, DateTime to);
  Future<List<SpeedViolation>> getSpeedViolations(
      int vehicleId, DateTime from, DateTime to,
      {int threshold = 120});
  Future<List<IdleEpisode>> getIdleTime(
      int vehicleId, DateTime from, DateTime to);
  Future<List<GeofenceActivityEntry>> getGeofenceActivity(
      int vehicleId, String period);
}

class RemoteReportsRepository implements ReportsRepository {
  final Dio _dio;
  const RemoteReportsRepository(this._dio);

  @override
  Future<ActivitySummary> getActivitySummary(
      int vehicleId, String period) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vehicles/$vehicleId/reports/activity',
      queryParameters: {'period': period},
    );
    return ActivitySummary.fromJson(response.data!);
  }

  @override
  Future<List<TripLogEntry>> getTripLog(
      int vehicleId, DateTime from, DateTime to) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vehicles/$vehicleId/reports/trip-log',
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    final trips = (response.data!['trips'] as List<dynamic>?) ?? [];
    return trips
        .map((e) => TripLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SpeedViolation>> getSpeedViolations(
      int vehicleId, DateTime from, DateTime to,
      {int threshold = 120}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vehicles/$vehicleId/reports/speed-violations',
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'threshold': threshold,
      },
    );
    final violations =
        (response.data!['violations'] as List<dynamic>?) ?? [];
    return violations
        .map((e) => SpeedViolation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<IdleEpisode>> getIdleTime(
      int vehicleId, DateTime from, DateTime to) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vehicles/$vehicleId/reports/idle',
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );
    final episodes = (response.data!['episodes'] as List<dynamic>?) ?? [];
    return episodes
        .map((e) => IdleEpisode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<GeofenceActivityEntry>> getGeofenceActivity(
      int vehicleId, String period) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vehicles/$vehicleId/reports/geofence-activity',
      queryParameters: {'period': period},
    );
    final geofences =
        (response.data!['geofences'] as List<dynamic>?) ?? [];
    return geofences
        .map((e) => GeofenceActivityEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return RemoteReportsRepository(ref.watch(dioProvider));
});
