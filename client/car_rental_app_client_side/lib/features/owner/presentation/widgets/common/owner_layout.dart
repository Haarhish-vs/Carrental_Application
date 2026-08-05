import 'package:flutter/material.dart';

import 'owner_colors.dart';
import 'owner_spacing.dart';

/// Simple responsive wrap-based grid so metric cards reflow cleanly
/// from 1 column (mobile) up to N columns (desktop).
class OwnerResponsiveGrid extends StatelessWidget {
  const OwnerResponsiveGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.spacing = OwnerSpacing.md,
    this.runSpacing = OwnerSpacing.md,
  });

  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = OwnerBreakpoints.columnsFor(width, max: maxColumns);
        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Generic rounded white "card" surface used for charts, review cards,
/// notification rows, etc.
class OwnerSurfaceCard extends StatelessWidget {
  const OwnerSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OwnerSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: OwnerColors.surface,
        borderRadius: BorderRadius.circular(OwnerRadius.lg),
        border: Border.all(color: OwnerColors.border),
      ),
      child: child,
    );
  }
}
