import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../models/booking_flow_state.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (method) {
      case PaymentMethod.upi:
        return Icons.qr_code_2_rounded;
      case PaymentMethod.creditCard:
        return Icons.credit_card_rounded;
      case PaymentMethod.debitCard:
        return Icons.payment_rounded;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.netBanking:
        return Icons.account_balance_rounded;
    }
  }

  String _getDescription() {
    switch (method) {
      case PaymentMethod.upi:
        return "Pay instantly via Google Pay, PhonePe, or BHIM";
      case PaymentMethod.creditCard:
        return "All major cards accepted. Safe & secure payment.";
      case PaymentMethod.debitCard:
        return "Direct bank payment via debit cards";
      case PaymentMethod.wallet:
        return "Pay using Apple Pay, PayPal, or local digital wallets";
      case PaymentMethod.netBanking:
        return "Secure redirect to your bank's portal";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.mdBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.slate200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? AppElevation.selectShadow
              : AppElevation.cardShadow,
        ),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.slate100,
              radius: 20,
              child: Icon(
                _getIcon(),
                color: isSelected ? AppColors.accent : AppColors.slate600,
                size: 22,
              ),
            ),
            const Gap(AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.slate900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    _getDescription(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.slate300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
