import 'package:flutter/material.dart';

import 'package:car_rental_app_client_side/core/utils/indian_currency_formatter.dart';
import '../common/owner_colors.dart';
import '../../../models/owner_dummy_data.dart';

/// Monthly Revenue line/area chart — 12 months, dummy data.
/// CustomPainter implementation formatted with Indian Rupee.
class EarningsLineChart extends StatelessWidget {
  const EarningsLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    final data = OwnerDummyData.monthlyRevenue;
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.25;

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22, left: 4),
        child: CustomPaint(
          size: Size.infinite,
          painter: _LineChartPainter(data: data, maxY: maxY, labels: OwnerDummyData.monthLabels),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.data, required this.maxY, required this.labels});

  final List<double> data;
  final double maxY;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const leftAxisWidth = 48.0;
    final chartWidth = size.width - leftAxisWidth;
    final chartHeight = size.height - 20;

    // Horizontal grid lines + Y axis labels.
    final gridPaint = Paint()
      ..color = OwnerColors.border
      ..strokeWidth = 1;
    final textStyle = const TextStyle(fontSize: 10.5, color: Colors.black54);

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (chartHeight * i / 4);
      canvas.drawLine(Offset(leftAxisWidth, y), Offset(size.width, y), gridPaint);
      final rawVal = (maxY * i / 4) * 100;
      final label = IndianCurrencyFormatter.format(rawVal, compact: true);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Build point positions.
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = leftAxisWidth + (chartWidth * i / (data.length - 1));
      final y = chartHeight - (chartHeight * data[i] / maxY);
      points.add(Offset(x, y));
    }

    // Area fill under the line.
    final areaPath = Path()..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, chartHeight);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [OwnerColors.primary.withValues(alpha: 0.22), OwnerColors.primary.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    // The line itself.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      linePath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    final linePaint = Paint()
      ..color = OwnerColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // X axis month labels.
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.maxY != maxY;
}
