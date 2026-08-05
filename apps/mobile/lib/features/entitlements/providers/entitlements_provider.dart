import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/entitlements_model.dart';

final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Map<String, dynamic>>('/auth/entitlements');
  return Entitlements.fromJson(response.data!);
});
