import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../models/booking_step.dart';
import '../providers/booking_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Booking Checkout Summary",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Price Breakdown", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 6.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.coupon);
              },
              child: const Text("Apply Promo Code"),
            ),
            const Gap(AppSpacing.md),
            ElevatedButton(
              onPressed: () {
                ref.read(bookingFlowProvider.notifier).nextStep();
                context.push(AppRoutes.paymentMethod);
              },
              child: const Text("Continue to Payment"),
            ),
          ],
        ),
      ),
    );
  }
}
