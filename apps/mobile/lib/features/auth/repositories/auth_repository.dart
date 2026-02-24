import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(ref.watch(dioProvider));
});
