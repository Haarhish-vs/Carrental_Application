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
import '../models/booking_flow_state.dart';
import '../providers/booking_provider.dart';
import '../widgets/timeline/booking_timeline.dart';
import '../utils/booking_price_calculator.dart';

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
  TripStatus _status = TripStatus.confirmed;

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cancel Reservation", style: AppTextStyles.h3.copyWith(fontSize: 18)),
          content: Text(
            "Are you sure you want to cancel this reservation? Full refund applies if cancelled 24 hours prior to release.",
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Keep Booking",
                style: TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _status = TripStatus.cancelled;
                });
                _showSuccessBanner("Reservation cancelled successfully");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(100, 44),
              ),
              child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Contact Support", style: AppTextStyles.h3.copyWith(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: AppColors.accent),
                title: const Text("+1 (800) 555-0199"),
                subtitle: const Text("Toll-Free Support Line"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent),
                title: const Text("Live Chat In-App"),
                subtitle: const Text("Average wait: 2 mins"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.slate900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('EEE, MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final vehicle = flowState.vehicle;
    final driver = flowState.driver;
    final totalAmount = BookingPriceCalculator.calculateGrandTotal(flowState);

    return AppScaffold(
      title: "Reservation Details",
      showProgress: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking reference
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reservation Reference",
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate400, fontWeight: FontWeight.bold),
                    ),
                    const Gap(2),
                    Text(
                      widget.bookingId,
                      style: AppTextStyles.h3.copyWith(fontSize: 18, color: AppColors.slate900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _status == TripStatus.cancelled
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _status == TripStatus.cancelled ? "Cancelled" : "Confirmed",
                    style: TextStyle(
                      color: _status == TripStatus.cancelled ? AppColors.error : AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.lg),

            // 1. Status timeline tracker
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
                  Text("Journey Status", style: AppTextStyles.subtitle1.copyWith(fontSize: 15)),
                  const Gap(AppSpacing.md),
                  BookingTimeline(status: _status),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),

            // 2. Selected Vehicle info
            if (vehicle != null) ...[
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
                        width: 90,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.name, style: AppTextStyles.subtitle1.copyWith(fontSize: 16)),
                          const Gap(4),
                          Wrap(
                            spacing: 6,
                            children: vehicle.specifications.take(2).map((spec) {
                              return Text(
                                spec,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.slate400,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.lg),
            ],

            // 3. Driver assignment status
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(color: AppColors.slate200),
                boxShadow: AppElevation.cardShadow,
              ),
              child: flowState.rentalType == RentalType.withDriver && driver != null
                  ? Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            driver.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driver.name, style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate900)),
                              const Gap(2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                                  const Gap(2),
                                  Text(
                                    "${driver.rating} • Chauffeur assigned",
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showSupportDialog,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.slate100,
                          radius: 20,
                          child: Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 20),
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Self Drive Reservation", style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate900)),
                              const Gap(2),
                              Text(
                                "No driver assigned. Pick up keys at the hub counter.",
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate400, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const Gap(AppSpacing.lg),

            // 4. Hub Schedules
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
                  Text("Schedules & Hub Coordinates", style: AppTextStyles.subtitle1.copyWith(fontSize: 15)),
                  const Gap(AppSpacing.md),
                  _CoordinateRow(
                    label: "RELEASE POINT",
                    location: flowState.pickupLocation ?? 'Pickup Hub',
                    time: _formatDateTime(flowState.pickupDateTime),
                  ),
                  const Divider(),
                  _CoordinateRow(
                    label: "RETURN POINT",
                    location: flowState.returnLocation ?? 'Return Hub',
                    time: _formatDateTime(flowState.returnDateTime),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),

            // 5. Total Paid Summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.lgBorderRadius,
                border: Border.all(color: AppColors.slate200),
                boxShadow: AppElevation.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Paid Amount", style: AppTextStyles.subtitle2),
                  Text(
                    "₹${totalAmount.toStringAsFixed(2)}",
                    style: AppTextStyles.h3.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),

            const Gap(AppSpacing.xxl),

            // 6. Support & Cancellation Action Buttons
            if (_status != TripStatus.cancelled) ...[
              ElevatedButton(
                onPressed: _showSupportDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.headset_mic_outlined, size: 18),
                    const Gap(8),
                    Text("Contact Trip Support", style: AppTextStyles.buttonLarge),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              OutlinedButton(
                onPressed: _showCancelDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined, size: 18),
                    Gap(8),
                    Text("Cancel Reservation"),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  ref.read(bookingFlowProvider.notifier).reset();
                  context.go(AppRoutes.booking);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Book New Ride"),
              ),
            ],
            const Gap(AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _CoordinateRow extends StatelessWidget {
  final String label;
  final String location;
  final String time;

  const _CoordinateRow({
    required this.label,
    required this.location,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.slate400,
              letterSpacing: 0.5,
            ),
          ),
          const Gap(4),
          Text(
            location,
            style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate800, fontSize: 13),
          ),
          const Gap(2),
          Text(
            time,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
