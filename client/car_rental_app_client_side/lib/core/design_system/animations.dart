import 'package:flutter/material.dart';

class AppAnimations {
  AppAnimations._();

  // Standard Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Easing Curves
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve decelerateCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}
