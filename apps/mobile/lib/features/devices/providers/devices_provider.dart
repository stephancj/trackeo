import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/device_repository.dart';
import '../device_model.dart';

final devicesProvider = FutureProvider<List<Device>>((ref) {
  return ref.watch(deviceRepositoryProvider).getDevices();
});

final selectedDeviceProvider = StateProvider<Device?>((ref) => null);
