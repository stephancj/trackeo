import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../devices/providers/devices_provider.dart';
import '../../devices/device_model.dart';

class MapView extends ConsumerWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackeo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(devicesProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.8566, 2.3522),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trackeo.mobile',
              ),
              devicesAsync.when(
                data: (devices) => MarkerLayer(
                  markers: devices
                      .where((d) => d.isOnline)
                      .map((d) => _buildMarker(context, d))
                      .toList(),
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),
          _DeviceListPanel(devicesAsync: devicesAsync),
        ],
      ),
    );
  }

  Marker _buildMarker(BuildContext context, Device device) {
    return Marker(
      point: const LatLng(48.8566, 2.3522), // Position mock — à remplacer par tc_positions
      width: 40,
      height: 40,
      child: Icon(
        Icons.location_on,
        color: device.isOnline ? Colors.green : Colors.grey,
        size: 36,
      ),
    );
  }
}

class _DeviceListPanel extends StatelessWidget {
  final AsyncValue<List<Device>> devicesAsync;
  const _DeviceListPanel({required this.devicesAsync});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: devicesAsync.when(
          data: (devices) => ListView.builder(
            controller: controller,
            itemCount: devices.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${devices.length} appareil(s)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              final device = devices[i - 1];
              return ListTile(
                leading: Icon(
                  Icons.gps_fixed,
                  color: device.isOnline ? Colors.green : Colors.grey,
                ),
                title: Text(device.name),
                subtitle: Text(device.uniqueId),
                trailing: Chip(
                  label: Text(device.status ?? 'unknown'),
                  backgroundColor: device.isOnline
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }
}
