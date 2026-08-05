import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../repositories/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>(
    (ref) => SecurityRepository(ref.watch(dioProvider)));
final publicTrackingProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, token) =>
        ref.watch(securityRepositoryProvider).publicTracking(token));
