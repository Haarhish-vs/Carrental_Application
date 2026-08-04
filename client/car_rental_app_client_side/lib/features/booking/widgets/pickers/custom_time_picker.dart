import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';

class CustomTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? selectedTime;
  final String placeholder;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const CustomTimePicker({
    super.key,
    required this.label,
    this.selectedTime,
    required this.placeholder,
    required this.onTimeSelected,
  });

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay initialTime = selectedTime ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.slate800,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedTime != null;
    final formattedValue = hasValue ? selectedTime!.format(context) : '';

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
          onTap: () => _selectTime(context),
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
                  Icons.access_time_outlined,
                  color: hasValue ? AppColors.accent : AppColors.slate400,
                  size: 20,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    hasValue ? formattedValue : placeholder,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: hasValue ? AppColors.slate900 : AppColors.slate400,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
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
