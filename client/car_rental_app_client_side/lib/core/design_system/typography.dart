import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get heading1 => AppTextStyles.h1;
  static TextStyle get heading2 => AppTextStyles.h2;
  static TextStyle get heading3 => AppTextStyles.h3;
  static TextStyle get subtitle1 => AppTextStyles.subtitle1;
  static TextStyle get subtitle2 => AppTextStyles.subtitle2;
  static TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  static TextStyle get bodyMedium => AppTextStyles.bodyMedium;
  static TextStyle get bodySmall => AppTextStyles.bodySmall;
  static TextStyle get buttonLarge => AppTextStyles.buttonLarge;
  static TextStyle get buttonMedium => AppTextStyles.buttonMedium;
  static TextStyle get caption => AppTextStyles.caption;
  static TextStyle get overline => AppTextStyles.overline;
}
