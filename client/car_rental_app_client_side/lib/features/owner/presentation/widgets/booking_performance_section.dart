import 'package:flutter/material.dart';

import 'booking_list_tile.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import 'common/owner_stat_card.dart';
import '../../models/owner_dummy_data.dart';

/// SECTION 6 — Booking Performance + recent bookings list.
class BookingPerformanceSection extends StatelessWidget {
  const BookingPerformanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Booking Performance',
          subtitle: 'Recent bookings & lifecycle overview',
          icon: Icons.done_all_rounded,
          actionLabel: 'View bookings',
        ),
        OwnerResponsiveGrid(
          maxColumns: 4,
          children: [for (final stat in OwnerDummyData.bookingPerformance) OwnerStatCard(item: stat)],
        ),
        const SizedBox(height: OwnerSpacing.lg),
        OwnerSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Bookings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Divider(height: OwnerSpacing.lg),
              for (final b in OwnerDummyData.recentBookings) BookingListTile(booking: b),
            ],
          ),
        ),
      ],
    );
  }
}
