import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

/// Skeleton placeholder that matches the layout of [VehicleCard] exactly.
/// Wrap a list of these in [TrackeoShimmer] for the sweep animation.
class VehicleCardSkeleton extends StatelessWidget {
  const VehicleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: circle icon + name/plate + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonCircle(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 140,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      SkeletonBox(
                        width: 90,
                        height: 11,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                // Status badge
                SkeletonBox(
                  width: 62,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Row 2: speed/time + battery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(
                  width: 110,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                SkeletonBox(
                  width: 56,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 3: address (full width)
            SkeletonBox(
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shimmer-wrapped list of [VehicleCardSkeleton] — drop-in replacement for
/// the fleet list loading state.
class VehicleListSkeleton extends StatelessWidget {
  final int count;

  const VehicleListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return TrackeoShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, __) => const VehicleCardSkeleton(),
      ),
    );
  }
}
