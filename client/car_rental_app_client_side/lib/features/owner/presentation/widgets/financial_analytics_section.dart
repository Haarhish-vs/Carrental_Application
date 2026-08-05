import 'package:flutter/material.dart';

import 'charts/revenue_pie_chart.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import 'common/owner_stat_card.dart';
import '../../models/owner_dummy_data.dart';

/// SECTION 7 — Financial Analytics + Revenue Distribution pie chart.
class FinancialAnalyticsSection extends StatelessWidget {
  const FinancialAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Financial Analytics',
          subtitle: 'Revenue, commission and payout breakdown',
          icon: Icons.account_balance_rounded,
          actionLabel: 'Export report',
        ),
        OwnerResponsiveGrid(
          maxColumns: 4,
          children: [for (final stat in OwnerDummyData.financialAnalytics) OwnerStatCard(item: stat)],
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revenue Distribution', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: OwnerSpacing.md),
              const RevenuePieChart(),
            ],
          ),
        ),
      ],
    );
  }
}
