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
import '../models/booking_flow_state.dart';
import '../providers/booking_provider.dart';
import '../widgets/cards/service_card.dart';
import '../widgets/cards/service_card_skeleton.dart';
import '../utils/booking_price_calculator.dart';

class AdditionalServicesScreen extends ConsumerStatefulWidget {
  const AdditionalServicesScreen({super.key});

  @override
  ConsumerState<AdditionalServicesScreen> createState() => _AdditionalServicesScreenState();
}

class _AdditionalServicesScreenState extends ConsumerState<AdditionalServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.extras);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final servicesListAsync = ref.watch(servicesListProvider);
    
    // Live subtotal evaluation using our pricing utility
    final subtotal = BookingPriceCalculator.calculateSubtotal(flowState);

    return AppScaffold(
      title: "Additional Add-ons",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Cost Calculation Banner Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Estimated Subtotal",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      "₹${subtotal.toStringAsFixed(2)}",
                      style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 22),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${flowState.rentalDurationDays} ${flowState.rentalDurationDays == 1 ? 'Day' : 'Days'}",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Text(
              "Optional Extras",
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Services Grid/List View
          Expanded(
            child: servicesListAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.slate300),
                          const Gap(AppSpacing.sm),
                          Text("No additional services available", style: AppTextStyles.subtitle2),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  physics: const BouncingScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final isSelected = flowState.selectedServices.any((s) => s.id == service.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ServiceCard(
                        service: service,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(bookingFlowProvider.notifier).toggleService(service);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                itemCount: 4,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: ServiceCardSkeleton(),
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
                      Text("Failed to load services", style: AppTextStyles.subtitle1.copyWith(color: AppColors.error)),
                      const Gap(AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => ref.refresh(servicesListProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Buttons
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
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.slate300, width: 1.5),
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
                    onPressed: () {
                      ref.read(bookingFlowProvider.notifier).nextStep();
                      context.push(AppRoutes.bookingSummary);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Review Checkout"),
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
