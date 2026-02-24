import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final String? error;

  const AuthState._({
    required this.status,
    this.user,
    this.token,
    this.error,
  });

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
      state = AuthState.authenticated(
        token: session.token!,
        user: AuthUser(
          id: 0,
          email: session.email!,
          name: session.name,
          role: 'user',
        ),
      );
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
        name: response.user.name,
      );
      state = AuthState.authenticated(
        token: response.accessToken,
        user: response.user,
      );
    } on DioException catch (e) {
      state = AuthState.unauthenticated(error: _parseError(e));
    } catch (_) {
      state = const AuthState.unauthenticated(error: 'Erreur inattendue');
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = const AuthState.unauthenticated();
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
