import 'package:flutter/material.dart';

/// Centralized Global Color & Theme System.
/// Changing the values here (e.g. `primary`) automatically updates the entire application.
class AppColors {
  AppColors._();

  // --- Brand & Primary Colors ---
  static const Color primary = Color(0xFF1E5AA8);
  static const Color primaryColor = primary;
  static const Color primaryDark = Color(0xFF103B66);
  static const Color primaryLight = Color(0xFFEAF2FF);
  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryColor = secondary;

  // --- Surfaces & Backgrounds ---
  static const Color background = Color(0xFFF4F7FB);
  static const Color backgroundColor = background;
  static const Color surface = Colors.white;
  static const Color surfaceColor = surface;
  static const Color cardBackground = Colors.white;
  static const Color segmentBackground = Color(0xFFEFF4FA);

  // --- Typography & Text ---
  static const Color textPrimary = Color(0xFF103B66);
  static const Color textColor = textPrimary;
  static const Color textDark = Color(0xFF1C1E21);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // --- Borders & Dividers ---
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderColor = border;
  static const Color divider = Color(0xFFE5E7EB);

  // --- Form & Inputs ---
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocusedBorder = primary;

  // --- Status & Feedback ---
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFE6F4EA);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color danger = error;
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color rating = Color(0xFFFFB020);

  // --- Common Reusable Button Styles ---
  static ButtonStyle primaryButtonStyle({
    double verticalPadding = 16,
    double borderRadius = 16,
    double fontSize = 15,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: textOnPrimary,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ButtonStyle dangerButtonStyle({
    double verticalPadding = 14,
    double borderRadius = 12,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: error,
      foregroundColor: textOnPrimary,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle({
    double verticalPadding = 14,
    double borderRadius = 12,
    Color color = primary,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}