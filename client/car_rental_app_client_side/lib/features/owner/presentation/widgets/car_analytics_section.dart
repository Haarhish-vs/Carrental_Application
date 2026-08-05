import 'package:flutter/material.dart';

import 'car_list_tile.dart';
import 'charts/car_bar_chart.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import 'common/owner_stat_card.dart';
import '../../models/owner_dummy_data.dart';

/// SECTION 4 — Car Analytics + Car Utilization bar chart + fleet list.
class CarAnalyticsSection extends StatelessWidget {
  const CarAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Car Analytics',
          subtitle: 'Fleet health, utilization and performance',
          icon: Icons.directions_car_rounded,
          actionLabel: 'Manage fleet',
        ),
        OwnerResponsiveGrid(
          maxColumns: 4,
          children: [for (final stat in OwnerDummyData.carAnalytics) OwnerStatCard(item: stat)],
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Car Utilization', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: OwnerSpacing.md),
              const CarBarChart(),
            ],
          ),
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fleet Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Divider(height: OwnerSpacing.lg),
              for (final car in OwnerDummyData.topCars) CarListTile(car: car),
            ],
          ),
        ),
      ],
    );
  }
}
