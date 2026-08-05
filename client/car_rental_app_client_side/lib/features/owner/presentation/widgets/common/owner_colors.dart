import 'package:flutter/material.dart';

/// Color palette used ONLY by the Owner Dashboard.
///
/// Kept entirely inside `features/owner/` (rather than touching
/// `core/theme/app_theme.dart`) so nothing outside the Owner feature
/// changes. [primary] and [ink] are the same values already used by
/// this screen before this rebuild, so the look stays consistent with
/// the rest of the app even though the app-wide theme file is untouched.
abstract final class OwnerColors {
  static const primary = Color(0xff3663F5);
  static const ink = Color(0xff18213E);

  static const primaryLight = Color(0xffE7ECFF);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xffF1F2F6);
  static const border = Color(0xffE7E9F0);
  static const textTertiary = Color(0xff9CA3AF);

  static const success = Color(0xff1F9B71);
  static const successBg = Color(0xffE4F8F0);
  static const danger = Color(0xffDC2626);
  static const dangerBg = Color(0xffFCE9E8);
  static const warning = Color(0xffD97706);
  static const warningBg = Color(0xffFEF3E2);
  static const info = Color(0xff2563EB);
  static const infoBg = Color(0xffE9F1FE);
  static const star = Color(0xffFBBF24);

  static const chartPalette = <Color>[
    primary,
    success,
    warning,
    Color(0xffEC4899),
    Color(0xff06B6D4),
    Color(0xff8B5CF6),
  ];
}
