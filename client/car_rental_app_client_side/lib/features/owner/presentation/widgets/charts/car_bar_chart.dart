import 'package:flutter/material.dart';

import '../common/owner_colors.dart';
import '../../../models/owner_dummy_data.dart';

/// Bar chart showing total rentals per car (Car Utilization), built
/// from plain `Container`/`Row` widgets — no external chart package.
///
/// Horizontally scrollable with a fixed column width per car so bars
/// stay readable (not squeezed) on narrow phone screens, while still
/// filling the available width nicely on tablets/desktop.
class CarBarChart extends StatelessWidget {
  const CarBarChart({super.key});

  static const _maxBarHeight = 135.0;
  static const _containerHeight = 210.0;
  static const _columnWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    final cars = OwnerDummyData.topCars;
    final maxRentals = cars.map((c) => c.totalRentals).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: _containerHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsScroll = cars.length * _columnWidth > constraints.maxWidth;
          final row = Row(
            mainAxisSize: needsScroll ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: needsScroll ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
            children: [
              for (final (i, car) in cars.indexed)
                SizedBox(
                  width: needsScroll ? _columnWidth : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${car.totalRentals}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: OwnerColors.ink),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          child: Container(
                            width: needsScroll ? 32 : null,
                            height: _maxBarHeight * (car.totalRentals / maxRentals),
                            color: OwnerColors.chartPalette[i % OwnerColors.chartPalette.length],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          car.name.split(' ').last,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );

          if (!needsScroll) return row;
          return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
        },
      ),
    );
  }
}
