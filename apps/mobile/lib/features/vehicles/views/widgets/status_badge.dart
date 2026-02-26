import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';

class StatusBadge extends StatelessWidget {
  final VehicleStatus status;

  const StatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
    VehicleStatus.online => AppColors.statusOnline,
    VehicleStatus.idle => AppColors.statusIdle,
    VehicleStatus.offline => AppColors.statusOffline,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
