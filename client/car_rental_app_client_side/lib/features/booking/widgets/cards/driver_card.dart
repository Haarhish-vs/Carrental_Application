import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../models/driver_model.dart';
import '../../utils/currency_formatter.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRecommended;
  final double? distance;

  const DriverCard({
    super.key,
    required this.driver,
    required this.isSelected,
    required this.onTap,
    this.isRecommended = false,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              top: isRecommended ? AppSpacing.xl + 4 : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.lgBorderRadius,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.slate200,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? AppElevation.selectShadow
                  : AppElevation.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Profile Image
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: CachedNetworkImage(
                        imageUrl: driver.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.slate200,
                          highlightColor: AppColors.slate100,
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.slate100,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.slate400,
                          ),
                        ),
                      ),
                    ),
                    if (driver.isVerified)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF16A34A),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap(AppSpacing.md),

                // Driver Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              driver.name,
                              style: AppTextStyles.subtitle1.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFBBF24),
                                size: 16,
                              ),
                              const Gap(2),
                              Text(
                                driver.rating.toString(),
                                style: AppTextStyles.subtitle2.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Gap(4),

                      // Experience & Trips Completed
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                          const Gap(4),
                          Text(
                            "${driver.experienceYears} years experience  •  ${driver.tripsCompleted} trips",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),

                      // Languages
                      Row(
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              driver.languages.join("  •  "),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.slate500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Distance from pickup
                      if (distance != null) ...[
                        const Gap(4),
                        Row(
                          children: [
                            const Icon(
                              Icons.pin_drop_outlined,
                              size: 14,
                              color: AppColors.slate400,
                            ),
                            const Gap(4),
                            Text(
                              distance! < 0.1
                                  ? "Available in your pickup area"
                                  : "${distance!.toStringAsFixed(1)} km from pickup",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Verified & Availability Green Status Row
                      const Gap(6),
                      Row(
                        children: [
                          if (driver.isVerified) ...[
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF16A34A),
                              size: 12,
                            ),
                            const Gap(4),
                            const Text(
                              "Verified Driver",
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(10),
                          ],
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF16A34A),
                            size: 12,
                          ),
                          const Gap(4),
                          const Text(
                            "Available",
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const Gap(12),

                      // Pricing and Selection Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: formatCurrency(driver.pricePerDay),
                              style: AppTextStyles.h3.copyWith(
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                              children: [
                                TextSpan(
                                  text: " / day",
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Custom Small Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const Gap(4),
                                ],
                                Text(
                                  isSelected ? "Selected" : "Select",
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.slate700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isRecommended)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: Colors.white, size: 11),
                  Gap(4),
                  Text(
                    "Recommended for you",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
