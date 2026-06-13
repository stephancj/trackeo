import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/providers/geocoding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import 'battery_indicator.dart';
import 'status_badge.dart';

class VehicleCard extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  @override
  ConsumerState<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends ConsumerState<VehicleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.967).animate(
      CurvedAnimation(parent: _press, curve: AppMotion.quint),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  IconData get _vehicleIcon {
    final n = widget.vehicle.name.toLowerCase();
    if (n.contains('bus') || n.contains('school')) return Icons.directions_bus;
    if (n.contains('truck') || n.contains('transit') || n.contains('van')) {
      return Icons.local_shipping;
    }
    if (n.contains('moto') || n.contains('pcx') || n.contains('bike')) {
      return Icons.pedal_bike;
    }
    return Icons.directions_car;
  }

  Color get _iconBgColor {
    final n = widget.vehicle.name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFFE8F0FE);
    if (n.contains('transit')) return const Color(0xFFFDF1E6);
    if (n.contains('bus')) return const Color(0xFFF3E8FD);
    if (n.contains('tesla')) return const Color(0xFFFDE8E8);
    return const Color(0xFFF3F4F6);
  }

  Color get _iconColor {
    final n = widget.vehicle.name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFF4285F4);
    if (n.contains('transit')) return const Color(0xFFE65100);
    if (n.contains('bus')) return const Color(0xFF9C27B0);
    if (n.contains('tesla')) return const Color(0xFFD32F2F);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context, ) {
    AsyncValue<String?>? addressAsync;
    if (widget.vehicle.position != null) {
      addressAsync = ref.watch(
        reverseGeocodeProvider(
          LatLng(widget.vehicle.position!.lat, widget.vehicle.position!.lon),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_vehicleIcon, color: _iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vehicle.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.vehicle.plate ?? widget.vehicle.serialNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: widget.vehicle.status),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.vehicle.status == VehicleStatus.online
                              ? Icons.speed
                              : Icons.schedule,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            children: [
                              if (widget.vehicle.status == VehicleStatus.online &&
                                  widget.vehicle.position != null)
                                TextSpan(
                                  text:
                                      '${widget.vehicle.position!.speedKmh.toInt()} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              TextSpan(
                                text: widget.vehicle.status ==
                                        VehicleStatus.online
                                    ? 'km/h'
                                    : widget.vehicle.status ==
                                            VehicleStatus.idle
                                        ? widget.vehicle.lastUpdate != null
                                            ? 'Arrêté ${timeago.format(widget.vehicle.lastUpdate!, locale: 'fr')}'
                                            : 'Arrêté'
                                        : widget.vehicle.lastUpdate != null
                                            ? 'Inactif ${timeago.format(widget.vehicle.lastUpdate!, locale: 'fr')}'
                                            : 'Hors ligne',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    BatteryIndicator(
                        battery: widget.vehicle.position?.battery ?? 0),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: addressAsync != null
                          ? addressAsync.when(
                              data: (address) => Text(
                                address ??
                                    widget.vehicle.position?.address ??
                                    'Position inconnue',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const Text(
                                'Localisation...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                              error: (_, __) => const Text(
                                'Position inconnue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            )
                          : const Text(
                              'Location unknown',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
