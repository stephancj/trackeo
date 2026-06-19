import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/alert_model.dart';
import 'widgets/alert_trace_map.dart';

/// Plein écran montrant où une alerte s'est produite. Pour un excès de vitesse,
/// trace le segment GPS coloré par vitesse (rouge = excès) ; sinon, une épingle.
class AlertLocationView extends StatelessWidget {
  final AlertModel alert;
  final String title;
  final Color color;
  final IconData icon;

  const AlertLocationView({
    super.key,
    required this.alert,
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isSpeed = alert.type == 'speed_limit';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AlertTraceMap(
              alert: alert,
              color: color,
              icon: icon,
              interactive: true,
            ),
          ),

          // Bouton retour
          Positioned(
            top: topPad + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: AppColors.primaryDark),
              ),
            ),
          ),

          // Légende vitesse (excès uniquement)
          if (isSpeed)
            Positioned(
              top: topPad + 8,
              right: 16,
              child: const SpeedTraceLegend(),
            ),

          // Carte d'info en bas
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + bottomPad,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (alert.message != null &&
                            alert.message!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            alert.message!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
