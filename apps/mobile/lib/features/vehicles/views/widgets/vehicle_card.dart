import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';
import 'battery_indicator.dart';
import 'status_badge.dart';

class VehicleCard extends StatelessWidget {
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
      return Icons.two_wheeler;
    }
    return Icons.directions_car;
  }

  Color get _statusColor => switch (vehicle.status) {
        VehicleStatus.online => AppColors.statusOnline,
        VehicleStatus.idle => AppColors.statusIdle,
        VehicleStatus.offline => AppColors.statusOffline,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barre colorée de statut à gauche
              Container(width: 4, color: _statusColor),

              // Icône véhicule
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_vehicleIcon, color: _statusColor, size: 22),
                ),
              ),

              // Contenu principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12, right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom + Badge statut
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: vehicle.status),
                        ],
                      ),

                      // Immatriculation
                      const SizedBox(height: 2),
                      Text(
                        vehicle.plate,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),

                      // Vitesse + Batterie
                      if (vehicle.position != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.speed,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              '${vehicle.position!.speedKmh.toInt()} km/h',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 14),
                            BatteryIndicator(battery: vehicle.position!.battery),
                          ],
                        ),
                      ],

                      // Adresse
                      if (vehicle.position?.address != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 11, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                vehicle.position!.address!,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textHint),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
