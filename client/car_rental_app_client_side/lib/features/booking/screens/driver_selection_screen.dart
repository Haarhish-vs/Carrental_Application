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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Select Professional Driver",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Professional Drivers", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 4.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.read(bookingFlowProvider.notifier).nextStep();
                context.push(AppRoutes.additionalServices);
              },
              child: const Text("Continue to Services"),
            ),
          ],
        ),
      ),
    );
  }
}
