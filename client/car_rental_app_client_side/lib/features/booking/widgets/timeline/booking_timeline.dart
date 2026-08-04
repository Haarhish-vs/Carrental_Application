import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum TripStatus {
  confirmed,
  active,
  completed,
  cancelled,
}

class BookingTimeline extends StatelessWidget {
  final TripStatus status;

  const BookingTimeline({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == TripStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.error, size: 24),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reservation Cancelled",
                    style: AppTextStyles.subtitle2.copyWith(color: AppColors.error),
                  ),
                  const Gap(2),
                  const Text(
                    "This booking was cancelled. Refund processed back to your payment mode.",
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final int activeIndex;
    switch (status) {
      case TripStatus.confirmed:
        activeIndex = 0;
        break;
      case TripStatus.active:
        activeIndex = 1;
        break;
      case TripStatus.completed:
        activeIndex = 2;
        break;
      default:
        activeIndex = 0;
    }

    final steps = [
      _TimelineStep(
        title: "Reservation Confirmed",
        description: "Your vehicle is booked and ready for release",
        time: "10:30 AM",
      ),
      _TimelineStep(
        title: "Vehicle Picked Up (Active)",
        description: "Key handed over, trip active in progress",
        time: "Pending",
      ),
      _TimelineStep(
        title: "Vehicle Returned (Completed)",
        description: "Returned to hub, security deposit released",
        time: "Pending",
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicator column
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.accent
                        : (isActive ? AppColors.primary : Colors.white),
                    border: Border.all(
                      color: isCompleted || isActive ? Colors.transparent : AppColors.slate300,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: isCompleted ? AppColors.accent : AppColors.slate200,
                  ),
              ],
            ),
            const Gap(16),

            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: isActive ? AppColors.primary : (isCompleted ? AppColors.slate800 : AppColors.slate400),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: isActive ? AppColors.slate600 : AppColors.slate400,
                      fontSize: 12,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                ],
              ),
            ),

            // Time column
            Text(
              step.time,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.accent : AppColors.slate400,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineStep {
  final String title;
  final String description;
  final String time;

  _TimelineStep({
    required this.title,
    required this.description,
    required this.time,
  });
}
