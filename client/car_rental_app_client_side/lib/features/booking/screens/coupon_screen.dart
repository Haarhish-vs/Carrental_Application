import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../providers/booking_provider.dart';

class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key});

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Apply Coupon",
      showProgress: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter Promo Code", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 7.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                context.pop();
              },
              child: const Text("Go Back to Summary"),
            ),
          ],
        ),
      ),
    );
  }
}
