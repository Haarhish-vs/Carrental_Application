import 'package:flutter/material.dart';

import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_stat_card.dart';
import '../../models/owner_dummy_data.dart';

/// SECTION 1 — Quick Statistics.
class QuickStatsSection extends StatelessWidget {
  const QuickStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Quick Statistics',
          subtitle: 'A snapshot of your business at a glance',
          icon: Icons.grid_view_rounded,
        ),
        OwnerResponsiveGrid(
          maxColumns: 4,
          children: [for (final stat in OwnerDummyData.quickStats) OwnerStatCard(item: stat)],
        ),
      ],
    );
  }
}

/// SECTION 2 — Booking Analytics.
class BookingAnalyticsSection extends StatelessWidget {
  const BookingAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Booking Analytics',
          subtitle: 'Request-to-completion booking funnel',
          icon: Icons.assignment_rounded,
        ),
        OwnerResponsiveGrid(
          maxColumns: 4,
          children: [for (final stat in OwnerDummyData.bookingAnalytics) OwnerStatCard(item: stat)],
        ),
      ],
    );
  }
}

/// SECTION 9 — Performance Metrics.
class PerformanceMetricsSection extends StatelessWidget {
  const PerformanceMetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Performance Metrics',
          subtitle: 'Operational efficiency at a glance',
          icon: Icons.speed_rounded,
        ),
        OwnerResponsiveGrid(
          maxColumns: 3,
          children: [for (final stat in OwnerDummyData.performanceMetrics) OwnerStatCard(item: stat)],
        ),
      ],
    );
  }
}
