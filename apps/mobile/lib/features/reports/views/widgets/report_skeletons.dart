import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ── Activity Tab Skeleton ────────────────────────────────────────────────────

/// Skeleton for the Activity tab — 2-column grid of 6 stat cards.
class ActivityTabSkeleton extends StatelessWidget {
  const ActivityTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackeoShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: List.generate(6, (_) => const _StatCardSkeleton()),
        ),
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SkeletonCircle(size: 28),
          const SizedBox(height: 10),
          SkeletonBox(
              width: 52, height: 18, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 6),
          SkeletonBox(
              width: 72, height: 10, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}

// ── Generic Report List Skeleton ─────────────────────────────────────────────

/// Skeleton for list-based report tabs: Trip Log, Speed Violations,
/// Idle Time, and Geofence Activity.
class ReportListSkeleton extends StatelessWidget {
  final int count;

  const ReportListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return TrackeoShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const _ReportItemSkeleton(),
      ),
    );
  }
}

class _ReportItemSkeleton extends StatelessWidget {
  const _ReportItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: tag + date
          Row(
            children: [
              SkeletonBox(
                width: 72,
                height: 22,
                borderRadius: BorderRadius.circular(6),
              ),
              const Spacer(),
              SkeletonBox(
                width: 88,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Line 1 (origin)
          Row(
            children: [
              const SkeletonCircle(size: 12),
              const SizedBox(width: 8),
              SkeletonBox(
                width: 180,
                height: 11,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Line 2 (destination)
          Row(
            children: [
              const SkeletonCircle(size: 12),
              const SizedBox(width: 8),
              SkeletonBox(
                width: 150,
                height: 11,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bottom stats row
          Row(
            children: [
              SkeletonBox(
                  width: 56,
                  height: 11,
                  borderRadius: BorderRadius.circular(4)),
              const SizedBox(width: 20),
              SkeletonBox(
                  width: 48,
                  height: 11,
                  borderRadius: BorderRadius.circular(4)),
              const SizedBox(width: 20),
              SkeletonBox(
                  width: 48,
                  height: 11,
                  borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ],
      ),
    );
  }
}
