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

  /// Marque toutes les alertes ouvertes comme lues côté serveur.
  Future<void> markAllRead() async {
    await _dio.patch('/alerts/mark-all-read');
  }

  /// Acquitte une alerte spécifique.
  Future<void> ackAlert(String id) async {
    await _dio.patch('/alerts/$id/ack');
  }
}
