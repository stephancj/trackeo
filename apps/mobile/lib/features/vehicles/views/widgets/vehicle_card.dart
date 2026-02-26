import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/providers/geocoding_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import 'battery_indicator.dart';
import 'status_badge.dart';

class VehicleCard extends ConsumerWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;

  const VehicleCard({super.key, required this.vehicle, this.onTap});

  IconData get _vehicleIcon {
    final n = vehicle.name.toLowerCase();
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
    // According to design, each vehicle has a specific color for the icon container.
    // For MVP, we can pick a color based on the type or name
    final n = vehicle.name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFFE8F0FE); // light blue
    if (n.contains('transit')) return const Color(0xFFFDF1E6); // light orange
    if (n.contains('bus')) return const Color(0xFFF3E8FD); // light purple
    if (n.contains('tesla')) return const Color(0xFFFDE8E8); // light red
    return const Color(0xFFF3F4F6); // light gray
  }

  Color get _iconColor {
    final n = vehicle.name.toLowerCase();
    if (n.contains('toyota')) return const Color(0xFF4285F4);
    if (n.contains('transit')) return const Color(0xFFE65100);
    if (n.contains('bus')) return const Color(0xFF9C27B0);
    if (n.contains('tesla')) return const Color(0xFFD32F2F);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<String?>? addressAsync;
    if (vehicle.position != null) {
      addressAsync = ref.watch(
        reverseGeocodeProvider(
          LatLng(vehicle.position!.lat, vehicle.position!.lon),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
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
              // Ligne 1 : Icon + Titre + Badge statut
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
                          vehicle.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicle.plate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: vehicle.status),
                ],
              ),
              const SizedBox(height: 20),

              // Ligne 2 : Info temporelle/Vitesse + Batterie
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        vehicle.status == VehicleStatus.online
                            ? Icons.speed
                            : Icons.schedule,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            if (vehicle.status == VehicleStatus.online &&
                                vehicle.position != null)
                              TextSpan(
                                text: '${vehicle.position!.speedKmh.toInt()} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            TextSpan(
                              text: vehicle.status == VehicleStatus.online
                                  ? 'km/h'
                                  : vehicle.status == VehicleStatus.idle
                                  ? vehicle.lastUpdate != null
                                        ? '${timeago.format(vehicle.lastUpdate!).replaceAll(' ago', '')} stopped'
                                        : 'Stopped'
                                  : vehicle.lastUpdate != null
                                  ? 'Seen ${timeago.format(vehicle.lastUpdate!)}'
                                  : 'Offline',
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
                  BatteryIndicator(battery: vehicle.position?.battery ?? 0),
                ],
              ),

              const SizedBox(height: 12),

              // Ligne 3: Adresse
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
                                  vehicle.position?.address ??
                                  'Location unknown',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => const Text(
                              'Resolving location...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                            error: (_, __) => const Text(
                              'Location unknown',
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
    );
  }
}
