import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../models/booking_flow_state.dart';
import '../../utils/booking_price_calculator.dart';
import '../../utils/currency_formatter.dart';

class PriceCard extends StatefulWidget {
  final BookingFlowState state;

  const PriceCard({super.key, required this.state});

  @override
  State<PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    final baseCharge = BookingPriceCalculator.calculateBaseRentalCharge(state);
    final driverFee = BookingPriceCalculator.calculateDriverFee(state);
    final insurance = BookingPriceCalculator.calculateInsurance(state);
    final services = BookingPriceCalculator.calculateAdditionalServices(state);
    final discount = BookingPriceCalculator.calculateDiscount(state);
    final tax = BookingPriceCalculator.calculateTax(state);
    final deposit = BookingPriceCalculator.calculateSecurityDeposit(state);
    final grandTotal = BookingPriceCalculator.calculateGrandTotal(state);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.slate200, width: 1),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with toggle
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const Gap(10),
                      Text(
                        "Fare Breakdown",
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.slate600,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Expandable Items
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _PriceRow(
                    label:
                        "Base Rental Fee (${state.rentalDurationDays} ${state.rentalDurationDays == 1 ? 'day' : 'days'})",
                    value: baseCharge,
                  ),
                  if (state.rentalType == RentalType.withDriver) ...[
                    const Gap(AppSpacing.sm),
                    _PriceRow(label: "Chauffeur Service Fee", value: driverFee),
                  ],
                  if (insurance > 0) ...[
                    const Gap(AppSpacing.sm),
                    _PriceRow(
                      label: "Collision Protection Cover",
                      value: insurance,
                    ),
                  ],
                  if (services > 0) ...[
                    const Gap(AppSpacing.sm),
                    _PriceRow(label: "Other Optional Add-ons", value: services),
                  ],
                  const Gap(AppSpacing.sm),
                  _PriceRow(label: "Taxes & Local Fees (18% GST)", value: tax),
                  const Gap(AppSpacing.sm),
                  _PriceRow(
                    label: "Refundable Security Deposit",
                    value: deposit,
                    isSecondary: true,
                  ),
                  if (discount > 0) ...[
                    const Gap(AppSpacing.sm),
                    _PriceRow(
                      label: "Coupon Code Applied (${state.coupon?.code})",
                      value: -discount,
                      isPromo: true,
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // Grand Total Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Grand Total Due",
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.slate800,
                        fontSize: 13,
                      ),
                    ),
                    if (deposit > 0) ...[
                      const Gap(2),
                      Text(
                        "Includes ${formatCurrency(deposit)} refundable deposit",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  formatCurrency(grandTotal),
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.accent,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isSecondary;
  final bool isPromo;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isSecondary = false,
    this.isPromo = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = AppColors.slate800;
    FontWeight valueWeight = FontWeight.w600;

    if (isSecondary) {
      valueColor = AppColors.slate600;
      valueWeight = FontWeight.normal;
    } else if (isPromo) {
      valueColor = AppColors.accent;
    }

    final formattedValue = value.isNegative
        ? "-${formatCurrency(value.abs())}"
        : formatCurrency(value);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSecondary ? AppColors.slate500 : AppColors.slate700,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          formattedValue,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: valueWeight,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
