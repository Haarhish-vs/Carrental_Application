import 'package:flutter/material.dart';

import 'package:car_rental_app_client_side/core/utils/indian_currency_formatter.dart';
import 'common/owner_colors.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import 'common/owner_stat_card.dart';
import '../../models/owner_dummy_data.dart';

/// SECTION 5 — Customer Analytics.
class CustomerAnalyticsSection extends StatelessWidget {
  const CustomerAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Customer Analytics',
          subtitle: 'Who is renting, and how often',
          icon: Icons.people_alt_rounded,
          actionLabel: 'View all',
        ),
        OwnerResponsiveGrid(
          maxColumns: 3,
          children: [for (final stat in OwnerDummyData.customerAnalytics) OwnerStatCard(item: stat)],
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Customers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Divider(height: OwnerSpacing.lg),
              for (final c in OwnerDummyData.topCustomers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: OwnerColors.primaryLight,
                        child: Icon(Icons.person_rounded, color: OwnerColors.primary, size: 18),
                      ),
                      const SizedBox(width: OwnerSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                              '${c.totalBookings} bookings · ${IndianCurrencyFormatter.format(c.totalSpent)} spent',
                              style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (c.isRepeat)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: OwnerColors.successBg,
                            borderRadius: BorderRadius.circular(OwnerRadius.pill),
                          ),
                          child: const Text(
                            'Repeat',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OwnerColors.success),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
