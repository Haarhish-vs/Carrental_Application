import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../models/booking_step.dart';
import '../providers/booking_provider.dart';

class BookingSuccessScreen extends ConsumerStatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  ConsumerState<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends ConsumerState<BookingSuccessScreen> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.success);
    });
  }

  void _downloadInvoice() async {
    setState(() {
      _isDownloading = true;
    });

    // Simulate invoice PDF build and download delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              Gap(8),
              Text(
                "Invoice downloaded successfully!",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final bookingId = flowState.bookingId ?? "bk_98765432";
    final vehicle = flowState.vehicle;

    return AppScaffold(
      title: "Confirmation",
      showProgress: true, // Shows progress bar in final Confirmed milestone
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Success Animation
              // Try loading Lottie success, fallback to premium animated icon
              Lottie.asset(
                'assets/animations/booking_success.json',
                width: 150,
                height: 150,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.accent,
                      size: 64,
                    ),
                  );
                },
              ),
              const Gap(AppSpacing.lg),

              // 2. Success Messages
              Text(
                "Reservation Confirmed!",
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                "Your ride is reserved and will be ready at your selected hub.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate500),
                textAlign: TextAlign.center,
              ),
              const Gap(AppSpacing.xl),

              // 3. Receipt Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.lgBorderRadius,
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: AppElevation.cardShadow,
                ),
                child: Column(
                  children: [
                    _ReceiptRow(
                      label: "BOOKING ID",
                      value: bookingId,
                      isHighlight: true,
                    ),
                    const Divider(),
                    _ReceiptRow(
                      label: "VEHICLE RIDE",
                      value: vehicle?.name ?? 'Premium Car',
                    ),
                    const Divider(),
                    _ReceiptRow(
                      label: "PICK-UP HUB",
                      value: flowState.pickupLocation ?? 'Selected Location',
                    ),
                    const Divider(),
                    _ReceiptRow(
                      label: "SCHEDULE DATE",
                      value: _formatDateTime(flowState.pickupDateTime),
                    ),
                  ],
                ),
              ),

              const Gap(AppSpacing.xxl),

              // 4. Action buttons
              ElevatedButton(
                onPressed: _isDownloading ? null : _downloadInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_download_outlined, size: 20),
                          const Gap(8),
                          Text("Download PDF Invoice", style: AppTextStyles.buttonLarge),
                        ],
                      ),
              ),
              const Gap(AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  context.push('${AppRoutes.bookingDetails}/$bookingId');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_outlined, size: 18),
                    const Gap(8),
                    Text(
                      "Track Reservation Status",
                      style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              TextButton(
                onPressed: () {
                  ref.read(bookingFlowProvider.notifier).reset();
                  context.go(AppRoutes.booking);
                },
                child: Text(
                  "Return to Home",
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.slate400,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.subtitle2.copyWith(
                color: isHighlight ? AppColors.accent : AppColors.slate800,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
