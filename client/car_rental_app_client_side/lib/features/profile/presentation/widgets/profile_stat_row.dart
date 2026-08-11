import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileStatItem {
  const ProfileStatItem({required this.icon, required this.label, required this.value, this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}

/// A row of compact statistic tiles (icon, value, label) — used for
/// Customer activity (Bookings / Currently Rented / Completed Trips)
/// and Owner fleet/renter stats. Wraps responsively on narrow screens
/// instead of squeezing or overflowing.
class ProfileStatRow extends StatelessWidget {
  const ProfileStatRow({super.key, required this.items});

  final List<ProfileStatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = items.length <= 2
            ? items.length
            : (constraints.maxWidth < 360 ? 2 : items.length);
        final spacing = 10.0;
        final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: itemWidth, child: _StatTile(item: item)),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final ProfileStatItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(item.icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
