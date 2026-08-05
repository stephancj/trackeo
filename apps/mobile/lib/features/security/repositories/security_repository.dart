import 'package:dio/dio.dart';

class SecurityRepository {
  final Dio dio;
  SecurityRepository(this.dio);
  Future<Map<String, dynamic>> sos(int deviceId) async =>
      (await dio.post<Map<String, dynamic>>('/vehicles/$deviceId/sos')).data!;
  Future<Map<String, dynamic>> theft(int deviceId) async =>
      (await dio.post<Map<String, dynamic>>('/vehicles/$deviceId/theft')).data!;
  Future<Map<String, dynamic>> cancelTheft(String incidentId) async =>
      (await dio.delete<Map<String, dynamic>>('/incidents/$incidentId/theft'))
          .data!;
  Future<Map<String, dynamic>> createLink(int deviceId, int minutes) async =>
      (await dio.post<Map<String, dynamic>>('/vehicles/$deviceId/share-links',
              data: {'durationMinutes': minutes}))
          .data!;
  Future<Map<String, dynamic>> publicTracking(String token) async =>
      (await dio.get<Map<String, dynamic>>('/public/tracking/$token')).data!;
}
