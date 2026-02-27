import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

/// URL de base — pointer vers localhost en dev, domaine VPS en prod.
// const String kBaseUrl = 'http://localhost:3000/api';

// String _deriveBaseUrl() {
//   if (kIsWeb) {
//     // Récupère l'IP ou le nom d'hôte présent dans la barre d'adresse
//     final host = html.window.location.hostname;
//     if (host != 'localhost' && host != '127.0.0.1') {
//       return 'http://$host:3000/api';
//     }
//   }
//   return 'http://localhost:3000/api';
// }
// final String kBaseUrl = _deriveBaseUrl();

const String kBaseUrl = 'http://192.168.88.69:3000/api';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Intercepteur JWT — injecte le token Bearer à chaque requête
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
