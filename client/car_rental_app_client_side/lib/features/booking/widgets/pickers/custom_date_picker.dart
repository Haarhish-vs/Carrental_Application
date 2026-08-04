import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/design_system/radius.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final String placeholder;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDatePicker({
    super.key,
    required this.label,
    this.selectedDate,
    required this.placeholder,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = selectedDate ?? DateTime.now();
    final DateTime startLimit = firstDate ?? DateTime.now();
    final DateTime endLimit = lastDate ?? DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(startLimit) ? startLimit : initialDate,
      firstDate: startLimit,
      lastDate: endLimit,
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
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedDate != null;
    final formattedValue = hasValue ? DateFormat('EEE, MMM d, yyyy').format(selectedDate!) : '';

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
          onTap: () => _selectDate(context),
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
                  Icons.calendar_month_outlined,
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
