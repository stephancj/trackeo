import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/security_provider.dart';

class PublicTrackingView extends ConsumerWidget {
  final String token;
  const PublicTrackingView({super.key, required this.token});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      backgroundColor: AppColors.background,
      body: ref.watch(publicTrackingProvider(token)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const _Expired(),
            data: (data) {
              final vehicle = Map<String, dynamic>.from(data['vehicle'] as Map);
              final position = vehicle['position'] == null
                  ? null
                  : Map<String, dynamic>.from(vehicle['position'] as Map);
              final point = position == null
                  ? null
                  : LatLng((position['lat'] as num).toDouble(),
                      (position['lon'] as num).toDouble());
              return Stack(children: [
                if (point != null)
                  FlutterMap(
                      options:
                          MapOptions(initialCenter: point, initialZoom: 15),
                      children: [
                        TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.trackeo.client.app'),
                        MarkerLayer(markers: [
                          Marker(
                              point: point,
                              width: 54,
                              height: 54,
                              child: Container(
                                  decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle),
                                  child: const Icon(
                                      Icons.directions_car_rounded,
                                      color: Colors.white)))
                        ])
                      ])
                else
                  const Center(child: Text('Position indisponible')),
                Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 16,
                    child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 18)
                            ]),
                        child: Row(children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    vehicle['name'] as String? ??
                                        'Véhicule partagé',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17)),
                                Text(
                                    'Statut : ${vehicle['status'] ?? 'inconnu'}',
                                    style:
                                        const TextStyle(color: Colors.white70))
                              ]))
                        ])))
              ]);
            },
          ));
}

class _Expired extends StatelessWidget {
  const _Expired();
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.link_off_rounded, size: 52, color: AppColors.textHint),
            SizedBox(height: 14),
            Text('Lien expiré ou révoqué',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Demandez au propriétaire de générer un nouveau lien.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary))
          ])));
}
