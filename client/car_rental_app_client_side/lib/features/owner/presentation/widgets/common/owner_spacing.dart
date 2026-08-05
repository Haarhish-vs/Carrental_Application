/// 8-point grid spacing + radius constants used ONLY by the Owner
/// Dashboard. Kept local to `features/owner/` on purpose.
abstract final class OwnerSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

abstract final class OwnerRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 22;
  static const double pill = 999;
}

/// Responsive column-count helper supporting 320px phones up to 12"+ tablets & desktop.
abstract final class OwnerBreakpoints {
  static int columnsFor(double width, {int max = 4}) {
    if (width < 340) return 1; // Ultra-small screens (e.g. 320px iPhone SE)
    if (width < 640) return 1; // Standard mobile screens (360px - 480px)
    if (width < 900) return 2; // Large phones in landscape & small tablets (7-8")
    if (width < 1200) return 3; // Tablets (10-12") & foldables
    return max; // Large tablet landscape & Desktop
  }
}
