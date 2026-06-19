import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_shell.dart';
import '../../../../core/navigation/trackeo_route.dart';
import '../../../vehicles/providers/vehicles_provider.dart';
import '../../models/alert_model.dart';
import '../../providers/alerts_provider.dart';
import '../alert_location_view.dart';

class AlertDetailSheet extends ConsumerStatefulWidget {
  final AlertModel alert;

  const AlertDetailSheet({super.key, required this.alert});

  /// Ouvre la fiche détail d'une alerte en bottom sheet.
  /// Si l'alerte est "open", elle est automatiquement acquittée à l'ouverture.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    AlertModel alert,
  ) {
    // Acquittement immédiat si l'alerte est non lue (optimiste)
    if (alert.status == 'open') {
      ref.read(alertsProvider.notifier).ackAlert(alert.id);
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlertDetailSheet(alert: alert),
    );
  }

  @override
  ConsumerState<AlertDetailSheet> createState() => _AlertDetailSheetState();
}

class _AlertDetailSheetState extends ConsumerState<AlertDetailSheet> {
  bool _isAcking = false;

  /// Lit l'alerte depuis le provider pour refléter les mises à jour optimistes.
  AlertModel get _alert {
    final current = ref.watch(alertsProvider).valueOrNull;
    if (current == null) return widget.alert;
    return current.firstWhere(
      (a) => a.id == widget.alert.id,
      orElse: () => widget.alert,
    );
  }

  /// Nom du véhicule lié à l'alerte (via deviceId), ou null si introuvable.
  String? get _vehicleName {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull;
    if (vehicles == null) return null;
    for (final v in vehicles) {
      if (v.id == _alert.deviceId) return v.name;
    }
    return null;
  }

  /// Montre l'alerte sur la carte. Si elle porte une position (ex. lieu de
  /// l'excès), ouvre le plein écran à cet endroit exact ; sinon, repli sur la
  /// carte live centrée sur le véhicule.
  void _openOnMap() {
    final a = _alert;
    if (a.hasLocation) {
      Navigator.of(context).push(
        TrackeoRoute(
          builder: (_) => AlertLocationView(
            lat: a.lat!,
            lon: a.lon!,
            title: _title,
            subtitle: a.message,
            color: _color,
            icon: _icon,
          ),
        ),
      );
      return;
    }
    ref.read(selectedVehicleIdProvider.notifier).state = a.deviceId;
    ref.read(activeTabProvider.notifier).state = 1; // onglet Carte
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Mini-carte (lecture seule) montrant le lieu de l'alerte, tap → plein écran.
  Widget _buildMiniMap(AlertModel a) {
    final point = LatLng(a.lat!, a.lon!);
    return GestureDetector(
      onTap: _openOnMap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 150,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: AppMapTiles.positron,
                    subdomains: AppMapTiles.subdomains,
                    retinaMode: true,
                    userAgentPackageName: 'mg.trackeo.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(_icon, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Indice "agrandir"
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full_rounded,
                          size: 13, color: AppColors.primaryDark),
                      SizedBox(width: 5),
                      Text(
                        'Agrandir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _color {
    switch (_alert.type) {
      case 'geofence_enter':
        return Colors.green;
      case 'geofence_exit':
        return Colors.orange;
      case 'low_battery':
        return AppColors.batteryLow;
      case 'speed_limit':
        return AppColors.statusAlert;
      default:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (_alert.type) {
      case 'geofence_enter':
        return Icons.login_rounded;
      case 'geofence_exit':
        return Icons.logout_rounded;
      case 'low_battery':
        return Icons.battery_alert_rounded;
      case 'speed_limit':
        return Icons.speed_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String get _title {
    switch (_alert.type) {
      case 'geofence_enter':
        return 'Entrée dans la zone';
      case 'geofence_exit':
        return 'Sortie de la zone';
      case 'low_battery':
        return 'Batterie faible';
      case 'speed_limit':
        return 'Excès de vitesse';
      default:
        return _alert.type;
    }
  }

  String get _typeLabel {
    switch (_alert.type) {
      case 'geofence_enter':
        return 'Geofence · Entrée';
      case 'geofence_exit':
        return 'Geofence · Sortie';
      case 'low_battery':
        return 'Batterie';
      case 'speed_limit':
        return 'Vitesse';
      default:
        return _alert.type;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan.',
      'fév.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sep.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final d = dt.toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} · $h:$m';
  }

  Future<void> _ack() async {
    setState(() => _isAcking = true);
    await ref.read(alertsProvider.notifier).ackAlert(_alert.id);
    setState(() => _isAcking = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _alert.status == 'open';
    final color = _color;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ─────────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Icon ───────────────────────────────────────────────────────────
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: color, size: 38),
          ),
          const SizedBox(height: 16),

          // ── Title + status badge ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isOpen) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Nouveau',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // ── Type label + date ──────────────────────────────────────────────
          Text(
            _typeLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDate(_alert.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),

          if (_vehicleName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _vehicleName!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Mini-carte (lieu de l'alerte) ──────────────────────────────────
          if (_alert.hasLocation) ...[
            _buildMiniMap(_alert),
            const SizedBox(height: 16),
          ],

          // ── Message card ───────────────────────────────────────────────────
          if (_alert.message != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DÉTAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _alert.message!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Actions ────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openOnMap,
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text(
                'Voir sur la carte',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (isOpen) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isAcking ? null : _ack,
                icon: _isAcking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      )
                    : const Icon(Icons.done_rounded, size: 18),
                label: const Text(
                  'Marquer comme lu',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.withValues(alpha: 0.8), size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Lu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
