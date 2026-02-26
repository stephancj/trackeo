import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);

  /// Enregistre le subscription ID OneSignal pour l'utilisateur connecté.
  /// Permet au backend de cibler cet appareil via include_subscription_ids.
  Future<void> registerPushToken(String subscriptionId);
}

class RemoteAuthRepository implements AuthRepository {
  final Dio _dio;
  const RemoteAuthRepository(this._dio);

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data!);
  }

  @override
  Future<void> registerPushToken(String subscriptionId) async {
    await _dio.post<void>(
      '/auth/push-token',
      data: {'subscriptionId': subscriptionId},
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(ref.watch(dioProvider));
});
