import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);

  /// Enregistre le subscription ID OneSignal pour l'utilisateur connecté.
  /// Permet au backend de cibler cet appareil via include_subscription_ids.
  Future<void> registerPushToken(String subscriptionId);

  /// Met à jour le profil utilisateur (name, phone).
  Future<AuthUser> updateProfile({String? name, String? phone});

  /// Met à jour les paramètres d'alerte.
  Future<AuthUser> updateAlertSettings({
    bool? alertsEnabled,
    bool? alertSos,
    bool? alertLowBattery,
    bool? alertSpeedLimit,
    bool? alertViaPush,
    bool? alertViaWhatsapp,
  });
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

  @override
  Future<AuthUser> updateProfile({String? name, String? phone}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/profile',
      data: {if (name != null) 'name': name, if (phone != null) 'phone': phone},
    );
    return AuthUser.fromJson(response.data!);
  }

  @override
  Future<AuthUser> updateAlertSettings({
    bool? alertsEnabled,
    bool? alertSos,
    bool? alertLowBattery,
    bool? alertSpeedLimit,
    bool? alertViaPush,
    bool? alertViaWhatsapp,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/alert-settings',
      data: {
        if (alertsEnabled != null) 'alertsEnabled': alertsEnabled,
        if (alertSos != null) 'alertSos': alertSos,
        if (alertLowBattery != null) 'alertLowBattery': alertLowBattery,
        if (alertSpeedLimit != null) 'alertSpeedLimit': alertSpeedLimit,
        if (alertViaPush != null) 'alertViaPush': alertViaPush,
        if (alertViaWhatsapp != null) 'alertViaWhatsapp': alertViaWhatsapp,
      },
    );
    return AuthUser.fromJson(response.data!);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthRepository(ref.watch(dioProvider));
});
