import 'package:flutter/material.dart';

import 'charts/earnings_line_chart.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import 'common/owner_stat_card.dart';
import '../../models/owner_dummy_data.dart';

/// SECTION 3 — Earnings Analytics + Monthly Revenue line chart.
class EarningsAnalyticsSection extends StatelessWidget {
  const EarningsAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Earnings Analytics',
          subtitle: 'Track revenue across every time horizon',
          icon: Icons.trending_up_rounded,
        ),
        OwnerResponsiveGrid(
          maxColumns: 4,
          children: [for (final stat in OwnerDummyData.earningsAnalytics) OwnerStatCard(item: stat)],
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Revenue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Text('Last 12 months', style: TextStyle(color: Colors.black54, fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: OwnerSpacing.md),
              const EarningsLineChart(),
            ],
          ),
        ),
      ],
    );
  }
}
