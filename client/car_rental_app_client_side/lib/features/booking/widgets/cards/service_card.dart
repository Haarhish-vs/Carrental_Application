import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../models/service_model.dart';
import '../../utils/currency_formatter.dart';

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

  IconData _getServiceIcon(String id) {
    switch (id) {
      case 'srv_insurance':
        return Icons.shield_outlined;
      case 'srv_extra_driver':
        return Icons.person_add_alt_outlined;
      case 'srv_child_seat':
        return Icons.child_care_rounded;
      case 'srv_wifi':
        return Icons.wifi_rounded;
      case 'srv_fastag':
        return Icons.local_activity_outlined;
      case 'srv_dash_cam':
        return Icons.videocam_outlined;
      case 'srv_roadside':
        return Icons.car_repair_rounded;
      default:
        return Icons.add_shopping_cart_rounded;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Service Category Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getServiceIcon(service.id),
                color: isSelected ? AppColors.accent : AppColors.slate600,
                size: 24,
              ),
            ),
            const Gap(AppSpacing.md),

            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.name,
                    style: AppTextStyles.subtitle1.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    service.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate500,
                      fontSize: 11,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    "${formatCurrency(service.price)} ${service.isReoccurring ? '/ day' : 'flat fee'}",
                    style: AppTextStyles.subtitle2.copyWith(
                      fontSize: 12,
                      color: isSelected ? AppColors.accent : AppColors.slate700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.md),

            // Selection Toggle
            Switch.adaptive(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.accent,
              inactiveThumbColor: AppColors.slate400,
              inactiveTrackColor: AppColors.slate200,
            ),
          ],
        ),
      ),
    );
  }
}
