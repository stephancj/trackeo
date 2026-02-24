import 'package:dio/dio.dart';
import '../models/alert_model.dart';

class AlertRepository {
  final Dio _dio;

  AlertRepository(this._dio);

  Future<List<AlertModel>> fetchAlerts() async {
    final response = await _dio.get('/alerts');
    final data = response.data as List;
    return data
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
