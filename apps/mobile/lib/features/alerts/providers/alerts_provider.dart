import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../repositories/alert_repository.dart';
import '../models/alert_model.dart';

final alertRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AlertRepository(dio);
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<AlertModel>>> {
  final AlertRepository _repository;

  AlertsNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _repository.fetchAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<AlertModel>>>((ref) {
      final repo = ref.watch(alertRepositoryProvider);
      return AlertsNotifier(repo);
    });
