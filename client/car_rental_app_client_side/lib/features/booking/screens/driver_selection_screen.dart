import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/booking_step.dart';
import '../providers/booking_provider.dart';
import '../widgets/cards/driver_card.dart';
import '../widgets/cards/driver_card_skeleton.dart';

class DriverSelectionScreen extends ConsumerStatefulWidget {
  const DriverSelectionScreen({super.key});

  @override
  ConsumerState<DriverSelectionScreen> createState() => _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends ConsumerState<DriverSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.driver);
    });
  }

  void _validateAndNavigate() {
    final state = ref.read(bookingFlowProvider);
    if (state.driver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please select a driver to proceed",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }

    ref.read(bookingFlowProvider.notifier).nextStep();
    context.push(AppRoutes.additionalServices);
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final driversListAsync = ref.watch(driversListProvider);

    return AppScaffold(
      title: "Driver Assignment",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select Chauffeur", style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                const Gap(4),
                Text(
                  "Choose a highly-rated verified driver to guide your trip.",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),

          // Main List Content
          Expanded(
            child: driversListAsync.when(
              data: (drivers) {
                if (drivers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.slate300),
                          const Gap(AppSpacing.sm),
                          Text("No drivers available", style: AppTextStyles.subtitle2),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  physics: const BouncingScrollPhysics(),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final isSelected = flowState.driver?.id == driver.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DriverCard(
                        driver: driver,
                        isSelected: isSelected,
                        onTap: () {
                          if (isSelected) {
                            ref.read(bookingFlowProvider.notifier).selectDriver(null);
                          } else {
                            ref.read(bookingFlowProvider.notifier).selectDriver(driver);
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: DriverCardSkeleton(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                      const Gap(AppSpacing.sm),
                      Text(
                        "Failed to load drivers",
                        style: AppTextStyles.subtitle1.copyWith(color: AppColors.error),
                      ),
                      const Gap(4),
                      Text(
                        error.toString(),
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const Gap(AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => ref.refresh(driversListProvider),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 44),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom CTA Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(bookingFlowProvider.notifier).prevStep();
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 18),
                        Gap(4),
                        Text("Back"),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _validateAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Accessories"),
                        Gap(6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
