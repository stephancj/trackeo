import 'package:dio/dio.dart';
import '../models/geofence_model.dart';

class GeofenceRepository {
  final Dio _dio;

  GeofenceRepository(this._dio);

  Future<List<Geofence>> fetchGeofences() async {
    final response = await _dio.get('/geofences');
    final data = response.data as List;
    return data
        .map((e) => Geofence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Geofence> createGeofence(Map<String, dynamic> payload) async {
    final response = await _dio.post('/geofences', data: payload);
    return Geofence.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Geofence> updateGeofence(int id, Map<String, dynamic> payload) async {
    final response = await _dio.patch('/geofences/$id', data: payload);
    return Geofence.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGeofence(int id) async {
    await _dio.delete('/geofences/$id');
  }
}
