import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';

class LocationSelector extends StatelessWidget {
  final String label;
  final String? selectedLocation;
  final String placeholder;
  final VoidCallback onTap;
  final IconData icon;

  const LocationSelector({
    super.key,
    required this.label,
    this.selectedLocation,
    required this.placeholder,
    required this.onTap,
    this.icon = Icons.location_on_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedLocation != null && selectedLocation!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subtitle2.copyWith(
            color: AppColors.slate500,
            fontSize: 12,
          ),
        ),
        const Gap(AppSpacing.xxs),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdBorderRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBorderRadius,
              border: Border.all(
                color: hasValue ? AppColors.slate300 : AppColors.slate200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasValue ? AppColors.accent : AppColors.slate400,
                  size: 20,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    hasValue ? selectedLocation! : placeholder,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: hasValue ? AppColors.slate900 : AppColors.slate400,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.slate400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
