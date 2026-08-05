import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../models/booking_step.dart';

class BookingProgressIndicator extends StatelessWidget {
  final BookingStep currentStep;

  const BookingProgressIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    // Map active step enum to 5 logical progress milestones
    final int activeMilestone;
    switch (currentStep) {
      case BookingStep.vehicle:
      case BookingStep.pickup:
        activeMilestone = 0;
        break;
      case BookingStep.driver:
        activeMilestone = 1;
        break;
      case BookingStep.extras:
        activeMilestone = 2;
        break;
      case BookingStep.summary:
      case BookingStep.payment:
        activeMilestone = 3;
        break;
      case BookingStep.success:
        activeMilestone = 4;
        break;
    }

    final milestones = [
      'Vehicle',
      'Pickup',
      'Extras',
      'Payment',
      'Confirmed',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.slate200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double dotSize = 24.0;
            final int totalSteps = milestones.length;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Line (Inactive)
                    Positioned(
                      left: dotSize / 2,
                      right: dotSize / 2,
                      child: Container(
                        height: 2,
                        color: AppColors.slate200,
                      ),
                    ),
                    // Active Line
                    Positioned(
                      left: dotSize / 2,
                      right: dotSize / 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: 2.5,
                          width: (width - dotSize) * (activeMilestone / (totalSteps - 1)),
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    // Step Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(totalSteps, (index) {
                        final isCompleted = index < activeMilestone;
                        final isActive = index == activeMilestone;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.accent
                                : (isActive ? AppColors.primary : Colors.white),
                            border: Border.all(
                              color: isCompleted || isActive
                                  ? Colors.transparent
                                  : AppColors.slate300,
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.15),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : (isActive
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.slate500,
                                        ),
                                      )),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Text Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(totalSteps, (index) {
                    final isActive = index == activeMilestone;
                    final isCompleted = index < activeMilestone;

                    return SizedBox(
                      width: width / totalSteps,
                      child: Text(
                        milestones[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary
                              : (isCompleted ? AppColors.slate700 : AppColors.slate400),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
