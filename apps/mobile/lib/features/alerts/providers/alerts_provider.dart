import 'dart:async';
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
  Timer? _pollTimer;

  AlertsNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
    // Polling léger : les alertes sont la donnée la plus urgente, mais une
    // cadence de 60 s suffit (pas de WebSocket en MVP). Rafraîchissement
    // silencieux pour ne pas faire clignoter la liste.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => silentRefresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Rechargement initial / explicite : passe par l'état loading (skeleton).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _repository.fetchAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Rechargement sans flash : conserve les données affichées tant que le
  /// fetch n'a pas abouti. Utilisé par le polling et le pull-to-refresh.
  Future<void> silentRefresh() async {
    try {
      final alerts = await _repository.fetchAlerts();
      if (mounted) state = AsyncValue.data(alerts);
    } catch (_) {
      // Silencieux : on garde l'état courant (données ou erreur déjà affichée).
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
      rethrow;
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
      // En cas d'erreur, on recharge l'état réel depuis le serveur.
      await refresh();
      rethrow;
    }
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<AlertModel>>>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return AlertsNotifier(repo);
});
