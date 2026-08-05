import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../models/report_models.dart';
import '../repositories/reports_repository.dart';

class TripPlaybackView extends ConsumerStatefulWidget {
  final TripLogEntry trip;
  const TripPlaybackView({super.key, required this.trip});
  @override
  ConsumerState<TripPlaybackView> createState() => _TripPlaybackViewState();
}

class _TripPlaybackViewState extends ConsumerState<TripPlaybackView> {
  TripLogEntry? loaded;
  double progress = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.trip.id == null) return;
    final value =
        await ref.read(reportsRepositoryProvider).getPlayback(widget.trip.id!);
    if (mounted) setState(() => loaded = value);
  }

  @override
  Widget build(BuildContext context) {
    final trip = loaded ?? widget.trip;
    final points = trip.path.map((p) => LatLng(p.lat, p.lon)).toList();
    final index = points.isEmpty ? 0 : (progress * (points.length - 1)).round();
    return Scaffold(
        appBar: AppBar(title: const Text('Playback du trajet')),
        body: points.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                Expanded(
                    child: FlutterMap(
                        options: MapOptions(
                            initialCenter: points.first, initialZoom: 13),
                        children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.trackeo.client.app'),
                      PolylineLayer(polylines: [
                        Polyline(
                            points: points,
                            strokeWidth: 5,
                            color: AppColors.primary)
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                            point: points[index],
                            width: 48,
                            height: 48,
                            child: Container(
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryDark),
                                child: const Icon(Icons.directions_car_rounded,
                                    color: Colors.white)))
                      ])
                    ])),
                Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    child: Column(children: [
                      Slider(
                          value: progress,
                          onChanged: (v) => setState(() => progress = v)),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(progress * 100).round()} %',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '${trip.distanceKm.toStringAsFixed(1)} km · ${trip.durationMin} min')
                          ])
                    ]))
              ]));
  }
}
