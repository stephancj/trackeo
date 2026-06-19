import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_track_provider.dart';
import '../../../vehicles/models/vehicle_model.dart';

/// Seuil d'excès (doit refléter SPEED_LIMIT_KMH côté backend).
const double kSpeedLimitKmh = 120;

/// Couleur d'un point selon sa vitesse (km/h) — même palette que l'historique.
Color speedColor(double kmh) {
  if (kmh < 5) return const Color(0xFF9CA3AF); // arrêté → gris
  if (kmh < 30) return const Color(0xFF4ECB8D); // lent   → vert
  if (kmh < 70) return const Color(0xFF5B8DEF); // urbain → bleu
  if (kmh < 100) return const Color(0xFFF59E0B); // route  → orange
  return const Color(0xFFEF4444); // excès  → rouge
}

/// Carte traçant le segment GPS autour d'une alerte (fenêtre ±5 min), coloré
/// par vitesse — le rouge matérialise l'excès. Repli sur un simple marqueur si
/// l'alerte n'a pas de trace (autre type) ou si l'historique est vide.
class AlertTraceMap extends ConsumerStatefulWidget {
  final AlertModel alert;
  final Color color;
  final IconData icon;
  final bool interactive;

  const AlertTraceMap({
    super.key,
    required this.alert,
    required this.color,
    required this.icon,
    this.interactive = true,
  });

  @override
  ConsumerState<AlertTraceMap> createState() => _AlertTraceMapState();
}

class _AlertTraceMapState extends ConsumerState<AlertTraceMap> {
  final _map = MapController();
  static const _window = Duration(minutes: 5);

  // Évite de refit la caméra à chaque rebuild (un fit par jeu de données).
  int _fittedFor = -1;

  AlertTrackKey? get _trackKey {
    final a = widget.alert;
    if (a.type != 'speed_limit') return null; // trace réservée aux excès
    final from = a.createdAt.subtract(_window).millisecondsSinceEpoch;
    final to = a.createdAt.add(_window).millisecondsSinceEpoch;
    return (a.deviceId, from, to);
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = _trackKey;
    final focal = widget.alert.hasLocation
        ? LatLng(widget.alert.lat!, widget.alert.lon!)
        : null;

    if (key == null) {
      return _buildMap(const [], focal);
    }
    final trackAsync = ref.watch(alertTrackProvider(key));
    return trackAsync.when(
      data: (positions) => _buildMap(positions, focal),
      loading: () => const ColoredBox(
        color: Color(0xFFEDEEF0),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      error: (_, __) => _buildMap(const [], focal),
    );
  }

  Widget _buildMap(List<VehiclePosition> positions, LatLng? focal) {
    final pts = positions.map((p) => LatLng(p.lat, p.lon)).toList();
    final speeding = [
      for (final p in positions)
        if (p.speedKmh > kSpeedLimitKmh) LatLng(p.lat, p.lon),
    ];

    // Cible de cadrage : priorité au segment en excès, sinon toute la trace,
    // sinon le point focal.
    final List<LatLng> fitTarget = speeding.length >= 2
        ? speeding
        : (pts.length >= 2 ? pts : [if (focal != null) focal]);

    if (fitTarget.isNotEmpty) {
      final sig = Object.hash(fitTarget.length, fitTarget.first, fitTarget.last);
      if (sig != _fittedFor) {
        _fittedFor = sig;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fit(fitTarget));
      }
    }

    final center = focal ?? (pts.isNotEmpty ? pts.first : _fallbackCenter);

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: AppMapTiles.positron,
          subdomains: AppMapTiles.subdomains,
          retinaMode: true,
          userAgentPackageName: 'mg.trackeo.app',
        ),
        if (pts.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: pts,
                strokeWidth: 5,
                gradientColors:
                    positions.map((p) => speedColor(p.speedKmh)).toList(),
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        MarkerLayer(markers: _markers(pts, focal)),
      ],
    );
  }

  List<Marker> _markers(List<LatLng> pts, LatLng? focal) {
    final markers = <Marker>[];
    if (pts.length >= 2) {
      markers.add(_dot(pts.first, AppColors.primary)); // départ du segment
      markers.add(_dot(pts.last, const Color(0xFF6B7280))); // fin du segment
    }
    // Épingle de l'alerte (lieu où l'excès a été détecté).
    if (focal != null) {
      markers.add(
        Marker(
          point: focal,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
        ),
      );
    }
    return markers;
  }

  Marker _dot(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 16,
      height: 16,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }

  void _fit(List<LatLng> points) {
    if (!mounted || points.isEmpty) return;
    if (points.length == 1) {
      _map.move(points.first, 16);
      return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  static const _fallbackCenter = LatLng(-18.9137, 47.5361);
}

/// Légende compacte de la palette de vitesse (pour le plein écran).
class SpeedTraceLegend extends StatelessWidget {
  const SpeedTraceLegend({super.key});

  static const _entries = [
    (color: Color(0xFF4ECB8D), label: '< 30'),
    (color: Color(0xFF5B8DEF), label: '30–70'),
    (color: Color(0xFFF59E0B), label: '70–100'),
    (color: Color(0xFFEF4444), label: '> 100'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in _entries) ...[
            Container(
              width: 14,
              height: 5,
              decoration: BoxDecoration(
                color: e.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              e.label,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            ),
            const SizedBox(width: 10),
          ],
          const Text(
            'km/h',
            style: TextStyle(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
