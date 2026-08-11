import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/trip_insight.dart';
import 'section_card.dart';

/// Compact "Trip Insights" block: total trips, most/least used vehicle,
/// and a short per-vehicle usage list with proportional bars (and
/// distance, only when the backend-provided odometer value is
/// available — see `TripInsights.fromBookings`).
///
/// This is the section the user asked to live inside **My Trips**
/// (`MyBookingsScreen`) rather than the Profile screen.
class TripInsightsCard extends StatelessWidget {
  const TripInsightsCard({super.key, required this.insights});

  final TripInsights insights;

  @override
  Widget build(BuildContext context) {
    if (insights.totalTrips == 0) return const SizedBox.shrink();

    final maxTrips = insights.usageByVehicle
        .map((v) => v.tripCount)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return SectionCard(
      title: 'Trip Insights',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniStat(label: 'Total Trips', value: '${insights.totalTrips}'),
              if (insights.mostUsed != null)
                _MiniStat(label: 'Most Used', value: insights.mostUsed!.vehicleName),
              if (insights.leastUsed != null && insights.leastUsed != insights.mostUsed)
                _MiniStat(label: 'Least Used', value: insights.leastUsed!.vehicleName),
            ],
          ),
          if (insights.usageByVehicle.length > 1) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            for (final usage in insights.usageByVehicle)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: VehicleUsageRow(usage: usage, maxTrips: maxTrips),
              ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// One compact row: vehicle name, a proportional bar for trip count,
/// and (only when available) its distance/odometer reading.
class VehicleUsageRow extends StatelessWidget {
  const VehicleUsageRow({super.key, required this.usage, required this.maxTrips});

  final VehicleUsage usage;
  final int maxTrips;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            usage.vehicleName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usage.tripCount / maxTrips,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            usage.distanceKm != null
                ? '${usage.distanceKm!.toStringAsFixed(0)} km'
                : '${usage.tripCount} trip${usage.tripCount == 1 ? '' : 's'}',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
