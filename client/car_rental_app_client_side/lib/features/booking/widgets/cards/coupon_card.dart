import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';
import '../../models/coupon_model.dart';

class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isApplied;
  final VoidCallback onTap;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.isApplied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBorderRadius,
              border: Border.all(
                color: isApplied ? AppColors.accent : AppColors.slate200,
                width: isApplied ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Voucher Icon
                CircleAvatar(
                  backgroundColor: isApplied 
                      ? AppColors.accent.withOpacity(0.12) 
                      : AppColors.slate100,
                  radius: 20,
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: isApplied ? AppColors.accent : AppColors.slate500,
                    size: 20,
                  ),
                ),
                const Gap(AppSpacing.md),

                // Coupon details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.slate300, width: 0.5),
                            ),
                            child: Text(
                              coupon.code,
                              style: AppTextStyles.subtitle2.copyWith(
                                color: AppColors.slate800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isApplied) ...[
                            const Gap(8),
                            const Text(
                              "Applied",
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(6),
                      Text(
                        coupon.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.slate800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        "Min. Booking: ₹${coupon.minBookingValue.toStringAsFixed(0)}",
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Checked indicator on top right corner
          if (isApplied)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: AppColors.accent,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
