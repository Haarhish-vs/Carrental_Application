import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../models/booking_step.dart';
import '../../models/booking_flow_state.dart';
import '../providers/booking_provider.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.payment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Select Payment Mode",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Payment Methods", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 8.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                // Mock selection
                ref.read(bookingFlowProvider.notifier).setPaymentMethod(PaymentMethod.upi);
                
                // Submit checkout
                final success = await ref.read(bookingFlowProvider.notifier).submitBooking();
                if (success && mounted) {
                  context.push(AppRoutes.bookingSuccess);
                }
              },
              child: const Text("Pay & Confirm Reservation"),
            ),
          ],
        ),
      ),
    );
  }
}
