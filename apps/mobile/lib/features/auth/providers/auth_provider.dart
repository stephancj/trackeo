import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/platform/onesignal_login.dart';
import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final String? error;

  const AuthState._({required this.status, this.user, this.token, this.error});

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.unauthenticated({String? error})
    : this._(status: AuthStatus.unauthenticated, error: error);

  AuthState.authenticated({required String token, required AuthUser user})
    : this._(status: AuthStatus.authenticated, token: token, user: user);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState.loading()) {
    _tryRestoreSession();
  }

  final AuthRepository _repo;

  /// Restaure la session depuis le localStorage (web) / SharedPreferences
  Future<void> _tryRestoreSession() async {
    final session = await TokenStorage.getSession();
    if (session.token != null && session.email != null) {
      final user = AuthUser(
        id: session.userId ?? 0,
        email: session.email!,
        name: session.name,
        phone: session.phone,
        role: 'user',
      );
      state = AuthState.authenticated(token: session.token!, user: user);
      // Ré-enregistre l'utilisateur dans OneSignal après redémarrage de l'app
      if (user.id != 0) _linkOneSignal(user.id);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final response = await _repo.login(email, password);
      await TokenStorage.saveSession(
        token: response.accessToken,
        email: response.user.email,
        userId: response.user.id,
        name: response.user.name,
        phone: response.user.phone,
      );
      state = AuthState.authenticated(
        token: response.accessToken,
        user: response.user,
      );
      _linkOneSignal(response.user.id);
    } on DioException catch (e) {
      state = AuthState.unauthenticated(error: _parseError(e));
    } catch (_) {
      state = const AuthState.unauthenticated(error: 'Erreur inattendue');
    }
  }

  Future<void> logout() async {
    await OneSignal.logout(); // Détache l'utilisateur (mobile)
    oneSignalLogoutPlatform(); // Détache l'utilisateur (web JS direct)
    await TokenStorage.clear();
    state = const AuthState.unauthenticated();
  }

  /// Lie cet utilisateur à OneSignal pour recevoir les push ciblés.
  void _linkOneSignal(int userId) {
    OneSignal.login(userId.toString()); // mobile (natif)
    oneSignalLoginPlatform(
      userId.toString(),
    ); // web (JS direct — le plugin ne bridge pas login sur web)
    _tryRegisterPushToken(); // Enregistre le subscription ID côté backend (fire & forget)
  }

  /// Met à jour le profil utilisateur (name, phone).
  Future<void> updateProfile({String? name, String? phone}) async {
    final updatedUser = await _repo.updateProfile(name: name, phone: phone);
    state = AuthState.authenticated(token: state.token!, user: updatedUser);
    await TokenStorage.saveSession(
      token: state.token!,
      email: updatedUser.email,
      userId: updatedUser.id,
      name: updatedUser.name,
      phone: updatedUser.phone,
    );
  }

  /// Met à jour les paramètres d'alerte.
  Future<void> updateAlertSettings({
    bool? alertsEnabled,
    bool? alertSos,
    bool? alertLowBattery,
    bool? alertSpeedLimit,
    bool? alertViaPush,
    bool? alertViaWhatsapp,
  }) async {
    final updatedUser = await _repo.updateAlertSettings(
      alertsEnabled: alertsEnabled,
      alertSos: alertSos,
      alertLowBattery: alertLowBattery,
      alertSpeedLimit: alertSpeedLimit,
      alertViaPush: alertViaPush,
      alertViaWhatsapp: alertViaWhatsapp,
    );
    state = AuthState.authenticated(token: state.token!, user: updatedUser);
  }

  /// Lit le subscription ID OneSignal (web) et l'enregistre côté backend.
  /// Attend 3s pour laisser le SDK OneSignal finir son initialisation.
  /// Fire & forget — les erreurs sont ignorées silencieusement.
  Future<void> _tryRegisterPushToken() async {
    // Attente : OneSignal init + login peuvent être asynchrones
    await Future.delayed(const Duration(seconds: 3));

    final subId = getOneSignalSubId(); // null sur mobile (stub no-op)
    if (subId == null || subId.isEmpty) return;

    try {
      await _repo.registerPushToken(subId);
    } catch (_) {
      // Best-effort — la prochaine ouverture de session réessaiera
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Email ou mot de passe incorrect';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
