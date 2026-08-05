import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/owner_colors.dart';
import '../common/owner_spacing.dart';
import '../../../models/owner_dummy_data.dart';

/// Revenue Distribution pie chart (Owner Net Income vs Platform
/// Commission), with a matching legend. Implemented with a plain
/// `CustomPainter` — made fully responsive for small devices (< 360px).
class RevenuePieChart extends StatelessWidget {
  const RevenuePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final slices = OwnerDummyData.revenueDistribution;
    const colors = [OwnerColors.primary, OwnerColors.warning];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 420;

        final chartWidget = SizedBox(
          height: isSmallScreen ? 140 : 180,
          width: isSmallScreen ? 140 : 180,
          child: CustomPaint(
            painter: _PiePainter(values: slices.map((e) => e.value).toList(), colors: colors),
          ),
        );

        final legendWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, s) in slices.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${s.key} (${s.value.toInt()}%)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

        if (isSmallScreen) {
          return Column(
            children: [
              chartWidget,
              const SizedBox(height: OwnerSpacing.md),
              legendWidget,
            ],
          );
        }

        return Row(
          children: [
            chartWidget,
            const SizedBox(width: OwnerSpacing.lg),
            Expanded(child: legendWidget),
          ],
        );
      },
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final holeRadius = outerRadius * 0.52;

    var startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }

    // Punch the donut hole.
    final holePaint = Paint()..color = OwnerColors.surface;
    canvas.drawCircle(center, holeRadius, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) => oldDelegate.values != values;
}
