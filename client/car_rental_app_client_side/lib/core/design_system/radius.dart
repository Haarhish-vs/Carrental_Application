import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0; // Standard 16px corner radius
  static const double xl = 24.0;
  static const double round = 999.0;

  static BorderRadius get xsBorderRadius => BorderRadius.circular(xs);
  static BorderRadius get smBorderRadius => BorderRadius.circular(sm);
  static BorderRadius get mdBorderRadius => BorderRadius.circular(md);
  static BorderRadius get lgBorderRadius => BorderRadius.circular(lg);
  static BorderRadius get xlBorderRadius => BorderRadius.circular(xl);
  static BorderRadius get roundBorderRadius => BorderRadius.circular(round);
}
