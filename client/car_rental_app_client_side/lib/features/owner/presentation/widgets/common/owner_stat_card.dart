import 'package:flutter/material.dart';

import 'owner_colors.dart';
import 'owner_spacing.dart';

/// Trend direction for a statistic's percentage indicator.
enum OwnerTrend { up, down, flat }

/// Generic model powering every metric/statistic card on the Owner
/// Dashboard.
class OwnerStatItem {
  const OwnerStatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.trendPercent,
    this.trend = OwnerTrend.flat,
    this.trendLabel,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final double? trendPercent;
  final OwnerTrend trend;
  final String? trendLabel;
}

/// The single reusable "metric card" used across every analytics
/// section of the Owner Dashboard — hardened for 320px screens & text scaling.
class OwnerStatCard extends StatelessWidget {
  const OwnerStatCard({super.key, required this.item});

  final OwnerStatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OwnerSpacing.md),
      decoration: BoxDecoration(
        color: OwnerColors.surface,
        borderRadius: BorderRadius.circular(OwnerRadius.md),
        border: Border.all(color: OwnerColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(OwnerRadius.sm),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              if (item.trendPercent != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _TrendPill(item: item),
                  ),
                ),
            ],
          ),
          const SizedBox(height: OwnerSpacing.md),
          Text(
            item.value,
            style: const TextStyle(color: OwnerColors.ink, fontSize: 20, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.title,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.trendPercent == null && item.trendLabel != null) ...[
            const SizedBox(height: OwnerSpacing.xs),
            Text(
              item.trendLabel!,
              style: const TextStyle(color: OwnerColors.textTertiary, fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.item});

  final OwnerStatItem item;

  @override
  Widget build(BuildContext context) {
    final isUp = item.trend == OwnerTrend.up;
    final color = isUp ? OwnerColors.success : OwnerColors.danger;
    final bg = isUp ? OwnerColors.successBg : OwnerColors.dangerBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(OwnerRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '${item.trendPercent}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
