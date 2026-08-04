import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../models/booking_step.dart';
import '../../models/booking_flow_state.dart';
import '../providers/booking_provider.dart';
import '../widgets/cards/payment_method_card.dart';
import '../utils/booking_price_calculator.dart';

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

  void _submitPayment() async {
    final state = ref.read(bookingFlowProvider);
    if (state.paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please select a payment method to complete booking",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }

    final success = await ref.read(bookingFlowProvider.notifier).submitBooking();
    if (success && mounted) {
      context.push(AppRoutes.bookingSuccess);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(bookingFlowProvider).errorMessage ?? "Payment failed. Please try again.",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final totalAmount = BookingPriceCalculator.calculateGrandTotal(flowState);

    final paymentMethods = [
      PaymentMethod.upi,
      PaymentMethod.creditCard,
      PaymentMethod.debitCard,
      PaymentMethod.wallet,
      PaymentMethod.netBanking,
    ];

    return AppScaffold(
      title: "Select Payment",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Text
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose Payment Mode",
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                Text(
                  "Select your preferred secure payment channel.",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate500),
                ),
              ],
            ),
          ),

          // Payment List Options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                final isSelected = flowState.paymentMethod == method;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PaymentMethodCard(
                    method: method,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(bookingFlowProvider.notifier).setPaymentMethod(method);
                    },
                  ),
                );
              },
            ),
          ),

          // Sticky Footer with Total & CTA
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Due",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          "\$${totalAmount.toStringAsFixed(2)}",
                          style: AppTextStyles.h2.copyWith(color: AppColors.accent, fontSize: 22),
                        ),
                      ],
                    ),
                    Text(
                      "Secure SSL Checkout",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.md),
                Row(
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
                        onPressed: flowState.isLoading ? null : _submitPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: flowState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Pay & Confirm"),
                                  const Gap(6),
                                  const Icon(Icons.lock_outline_rounded, size: 16),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
