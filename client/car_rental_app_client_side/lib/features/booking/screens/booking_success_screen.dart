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

class BookingSuccessScreen extends ConsumerStatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  ConsumerState<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends ConsumerState<BookingSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final bookingId = flowState.bookingId ?? "bk_default";

    return AppScaffold(
      title: "Booking Completed",
      showProgress: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const Gap(AppSpacing.md),
            Text("Reservation Confirmed!", style: AppTextStyles.h2, textAlign: TextAlign.center),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 9.", style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                context.push('${AppRoutes.bookingDetails}/$bookingId');
              },
              child: const Text("Track Booking Details"),
            ),
            const Gap(AppSpacing.sm),
            TextButton(
              onPressed: () {
                ref.read(bookingFlowProvider.notifier).reset();
                context.go(AppRoutes.booking);
              },
              child: const Text("Go Home"),
            ),
          ],
        ),
      ),
    );
  }
}
