import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppElevation {
  AppElevation._();

  static List<BoxShadow> get none => [];

  // Soft shadow for general card layout
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: AppColors.shadow,
          blurRadius: 12,
          offset: Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  // Slightly stronger shadow for highlights or dialogs
  static List<BoxShadow> get selectShadow => [
        const BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 16,
          offset: Offset(0, 6),
          spreadRadius: 1,
        ),
      ];

  // Bottom sheets upward shadow
  static List<BoxShadow> get sheetShadow => [
        const BoxShadow(
          color: Color(0x120F172A),
          blurRadius: 24,
          offset: Offset(0, -4),
          spreadRadius: 2,
        ),
      ];
}
