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
    return AppScaffold(
      title: "Select Add-ons",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Optional Accessories", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 5.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.read(bookingFlowProvider.notifier).nextStep();
                context.push(AppRoutes.bookingSummary);
              },
              child: const Text("Continue to Checkout Summary"),
            ),
          ],
        ),
      ),
    );
  }
}
