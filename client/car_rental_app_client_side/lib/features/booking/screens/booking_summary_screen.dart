import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/booking_step.dart';
import '../models/booking_flow_state.dart';
import '../providers/booking_provider.dart';
import '../widgets/cards/price_card.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.summary);
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('EEE, MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final vehicle = flowState.vehicle;

    return AppScaffold(
      title: "Booking Summary",
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Review Details",
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Gap(AppSpacing.md),

                  // 1. Selected Vehicle card summary
                  if (vehicle != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.lgBorderRadius,
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: AppElevation.cardShadow,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              vehicle.imageUrl,
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.name,
                                  style: AppTextStyles.subtitle1.copyWith(fontSize: 16),
                                ),
                                const Gap(4),
                                Text(
                                  flowState.rentalType == RentalType.withDriver
                                      ? "With Chauffeur"
                                      : "Self Drive",
                                  style: TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const Gap(AppSpacing.lg),

                  // 2. Journey Details
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: AppElevation.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _JourneyItem(
                          icon: Icons.circle,
                          iconColor: AppColors.accent,
                          label: "PICK-UP HUB & DATE",
                          location: flowState.pickupLocation ?? '',
                          dateTime: _formatDateTime(flowState.pickupDateTime),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22.0),
                          child: Container(
                            width: 1.5,
                            height: 24,
                            color: AppColors.slate200,
                          ),
                        ),
                        _JourneyItem(
                          icon: Icons.circle,
                          iconColor: AppColors.primary,
                          label: "RETURN HUB & DATE",
                          location: flowState.returnLocation ?? '',
                          dateTime: _formatDateTime(flowState.returnDateTime),
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.lg),

                  // 3. Coupon Application Bar
                  _CouponBar(
                    couponCode: flowState.coupon?.code,
                    couponDesc: flowState.coupon?.description,
                    onApplyPressed: () => context.push(AppRoutes.coupon),
                    onRemovePressed: () => ref.read(bookingFlowProvider.notifier).removeCoupon(),
                  ),

                  const Gap(AppSpacing.lg),

                  // 4. Expandable Fare breakdown card
                  PriceCard(state: flowState),
                  const Gap(AppSpacing.xl),
                ],
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
                      context.push(AppRoutes.paymentMethod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Proceed to Pay"),
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

class _JourneyItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String location;
  final String dateTime;

  const _JourneyItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.location,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 2.0),
          child: Icon(icon, color: iconColor, size: 10),
        ),
        const Gap(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Gap(2),
              Text(
                location,
                style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(1),
              Text(
                dateTime,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CouponBar extends StatelessWidget {
  final String? couponCode;
  final String? couponDesc;
  final VoidCallback onApplyPressed;
  final VoidCallback onRemovePressed;

  const _CouponBar({
    this.couponCode,
    this.couponDesc,
    required this.onApplyPressed,
    required this.onRemovePressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoupon = couponCode != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(
          color: hasCoupon ? AppColors.accent.withOpacity(0.4) : AppColors.slate200,
        ),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer_outlined,
            color: hasCoupon ? AppColors.accent : AppColors.slate400,
            size: 22,
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: hasCoupon
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              couponCode!,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Gap(6),
                          const Text(
                            "Applied",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        couponDesc ?? '',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Promo Codes",
                        style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate800, fontSize: 13),
                      ),
                      const Gap(2),
                      Text(
                        "Apply coupon to redeem savings",
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate400, fontSize: 11),
                      ),
                    ],
                  ),
          ),
          hasCoupon
              ? TextButton(
                  onPressed: onRemovePressed,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text("Remove"),
                )
              : TextButton(
                  onPressed: onApplyPressed,
                  child: const Text("Apply"),
                ),
        ],
      ),
    );
  }
}
