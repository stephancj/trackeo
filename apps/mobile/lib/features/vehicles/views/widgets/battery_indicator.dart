import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BatteryIndicator extends StatelessWidget {
  final int? battery;
  final bool? charging;

  const BatteryIndicator({super.key, this.battery, this.charging});

  Color _color(int pct) {
    if (pct <= 20) return AppColors.batteryLow;
    if (pct <= 50) return AppColors.batteryMedium;
    return AppColors.batteryGood;
  }

  IconData _icon(int pct, bool isCharging) {
    if (isCharging) return Icons.battery_charging_full;
    if (pct <= 20) return Icons.battery_alert;
    if (pct <= 50) return Icons.battery_3_bar;
    return Icons.battery_full;
  }

  @override
  Widget build(BuildContext context) {
    if (battery == null) return const SizedBox.shrink();
    final isCharging = charging == true;
    final color = isCharging ? AppColors.batteryGood : _color(battery!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(battery!, isCharging), size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          '${battery!}%',
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
