import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/day_activity_model.dart';
import '../../providers/history_provider.dart';

/// Bottom sheet calendrier d'activité : pour chaque jour, un point indique s'il
/// y a eu du mouvement (et son intensité). L'utilisateur choisit une date en
/// sachant où il y a eu de l'activité, au lieu de deviner.
///
/// Renvoie via `Navigator.pop` la `DateTime` choisie (jour, sans heure), ou
/// `null` si fermé sans sélection.
class ActivityCalendarSheet extends ConsumerStatefulWidget {
  final int vehicleId;
  final DateTime selectedDate;

  const ActivityCalendarSheet({
    super.key,
    required this.vehicleId,
    required this.selectedDate,
  });

  @override
  ConsumerState<ActivityCalendarSheet> createState() =>
      _ActivityCalendarSheetState();
}

class _ActivityCalendarSheetState extends ConsumerState<ActivityCalendarSheet> {
  late DateTime _month; // 1er du mois affiché

  static const _monthNames = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    return _month.isBefore(thisMonth);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Color _dotColor(ActivityLevel level) => switch (level) {
        ActivityLevel.high => const Color(0xFF2C9B68),
        ActivityLevel.medium => AppColors.primary,
        ActivityLevel.low => AppColors.primary.withValues(alpha: 0.45),
        ActivityLevel.none => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(
      activeDaysProvider((widget.vehicleId, _month.year, _month.month)),
    );
    final days = daysAsync.valueOrNull ?? const <DayActivity>[];
    final byDay = {
      for (final d in days)
        if (d.date.year == _month.year && d.date.month == _month.month)
          d.date.day: d,
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday - 1;

    final activeCount = days.where((d) => d.hasMovement).length;
    final totalKm = days.fold<double>(0, (s, d) => s + d.distanceKm);

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          activity: byDay[day],
          dotColor: _dotColor(byDay[day]?.level ?? ActivityLevel.none),
          isSelected: widget.selectedDate.year == _month.year &&
              widget.selectedDate.month == _month.month &&
              widget.selectedDate.day == day,
          isToday: today.year == _month.year &&
              today.month == _month.month &&
              today.day == day,
          isFuture: DateTime(_month.year, _month.month, day).isAfter(today),
          onTap: () => Navigator.pop(
            context,
            DateTime(_month.year, _month.month, day),
          ),
        ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // En-tête : navigation mois + résumé
            Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_monthNames[_month.month - 1]} ${_month.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 16,
                        child: daysAsync.isLoading
                            ? const _LoadingSummary()
                            : Text(
                                activeCount == 0
                                    ? 'Aucune activité ce mois'
                                    : '$activeCount jour${activeCount > 1 ? 's' : ''} actif${activeCount > 1 ? 's' : ''} · ${totalKm.round()} km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _canGoNext ? () => _shiftMonth(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Jours de la semaine
            Row(
              children: _weekdays
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Grille
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.84,
              children: cells,
            ),
            const SizedBox(height: 14),

            // Légende
            const _Legend(),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DayActivity? activity;
  final Color dotColor;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.activity,
    required this.dotColor,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDot = (activity?.hasMovement ?? false);

    Color numColor;
    if (isSelected) {
      numColor = AppColors.primaryDark;
    } else if (isFuture) {
      numColor = AppColors.textHint.withValues(alpha: 0.5);
    } else if (!hasDot) {
      numColor = AppColors.textHint;
    } else {
      numColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.quint,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: numColor,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasDot
                      ? (isSelected
                          ? AppColors.primaryDark.withValues(alpha: 0.8)
                          : dotColor)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.primaryDark : AppColors.textHint,
        ),
      ),
    );
  }
}

class _LoadingSummary extends StatelessWidget {
  const _LoadingSummary();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 11,
          height: 11,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Analyse de l\'activité…',
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(AppColors.primary.withValues(alpha: 0.45), 'Faible'),
        _legendItem(AppColors.primary, 'Moyenne'),
        _legendItem(const Color(0xFF2C9B68), 'Élevée'),
        _legendItem(AppColors.divider, 'Aucun mouvement'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
