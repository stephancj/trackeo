import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../repositories/geofence_repository.dart';
import '../models/geofence_model.dart';

final geofenceRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return GeofenceRepository(dio);
});

class GeofencesNotifier extends StateNotifier<AsyncValue<List<Geofence>>> {
  final GeofenceRepository _repository;

  GeofencesNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final geofences = await _repository.fetchGeofences();
      state = AsyncValue.data(geofences);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Geofence?> createGeofence(Map<String, dynamic> payload) async {
    try {
      final geofence = await _repository.createGeofence(payload);
      if (state is AsyncData) {
        state = AsyncValue.data([...state.value!, geofence]);
      } else {
        await refresh();
      }
      return geofence;
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleGeofence(Geofence geofence, bool isActive) async {
    final previousState = state;
    if (state is AsyncData) {
      state = AsyncValue.data(
        state.value!
            .map(
              (e) => e.id == geofence.id
                  ? Geofence(
                      id: e.id,
                      name: e.name,
                      deviceIds: e.deviceIds,
                      centerLat: e.centerLat,
                      centerLon: e.centerLon,
                      radiusM: e.radiusM,
                      isActive: isActive,
                      userId: e.userId,
                    )
                  : e,
            )
            .toList(),
      );
    }
    try {
      await _repository.updateGeofence(geofence.id, {'isActive': isActive});
    } catch (e) {
      state = previousState;
    }
  }
}

final geofencesProvider =
    StateNotifierProvider<GeofencesNotifier, AsyncValue<List<Geofence>>>((ref) {
      final repo = ref.watch(geofenceRepositoryProvider);
      return GeofencesNotifier(repo);
    });
