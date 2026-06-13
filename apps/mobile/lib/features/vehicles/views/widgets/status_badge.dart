import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/vehicle_model.dart';

class StatusBadge extends StatefulWidget {
  final VehicleStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse(); // (re)lit la préférence motion réduit après le 1er layout
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  /// Anime le halo uniquement si le véhicule est "online" ET que l'utilisateur
  /// n'a pas demandé de réduire les animations (WCAG).
  void _syncPulse() {
    final shouldPulse =
        widget.status == VehicleStatus.online && !AppMotion.reduce(context);
    if (shouldPulse) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.status) {
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
          SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.status == VehicleStatus.online)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Transform.scale(
                      scale: _scale.value,
                      child: Opacity(
                        opacity: _opacity.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _color, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.status.label,
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
