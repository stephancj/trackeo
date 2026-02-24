import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../device_model.dart';

abstract class DeviceRepository {
  Future<List<Device>> getDevices();
  Future<Device> getDevice(int id);
}

class RemoteDeviceRepository implements DeviceRepository {
  final Dio _dio;
  const RemoteDeviceRepository(this._dio);

  @override
  Future<List<Device>> getDevices() async {
    final response = await _dio.get<List<dynamic>>('/devices');
    return (response.data ?? [])
        .map((json) => Device.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Device> getDevice(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/devices/$id');
    return Device.fromJson(response.data!);
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return RemoteDeviceRepository(ref.watch(dioProvider));
});
