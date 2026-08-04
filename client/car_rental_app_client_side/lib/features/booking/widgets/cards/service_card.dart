import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../models/service_model.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

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
          borderRadius: AppRadius.lgBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.slate200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppElevation.selectShadow : AppElevation.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Check Indicator Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.slate300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const Gap(AppSpacing.md),

            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: AppTextStyles.subtitle1.copyWith(
                            fontSize: 16,
                            color: AppColors.slate900,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '\$${service.price.toStringAsFixed(0)}',
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      Text(
                        service.isReoccurring ? '/ day' : 'flat fee',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    service.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.slate500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
