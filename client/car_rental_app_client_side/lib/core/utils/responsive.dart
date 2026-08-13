import 'package:flutter/material.dart';

/// Screen device category breakpoints.
enum DeviceType {
  smallMobile,
  mobile,
  tablet,
  desktop,
}

/// Centralized responsive UI utility for the entire Flutter application.
/// Handles screen sizing, device classification, responsive padding, font scaling,
/// grid configuration, and adaptive component dimensions for phones and tablets.
class Responsive {
  Responsive._();

  // Breakpoints in logical pixels
  static const double kSmallMobileBreakpoint = 360.0;
  static const double kMobileBreakpoint = 600.0;
  static const double kTabletBreakpoint = 1000.0;

  /// Returns current screen width.
  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  /// Returns current screen height.
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  /// Returns current device orientation.
  static Orientation orientation(BuildContext context) =>
      MediaQuery.of(context).orientation;

  /// Returns true if device is in landscape orientation.
  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  /// Identifies current [DeviceType] based on screen width.
  static DeviceType getDeviceType(BuildContext context) {
    final w = width(context);
    if (w < kSmallMobileBreakpoint) return DeviceType.smallMobile;
    if (w < kMobileBreakpoint) return DeviceType.mobile;
    if (w < kTabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Device type checkers
  static bool isSmallMobile(BuildContext context) =>
      width(context) < kSmallMobileBreakpoint;

  static bool isMobile(BuildContext context) =>
      width(context) < kMobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= kMobileBreakpoint && w < kTabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      width(context) >= kTabletBreakpoint;

  /// Resolves a value based on the active screen device type.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? smallMobile,
    T? tablet,
    T? desktop,
  }) {
    final device = getDeviceType(context);
    switch (device) {
      case DeviceType.smallMobile:
        return smallMobile ?? mobile;
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Base scale factor derived from reference mobile width (375.0 logical pixels).
  static double scale(BuildContext context, {double minScale = 0.8, double maxScale = 1.25}) {
    final w = width(context);
    return (w / 375.0).clamp(minScale, maxScale);
  }

  /// Calculates clamped, proportional responsive size (dimensions, paddings, icons).
  static double size(
    BuildContext context,
    double baseSize, {
    double minScale = 0.8,
    double maxScale = 1.25,
  }) {
    return baseSize * scale(context, minScale: minScale, maxScale: maxScale);
  }

  /// Calculates clamped, proportional responsive font size.
  static double fontSize(
    BuildContext context,
    double baseSize, {
    double minScale = 0.85,
    double maxScale = 1.25,
  }) {
    return baseSize * scale(context, minScale: minScale, maxScale: maxScale);
  }

  /// Horizontal page padding relative to screen width.
  static double pagePadding(BuildContext context) {
    return value<double>(
      context,
      smallMobile: 12.0,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Page content edge insets.
  static EdgeInsets pageInsets(BuildContext context, {double vertical = 16.0}) {
    return EdgeInsets.symmetric(
      horizontal: pagePadding(context),
      vertical: vertical,
    );
  }

  /// Responsive grid columns count for car grids.
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int? smallMobile,
    int tablet = 3,
    int desktop = 4,
  }) {
    return value<int>(
      context,
      smallMobile: smallMobile ?? 2,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Calculates a fully dynamic grid aspect ratio based on screen width & content height.
  /// Dynamically adapts cards to prevent bottom and right overflow bugs on any device size.
  static double dynamicGridAspectRatio(
    BuildContext context, {
    double cardContentBaseHeight = 105.0,
    double imageWidthRatio = 0.32,
    double minRatio = 0.46,
    double maxRatio = 0.72,
  }) {
    final w = width(context);
    final s = scale(context);
    final int cols = gridColumns(context);
    final double gridPadding = (16.0 * s).clamp(12.0, 24.0);
    final double spacing = (12.0 * s).clamp(8.0, 16.0);

    final double totalHorizontalSpacing = (gridPadding * 2) + (spacing * (cols - 1));
    final double cardWidth = (w - totalHorizontalSpacing) / cols;
    final double imageHeight = (w * imageWidthRatio).clamp(100.0, 140.0);
    final double estimatedCardHeight = imageHeight + (cardContentBaseHeight * s);

    return (cardWidth / estimatedCardHeight).clamp(minRatio, maxRatio);
  }

  /// Legacy static aspect ratio helper for fallback.
  static double gridChildAspectRatio(
    BuildContext context, {
    double mobile = 0.48,
    double? smallMobile,
    double tablet = 0.58,
    double desktop = 0.68,
  }) {
    return dynamicGridAspectRatio(context);
  }

  /// Responsive car card width for horizontal lists.
  static double carCardWidth(BuildContext context) {
    final w = width(context);
    return (w * 0.68).clamp(230.0, 270.0);
  }

  /// Responsive horizontal rail height.
  static double carRailHeight(BuildContext context) {
    final w = width(context);
    final s = scale(context);
    final double imageHeight = (w * 0.32).clamp(100.0, 140.0);
    final double contentHeight = 105.0 * s;
    return imageHeight + contentHeight + (16.0 * s);
  }
}

/// Helper extension on [BuildContext] for clean inline responsive calls across all screens.
extension ResponsiveContextX on BuildContext {
  double get screenWidth => Responsive.width(this);
  double get screenHeight => Responsive.height(this);
  DeviceType get deviceType => Responsive.getDeviceType(this);

  bool get isSmallMobile => Responsive.isSmallMobile(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);

  /// Screen scale factor derived from 375 logical pixels mobile reference width.
  double get scale => Responsive.scale(this);

  /// Scales any fixed base pixel dimension (padding, margin, width, height) relative to screen scale.
  double rSize(double baseSize, {double minScale = 0.8, double maxScale = 1.25}) =>
      Responsive.size(this, baseSize, minScale: minScale, maxScale: maxScale);

  /// Scales font size relative to screen scale.
  double rFont(double baseSize, {double minScale = 0.85, double maxScale = 1.25}) =>
      Responsive.fontSize(this, baseSize, minScale: minScale, maxScale: maxScale);

  double get pagePadding => Responsive.pagePadding(this);
  EdgeInsets pageInsets({double vertical = 16.0}) =>
      Responsive.pageInsets(this, vertical: vertical);

  int gridColumns({
    int mobile = 2,
    int? smallMobile,
    int tablet = 3,
    int desktop = 4,
  }) =>
      Responsive.gridColumns(
        this,
        mobile: mobile,
        smallMobile: smallMobile,
        tablet: tablet,
        desktop: desktop,
      );

  /// Dynamic grid child aspect ratio automatically calculated for current screen size.
  double dynamicGridAspectRatio({
    double cardContentBaseHeight = 105.0,
    double imageWidthRatio = 0.32,
  }) =>
      Responsive.dynamicGridAspectRatio(
        this,
        cardContentBaseHeight: cardContentBaseHeight,
        imageWidthRatio: imageWidthRatio,
      );

  double get gridAspectRatio => Responsive.dynamicGridAspectRatio(this);

  double get carCardWidth => Responsive.carCardWidth(this);
  double get carRailHeight => Responsive.carRailHeight(this);
}

/// Reusable layout builder widget passing responsive context & constraints.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    DeviceType deviceType,
  ) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final DeviceType deviceType;
        if (w < Responsive.kSmallMobileBreakpoint) {
          deviceType = DeviceType.smallMobile;
        } else if (w < Responsive.kMobileBreakpoint) {
          deviceType = DeviceType.mobile;
        } else if (w < Responsive.kTabletBreakpoint) {
          deviceType = DeviceType.tablet;
        } else {
          deviceType = DeviceType.desktop;
        }
        return builder(context, constraints, deviceType);
      },
    );
  }
}
