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

  /// Marque toutes les alertes comme lues (mise à jour optimiste, sans flash loading).
  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.map((a) => a.copyWith(status: 'acked')).toList(),
      );
    }
    try {
      await _repository.markAllRead();
    } catch (_) {
      await refresh();
    }
  }

  /// Acquitte une alerte avec mise à jour optimiste immédiate.
  Future<void> ackAlert(String alertId) async {
    // Mise à jour optimiste : on marque localement sans recharger
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current
            .map((a) => a.id == alertId ? a.copyWith(status: 'acked') : a)
            .toList(),
      );
    }
    try {
      await _repository.ackAlert(alertId);
    } catch (_) {
      // En cas d'erreur, on recharge l'état réel depuis le serveur
      await refresh();
    }
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<AlertModel>>>((ref) {
      final repo = ref.watch(alertRepositoryProvider);
      return AlertsNotifier(repo);
    });
