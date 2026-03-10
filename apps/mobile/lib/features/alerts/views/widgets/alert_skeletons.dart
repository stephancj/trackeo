import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ── Geofence Carousel Skeleton ───────────────────────────────────────────────

/// Skeleton for the geofence carousel (230px tall), shown while geofences load.
class GeofenceCarouselSkeleton extends StatelessWidget {
  const GeofenceCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackeoShimmer(
      child: SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          itemBuilder: (_, __) => const _GeofenceCardSkeleton(),
        ),
      ),
    );
  }
}

class _GeofenceCardSkeleton extends StatelessWidget {
  const _GeofenceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.88;
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: circle icon + name
          Row(
            children: [
              const SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 15, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 11, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              const Spacer(),
              // Status badge
              SkeletonBox(width: 52, height: 22, borderRadius: BorderRadius.circular(11)),
            ],
          ),
          const SizedBox(height: 20),
          // Map placeholder (fake map area)
          Expanded(
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          // Bottom row: radius + vehicle
          Row(
            children: [
              SkeletonBox(width: 90, height: 11, borderRadius: BorderRadius.circular(4)),
              const Spacer(),
              SkeletonBox(width: 70, height: 11, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Alert List Skeleton ──────────────────────────────────────────────────────

/// Skeleton for the RECENT ACTIVITY list in the Alerts view.
class AlertListSkeleton extends StatelessWidget {
  final int count;

  const AlertListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return TrackeoShimmer(
      child: Column(
        children: List.generate(
          count,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? 10 : 0),
            child: const _AlertItemSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _AlertItemSkeleton extends StatelessWidget {
  const _AlertItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Left: colored icon circle
          const SkeletonCircle(size: 40),
          const SizedBox(width: 12),
          // Middle: two lines of text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  height: 13,
                  width: 160,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                SkeletonBox(
                  height: 11,
                  width: 110,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: timestamp
          SkeletonBox(
            width: 44,
            height: 11,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
