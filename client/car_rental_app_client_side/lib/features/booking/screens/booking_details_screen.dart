import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../providers/booking_provider.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Booking Tracking",
      showProgress: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Booking ID: ${widget.bookingId}", style: AppTextStyles.h3),
            const Gap(AppSpacing.xs),
            Text("Fleshed out in Checkpoint 10.", style: AppTextStyles.bodyMedium),
            const Gap(AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.read(bookingFlowProvider.notifier).reset();
                context.go(AppRoutes.booking);
              },
              child: const Text("Create New Reservation"),
            ),
          ],
        ),
      ),
    );
  }
}
